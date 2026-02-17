//
//  AuthenticationView.swift
//  PeaTutorApp
//
//  Created by Charles on 11/10/25.
//

import SwiftUI

// MARK: - Main Authentication View
struct AuthenticationView: View {
    @StateObject private var aws = AWSService.shared
    @State private var showingSignUp = false
    
    var body: some View {
        Group {
            if aws.isSignedIn {
                // User is signed in - show main app
                ContentView()
            } else {
                // User not signed in - show auth screen
                if showingSignUp {
                    SignUpView(showingSignUp: $showingSignUp)
                } else {
                    SignInView(showingSignUp: $showingSignUp)
                }
            }
        }
    }
}

// MARK: - Sign In View
struct SignInView: View {
    @StateObject private var aws = AWSService.shared
    @Binding var showingSignUp: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // Logo
                Image(systemName: "graduationcap.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("PeaTutor")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Sign in to continue")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    Button(action: signIn) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSignIn ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!canSignIn || isLoading)
                }
                .padding(.horizontal)
                
                // Sign up link
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.secondary)
                    Button("Sign Up") {
                        showingSignUp = true
                    }
                    .fontWeight(.medium)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
        .alert("Sign In Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var canSignIn: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private func signIn() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await aws.signIn(email: email, password: password)
                isLoading = false
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @StateObject private var aws = AWSService.shared
    @Binding var showingSignUp: Bool
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 20)
                    
                    // Header
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Create Account")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Form
                    VStack(spacing: 16) {
                        TextField("Full Name", text: $fullName)
                            .textContentType(.name)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        SecureField("Password (8+ characters)", text: $password)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        if !confirmPassword.isEmpty && password != confirmPassword {
                            Text("Passwords don't match")
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Text("Password must have 8+ characters with uppercase, lowercase, and number")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: signUp) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Create Account")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canSignUp ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(!canSignUp || isLoading)
                    }
                    .padding(.horizontal)
                    
                    // Sign in link
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.secondary)
                        Button("Sign In") {
                            showingSignUp = false
                        }
                        .fontWeight(.medium)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarItems(leading: Button("Cancel") {
                showingSignUp = false
            })
        }
        .alert("Sign Up Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingConfirmation) {
            ConfirmationView(email: email, onConfirm: { code in
                confirmSignUp(code: code)
            })
        }
    }
    
    private var canSignUp: Bool {
        !fullName.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        password.count >= 8 &&
        password == confirmPassword &&
        passwordIsValid
    }
    
    private var passwordIsValid: Bool {
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        return hasUppercase && hasLowercase && hasNumber
    }
    
    private func signUp() {
        isLoading = true
        
        Task {
            do {
                let needsConfirmation = try await aws.signUp(
                    email: email,
                    password: password,
                    fullName: fullName
                )
                
                await MainActor.run {
                    isLoading = false
                    if !needsConfirmation {
                        showingConfirmation = true
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func confirmSignUp(code: String) {
        Task {
            do {
                try await aws.confirmSignUp(email: email, code: code)
                await MainActor.run {
                    showingConfirmation = false
                    showingSignUp = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Email Confirmation View
struct ConfirmationView: View {
    let email: String
    let onConfirm: (String) -> Void
    
    @State private var code = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "envelope.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Check Your Email")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("We sent a confirmation code to:")
                    .foregroundColor(.secondary)
                
                Text(email)
                    .fontWeight(.medium)
                
                TextField("6-digit code", text: $code)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                Button(action: {
                    onConfirm(code)
                }) {
                    Text("Confirm")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(code.count == 6 ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(code.count != 6)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
}
