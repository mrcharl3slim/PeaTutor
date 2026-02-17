//
//  AWSService.swift
//  PeaTutorApp
//
//  Created by Charles on 11/10/25.
//  Updated for Sprint 4: Multi-User Role System
//

import Foundation
import Amplify
import AWSCognitoAuthPlugin
import AWSS3StoragePlugin
import UIKit
import AWSPluginsCore
import AWSAPIPlugin
import AWSDataStorePlugin

// MARK: - AWS Service with Auth + Storage + Multi-User Features
@MainActor
class AWSService: ObservableObject {
    static let shared = AWSService()
    
    // Basic state
    @Published var isConfigured = false
    @Published var isSignedIn = false
    @Published var currentUser: AuthUser?
    
    // Sprint 4: Role-based state
    @Published var currentUserId: String?
    @Published var currentUserRole: UserRole?
    @Published var currentUserProfile: UserProfile?
    
    private init() {
        configureAmplify()
    }
    
    // MARK: - Amplify Configuration
    
    private func configureAmplify() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin())
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: AmplifyModels()))
            
            try Amplify.configure()
            
            print("✅ Sprint 4: Amplify configured with DataStore + Multi-User")
            isConfigured = true
            
            Task {
                await checkAuthStatus()
            }
        } catch {
            print("❌ Failed to configure Amplify: \(error)")
        }
    }
    
    // MARK: - Authentication Methods
    
    func checkAuthStatus() async {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            isSignedIn = session.isSignedIn
            
            if isSignedIn {
                currentUser = try await Amplify.Auth.getCurrentUser()
                currentUserId = currentUser?.userId
                print("✅ User signed in: \(currentUser?.username ?? "unknown")")
                
                // Fetch user profile with role
                if let userId = currentUserId {
                    await fetchUserProfile(userId: userId)
                }
            } else {
                print("ℹ️ No user signed in")
            }
        } catch {
            print("❌ Failed to check auth status: \(error)")
            isSignedIn = false
        }
    }
    
    /// Sign up with role - Sprint 4 Updated
    func signUp(
        email: String,
        password: String,
        displayName: String,
        role: UserRole
    ) async throws -> Bool {  // ✅ Changed return type to just Bool
        let userAttributes = [
            AuthUserAttribute(.email, value: email),
            AuthUserAttribute(.name, value: displayName)
            // Role will be stored in UserProfile table after confirmation
        ]
        
        let options = AuthSignUpRequest.Options(userAttributes: userAttributes)
        
        let signUpResult = try await Amplify.Auth.signUp(
            username: email,
            password: password,
            options: options
        )
        
        print("✅ Sign up result: \(signUpResult)")
        
        let needsConfirmation: Bool
        switch signUpResult.nextStep {
        case .confirmUser:
            print("Confirmation required")
            needsConfirmation = true
        case .done, .completeAutoSignIn:
            needsConfirmation = false
        @unknown default:
            needsConfirmation = false
        }
        
        // ✅ Store role temporarily - will create UserProfile after sign-in
        // Save role to UserDefaults temporarily
        UserDefaults.standard.set(role.rawValue, forKey: "pendingUserRole_\(email)")
        UserDefaults.standard.set(displayName, forKey: "pendingDisplayName_\(email)")
        
        print("✅ Sign up complete. Role: \(role.displayName)")
        print("ℹ️ UserProfile will be created after email confirmation and sign-in")
        
        return needsConfirmation  // ✅ Return just the Bool
    }
    
    /// Confirm sign up - Sprint 4 Updated
    func confirmSignUp(email: String, code: String) async throws -> String {
        print("🔐 Attempting to confirm user: \(email)")
        
        do {
            let confirmResult = try await Amplify.Auth.confirmSignUp(
                for: email,
                confirmationCode: code
            )
            
            print("✅ Confirmation API call successful")
            print("✅ Is sign up complete: \(confirmResult.isSignUpComplete)")
            
            let user = try await Amplify.Auth.getCurrentUser()
            print("✅ Got userId: \(user.userId)")
            
            return user.userId
            
        } catch let error as AuthError {
            print("❌ Confirmation error: \(error)")
            print("❌ Error description: \(error.errorDescription)")
            
            let errorDescription = error.errorDescription.lowercased()
            
            // ✅ CRITICAL FIX: Handle "already confirmed" - Error 6
            // This happens when user status is CONFIRMED in Cognito
            if error.errorDescription.contains("CONFIRMED") ||
               error.errorDescription.contains("confirmed") ||
               errorDescription.contains("error 6") {
                
                print("ℹ️ User already confirmed - getting userId")
                
                // User is confirmed, just get their ID
                do {
                    let user = try await Amplify.Auth.getCurrentUser()
                    print("✅ Got userId for already confirmed user: \(user.userId)")
                    return user.userId
                } catch {
                    print("❌ Can't get current user: \(error)")
                    
                    // Throw specific error with code 6
                    throw NSError(
                        domain: "Auth",
                        code: 6,
                        userInfo: [NSLocalizedDescriptionKey:
                            "User already confirmed. Please sign in instead."]
                    )
                }
            }
            
            // Handle invalid code
            if errorDescription.contains("codemismatch") ||
               errorDescription.contains("invalid") ||
               errorDescription.contains("incorrect") {
                throw NSError(
                    domain: "Auth",
                    code: 1002,
                    userInfo: [NSLocalizedDescriptionKey:
                        "Invalid confirmation code. Please check your email and try again."]
                )
            }
            
            // Handle expired code
            if errorDescription.contains("expired") {
                throw NSError(
                    domain: "Auth",
                    code: 1003,
                    userInfo: [NSLocalizedDescriptionKey:
                        "Confirmation code has expired. Please request a new code."]
                )
            }
            
            // Handle user not found
            if errorDescription.contains("not found") {
                throw NSError(
                    domain: "Auth",
                    code: 1004,
                    userInfo: [NSLocalizedDescriptionKey:
                        "User not found. Please sign up first."]
                )
            }
            
            // If we still got error 6 but didn't catch it above
            if let nsError = error as? NSError, nsError.code == 6 {
                throw NSError(
                    domain: "Auth",
                    code: 6,
                    userInfo: [NSLocalizedDescriptionKey:
                        "User already confirmed. Please sign in instead."]
                )
            }
            
            // Generic error
            print("❌ Unhandled error type: \(error)")
            throw error
        }
    }
    
    func resendConfirmationCode(email: String) async throws {
        print("📧 Resending confirmation code...")
        
        do {
            let result = try await Amplify.Auth.resendSignUpCode(for: email)
            print("✅ Code resent successfully")
        } catch {
            print("❌ Failed to resend code: \(error)")
            throw NSError(
                domain: "Auth",
                code: 1005,
                userInfo: [NSLocalizedDescriptionKey:
                    "Failed to resend code. Please try again later."]
            )
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            let result = try await Amplify.Auth.signIn(
                username: email,
                password: password
            )
            
            if result.isSignedIn {
                await checkAuthStatus()
                print("✅ User signed in successfully")
            }
            
        } catch let error as AuthError {
            let errorDescription = error.errorDescription.lowercased()
            
            // User not confirmed
            if errorDescription.contains("not") && errorDescription.contains("confirmed") {
                throw NSError(
                    domain: "Auth",
                    code: 1006,
                    userInfo: [NSLocalizedDescriptionKey:
                        "Please verify your email first. Check your inbox for the confirmation code."]
                )
            }
            
            // Invalid credentials
            if errorDescription.contains("incorrect") ||
               errorDescription.contains("invalid") {
                throw NSError(
                    domain: "Auth",
                    code: 1007,
                    userInfo: [NSLocalizedDescriptionKey:
                        "Invalid email or password. Please try again."]
                )
            }
            
            // User not found
            if errorDescription.contains("user") && errorDescription.contains("not") {
                throw NSError(
                    domain: "Auth",
                    code: 1008,
                    userInfo: [NSLocalizedDescriptionKey:
                        "No account found with this email. Please sign up first."]
                )
            }
            
            throw error
        }
    }
    
    func signOut() async {
        do {
            let username = currentUser?.username ?? "unknown"
            print("🚪 Signing out user: \(username)")
            
            // 1. Sign out from AWS Cognito
            try await Amplify.Auth.signOut()
            print("✅ Cognito sign out complete")
            
            // 2. Keep local history - filtered by userId on next login
            print("ℹ️  Local history preserved (filtered by userId)")
            
            // 3. Clear DataStore sync state
            do {
                try await DataStoreService.shared.stopDataStoreForLogout()
                print("✅ DataStore stopped (will restart on login)")
            } catch {
                print("⚠️ DataStore stop failed (non-critical): \(error)")
            }
            
            // 4. Clear temporary files
            await clearTemporaryFiles()
            print("✅ Temporary files cleared")
            
            // 5. Update state
            await MainActor.run {
                self.isSignedIn = false
                self.currentUser = nil
                self.currentUserId = nil
                self.currentUserRole = nil
                self.currentUserProfile = nil
            }
            
            print("✅ User '\(username)' signed out - history preserved for next login")
            
        } catch {
            print("❌ Sign out failed: \(error)")
            await MainActor.run {
                self.isSignedIn = false
                self.currentUser = nil
                self.currentUserId = nil
                self.currentUserRole = nil
                self.currentUserProfile = nil
            }
        }
    }
    
    private func clearTemporaryFiles() async {
        await Task.detached {
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
    
    // MARK: - User Profile Management (Sprint 4)
    
    func fetchUserProfile(userId: String) async {
        do {
            print("⏳ Fetching profile from cloud...")
            
            // Try cloud first (GraphQL query)
            let request = GraphQLRequest<UserProfile>.list(
                UserProfile.self,
                where: UserProfile.keys.userId == userId
            )
            
            let result = try await Amplify.API.query(request: request)
            
            switch result {
            case .success(let profiles):
                if let profile = profiles.first {
                    // Save to DataStore for offline access
                    let saved = try await Amplify.DataStore.save(profile)
                    
                    await MainActor.run {
                        self.currentUserProfile = saved
                        self.currentUserRole = saved.userRole
                        print("✅ Profile loaded from cloud: \(saved.displayName) (\(saved.userRole.rawValue))")
                    }
                } else {
                    print("⚠️ No profile found in cloud for userId: \(userId)")
                }
                
            case .failure(let error):
                print("❌ Cloud query failed: \(error.errorDescription)")
                
                // Fallback to local DataStore
                await fetchFromLocalDataStore(userId: userId)
            }
            
        } catch {
            print("❌ Error fetching profile: \(error)")
            
            // Fallback to local DataStore
            await fetchFromLocalDataStore(userId: userId)
        }
    }

    private func fetchFromLocalDataStore(userId: String) async {
        do {
            let profiles = try await Amplify.DataStore.query(
                UserProfile.self,
                where: UserProfile.keys.userId == userId
            )
            
            if let profile = profiles.first {
                await MainActor.run {
                    self.currentUserProfile = profile
                    self.currentUserRole = profile.userRole
                    print("✅ Profile loaded from local: \(profile.displayName)")
                }
            } else {
                print("⚠️ No profile found locally for userId: \(userId)")
            }
        } catch {
            print("❌ Error querying local DataStore: \(error)")
        }
    }
    
    func createUserProfile(
        userId: String,
        email: String,
        displayName: String,
        role: UserRole,
        schoolName: String? = nil,
        gradeLevel: String? = nil
    ) async throws -> UserProfile {
        let profile = UserProfile(
            id: UUID().uuidString,
            userId: userId,
            email: email,
            userRole: role,
            displayName: displayName,
            schoolName: schoolName,
            gradeLevel: gradeLevel,
            profileImageUrl: nil,
            onboardingCompleted: false,
            createdAt: Temporal.DateTime.now(),
            updatedAt: Temporal.DateTime.now()
        )
        
        try await Amplify.DataStore.save(profile)
        print("✅ UserProfile created: \(displayName) (\(role.rawValue))")
        
        await MainActor.run {
            self.currentUserProfile = profile
            self.currentUserRole = role
        }
        
        return profile
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws {
        var updatedProfile = profile
        updatedProfile.updatedAt = Temporal.DateTime.now()
        
        try await Amplify.DataStore.save(updatedProfile)
        print("✅ UserProfile updated: \(profile.displayName)")
        
        await MainActor.run {
            self.currentUserProfile = updatedProfile
        }
    }
    
    func completeOnboarding() async throws {
        guard var profile = currentUserProfile else {
            throw AWSServiceError.profileNotFound
        }
        
        profile.onboardingCompleted = true
        try await updateUserProfile(profile)
    }
    
    func fetchUserProfileByEmail(_ email: String) async throws -> UserProfile? {
        let profiles = try await Amplify.DataStore.query(
            UserProfile.self,
            where: UserProfile.keys.email == email
        )
        return profiles.first
    }
    
    // MARK: - Class Management (Sprint 4)
    
    func createClass(
        className: String,
        subject: String?,
        description: String?,
        gradeLevel: String?
    ) async throws -> Classroom {
        guard let userId = currentUserId, currentUserRole == .teacher else {
            throw AWSServiceError.unauthorized
        }
        
        let classCode = generateClassCode()
        
        let newClass = Classroom(
            id: UUID().uuidString,
            teacherId: userId,
            className: className,
            classCode: classCode,
            subject: subject,
            description: description,
            gradeLevel: gradeLevel,
            isActive: true,
            createdAt: Temporal.DateTime.now(),
            updatedAt: Temporal.DateTime.now()
        )
        
        try await Amplify.DataStore.save(newClass)
        print("✅ Class created: \(className) (Code: \(classCode))")
        
        return newClass
    }
    
    private func generateClassCode() -> String {
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Exclude similar chars
        return String((0..<6).map { _ in letters.randomElement()! })
    }
    
    func fetchTeacherClasses() async throws -> [Classroom] {
        guard let userId = currentUserId, currentUserRole == .teacher else {
            throw AWSServiceError.unauthorized
        }
        
        return try await Amplify.DataStore.query(
            Classroom.self,
            where: Classroom.keys.teacherId == userId
        )
    }
    
    func findClassByCode(_ code: String) async throws -> Classroom? {
        let classes = try await Amplify.DataStore.query(
            Classroom.self,
            where: Classroom.keys.classCode == code.uppercased()
        )
        return classes.first
    }
    
    // MARK: - Student Enrollment (Sprint 4)
    
    func joinClass(classCode: String) async throws -> ClassroomMembership {
        guard let userId = currentUserId, currentUserRole == .student else {
            throw AWSServiceError.unauthorized
        }
        
        guard let classModel = try await findClassByCode(classCode) else {
            throw ClassError.classNotFound
        }
        
        // Check if already a member
        let existing = try await Amplify.DataStore.query(
            ClassroomMembership.self,
            where: ClassroomMembership.keys.classroom.eq(classModel.id)
                && ClassroomMembership.keys.studentId == userId
        )
        
        if let existingMembership = existing.first {
            print("ℹ️ Already a member of this class")
            return existingMembership
        }
        
        let membership = ClassroomMembership(
            studentId: userId,
            status: .approved, // Auto-approve for now
            enrolledAt: Temporal.DateTime.now(),
            approvedAt: Temporal.DateTime.now(),
            approvedBy: classModel.teacherId,
            classroom: classModel
        )
        
        try await Amplify.DataStore.save(membership)
        print("✅ Joined class: \(classModel.className)")
        
        // Update student's profile with classroom grade level if not already set
        if let classroomGradeLevel = classModel.gradeLevel {
            await updateStudentGradeLevelIfNeeded(userId: userId, gradeLevel: classroomGradeLevel)
        }
        
        return membership
    }
    
    /// Update student's grade level when they join a class
    /// Only updates if the student doesn't have a grade level set yet
    private func updateStudentGradeLevelIfNeeded(userId: String, gradeLevel: String) async {
        do {
            let profiles = try await Amplify.DataStore.query(
                UserProfile.self,
                where: UserProfile.keys.userId == userId
            )
            
            guard var profile = profiles.first else {
                print("⚠️ Could not find profile to update grade level")
                return
            }
            
            // Only update if grade level is not already set
            if profile.gradeLevel == nil || profile.gradeLevel?.isEmpty == true {
                profile.gradeLevel = gradeLevel
                try await Amplify.DataStore.save(profile)
                
                // Update local state
                self.currentUserProfile = profile
                
                print("✅ Updated student grade level to: \(gradeLevel)")
            } else {
                print("ℹ️ Student already has grade level: \(profile.gradeLevel ?? "unknown")")
            }
        } catch {
            print("⚠️ Failed to update student grade level: \(error)")
        }
    }
    
    func fetchStudentClasses() async throws -> [Classroom] {
        guard let userId = currentUserId, currentUserRole == .student else {
            throw AWSServiceError.unauthorized
        }
        
        let memberships = try await Amplify.DataStore.query(
            ClassroomMembership.self,
            where: ClassroomMembership.keys.studentId == userId
                && ClassroomMembership.keys.status == MembershipStatus.approved.rawValue
        )
        
        var classes: [Classroom] = []
        for membership in memberships {
            if let classroom = membership.classroom {
                        classes.append(classroom)
                    }
        }
        
        return classes
    }
    
    // MARK: - Parent-Child Linking (Sprint 4)
    
    func generateChildLinkingCode() async throws -> ParentChildRelationship {
        guard let userId = currentUserId, currentUserRole == .student else {
            throw AWSServiceError.unauthorized
        }
        
        let linkingCode = generateLinkingCode()
        
        let relationship = ParentChildRelationship(
            id: UUID().uuidString,
            parentId: "PENDING", // Will be filled when parent links
            childId: userId,
            linkingCode: linkingCode,
            relationshipType: .parent,
            status: .pending,
            createdAt: Temporal.DateTime.now()
        )
        
        try await Amplify.DataStore.save(relationship)
        print("✅ Generated linking code: \(linkingCode)")
        
        return relationship
    }
    
    private func generateLinkingCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<8).map { _ in chars.randomElement()! })
    }
    
    func linkToChild(linkingCode: String, relationshipType: RelationshipType) async throws -> ParentChildRelationship {
        guard let userId = currentUserId, currentUserRole == .parent else {
            throw AWSServiceError.unauthorized
        }
        
        let relationships = try await Amplify.DataStore.query(
            ParentChildRelationship.self,
            where: ParentChildRelationship.keys.linkingCode == linkingCode.uppercased()
        )
        
        guard var relationship = relationships.first else {
            throw LinkError.invalidCode
        }
        
        relationship.parentId = userId
        relationship.relationshipType = relationshipType
        relationship.status = .approved
        relationship.approvedAt = Temporal.DateTime.now()
        
        try await Amplify.DataStore.save(relationship)
        print("✅ Linked to child")
        
        return relationship
    }
    
    func fetchLinkedChildren() async throws -> [UserProfile] {
        guard let userId = currentUserId, currentUserRole == .parent else {
            throw AWSServiceError.unauthorized
        }
        
        let relationships = try await Amplify.DataStore.query(
            ParentChildRelationship.self,
            where: ParentChildRelationship.keys.parentId == userId
                && ParentChildRelationship.keys.status == LinkStatus.approved.rawValue
        )
        
        var children: [UserProfile] = []
        for relationship in relationships {
            let profiles = try await Amplify.DataStore.query(
                UserProfile.self,
                where: UserProfile.keys.userId == relationship.childId
            )
            if let profile = profiles.first {
                children.append(profile)
            }
        }
        
        return children
    }
    
    // MARK: - Storage Methods (Your Existing Implementation - Keep As-Is)
    
    private func getIdentityId() async throws -> String {
        let session = try await Amplify.Auth.fetchAuthSession()
        
        if let identityProvider = session as? AuthCognitoIdentityProvider {
            let identityIdResult = try identityProvider.getIdentityId().get()
            return identityIdResult
        }
        
        guard let cognitoSession = session as? AuthCognitoTokensProvider else {
            throw NSError(domain: "AWSService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Could not get Cognito session"])
        }
        
        let tokens = try cognitoSession.getCognitoTokens().get()
        let userSub = tokens.idToken
        
        throw NSError(domain: "AWSService", code: -2,
                     userInfo: [NSLocalizedDescriptionKey: "Could not retrieve Cognito Identity ID"])
    }
    
    func uploadWorksheet(data: Data, filename: String, mimeType: String) async throws -> String {
        let identityId = try await getIdentityId()
        
        let timestamp = Date().timeIntervalSince1970
        let uniqueFilename = "\(timestamp)_\(filename)"
        
        let key = "private/\(identityId)/worksheets/\(uniqueFilename)"
        
        print("📤 Uploading worksheet: \(filename)")
        print("📤 S3 Key: \(key)")
        print("🆔 Identity ID: \(identityId)")
        
        let options = StorageUploadDataRequest.Options(
            accessLevel: .guest,
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
    
    func uploadSolutionImage(
        _ imageData: Data,
        worksheetId: String,
        questionId: String
    ) async throws -> String {
        
        let identityId = try await getIdentityId()
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "\(questionId)-\(timestamp).jpg"
        
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
        
        Task {
            for await progress in await uploadTask.progress {
                let percent = Int(progress.fractionCompleted * 100)
                if percent % 20 == 0 {
                    print("📊 Upload progress: \(percent)%")
                }
            }
        }
        
        let result = try await uploadTask.value
        print("✅ Upload complete: \(result)")
        
        return key
    }
    
    func downloadFile(key: String) async throws -> Data {
        print("📥 Downloading file: \(key)")
        
        let options = StorageDownloadDataRequest.Options(
            accessLevel: .guest
        )
        
        let downloadTask = Amplify.Storage.downloadData(
            path: .fromString(key),
            options: options
        )
        
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
    
    func listWorksheets() async throws -> [StorageListResult.Item] {
        let identityId = try await getIdentityId()
        let prefix = "private/\(identityId)/worksheets/"
        
        print("📂 Listing worksheets")
        print("📂 Prefix: \(prefix)")
        
        let options = StorageListRequest.Options(
            accessLevel: .guest,
            pageSize: 1000
        )
        
        let result = try await Amplify.Storage.list(
            path: .fromString(prefix),
            options: options
        )
        
        print("✅ Found \(result.items.count) worksheet(s)")
        
        for (index, item) in result.items.prefix(3).enumerated() {
            print("📄 Item \(index + 1): \(item.key)")
        }
        
        return result.items
    }
    
    func listSolutions() async throws -> [StorageListResult.Item] {
        let identityId = try await getIdentityId()
        let prefix = "private/\(identityId)/solutions/"
        
        print("📂 Listing solutions")
        print("📂 Prefix: \(prefix)")
        
        let options = StorageListRequest.Options(
            accessLevel: .guest,
            pageSize: 1000
        )
        
        let result = try await Amplify.Storage.list(
            path: .fromString(prefix),
            options: options
        )
        
        print("✅ Found \(result.items.count) solution(s)")
        
        for (index, item) in result.items.prefix(3).enumerated() {
            print("📄 Item \(index + 1): \(item.key)")
        }
        
        return result.items
    }
    
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
    
    private func waitForDataStoreSync() async {
        print("⏳ Waiting for DataStore sync...")
        
        await withCheckedContinuation { continuation in
            var resumed = false
            
            let subscription = Amplify.Hub.listen(to: .dataStore) { payload in
                if payload.eventName == HubPayload.EventName.DataStore.syncQueriesReady {
                    if !resumed {
                        resumed = true
                        print("✅ DataStore sync completed")
                        continuation.resume()
                    }
                }
            }
            
            // Timeout after 5 seconds
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                if !resumed {
                    resumed = true
                    print("⏱️ Sync timeout - proceeding anyway")
                    continuation.resume()
                }
            }
        }
    }
    
}

// MARK: - Error Types

enum AWSServiceError: LocalizedError {
    case profileNotFound
    case invalidRole
    case unauthorized
    case signUpIncomplete
    
    var errorDescription: String? {
        switch self {
        case .profileNotFound:
            return "User profile not found"
        case .invalidRole:
            return "Invalid user role"
        case .unauthorized:
            return "You are not authorized to perform this action"
        case .signUpIncomplete:
            return "Please complete sign up process"
        }
    }
}

enum ClassError: LocalizedError {
    case classNotFound
    case alreadyMember
    
    var errorDescription: String? {
        switch self {
        case .classNotFound: return "Class not found"
        case .alreadyMember: return "Already a member of this class"
        }
    }
}

enum LinkError: LocalizedError {
    case invalidCode
    case alreadyLinked
    
    var errorDescription: String? {
        switch self {
        case .invalidCode: return "Invalid linking code"
        case .alreadyLinked: return "Already linked to this child"
        }
    }
}
