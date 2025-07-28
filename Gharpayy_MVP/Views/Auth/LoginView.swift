//
//  LoginView.swift
//  Gharpayy_MVP
//
//  Created by Aryan Sharma on 28/07/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService()
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var selectedRole: UserRole?
    @State private var showingRoleSelection = true
    
    var body: some View {
        NavigationView {
            if showingRoleSelection {
                VStack {
                    RoleSelectionView(selectedRole: $selectedRole)
                    
                    if selectedRole != nil {
                        Button("Continue") {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showingRoleSelection = false
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            } else {
                loginContent
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
        .environmentObject(authService)
    }
    
    private var loginContent: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 16) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showingRoleSelection = true
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back to Role Selection")
                    }
                    .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                
                Image(systemName: iconForRole(selectedRole ?? .tenant))
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Sign in as \(selectedRole?.displayName ?? "")")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding(.top, 20)
            
            // Form
            VStack(spacing: 20) {
                CustomTextField(
                    title: "Email",
                    text: $email,
                    placeholder: "Enter your email",
                    keyboardType: .emailAddress
                )
                
                CustomTextField(
                    title: "Password",
                    text: $password,
                    placeholder: "Enter your password",
                    isSecure: true
                )
                
                // Error message
                if let errorMessage = authService.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                
                // Sign In Button
                Button(action: signIn) {
                    if authService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(email.isEmpty || password.isEmpty || authService.isLoading)
                
                // Forgot Password
                Button("Forgot Password?") {
                    Task {
                        await authService.resetPassword(email: email)
                    }
                }
                .foregroundColor(.blue)
                .font(.subheadline)
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Sign Up
            VStack(spacing: 16) {
                Text("Don't have an account?")
                    .foregroundColor(.secondary)
                
                Button("Create Account") {
                    showingSignUp = true
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView(selectedRole: selectedRole ?? .tenant)
                .environmentObject(authService)
        }
    }
    
    private func signIn() {
        Task {
            await authService.signIn(email: email, password: password)
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

// MARK: - Custom UI Components

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textContentType(.oneTimeCode)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .autocapitalization(.none)
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue)
                    .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 2)
                    .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    LoginView()
}
