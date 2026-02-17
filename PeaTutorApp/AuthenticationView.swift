//
//  AuthenticationView.swift
//  PeaTutorApp
//
//  Created by Charles on 11/10/25.
//  Updated for Sprint 4: Role-Based Multi-User System
//

import SwiftUI
import Amplify

// MARK: - Main Authentication View
struct AuthenticationView: View {
    @StateObject private var awsService = AWSService.shared
    
    @ViewBuilder
    var body: some View {
        if awsService.isSignedIn {
            if let userRole = awsService.currentUserRole {
                roleBasedHomeView(for: userRole)
            } else {
                ProgressView("Loading your profile...")
                    .task {
                        await awsService.checkAuthStatus()  // ✅ Use checkAuthStatus instead
                    }
            }
        } else {
            SignInFlow()
        }
    }
    
    @ViewBuilder
    private func roleBasedHomeView(for role: UserRole) -> some View {
        switch role {
        case .teacher:
            TeacherDashboardView()
        case .student:
            StudentDashboardView()
        case .parent:
            ParentDashboardView()
        }
    }
}

// MARK: - Sign In Flow
struct SignInFlow: View {
    @State private var showSignUp = false
    
    var body: some View {
        Group {
            if showSignUp {
                SignUpView(showSignUp: $showSignUp)
            } else {
                SignInView(showSignUp: $showSignUp)
            }
        }
    }
}

// MARK: - Sign In View
struct SignInView: View {
    @Binding var showSignUp: Bool
    @StateObject private var awsService = AWSService.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSigningIn = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Logo
                VStack(spacing: 12) {
                    Image(systemName: "graduationcap.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue.gradient)
                    
                    Text("MagicMaths")
                        .font(.largeTitle.bold())
                    
                    Text("Smart Math Tutoring Platform")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Sign In Form
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        
                        TextField("Enter your email", text: $email)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        
                        SecureField("Enter your password", text: $password)
                            .textContentType(.password)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        Task {
                            await signIn()
                        }
                    }) {
                        Group {
                            if isSigningIn {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(isFormValid ? Color.blue : Color.gray)
                        .cornerRadius(16)
                    }
                    .disabled(!isFormValid || isSigningIn)
                }
                .padding(.horizontal)
                
                // Sign Up Link
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.secondary)
                    
                    Button("Sign Up") {
                        showSignUp = true
                    }
                    .bold()
                }
                .font(.subheadline)
                .padding(.bottom, 40)
            }
            .alert("Sign In Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private func signIn() async {
        isSigningIn = true
        
        do {
            try await awsService.signIn(email: email, password: password)
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
        
        isSigningIn = false
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @Binding var showSignUp: Bool
    @StateObject private var awsService = AWSService.shared
    
    enum SignUpStep {
        case roleSelection
        case userInfo
        case confirmation
        case profileCreation
    }
    
    @State private var currentStep: SignUpStep = .roleSelection
    @State private var selectedRole: UserRole?
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var schoolName = ""
    @State private var gradeLevel = ""
    @State private var confirmationCode = ""
    @State private var cognitoUserId = ""
    
    @State private var isSigningUp = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
                switch currentStep {
                case .roleSelection:
                    RoleSelectionView(selectedRole: $selectedRole) {
                        withAnimation {
                            currentStep = .userInfo
                        }
                    }
                    
                case .userInfo:
                    UserInfoView(
                        role: selectedRole ?? .student,
                        displayName: $displayName,
                        email: $email,
                        password: $password,
                        confirmPassword: $confirmPassword,
                        schoolName: $schoolName,
                        gradeLevel: $gradeLevel,
                        isSigningUp: $isSigningUp,
                        onSignUp: signUp,
                        onBack: {
                            withAnimation {
                                currentStep = .roleSelection
                            }
                        }
                    )
                    
                case .confirmation:
                    ConfirmationView(
                        email: email,
                        confirmationCode: $confirmationCode,
                        isConfirming: $isSigningUp,
                        onConfirm: confirmSignUp,
                        onResend: resendCode
                    )
                    
                case .profileCreation:
                    ProgressView("Creating your profile...")
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        
    }
    
    private func signUp() async {
        guard let role = selectedRole else { return }
        
        isSigningUp = true
        
        do {
            let needsConfirmation = try await awsService.signUp(
                email: email,
                password: password,
                displayName: displayName,
                role: role
            )
            
            await MainActor.run {
                if needsConfirmation {
                    currentStep = .confirmation
                } else {
                    Task {
                        await createProfile()
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
        
        isSigningUp = false
    }
    
    // ✅ CRITICAL FIX: Updated confirmSignUp with Error 6 handling
    private func confirmSignUp() async {
        isSigningUp = true
        
        print("🔐 Confirming sign-up for: \(email)")
        
        do {
            // Try to confirm
            let userId = try await awsService.confirmSignUp(
                email: email,
                code: confirmationCode
            )
            
            print("✅ Confirmation successful, userId: \(userId)")
            
            await MainActor.run {
                self.cognitoUserId = userId
                self.currentStep = .profileCreation
            }
            
            // Sign in and create profile
            await signInAndCreateProfile()
            
        } catch let error as NSError {
            print("❌ Confirmation error: \(error)")
            print("❌ Error code: \(error.code)")
            print("❌ Error domain: \(error.domain)")
            
            // ✅ FIX: Handle Error 6 (user already confirmed)
            if error.code == 6 ||
               error.localizedDescription.contains("CONFIRMED") ||
               error.localizedDescription.contains("already confirmed") {
                
                print("ℹ️ User already confirmed - proceeding to sign in")
                
                // User is already confirmed, just sign them in
                await MainActor.run {
                    self.currentStep = .profileCreation
                }
                
                await signInAndCreateProfile()
                return
            }
            
            // ✅ Handle specific error codes
            await MainActor.run {
                switch error.code {
                case 1002:
                    // Invalid code
                    self.errorMessage = "Invalid confirmation code. Please check your email and try again."
                    
                case 1003:
                    // Expired code
                    self.errorMessage = "Confirmation code has expired. Please request a new code using the 'Resend Code' button."
                    
                case 1004:
                    // User not found
                    self.errorMessage = "User not found. Please sign up again."
                    self.currentStep = .roleSelection
                    
                default:
                    // Unknown error - try signing in anyway (might already be confirmed)
                    self.errorMessage = "Confirmation issue detected. Attempting to sign in..."
                    
                    Task {
                        // Try signing in anyway - user might be confirmed already
                        await signInAndCreateProfile()
                    }
                }
                
                self.isSigningUp = false
            }
        } catch {
            // Catch-all for non-NSError types
            await MainActor.run {
                print("❌ Unexpected error type: \(error)")
                self.errorMessage = "Confirmation failed: \(error.localizedDescription)\n\nTrying to sign in..."
                
                Task {
                    await signInAndCreateProfile()
                }
                
                self.isSigningUp = false
            }
        }
    }
    
    // ✅ NEW: Consolidated sign-in and profile creation
     private func signInAndCreateProfile() async {
         do {
             print("🔐 Signing in user: \(email)")
             
             // Sign in
             try await awsService.signIn(email: email, password: password)
             
             print("✅ Sign in successful")
             
             // Create profile
             await createProfile()
             
         } catch {
             print("❌ Sign-in failed: \(error)")
             
             await MainActor.run {
                 let errorDesc = error.localizedDescription.lowercased()
                 
                 if errorDesc.contains("not") && errorDesc.contains("confirmed") {
                     // User still not confirmed
                     self.errorMessage = "Email not confirmed yet. Please check your email and enter the code."
                     self.currentStep = .confirmation
                 } else if errorDesc.contains("incorrect") || errorDesc.contains("invalid") {
                     // Wrong password (shouldn't happen, but just in case)
                     self.errorMessage = "Sign-in failed. Please try signing up again."
                     self.currentStep = .roleSelection
                 } else {
                     self.errorMessage = "Sign-in failed: \(error.localizedDescription)"
                 }
                 
                 self.isSigningUp = false
             }
         }
     }
    
    private func createProfile() async {
        guard let role = selectedRole else {
            await MainActor.run {
                self.errorMessage = "Role not selected"
                self.isSigningUp = false
            }
            return
        }
        
        do {
            let user = try await Amplify.Auth.getCurrentUser()
            
            _ = try await awsService.createUserProfile(
                userId: user.userId,
                email: email,
                displayName: displayName,
                role: role,
                schoolName: schoolName.isEmpty ? nil : schoolName,
                gradeLevel: gradeLevel.isEmpty ? nil : gradeLevel
            )
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Account created but profile failed: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            self.isSigningUp = false
        }
    }
    
    // ✅ NEW: Resend confirmation code
    private func resendCode() async {
        print("📧 Resending confirmation code to: \(email)")
        
        do {
            try await awsService.resendConfirmationCode(email: email)
            
            await MainActor.run {
                self.errorMessage = "New confirmation code sent! Check your email."
            }
            
        } catch {
            print("❌ Failed to resend code: \(error)")
            
            await MainActor.run {
                self.errorMessage = "Failed to resend code: \(error.localizedDescription)"
            }
        }
    }
    
}

// MARK: - User Info View (with Your Password Validation)
struct UserInfoView: View {
    let role: UserRole
    @Binding var displayName: String
    @Binding var email: String
    @Binding var password: String
    @Binding var confirmPassword: String
    @Binding var schoolName: String
    @Binding var gradeLevel: String
    @Binding var isSigningUp: Bool
    var onSignUp: () async -> Void
    var onBack: () -> Void
    
    let gradeLevels = ["Primary 1", "Primary 2", "Primary 3", "Primary 4", "Primary 5", "Primary 6",
                       "Secondary 1", "Secondary 2", "Secondary 3", "Secondary 4", "Secondary 5",
                       "Junior College 1", "Junior College 2"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: role.icon)
                        .font(.system(size: 60))
                        .foregroundStyle(.blue.gradient)
                    
                    Text("Create \(role.displayName) Account")
                        .font(.title2.bold())
                }
                .padding(.top, 20)
                
                // Form
                VStack(spacing: 16) {
                    FormField(title: "Full Name", text: $displayName, placeholder: "Enter your name")
                    
                    FormField(title: "Email", text: $email, placeholder: "Enter your email")
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    
                    FormField(title: "Password", text: $password, placeholder: "Create a password", isSecure: true)
                    
                    FormField(title: "Confirm Password", text: $confirmPassword, placeholder: "Confirm password", isSecure: true)
                    
                    // Password validation feedback
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
                    
                    if role == .student {
                        FormField(title: "School (Optional)", text: $schoolName, placeholder: "Enter school name")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Grade Level (Optional)")
                                .font(.subheadline.bold())
                                .foregroundColor(.secondary)
                            
                            Picker("Grade Level", selection: $gradeLevel) {
                                Text("Select Grade").tag("")
                                ForEach(gradeLevels, id: \.self) { grade in
                                    Text(grade).tag(grade)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Sign Up Button
                Button(action: {
                    Task {
                        await onSignUp()
                    }
                }) {
                    Group {
                        if isSigningUp {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Create Account")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(isFormValid ? Color.blue : Color.gray)
                    .cornerRadius(16)
                }
                .disabled(!isFormValid || isSigningUp)
                .padding(.horizontal)
                
                // Back Button
                Button(action: onBack) {
                    Text("← Back to Role Selection")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private var isFormValid: Bool {
        !displayName.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        !password.isEmpty &&
        password.count >= 8 &&
        password == confirmPassword &&
        passwordIsValid  // Your validation!
    }
    
    // Your excellent password validation preserved!
    private var passwordIsValid: Bool {
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        return hasUppercase && hasLowercase && hasNumber
    }
}

// MARK: - Form Field Helper
struct FormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.secondary)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textContentType(.password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                TextField(placeholder, text: $text)
                    .textContentType(.emailAddress)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
    }
}

// MARK: - Confirmation View
struct ConfirmationView: View {
    let email: String
    @Binding var confirmationCode: String
    @Binding var isConfirming: Bool
    let onConfirm: () async -> Void
    let onResend: () async -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "envelope.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue.gradient)
                
                Text("Check Your Email")
                    .font(.title.bold())
                
                Text("We've sent a confirmation code to")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(email)
                    .font(.subheadline.bold())
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirmation Code")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    
                    TextField("Enter 6-digit code", text: $confirmationCode)
                        .keyboardType(.numberPad)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .onChange(of: confirmationCode) { _, newValue in
                            // Limit to 6 digits
                            confirmationCode = String(newValue.prefix(6))
                        }
                }
                
                Button(action: {
                    Task {
                        await onConfirm()
                    }
                }) {
                    Group {
                        if isConfirming {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Confirm & Continue")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(confirmationCode.count == 6 ? Color.blue : Color.gray)
                    .cornerRadius(16)
                }
                .disabled(confirmationCode.count != 6 || isConfirming)
                
                Button(action: {
                    Task { await onResend() }
                }) {
                    Text("Didn't receive code? Resend")
                        .font(.footnote)
                }
                .disabled(isConfirming)
                .padding(.top)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

#Preview {
    AuthenticationView()
}
