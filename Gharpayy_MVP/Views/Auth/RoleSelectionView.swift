//
//  RoleSelectionView.swift
//  Gharpayy_MVP
//
//  Created by Aryan Sharma on 28/07/25.
//

import SwiftUI

struct RoleSelectionView: View {
    @Binding var selectedRole: UserRole?
    @State private var animateCards = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "house.lodge.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Welcome to Gharpayy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Choose your role to get started")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            // Role Cards
            VStack(spacing: 20) {
                ForEach(UserRole.allCases, id: \.self) { role in
                    RoleCard(
                        role: role,
                        isSelected: selectedRole == role,
                        onTap: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                selectedRole = role
                            }
                        }
                    )
                    .scaleEffect(animateCards ? 1.0 : 0.8)
                    .opacity(animateCards ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(UserRole.allCases.firstIndex(of: role) ?? 0) * 0.1), value: animateCards)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .onAppear {
            animateCards = true
        }
    }
}

struct RoleCard: View {
    let role: UserRole
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: iconForRole(role))
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 40, height: 40)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.displayName)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(descriptionForRole(role))
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue : Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
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
    
    private func descriptionForRole(_ role: UserRole) -> String {
        switch role {
        case .tenant:
            return "Looking for PG accommodation"
        case .owner:
            return "Managing PG properties"
        case .admin:
            return "Platform administration"
        }
    }
}

#Preview {
    RoleSelectionView(selectedRole: .constant(nil))
}
