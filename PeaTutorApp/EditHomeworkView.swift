//
//  EditHomeworkView.swift
//  PeaTutorApp
//
//  Sprint 5 Phase 3: Edit homework assignments
//

import SwiftUI
import Amplify

struct EditHomeworkView: View {
    let homework: Homework
    let classroom: Classroom
    var onHomeworkUpdated: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var homeworkService = HomeworkService.shared
    
    @State private var title: String
    @State private var description: String
    @State private var dueDate: Date
    @State private var totalPoints: String
    @State private var instructions: String
    @State private var learningObjectives: String
    @State private var allowLateSubmissions: Bool
    @State private var allowMultipleAttempts: Bool
    @State private var maxAttempts: String
    @State private var isPublished: Bool
    
    @State private var isUpdating = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    
    init(homework: Homework, classroom: Classroom, onHomeworkUpdated: @escaping () -> Void) {
        self.homework = homework
        self.classroom = classroom
        self.onHomeworkUpdated = onHomeworkUpdated
        
        _title = State(initialValue: homework.title)
        _description = State(initialValue: homework.description ?? "")
        _dueDate = State(initialValue: homework.dueDate.foundationDate)
        _totalPoints = State(initialValue: homework.totalPoints.map { "\($0)" } ?? "")
        _instructions = State(initialValue: homework.instructions ?? "")
        _learningObjectives = State(initialValue: homework.learningObjectives ?? "")
        _allowLateSubmissions = State(initialValue: homework.allowLateSubmissions ?? false)
        _allowMultipleAttempts = State(initialValue: homework.allowMultipleAttempts ?? false)
        _maxAttempts = State(initialValue: homework.maxAttempts.map { "\($0)" } ?? "")
        _isPublished = State(initialValue: homework.isPublished)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section("Basic Information") {
                    TextField("Title", text: $title)
                    
                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                        .overlay(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("Description (optional)")
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                        }
                }
                
                // Due Date & Points
                Section("Assignment Details") {
                    DatePicker("Due Date", selection: $dueDate, in: Date()...)
                        .datePickerStyle(.compact)
                    
                    TextField("Total Points (optional)", text: $totalPoints)
                        .keyboardType(.numberPad)
                }
                
                // Instructions
                Section("Instructions") {
                    TextEditor(text: $instructions)
                        .frame(minHeight: 100)
                        .overlay(alignment: .topLeading) {
                            if instructions.isEmpty {
                                Text("Add instructions for students (optional)")
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                        }
                }
                
                // Learning Objectives
                Section("Learning Objectives") {
                    TextEditor(text: $learningObjectives)
                        .frame(minHeight: 100)
                        .overlay(alignment: .topLeading) {
                            if learningObjectives.isEmpty {
                                Text("What should students learn? (optional)")
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                        }
                }
                
                // Settings
                Section("Settings") {
                    Toggle("Allow Late Submissions", isOn: $allowLateSubmissions)
                    
                    Toggle("Allow Multiple Attempts", isOn: $allowMultipleAttempts)
                    
                    if allowMultipleAttempts {
                        TextField("Max Attempts (optional)", text: $maxAttempts)
                            .keyboardType(.numberPad)
                    }
                }
                
                // Publishing Status
                Section {
                    Toggle("Published", isOn: $isPublished)
                } header: {
                    Text("Publishing")
                } footer: {
                    Text(isPublished ? "Students can see and submit this homework" : "Only you can see this homework. Publish it when ready.")
                }
                
                // Worksheet Info (Read-only)
                if let worksheet = homework.worksheet {
                    Section("Worksheet") {
                        HStack {
                            Text("Worksheet")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(worksheet.title)
                                .foregroundColor(.primary)
                        }
                        
                        Text("Cannot be changed after creation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Homework")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await updateHomework()
                        }
                    }
                    .disabled(!isFormValid || isUpdating)
                    .bold()
                }
            }
            .disabled(isUpdating)
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    onHomeworkUpdated()
                    dismiss()
                }
            } message: {
                Text("Homework updated successfully")
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - Validation
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        dueDate > Date()
    }
    
    // MARK: - Update Homework
    private func updateHomework() async {
        isUpdating = true
        
        do {
            // Parse optional numeric fields
            let points = totalPoints.isEmpty ? nil : Int(totalPoints)
            let maxAtt = maxAttempts.isEmpty ? nil : Int(maxAttempts)
            
            // Create updated homework
            let updated = Homework(
                id: homework.id,
                teacherId: homework.teacherId,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.isEmpty ? nil : description,
                dueDate: Temporal.DateTime(dueDate),
                assignedDate: homework.assignedDate,
                totalPoints: points,
                isPublished: isPublished,
                worksheet: homework.worksheet,
                instructions: instructions.isEmpty ? nil : instructions,
                learningObjectives: learningObjectives.isEmpty ? nil : learningObjectives,
                allowLateSubmissions: allowLateSubmissions,
                allowMultipleAttempts: allowMultipleAttempts,
                maxAttempts: maxAtt,
                classroom: homework.classroom,
                submissions: homework.submissions
            )
            
            // Save updated homework
            try await Amplify.DataStore.save(updated)
            
            // If newly published, create analytics
            if isPublished && !homework.isPublished {
                try await homeworkService.updateAnalytics(for: updated.id)
            }
            
            await MainActor.run {
                showSuccessAlert = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isUpdating = false
    }
}
