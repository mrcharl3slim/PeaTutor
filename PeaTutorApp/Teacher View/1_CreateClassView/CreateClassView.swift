//
//  CreateClassView.swift
//  PeaTutorApp
//
//  Created by Charles on 19/10/25.
//

import SwiftUI

struct CreateClassView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var awsService = AWSService.shared
    
    @State private var className = ""
    @State private var subject = ""
    @State private var description = ""
    @State private var gradeLevel = ""
    
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var createdClass: Classroom?
    
    var onClassCreated: () async -> Void
    
    let subjects = ["Mathematics", "Science", "English", "History", "Physics", "Chemistry", "Biology", "Other"]
    let gradeLevels = ["Primary 1", "Primary 2", "Primary 3", "Primary 4", "Primary 5", "Primary 6",
                       "Secondary 1", "Secondary 2", "Secondary 3", "Secondary 4", "Secondary 5",
                       "Junior College 1", "Junior College 2"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Class Name", text: $className)
                        .textInputAutocapitalization(.words)
                    
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
                } header: {
                    Text("Basic Information")
                }
                
                Section {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                } header: {
                    Text("Description (Optional)")
                } footer: {
                    Text("Provide details about the class, topics covered, or expectations")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Class Code Generation", systemImage: "key.fill")
                            .font(.subheadline.bold())
                        
                        Text("A unique 6-character code will be automatically generated for students to join this class")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Create Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await createClass()
                        }
                    }
                    .disabled(!isFormValid || isCreating)
                    .bold()
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
                            Text("Creating class...")
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
                if let createdClass = createdClass {
                    ClassCreatedSuccessView(classModel: createdClass) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !className.trimmingCharacters(in: .whitespaces).isEmpty &&
        !subject.isEmpty &&
        !gradeLevel.isEmpty
    }
    
    private func createClass() async {
        isCreating = true
        
        do {
            let newClass = try await awsService.createClass(
                className: className.trimmingCharacters(in: .whitespaces),
                subject: subject.isEmpty ? nil : subject,
                description: description.trimmingCharacters(in: .whitespaces).isEmpty ? nil : description,
                gradeLevel: gradeLevel.isEmpty ? nil : gradeLevel
            )
            
            await MainActor.run {
                self.createdClass = newClass
                self.showSuccess = true
            }
            
            await onClassCreated()
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
        
        isCreating = false
    }
}

// MARK: - Success View
struct ClassCreatedSuccessView: View {
    let classModel: Classroom
    var onDismiss: () -> Void
    
    @State private var showCopiedToast = false
    
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
                Text("Class Created!")
                    .font(.title.bold())
                
                Text(classModel.className)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // Class Code Card
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("Class Code")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(classModel.classCode)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .tracking(4)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Text("Students can use this code to join your class")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: copyClassCode) {
                    Label("Copy Code", systemImage: "doc.on.doc")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
            .padding(.horizontal)
            
            Spacer()
            
            // Done Button
            Button(action: onDismiss) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
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
    }
    
    private func copyClassCode() {
        UIPasteboard.general.string = classModel.classCode
        showCopiedToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopiedToast = false
        }
    }
}

#Preview {
    CreateClassView(onClassCreated: {})
}
