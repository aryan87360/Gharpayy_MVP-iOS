//
//  AdminUsersView.swift
//  Gharpayy_MVP
//
//  Created by Aryan Sharma on 28/07/25.
//

import SwiftUI

struct AdminUsersView: View {
    @StateObject private var firebaseService = FirebaseService()
    @State private var users: [User] = []
    @State private var filteredUsers: [User] = []
    @State private var isLoading = false
    @State private var selectedRole: UserRole? = nil
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter
                VStack(spacing: 12) {
                    SearchBar(text: $searchText, onSearchButtonClicked: applyFilters)
                        .padding(.horizontal)
                    
                    // Role Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            Button("All") {
                                selectedRole = nil
                                applyFilters()
                            }
                            .buttonStyle(FilterButtonStyle(isSelected: selectedRole == nil))
                            
                            ForEach(UserRole.allCases, id: \.self) { role in
                                Button(role.displayName) {
                                    selectedRole = role
                                    applyFilters()
                                }
                                .buttonStyle(FilterButtonStyle(isSelected: selectedRole == role))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
                
                if isLoading {
                    ProgressView("Loading users...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredUsers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No Users Found")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Try adjusting your search or filters")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredUsers) { user in
                                AdminUserCard(user: user) {
                                    loadUsers()
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Manage Users")
            .onAppear {
                loadUsers()
            }
            .onChange(of: searchText) { _ in
                applyFilters()
            }
        }
    }
    
    private func loadUsers() {
        isLoading = true
        Task {
            do {
                let allUsers = try await firebaseService.fetchAllUsers()
                await MainActor.run {
                    self.users = allUsers
                    self.filteredUsers = allUsers
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func applyFilters() {
        var filtered = users
        
        // Role filter
        if let selectedRole = selectedRole {
            filtered = filtered.filter { $0.role == selectedRole }
        }
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { user in
                user.name.localizedCaseInsensitiveContains(searchText) ||
                user.email.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        filteredUsers = filtered
    }
}

struct AdminUserCard: View {
    let user: User
    @StateObject private var firebaseService = FirebaseService()
    let onUpdate: () -> Void
    
    @State private var isProcessing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let phoneNumber = user.phoneNumber {
                        Text(phoneNumber)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(user.role.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(colorForRole(user.role))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    
                    if user.isVerified {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                            Text("Verified")
                                .font(.caption2)
                        }
                        .foregroundColor(.green)
                    }
                }
            }
            
            // User Stats
            HStack {
                Text("Joined: \(user.createdAt, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("ID: \(user.id?.suffix(8) ?? "Unknown")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Actions for Owner verification
            if user.role == .owner && !user.isVerified {
                Button("Verify License") {
                    verifyOwnerLicense()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isProcessing)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func colorForRole(_ role: UserRole) -> Color {
        switch role {
        case .tenant:
            return .blue
        case .owner:
            return .green
        case .admin:
            return .purple
        }
    }
    
    private func verifyOwnerLicense() {
        guard let userId = user.id else { return }
        
        isProcessing = true
        Task {
            do {
                try await firebaseService.verifyOwnerLicense(ownerId: userId)
                await MainActor.run {
                    self.isProcessing = false
                    onUpdate()
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                }
            }
        }
    }
}

struct FilterButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(isSelected ? .white : .blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.blue : Color.blue.opacity(0.1))
                    .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    AdminUsersView()
}
