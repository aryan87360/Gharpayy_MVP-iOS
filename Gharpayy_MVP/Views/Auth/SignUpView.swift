//
//  SignUpView.swift
//  Gharpayy_MVP
//
//  Created by Aryan Sharma on 28/07/25.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    let selectedRole: UserRole
    
    @State private var name = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingPasswordMismatchError = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: iconForRole(selectedRole))
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Create \(selectedRole.displayName) Account")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Join Gharpayy and start your journey")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 20) {
                        CustomTextField(
                            title: "Full Name",
                            text: $name,
                            placeholder: "Enter your full name"
                        )
                        
                        CustomTextField(
                            title: "Email",
                            text: $email,
                            placeholder: "Enter your email",
                            keyboardType: .emailAddress
                        )
                        
                        CustomTextField(
                            title: "Phone Number",
                            text: $phoneNumber,
                            placeholder: "Enter your phone number",
                            keyboardType: .phonePad
                        )
                        
                        CustomTextField(
                            title: "Password",
                            text: $password,
                            placeholder: "Create a password",
                            isSecure: true
                        )
                        .textContentType(.oneTimeCode)
                        
                        CustomTextField(
                            title: "Confirm Password",
                            text: $confirmPassword,
                            placeholder: "Confirm your password",
                            isSecure: true
                        )
                        .textContentType(.oneTimeCode)
                        
                        // Error messages
                        if showingPasswordMismatchError {
                            Text("Passwords do not match")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        if let errorMessage = authService.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Sign Up Button
                        Button(action: signUp) {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Create Account")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!isFormValid || authService.isLoading)
                    }
                    .padding(.horizontal, 20)
                    
                    // Terms and Privacy
                    VStack(spacing: 8) {
                        Text("By creating an account, you agree to our")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Button("Terms of Service") {
                                // Handle terms of service
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            
                            Text("and")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("Privacy Policy") {
                                // Handle privacy policy
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        !phoneNumber.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }
    
    private func signUp() {
        guard password == confirmPassword else {
            showingPasswordMismatchError = true
            return
        }
        
        showingPasswordMismatchError = false
        
        Task {
            await authService.signUp(
                email: email,
                password: password,
                name: name,
                phoneNumber: phoneNumber,
                role: selectedRole
            )
            
            if authService.isAuthenticated {
                dismiss()
            }
        }
    }
    
    private func iconForRole(_ role: UserRole) -> String {
        switch role {
        case .tenant:
            return "person.fill"
        case .owner:
            return "building.2.fill"
        case .admin:
            return "shield.fill"
        }
    }
}

#Preview {
    SignUpView(selectedRole: .tenant)
        .environmentObject(AuthService())
}
