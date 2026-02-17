//
//  CreateHomeworkView.swift
//  PeaTutorApp
//
//  Sprint 5 Phase 1: Teacher assigns homework with embedded worksheet upload
//

import SwiftUI
import Amplify

struct CreateHomeworkView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var awsService = AWSService.shared
    
    let classroom: Classroom
    let onHomeworkCreated: () -> Void
    
    // Worksheet selection state
    @State private var selectedWorksheet: Worksheet?
    @State private var showingWorksheetPicker = false
    @State private var showingWorksheetUpload = false
    
    // Homework details
    @State private var homeworkTitle = ""
    @State private var homeworkDescription = ""
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
    @State private var shouldPublish = true
    
    // UI state
    @State private var isCreating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var canAssign: Bool {
        selectedWorksheet != nil && !homeworkTitle.isEmpty && dueDate > Date()
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Section 1: Worksheet Selection
                worksheetSection
                
                // Section 2: Homework Details
                if selectedWorksheet != nil {
                    detailsSection
                }
                
                // Section 3: Assignment Settings
                if selectedWorksheet != nil {
                    settingsSection
                }
                
                // Section 4: Assign Button
                if selectedWorksheet != nil {
                    assignSection
                }
            }
            .navigationTitle("Assign Homework")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .disabled(isCreating)
            .overlay {
                if isCreating {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Creating homework...")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding(30)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 10)
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        // Worksheet picker sheet
        .sheet(isPresented: $showingWorksheetPicker) {
            WorksheetSelectionView { worksheet in
                selectedWorksheet = worksheet
                // Auto-fill title from worksheet if empty
                if homeworkTitle.isEmpty {
                    homeworkTitle = worksheet.title
                }
            }
        }
        // Worksheet upload sheet
        .sheet(isPresented: $showingWorksheetUpload) {
            NewWorksheetUploadView(
                onWorksheetUploaded: { worksheet in
                    selectedWorksheet = worksheet
                    if homeworkTitle.isEmpty {
                        homeworkTitle = worksheet.title
                    }
                    showingWorksheetUpload = false
                },
                onCancel: {
                    showingWorksheetUpload = false
                }
            )
        }
    }
    
    // MARK: - Worksheet Section
    
    private var worksheetSection: some View {
        Section {
            if let worksheet = selectedWorksheet {
                // Show selected worksheet
                SelectedWorksheetCard(worksheet: worksheet) {
                    selectedWorksheet = nil
                    homeworkTitle = ""
                }
            } else {
                // Worksheet selection options
                VStack(spacing: 16) {
                    Text("Choose a worksheet to assign")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Select from library
                    Button {
                        showingWorksheetPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Select from Library")
                                    .font(.headline)
                                Text("Choose a previously uploaded worksheet")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Upload new worksheet
                    Button {
                        showingWorksheetUpload = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Upload New Worksheet")
                                    .font(.headline)
                                Text("Take photo or import file")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        } header: {
            Text("Worksheet")
        } footer: {
            if selectedWorksheet == nil {
                Text("Select an existing worksheet or upload a new one to get started")
            }
        }
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        Section("Homework Details") {
            // Title
            TextField("Homework Title", text: $homeworkTitle)
                .font(.headline)
            
            // Description
            TextField("Description (optional)", text: $homeworkDescription, axis: .vertical)
                .lineLimit(3...6)
            
            // Due date
            DatePicker(
                "Due Date",
                selection: $dueDate,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            
            // Classroom info
            HStack {
                Text("Assign to")
                    .foregroundColor(.secondary)
                Spacer()
                Text(classroom.className)
                    .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        Section("Settings") {
            Toggle("Publish Immediately", isOn: $shouldPublish)
            
            if !shouldPublish {
                Label("Save as draft to review before publishing", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Assign Section
    
    private var assignSection: some View {
        Section {
            Button {
                Task {
                    await assignHomework()
                }
            } label: {
                HStack {
                    Spacer()
                    Text(shouldPublish ? "Assign Homework" : "Save as Draft")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .disabled(!canAssign)
        }
    }
    
    // MARK: - Assign Homework
    
    private func assignHomework() async {
        guard let worksheet = selectedWorksheet,
              let teacherId = awsService.currentUserId else {
            return
        }
        
        isCreating = true
        defer { isCreating = false }
        
        do {
            // Create homework using HomeworkService
            let homework = try await HomeworkService.shared.createHomework(
                teacherId: teacherId,
                classroomId: classroom.id,
                worksheet: worksheet,
                title: homeworkTitle,
                description: homeworkDescription.isEmpty ? nil : homeworkDescription,
                dueDate: dueDate,
                totalPoints: nil, // Not using scoring
                isPublished: shouldPublish
            )
            
            print("✅ Homework created: \(homework.id)")
            print("   Title: \(homework.title)")
            print("   Classroom: \(classroom.className)")
            print("   Worksheet: \(worksheet.title)")
            print("   Due: \(dueDate)")
            print("   Published: \(shouldPublish)")
            
            // Notify parent and dismiss
            onHomeworkCreated()
            dismiss()
            
        } catch {
            print("❌ Failed to create homework: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Selected Worksheet Card

struct SelectedWorksheetCard: View {
    let worksheet: Worksheet
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Selected Worksheet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: onRemove) {
                    Label("Change", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption)
                }
            }
            
            // Worksheet card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(worksheet.title)
                            .font(.headline)
                            .lineLimit(2)
                        
                        Text(formatDate(worksheet.uploadedAt.foundationDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                HStack(spacing: 20) {
                    StatBadge(
                        icon: "list.number",
                        value: "\(worksheet.questionCount ?? 0)",
                        label: "Questions"
                    )
                    
                    if let marks = worksheet.totalMarks {
                        StatBadge(
                            icon: "star.fill",
                            value: "\(marks)",
                            label: "Marks"
                        )
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
            )
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Uploaded " + formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline.bold())
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
