//
//  LinkChildView.swift
//  PeaTutorApp
//
//  Created by Charles on 19/10/25.
//

import SwiftUI
import Amplify

struct LinkChildView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var awsService = AWSService.shared
    
    @State private var linkingCode = ""
    @State private var relationshipType: RelationshipType = .parent
    @State private var isLinking = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var linkedChild: UserProfile?
    
    var onChildLinked: () async -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "link")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                    }
                    
                    Text("Link Child Account")
                        .font(.title.bold())
                    
                    Text("Enter the linking code provided by your child")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Linking Code Input
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Linking Code")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        
                        TextField("ABCD1234", text: $linkingCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .tracking(4)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .onChange(of: linkingCode) { _, newValue in
                                linkingCode = String(newValue.uppercased().prefix(8))
                            }
                    }
                    
                    // Relationship Type Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Relationship")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        
                        Picker("Relationship Type", selection: $relationshipType) {
                            ForEach([RelationshipType.parent, .guardian, .tutor], id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Info Card
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("How to get a linking code")
                                .font(.caption.bold())
                            Text("Ask your child to generate a code in their account settings")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Link Button
                Button(action: {
                    Task {
                        await linkChild()
                    }
                }) {
                    Text("Link Child Account")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(linkingCode.count == 8 ? Color.blue : Color.gray)
                        .cornerRadius(16)
                }
                .disabled(linkingCode.count != 8 || isLinking)
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .disabled(isLinking)
            .overlay {
                if isLinking {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Linking account...")
                                .font(.headline)
                        }
                        .padding(32)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .sheet(isPresented: $showSuccess) {
                if let linkedChild = linkedChild {
                    ChildLinkedSuccessView(child: linkedChild) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func linkChild() async {
        guard linkingCode.count == 8 else { return }
        
        isLinking = true
        
        do {
            let relationship = try await awsService.linkToChild(
                linkingCode: linkingCode,
                relationshipType: relationshipType
            )
            
            // Fetch child profile
            let profiles = try await Amplify.DataStore.query(
                UserProfile.self,
                where: UserProfile.keys.userId == relationship.childId
            )
            
            if let profile = profiles.first {
                await MainActor.run {
                    self.linkedChild = profile
                    self.showSuccess = true
                }
                
                await onChildLinked()
            }
            
        } catch {
            await MainActor.run {
                if error.localizedDescription.contains("not found") || error.localizedDescription.contains("invalid") {
                    self.errorMessage = "Invalid linking code. Please check and try again."
                } else {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
        
        isLinking = false
    }
}

// MARK: - Success View
struct ChildLinkedSuccessView: View {
    let child: UserProfile
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Success Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.green.gradient)
            }
            
            // Success Message
            VStack(spacing: 8) {
                Text("Successfully Linked!")
                    .font(.title.bold())
                
                Text("You can now monitor their progress")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Child Info Card
            VStack(spacing: 12) {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(child.initials)
                            .font(.title.bold())
                            .foregroundColor(.white)
                    )
                
                VStack(spacing: 4) {
                    Text(child.displayName)
                        .font(.headline)
                    
                    if let gradeLevel = child.gradeLevel {
                        Text(gradeLevel)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
            .padding(.horizontal)
            
            Spacer()
            
            // Done Button
            Button(action: onDismiss) {
                Text("View Dashboard")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Generate Linking Code View (For Students)
struct GenerateLinkingCodeView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var awsService = AWSService.shared
    
    @State private var linkingCode: String?
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showCopiedToast = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "person.badge.key")
                            .font(.system(size: 50))
                            .foregroundColor(.purple)
                    }
                    
                    Text("Link Parent Account")
                        .font(.title.bold())
                    
                    Text("Generate a code for your parent to link to your account")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                if let code = linkingCode {
                    // Display Code
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text("Your Linking Code")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(code)
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .tracking(4)
                                .foregroundColor(.purple)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        Text("Share this code with your parent")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: copyCode) {
                            Label("Copy Code", systemImage: "doc.on.doc")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.purple)
                                .cornerRadius(12)
                        }
                        
                        // Info Card
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.purple)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Code expires in 24 hours")
                                    .font(.caption.bold())
                                Text("Generate a new code if needed")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                } else {
                    // Generate Button
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await generateCode()
                        }
                    }) {
                        Label("Generate Linking Code", systemImage: "key.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.purple)
                            .cornerRadius(16)
                    }
                    .disabled(isGenerating)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .overlay(alignment: .top) {
                if showCopiedToast {
                    Text("Copied to clipboard!")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 60)
                }
            }
            .animation(.spring(), value: showCopiedToast)
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private func generateCode() async {
        isGenerating = true
        
        do {
            let relationship = try await awsService.generateChildLinkingCode()
            await MainActor.run {
                self.linkingCode = relationship.linkingCode
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
        
        isGenerating = false
    }
    
    private func copyCode() {
        guard let code = linkingCode else { return }
        UIPasteboard.general.string = code
        showCopiedToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopiedToast = false
        }
    }
}

#Preview {
    LinkChildView(onChildLinked: {})
}
