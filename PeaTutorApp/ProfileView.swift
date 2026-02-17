//
//  ProfileView.swift
//  PeaTutorApp
//
//  Created by Charles on 19/10/25.
//

import SwiftUI
import Amplify

struct ProfileView: View {
    @StateObject private var awsService = AWSService.shared
    @State private var showEditProfile = false
    @State private var showSignOutConfirmation = false
    @State private var showGenerateLinkingCode = false
    @State private var errorMessage: String?
    
    var body: some View {
        List {
            // Profile Header
            Section {
                profileHeader
            }
            
            // Profile Information
            Section("Profile Information") {
                if let profile = awsService.currentUserProfile {
                    InfoRow(label: "Name", value: profile.displayName, icon: "person.fill")
                    InfoRow(label: "Email", value: profile.email, icon: "envelope.fill")
                    InfoRow(label: "Role", value: profile.userRole.displayName, icon: profile.userRole.icon)
                    
                    if let schoolName = profile.schoolName {
                        InfoRow(label: "School", value: schoolName, icon: "building.2.fill")
                    }
                    
                    if let gradeLevel = profile.gradeLevel {
                        InfoRow(label: "Grade", value: gradeLevel, icon: "graduationcap.fill")
                    }
                }
            }
            
            // Role-specific Sections
            if awsService.currentUserRole == .student {
                studentSpecificSection
            }
            
            // Settings
            Section("Settings") {
                Button(action: { showEditProfile = true }) {
                    Label("Edit Profile", systemImage: "pencil")
                }
                
                NavigationLink {
                    Text("Notifications Settings")
                        .navigationTitle("Notifications")
                } label: {
                    Label("Notifications", systemImage: "bell")
                }
                
                NavigationLink {
                    Text("Privacy & Security")
                        .navigationTitle("Privacy")
                } label: {
                    Label("Privacy & Security", systemImage: "lock.shield")
                }
            }
            
            // App Info
            Section("About") {
                InfoRow(label: "Version", value: "1.0.0 (Sprint 4)", icon: "info.circle")
                
                NavigationLink {
                    Text("Help & Support")
                        .navigationTitle("Help")
                } label: {
                    Label("Help & Support", systemImage: "questionmark.circle")
                }
                
                NavigationLink {
                    Text("Terms & Privacy Policy")
                        .navigationTitle("Legal")
                } label: {
                    Label("Terms & Privacy", systemImage: "doc.text")
                }
            }
            #if DEBUG
            // Developer Tools
            Section("Developer Tools") {
                NavigationLink {
                    AWSSyncTestView()
                } label: {
                    Label("AWS Sync Test", systemImage: "cloud")
                }
            }
            #endif
            
            // Sign Out
            Section {
                Button(role: .destructive, action: { showSignOutConfirmation = true }) {
                    HStack {
                        Spacer()
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditProfile) {
            if let profile = awsService.currentUserProfile {
                EditProfileView(profile: profile)
            }
        }
        .sheet(isPresented: $showGenerateLinkingCode) {
            GenerateLinkingCodeView()
        }
        .alert("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    await signOut()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        HStack(spacing: 16) {
            // Avatar
            if let profile = awsService.currentUserProfile {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(profile.initials)
                            .font(.title.bold())
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.displayName)
                        .font(.title3.bold())
                    
                    HStack(spacing: 8) {
                        Image(systemName: profile.userRole.icon)
                            .font(.caption)
                        Text(profile.userRole.displayName)
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Student-Specific Section
    private var studentSpecificSection: some View {
        Section("Parent Linking") {
            Button(action: { showGenerateLinkingCode = true }) {
                Label("Generate Parent Linking Code", systemImage: "link")
            }
            
            NavigationLink {
                LinkedParentsView()
            } label: {
                Label("Linked Parents", systemImage: "figure.2.and.child.holdinghands")
            }
        }
    }
    
    // MARK: - Sign Out
    private func signOut() async {
        do {
            try await awsService.signOut()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
            }
        }
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var awsService = AWSService.shared
    
    let profile: UserProfile
    @State private var displayName: String
    @State private var schoolName: String
    @State private var gradeLevel: String
    
    @State private var isUpdating = false
    @State private var errorMessage: String?
    
    init(profile: UserProfile) {
        self.profile = profile
        _displayName = State(initialValue: profile.displayName)
        _schoolName = State(initialValue: profile.schoolName ?? "")
        _gradeLevel = State(initialValue: profile.gradeLevel ?? "")
    }
    
    let gradeLevels = ["Primary 1", "Primary 2", "Primary 3", "Primary 4", "Primary 5", "Primary 6",
                       "Secondary 1", "Secondary 2", "Secondary 3", "Secondary 4", "Secondary 5",
                       "Junior College 1", "Junior College 2"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Display Name", text: $displayName)
                    
                    Text(profile.email)
                        .foregroundColor(.secondary)
                }
                
                if profile.userRole == .student {
                    Section("School Information") {
                        TextField("School Name", text: $schoolName)
                        
                        Picker("Grade Level", selection: $gradeLevel) {
                            Text("Select Grade").tag("")
                            ForEach(gradeLevels, id: \.self) { grade in
                                Text(grade).tag(grade)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await updateProfile()
                        }
                    }
                    .disabled(displayName.isEmpty || isUpdating)
                    .bold()
                }
            }
            .disabled(isUpdating)
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private func updateProfile() async {
        isUpdating = true
        
        do {
            var updatedProfile = profile
            updatedProfile.displayName = displayName
            updatedProfile.schoolName = schoolName.isEmpty ? nil : schoolName
            updatedProfile.gradeLevel = gradeLevel.isEmpty ? nil : gradeLevel
            updatedProfile.updatedAt = Temporal.DateTime.now()
            
            try await awsService.updateUserProfile(updatedProfile)
            dismiss()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
        
        isUpdating = false
    }
}

// MARK: - Linked Parents View
struct LinkedParentsView: View {
    @StateObject private var awsService = AWSService.shared
    @State private var relationships: [ParentChildRelationship] = []
    @State private var parentProfiles: [String: UserProfile] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if relationships.isEmpty {
                ContentUnavailableView(
                    "No linked parents",
                    systemImage: "figure.2.and.child.holdinghands",
                    description: Text("Generate a linking code to allow parents to monitor your progress")
                )
            } else {
                List {
                    ForEach(relationships.filter { $0.status == .approved }, id: \.id) { relationship in
                        if let parent = parentProfiles[relationship.parentId] {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.purple.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text(parent.initials)
                                            .font(.headline)
                                            .foregroundColor(.purple)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(parent.displayName)
                                        .font(.headline)
                                    
                                    Text(relationship.relationshipType.displayName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if let approvedAt = relationship.approvedAt {
                                        Text("Linked \(formatDate(approvedAt))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Linked Parents")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadRelationships()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    private func loadRelationships() async {
        guard let userId = awsService.currentUserId else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetchedRelationships = try await Amplify.DataStore.query(
                ParentChildRelationship.self,
                where: ParentChildRelationship.keys.childId == userId
            )
            
            var profiles: [String: UserProfile] = [:]
            for relationship in fetchedRelationships where !relationship.parentId.isEmpty {
                let parentProfiles = try await Amplify.DataStore.query(
                    UserProfile.self,
                    where: UserProfile.keys.userId == relationship.parentId
                )
                if let profile = parentProfiles.first {
                    profiles[relationship.parentId] = profile
                }
            }
            
            await MainActor.run {
                self.relationships = fetchedRelationships
                self.parentProfiles = profiles
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func formatDate(_ date: Temporal.DateTime) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date.foundationDate, relativeTo: Date())
    }
}

// MARK: - Supporting Views
struct InfoRow2: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.caption)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }
}
