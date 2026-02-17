//
//  JoinClassView.swift
//  PeaTutorApp
//
//  Created by Charles on 19/10/25.
//

import SwiftUI

struct JoinClassView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var awsService = AWSService.shared
    
    @State private var classCode = ""
    @State private var isJoining = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var joinedClass: Classroom?
    
    var onClassJoined: () async -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                    }
                    
                    Text("Join a Class")
                        .font(.title.bold())
                    
                    Text("Enter the class code provided by your teacher")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Class Code Input
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Class Code")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        
                        TextField("ABC123", text: $classCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .tracking(4)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .onChange(of: classCode) { _, newValue in
                                // Auto-format: uppercase and limit to 6 characters
                                classCode = String(newValue.uppercased().prefix(6))
                            }
                    }
                    
                    // Info Card
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Class codes are 6 characters")
                                .font(.caption.bold())
                            Text("Ask your teacher for the code")
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
                
                // Join Button
                Button(action: {
                    Task {
                        await joinClass()
                    }
                }) {
                    Text("Join Class")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(classCode.count == 6 ? Color.blue : Color.gray)
                        .cornerRadius(16)
                }
                .disabled(classCode.count != 6 || isJoining)
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
            .disabled(isJoining)
            .overlay {
                if isJoining {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Joining class...")
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
                if let joinedClass = joinedClass {
                    ClassJoinedSuccessView(classModel: joinedClass) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func joinClass() async {
        guard classCode.count == 6 else { return }
        
        isJoining = true
        
        do {
            let membership = try await awsService.joinClass(classCode: classCode)
            
            // Fetch the class details
            if let classModel = try await awsService.findClassByCode(classCode) {
                await MainActor.run {
                    self.joinedClass = classModel
                    self.showSuccess = true
                }
                
                await onClassJoined()
            }
            
        } catch {
            await MainActor.run {
                if error.localizedDescription.contains("not found") {
                    self.errorMessage = "Invalid class code. Please check and try again."
                } else {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
        
        isJoining = false
    }
}

// MARK: - Success View
struct ClassJoinedSuccessView: View {
    let classModel: Classroom
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
                Text("Successfully Joined!")
                    .font(.title.bold())
                
                Text("You're now enrolled in")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Class Info Card
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "book.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(classModel.className)
                            .font(.headline)
                        
                        if let subject = classModel.subject {
                            Text(subject)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let gradeLevel = classModel.gradeLevel {
                            Label(gradeLevel, systemImage: "graduationcap")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
            .padding(.horizontal)
            
            Spacer()
            
            // Done Button
            Button(action: onDismiss) {
                Text("Go to Dashboard")
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

#Preview {
    JoinClassView(onClassJoined: {})
}
