//
//  ClassDetailView.swift
//  PeaTutorApp
//
//  Created by Charles on 19/10/25.
//

import SwiftUI
import Amplify

struct ClassDetailView: View {
    let classroom: Classroom
    @StateObject private var awsService = AWSService.shared
    @State private var members: [ClassroomMembership] = []
    @State private var studentProfiles: [String: UserProfile] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showEditClass = false
    @State private var showDeleteConfirmation = false
    @State private var showingCreateHomework = false
    @State private var homeworkCount: Int = 0
    @State private var homework: [Homework] = []
    @State private var isLoadingHomework = false
    @StateObject private var homeworkService = HomeworkService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Class Header Card
                classHeaderCard
                
                // Quick Actions
                quickActionsSection
                
                // Homework Section
                homeworkSection
                
                // Students Section
                studentsSection
                
                // Recent Activity (Placeholder for Sprint 5)
                recentActivitySection
            }
            .padding()
        }
        .navigationTitle(classroom.className)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { showEditClass = true }) {
                        Label("Edit Class", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                        Label("Delete Class", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditClass) {
            EditClassView(classModel: classroom) {
                // Refresh data after edit
                Task {
                    await loadMembers()
                }
            }
        }
        .sheet(isPresented: $showingCreateHomework) {
            CreateHomeworkView(classroom: classroom, onHomeworkCreated: {
                Task {
                        await loadMembers()  // Reloads both members AND homework count
                    }
                print("âœ… Homework assigned!")
            })
        }
        .alert("Delete Class", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteClass()
                }
            }
        } message: {
            Text("Are you sure you want to delete \(classroom.className)? This action cannot be undone.")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .task {
            await loadMembers()
        }
    }
    
    
    // MARK: - Class Header Card
    private var classHeaderCard: some View {
        VStack(spacing: 16) {
            // Icon & Code
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "book.fill")
                        .font(.system(size: 35))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Class Code")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(classroom.classCode)
                        .font(.title2.bold())
                        .foregroundColor(.blue)
                }
            }
            
            // Class Info
            VStack(alignment: .leading, spacing: 8) {
                if let subject = classroom.subject {
                    HStack {
                        Image(systemName: "book.closed")
                            .foregroundColor(.secondary)
                        Text(subject)
                            .font(.subheadline)
                    }
                }
                
                if let gradeLevel = classroom.gradeLevel {
                    HStack {
                        Image(systemName: "graduationcap")
                            .foregroundColor(.secondary)
                        Text(gradeLevel)
                            .font(.subheadline)
                    }
                }
                
                if let description = classroom.description, !description.isEmpty {
                    HStack(alignment: .top) {
                        Image(systemName: "text.alignleft")
                            .foregroundColor(.secondary)
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Stats
            HStack(spacing: 16) {
                StatItem(icon: "person.2.fill", label: "Students", value: "\(members.filter { $0.status == .approved }.count)")
                StatItem(icon: "doc.text.fill", label: "Homework", value: "\(homeworkCount)")
                StatItem(icon: "calendar", label: "Created", value: formatDate(classroom.createdAt))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            // Row 1: Assign Homework & View Curriculum
            HStack(spacing: 12) {
                Button { showingCreateHomework = true } label: {
                    QuickActionCard(
                        icon: "plus.circle.fill",
                        title: "Assign Homework",
                        subtitle: "Create new assignment",
                        color: .blue
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink {
                    TeacherClassCurriculumView(classroom: classroom)
                } label: {
                    QuickActionCard(
                        icon: "book.closed.fill",
                        title: "Curriculum",
                        subtitle: "View student progress",
                        color: .purple
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Row 2: Share Class Code
            Button(action: shareClassCode) {
                QuickActionCard(
                    icon: "square.and.arrow.up",
                    title: "Share Class Code",
                    subtitle: "Let students join",
                    color: .green
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Students Section
    private var studentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Students")
                    .font(.title3.bold())
                
                Spacer()
                
                Text("\(members.filter { $0.status == .approved }.count)")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
            }
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if members.isEmpty {
                ContentUnavailableView(
                    "No students yet",
                    systemImage: "person.2",
                    description: Text("Students will appear here when they join using the class code")
                )
                .frame(height: 200)
            } else {
                ForEach(members.filter { $0.status == .approved }, id: \.id) { member in
                    NavigationLink {
                        StudentAnalyticsView(
                            studentId: member.studentId,
                            classroom: classroom,
                            studentProfile: studentProfiles[member.studentId]
                        )
                    } label: {
                        StudentMemberCard(
                            membership: member,
                            profile: studentProfiles[member.studentId]
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Homework Section
    private var homeworkSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Homework")
                    .font(.title3.bold())
                
                Spacer()
                
                Text("\(homework.count)")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
            }
            
            if isLoadingHomework {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if homework.isEmpty {
                ContentUnavailableView(
                    "No homework yet",
                    systemImage: "doc.text",
                    description: Text("Create homework assignments to see them here")
                )
                .frame(height: 200)
            } else {
                ForEach(homework, id: \.id) { hw in
                    NavigationLink {
                        TeacherHomeworkDetailView(homework: hw, classroom: classroom)
                    } label: {
                        TeacherHomeworkCard(homework: hw)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Recent Activity
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.title3.bold())
            
            ContentUnavailableView(
                "No recent activity",
                systemImage: "clock",
                description: Text("Homework submissions and activity will appear here")
            )
            .frame(height: 200)
        }
    }
    
    // MARK: - Helper Methods
    private func loadMembers() async {
        isLoading = true
        isLoadingHomework = true
        defer { 
            isLoading = false
            isLoadingHomework = false
        }
        
        do {
            let fetchedMembers = try await Amplify.DataStore.query(
                ClassroomMembership.self,
                where: ClassroomMembership.keys.classroom.eq(classroom.id)
            )
            
            // Fetch student profiles
            var profiles: [String: UserProfile] = [:]
            for member in fetchedMembers {
                let studentProfiles = try await Amplify.DataStore.query(
                    UserProfile.self,
                    where: UserProfile.keys.userId == member.studentId
                )
                if let profile = studentProfiles.first {
                    profiles[member.studentId] = profile
                }
            }

            // Load full homework list for this classroom
            let fetchedHomework = try await homeworkService.fetchClassroomHomework(
                classroomId: classroom.id,
                publishedOnly: false
            )
            
            await MainActor.run {
                self.members = fetchedMembers.sorted { $0.enrolledAt > $1.enrolledAt }
                self.studentProfiles = profiles
                self.homework = fetchedHomework
                self.homeworkCount = fetchedHomework.count
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func shareClassCode() {
        let message = "Join my class on MathsMagic!\n\nClass: \(classroom.className)\nCode: \(classroom.classCode)"
        
        let activityVC = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func deleteClass() async {
        do {
            try await Amplify.DataStore.delete(classroom)
            // Navigate back will happen automatically
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func formatDate(_ date: Temporal.DateTime?) -> String {
        guard let date = date else {
            return "N/A"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date.foundationDate)
    }
}

// MARK: - Supporting Views
private struct StatItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
}

struct StudentMemberCard: View {
    let membership: ClassroomMembership
    let profile: UserProfile?
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(profile?.initials ?? "?")
                        .font(.headline)
                        .foregroundColor(.blue)
                )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(profile?.displayName ?? "Unknown Student")
                    .font(.headline)
                
                HStack(spacing: 8) {
                    if let gradeLevel = profile?.gradeLevel {
                        Label(gradeLevel, systemImage: "graduationcap")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Label("Joined \(formatJoinDate(membership.enrolledAt))", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Status Badge
            if membership.status == .approved {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
    }
    
    private func formatJoinDate(_ date: Temporal.DateTime) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date.foundationDate, relativeTo: Date())
    }
}

// MARK: - Edit Class View
struct EditClassView: View {
    @Environment(\.dismiss) var dismiss
    let classModel: Classroom
    var onClassUpdated: () -> Void
    
    @State private var className: String
    @State private var subject: String
    @State private var description: String
    @State private var gradeLevel: String
    @State private var isActive: Bool
    
    @State private var isUpdating = false
    @State private var errorMessage: String?
    
    init(classModel: Classroom, onClassUpdated: @escaping () -> Void) {
        self.classModel = classModel
        self.onClassUpdated = onClassUpdated
        
        _className = State(initialValue: classModel.className)
        _subject = State(initialValue: classModel.subject ?? "")
        _description = State(initialValue: classModel.description ?? "")
        _gradeLevel = State(initialValue: classModel.gradeLevel ?? "")
        _isActive = State(initialValue: classModel.isActive)
    }
    
    let subjects = ["Mathematics", "Science", "English", "History", "Physics", "Chemistry", "Biology", "Other"]
    let gradeLevels = ["Primary 1", "Primary 2", "Primary 3", "Primary 4", "Primary 5", "Primary 6",
                       "Secondary 1", "Secondary 2", "Secondary 3", "Secondary 4", "Secondary 5",
                       "Junior College 1", "Junior College 2"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Class Information") {
                    TextField("Class Name", text: $className)
                    
                    Picker("Subject", selection: $subject) {
                        Text("Select Subject").tag("")
                        ForEach(subjects, id: \.self) { subject in
                            Text(subject).tag(subject)
                        }
                    }
                    
                    Picker("Grade Level", selection: $gradeLevel) {
                        Text("Select Grade").tag("")
                        ForEach(gradeLevels, id: \.self) { grade in
                            Text(grade).tag(grade)
                        }
                    }
                }
                
                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Toggle("Class is Active", isOn: $isActive)
                } footer: {
                    Text("Inactive classes won't accept new students")
                }
            }
            .navigationTitle("Edit Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await updateClass()
                        }
                    }
                    .disabled(className.isEmpty || isUpdating)
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
    
    private func updateClass() async {
        isUpdating = true
        
        do {
            var updatedClass = classModel
            updatedClass.className = className
            updatedClass.subject = subject.isEmpty ? nil : subject
            updatedClass.description = description.isEmpty ? nil : description
            updatedClass.gradeLevel = gradeLevel.isEmpty ? nil : gradeLevel
            updatedClass.isActive = isActive
            updatedClass.updatedAt = Temporal.DateTime.now()
            
            try await Amplify.DataStore.save(updatedClass)
            
            onClassUpdated()
            dismiss()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
        
        isUpdating = false
    }
}

// MARK: - Teacher Homework Card
struct TeacherHomeworkCard: View {
    let homework: Homework
    @StateObject private var homeworkService = HomeworkService.shared
    @State private var analytics: HomeworkAnalytics?
    @State private var completionRate: Double = 0.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(homework.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let worksheet = homework.worksheet {
                        Text(worksheet.title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status Badge
                statusBadge
            }
            
            // Due Date
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text("Due: \(formatDueDate())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Stats
            if let analytics = analytics {
                HStack(spacing: 20) {
                    StatLabel(icon: "person.2.fill", value: "\(analytics.submittedCount)/\(analytics.totalStudents)", label: "Submitted")
                    
                    StatLabel(icon: "checkmark.circle.fill", value: "\(Int(completionRate))%", label: "Complete")
                    
                    if analytics.lateCount > 0 {
                        StatLabel(icon: "clock.badge.exclamationmark", value: "\(analytics.lateCount)", label: "Late")
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
            
            // Quick Actions
            HStack(spacing: 8) {
                if analytics != nil {
                    Label("\(analytics?.submittedCount ?? 0) submission\(analytics?.submittedCount == 1 ? "" : "s")", systemImage: "doc.text.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        .task {
            await loadAnalytics()
        }
    }
    
    private var statusBadge: some View {
        Text(homework.isPublished ? (isOverdue ? "Overdue" : "Active") : "Draft")
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(homework.isPublished ? (isOverdue ? Color.red : Color.green) : Color.gray)
            .cornerRadius(6)
    }
    
    private var isOverdue: Bool {
        Date() > homework.dueDate.foundationDate
    }
    
    private func formatDueDate() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: homework.dueDate.foundationDate, relativeTo: Date())
    }
    
    private func loadAnalytics() async {
        do {
            let fetchedAnalytics = try await homeworkService.fetchAnalytics(for: homework.id)
            let rate = try await homeworkService.completionPercentage(for: homework)
            
            await MainActor.run {
                self.analytics = fetchedAnalytics
                self.completionRate = rate
            }
        } catch {
            print("Error loading analytics: \(error.localizedDescription)")
        }
    }
}

// MARK: - Stat Label
struct StatLabel: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.caption.bold())
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .foregroundColor(.blue)
    }
}

