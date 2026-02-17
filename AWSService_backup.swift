//
//  AWSService.swift
//  PeaTutorApp
//
//  Created by Charles on 11/10/25.
//

import Foundation
import Amplify
import AWSCognitoAuthPlugin
import AWSS3StoragePlugin
import UIKit
import AWSPluginsCore
import AWSAPIPlugin
import AWSDataStorePlugin


// MARK: - AWS Service with Auth + Storage
@MainActor
class AWSService: ObservableObject {
    static let shared = AWSService()
    
    @Published var isConfigured = false
    @Published var isSignedIn = false
    @Published var currentUser: AuthUser?
    
    private init() {
        configureAmplify()
    }
    
    // In AWSService.swift - configureAmplify() method

    private func configureAmplify() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin())
            
            // 🆕 ADD THESE TWO LINES
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: AmplifyModels()))
            
            try Amplify.configure()
            
            print("✅ Sprint 3.1: Amplify configured with DataStore")
            isConfigured = true
            
            Task {
                await checkAuthStatus()
            }
        } catch {
            print("❌ Failed to configure Amplify: \(error)")
        }
    }
    
    // MARK: - Authentication Methods (from Sprint 1)
    
    func checkAuthStatus() async {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            isSignedIn = session.isSignedIn
            
            if isSignedIn {
                currentUser = try await Amplify.Auth.getCurrentUser()
                print("✅ User signed in: \(currentUser?.username ?? "unknown")")
            } else {
                print("ℹ️ No user signed in")
            }
        } catch {
            print("❌ Failed to check auth status: \(error)")
            isSignedIn = false
        }
    }
    
    func signUp(email: String, password: String, fullName: String) async throws -> Bool {
        let userAttributes = [
            AuthUserAttribute(.email, value: email),
            AuthUserAttribute(.name, value: fullName)
        ]
        
        let options = AuthSignUpRequest.Options(userAttributes: userAttributes)
        
        let result = try await Amplify.Auth.signUp(
            username: email,
            password: password,
            options: options
        )
        
        print("✅ Sign up result: \(result)")
        
        if case .confirmUser = result.nextStep {
            return false // Need to confirm email
        }
        
        return true
    }
    
    func confirmSignUp(email: String, code: String) async throws {
        let result = try await Amplify.Auth.confirmSignUp(
            for: email,
            confirmationCode: code
        )
        print("✅ Confirmation result: \(result)")
    }
    
    func signIn(email: String, password: String) async throws {
        let result = try await Amplify.Auth.signIn(
            username: email,
            password: password
        )
        
        if result.isSignedIn {
            await checkAuthStatus()
            print("✅ User signed in successfully")
        }
    }
    
    // ✅ REVISED: Logout without clearing local data
    func signOut() async {
        do {
            let username = currentUser?.username ?? "unknown"
            print("🚪 Signing out user: \(username)")
            
            // 1. Sign out from AWS Cognito
            try await Amplify.Auth.signOut()
            print("✅ Cognito sign out complete")
            
            // 2. ✅ KEEP LOCAL HISTORY - Don't clear SwiftData
            // History will persist and be filtered by userId when user logs back in
            print("ℹ️  Local history preserved (filtered by userId)")
            
            // 3. Clear DataStore sync state (but keep local data)
            // DataStore will re-sync when user logs back in
            do {
                try await DataStoreService.shared.stopDataStoreForLogout()
                print("✅ DataStore stopped (will restart on login)")
            } catch {
                print("⚠️ DataStore stop failed (non-critical): \(error)")
            }
            
            // 4. Clear only temporary files (not persistent data)
            await clearTemporaryFiles()
            print("✅ Temporary files cleared")
            
            // 5. Update state
            await MainActor.run {
                self.isSignedIn = false
                self.currentUser = nil
            }
            
            print("✅ User '\(username)' signed out - history preserved for next login")
            
        } catch {
            print("❌ Sign out failed: \(error)")
            await MainActor.run {
                self.isSignedIn = false
                self.currentUser = nil
            }
        }
    }

    // ✅ RENAMED: Only clear temporary files, not persistent data
    private func clearTemporaryFiles() async {
        await Task.detached {
            // Clear ONLY temporary directory (not Documents or other persistent storage)
            let tempDir = FileManager.default.temporaryDirectory
            do {
                let tempFiles = try FileManager.default.contentsOfDirectory(
                    at: tempDir,
                    includingPropertiesForKeys: nil
                )
                
                var clearedCount = 0
                for file in tempFiles {
                    do {
                        try FileManager.default.removeItem(at: file)
                        clearedCount += 1
                    } catch {
                        // Ignore errors - some temp files may be in use
                    }
                }
                if clearedCount > 0 {
                    print("✅ Cleared \(clearedCount) temporary files")
                }
                
            } catch {
                print("⚠️ Failed to enumerate temp files: \(error)")
            }
        }.value
    }
    
    // MARK: - Storage Methods (Manual Path Construction for ap-southeast-2)

    // MARK: - Storage Methods (Manual Path Construction)

    private func getIdentityId() async throws -> String {
        let session = try await Amplify.Auth.fetchAuthSession()
        
        // ✅ Correct way to get identity ID in Amplify
        if let identityProvider = session as? AuthCognitoIdentityProvider {
            let identityIdResult = try identityProvider.getIdentityId().get()
            return identityIdResult
        }
        
        // Fallback: try to get from credentials provider
        guard let cognitoSession = session as? AuthCognitoTokensProvider else {
            throw NSError(domain: "AWSService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Could not get Cognito session"])
        }
        
        // If we can't get identity ID, use user sub as identifier
        let tokens = try cognitoSession.getCognitoTokens().get()
        let userSub = tokens.idToken
        
        throw NSError(domain: "AWSService", code: -2,
                     userInfo: [NSLocalizedDescriptionKey: "Could not retrieve Cognito Identity ID"])
    }

    /// Upload worksheet file (PDF, DOCX, image)
    func uploadWorksheet(data: Data, filename: String, mimeType: String) async throws -> String {
        let identityId = try await getIdentityId()
        
        let timestamp = Date().timeIntervalSince1970
        let uniqueFilename = "\(timestamp)_\(filename)"
        
        // Manually construct private path with identity ID
        let key = "private/\(identityId)/worksheets/\(uniqueFilename)"
        
        print("📤 Uploading worksheet: \(filename)")
        print("📤 Bucket: peatutorstorage7d0e5-dev")
        print("📤 Region: ap-southeast-2")
        print("📤 S3 Key: \(key)")
        print("🆔 Identity ID: \(identityId)")
        
        let options = StorageUploadDataRequest.Options(
            accessLevel: .guest,  // Use guest with manual path
            metadata: [
                "contentType": mimeType,
                "originalFilename": filename,
                "uploadedAt": ISO8601DateFormatter().string(from: Date())
            ]
        )
        
        let uploadTask = Amplify.Storage.uploadData(
            path: .fromString(key),
            data: data,
            options: options
        )
        
        // Monitor progress
        Task {
            for await progress in await uploadTask.progress {
                let percent = Int(progress.fractionCompleted * 100)
                print("📊 Upload progress: \(percent)%")
            }
        }
        
        _ = try await uploadTask.value
        print("✅ Upload complete: \(key)")
        
        return key
    }

    /// Upload solution image from camera
    func uploadSolutionImage(
        _ imageData: Data,
        worksheetId: String,
        questionId: String
    ) async throws -> String {
        
        let identityId = try await getIdentityId()
        
        // Create unique filename with timestamp
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "\(questionId)-\(timestamp).jpg"
        
        // Construct S3 path: private/{identityId}/solutions/{worksheetId}/{filename}
        let key = "private/\(identityId)/solutions/\(worksheetId)/\(filename)"
        
        print("📤 Uploading solution image to S3")
        print("📍 Key: \(key)")
        print("📊 Size: \(imageData.count) bytes")
        
        let options = StorageUploadDataRequest.Options(
            accessLevel: .guest,
            metadata: [
                "worksheetId": worksheetId,
                "questionId": questionId,
                "timestamp": String(timestamp)
            ]
        )
        
        let uploadTask = Amplify.Storage.uploadData(
            path: .fromString(key),
            data: imageData,
            options: options
        )
        
        // Monitor progress
        Task {
            for await progress in await uploadTask.progress {
                let percent = Int(progress.fractionCompleted * 100)
                if percent % 20 == 0 { // Log every 20%
                    print("📊 Upload progress: \(percent)%")
                }
            }
        }
        
        let result = try await uploadTask.value
        print("✅ Upload complete: \(result)")
        
        return key
    }

    /// Download file from S3
    func downloadFile(key: String) async throws -> Data {
        print("📥 Downloading file: \(key)")
        
        let options = StorageDownloadDataRequest.Options(
            accessLevel: .guest
        )
        
        let downloadTask = Amplify.Storage.downloadData(
            path: .fromString(key),
            options: options
        )
        
        // Monitor progress
        Task {
            for await progress in await downloadTask.progress {
                let percent = Int(progress.fractionCompleted * 100)
                print("📊 Download progress: \(percent)%")
            }
        }
        
        let result = try await downloadTask.value
        print("✅ Download complete: \(result.count) bytes")
        
        return result
    }

    /// Get signed URL for file (valid for 15 minutes)
    func getFileURL(key: String) async throws -> URL {
        print("🔗 Generating signed URL for: \(key)")
        
        let options = StorageGetURLRequest.Options(
            accessLevel: .guest,
            expires: 900
        )
        
        let result = try await Amplify.Storage.getURL(
            path: .fromString(key),
            options: options
        )
        print("✅ Generated URL (valid for 15 min)")
        
        return result
    }

    /// List user's uploaded worksheets
    func listWorksheets() async throws -> [StorageListResult.Item] {
        let identityId = try await getIdentityId()
        let prefix = "private/\(identityId)/worksheets/"
        
        print("📂 Listing worksheets")
        print("📂 Prefix: \(prefix)")
        print("🆔 Identity ID: \(identityId)")
        
        let options = StorageListRequest.Options(
            accessLevel: .guest,
            pageSize: 1000
        )
        
        let result = try await Amplify.Storage.list(
            path: .fromString(prefix),
            options: options
        )
        
        print("✅ Found \(result.items.count) worksheet(s)")
        
        // Debug: Print first few items
        for (index, item) in result.items.prefix(3).enumerated() {
            print("📄 Item \(index + 1): \(item.key)")
        }
        
        return result.items
    }

    /// List user's solution images
    func listSolutions() async throws -> [StorageListResult.Item] {
        let identityId = try await getIdentityId()
        let prefix = "private/\(identityId)/solutions/"
        
        print("📂 Listing solutions")
        print("📂 Prefix: \(prefix)")
        print("🆔 Identity ID: \(identityId)")
        
        let options = StorageListRequest.Options(
            accessLevel: .guest,
            pageSize: 1000
        )
        
        let result = try await Amplify.Storage.list(
            path: .fromString(prefix),
            options: options
        )
        
        print("✅ Found \(result.items.count) solution(s)")
        
        // Debug: Print first few items
        for (index, item) in result.items.prefix(3).enumerated() {
            print("📄 Item \(index + 1): \(item.key)")
        }
        
        return result.items
    }

    /// Delete file from S3
    func deleteFile(key: String) async throws {
        print("🗑️ Deleting file: \(key)")
        
        let options = StorageRemoveRequest.Options(
            accessLevel: .guest
        )
        
        try await Amplify.Storage.remove(
            path: .fromString(key),
            options: options
        )
        print("✅ Deleted: \(key)")
    }

    // MARK: - Helpers

    private var currentUserId: String {
        return currentUser?.userId ?? "guest"
    }
}


