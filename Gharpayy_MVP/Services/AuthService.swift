//
//  AuthService.swift
//  Gharpayy_MVP
//
//  Created by Aryan Sharma on 28/07/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Listen for authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.fetchUserData(uid: user.uid)
            } else {
                self?.currentUser = nil
                self?.isAuthenticated = false
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String, name: String, phoneNumber: String, role: UserRole) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            let newUser = User(
                id: result.user.uid,
                email: email,
                name: name,
                phoneNumber: phoneNumber,
                role: role
            )
            
            try await saveUserToFirestore(user: newUser)
            
            // Create role-specific document
            await createRoleSpecificDocument(userId: result.user.uid, role: role)
            
            await MainActor.run {
                self.currentUser = newUser
                self.isAuthenticated = true
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            fetchUserData(uid: result.user.uid)
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchUserData(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] document, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                self?.isLoading = false
                return
            }
            
            if let document = document, document.exists {
                do {
                    let user = try document.data(as: User.self)
                    DispatchQueue.main.async {
                        self?.currentUser = user
                        self?.isAuthenticated = true
                        self?.isLoading = false
                    }
                } catch {
                    self?.errorMessage = "Failed to decode user data"
                    self?.isLoading = false
                }
            }
        }
    }
    
    private func saveUserToFirestore(user: User) async throws {
        try db.collection("users").document(user.id!).setData(from: user)
    }
    
    private func createRoleSpecificDocument(userId: String, role: UserRole) async {
        do {
            switch role {
            case .tenant:
                let tenant = Tenant(userId: userId)
                try db.collection("tenants").document(userId).setData(from: tenant)
                
            case .owner:
                let owner = Owner(userId: userId)
                try db.collection("owners").document(userId).setData(from: owner)
                
            case .admin:
                // Admin doesn't need additional document for now
                break
            }
        } catch {
            print("Error creating role-specific document: \(error)")
        }
    }
    
    // MARK: - User Profile Methods
    
    func updateUserProfile(name: String, phoneNumber: String) async {
        guard let userId = currentUser?.id else { return }
        
        isLoading = true
        
        do {
            let updates: [String: Any] = [
                "name": name,
                "phoneNumber": phoneNumber,
                "updatedAt": Timestamp()
            ]
            
            try await db.collection("users").document(userId).updateData(updates)
            
            await MainActor.run {
                self.currentUser?.name = name
                self.currentUser?.phoneNumber = phoneNumber
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func resetPassword(email: String) async {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
