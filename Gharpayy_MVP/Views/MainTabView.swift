//
//  MainTabView.swift
//  Gharpayy_MVP
//
//  Created by Aryan Sharma on 28/07/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        Group {
            if let userRole = authService.currentUser?.role {
                switch userRole {
                case .tenant:
                    TenantTabView()
                        .environmentObject(authService)
                case .owner:
                    OwnerTabView()
                        .environmentObject(authService)
                case .admin:
                    AdminTabView()
                        .environmentObject(authService)
                }
            } else {
                // Fallback loading state
                ProgressView("Loading...")
            }
        }
    }
    
}

// MARK: - Role-Specific Tab Views

struct TenantTabView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        TabView {
            TenantHomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Browse")
                }
            
            TenantFavoritesView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favorites")
                }
            
            TenantBookingsView()
                .tabItem {
                    Image(systemName: "calendar.badge.clock")
                    Text("Bookings")
                }
            
            TenantProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(.blue)
    }
}

struct OwnerTabView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        TabView {
            OwnerDashboardView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Dashboard")
                }
            
            OwnerPropertiesView()
                .tabItem {
                    Image(systemName: "building.2.fill")
                    Text("Properties")
                }
            
            OwnerBookingsView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Bookings")
                }
            
            OwnerInquiriesView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Inquiries")
                }
            
            OwnerProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(.blue)
    }
}

struct AdminTabView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        TabView {
            AdminDashboardView()
                .tabItem {
                    Image(systemName: "chart.pie.fill")
                    Text("Dashboard")
                }
            
            AdminListingsView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Listings")
                }
            
            AdminUsersView()
                .tabItem {
                    Image(systemName: "person.2")
                    Text("Users")
                }
            
            AdminSupportView()
                .tabItem {
                    Image(systemName: "questionmark.circle")
                    Text("Support")
                }
            
            AdminProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(.blue)
    }
}

// MARK: - Tenant Views Implementation

struct TenantFavoritesView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var firebaseService = FirebaseService()
    @State private var favoriteListings: [PGListing] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading favorites...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if favoriteListings.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No Favorites Yet")
                            .font(.title2)
                            .fontWeight(.medium)
                        Text("Start browsing PGs and add your favorites")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(favoriteListings) { listing in
                                NavigationLink(destination: PGDetailView(listing: listing)) {
                                    PGListingCard(listing: listing)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Favorites")
            .onAppear {
                loadFavorites()
            }
        }
    }
    
    private func loadFavorites() {
        guard let userId = authService.currentUser?.id else { return }
        
        isLoading = true
        Task {
            do {
                let favorites = try await firebaseService.fetchFavoriteListings(userId: userId)
                await MainActor.run {
                    self.favoriteListings = favorites
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

struct TenantBookingsView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var firebaseService = FirebaseService()
    @State private var bookings: [Booking] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading bookings...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if bookings.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No Bookings Yet")
                            .font(.title2)
                            .fontWeight(.medium)
                        Text("Your booking history will appear here")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(bookings) { booking in
                                BookingCard(booking: booking)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Bookings")
            .onAppear {
                loadBookings()
            }
        }
    }
    
    private func loadBookings() {
        guard let userId = authService.currentUser?.id else { return }
        
        isLoading = true
        Task {
            do {
                let userBookings = try await firebaseService.fetchUserBookings(userId: userId)
                await MainActor.run {
                    self.bookings = userBookings
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}



struct TenantProfileView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let user = authService.currentUser {
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text(user.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(user.role.displayName)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    .padding(.top, 40)
                }
                
                Spacer()
                
                Button("Sign Out") {
                    authService.signOut()
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Profile")
        }
    }
}

// Owner Views
struct OwnerDashboardView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Owner Dashboard")
                    .font(.title)
                    .padding()
                Text("Coming Soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Dashboard")
        }
    }
}



struct OwnerInquiriesView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Customer Inquiries")
                    .font(.title)
                    .padding()
                Text("Coming Soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Inquiries")
        }
    }
}

struct OwnerProfileView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let user = authService.currentUser {
                    VStack(spacing: 16) {
                        Image(systemName: "building.2.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text(user.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(user.role.displayName)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    .padding(.top, 40)
                }
                
                Spacer()
                
                Button("Sign Out") {
                    authService.signOut()
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Profile")
        }
    }
}

// Admin Views
struct AdminDashboardView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Admin Dashboard")
                    .font(.title)
                    .padding()
                Text("Coming Soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Dashboard")
        }
    }
}





struct AdminProfileView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let user = authService.currentUser {
                    VStack(spacing: 16) {
                        Image(systemName: "shield.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text(user.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(user.role.displayName)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    .padding(.top, 40)
                }
                
                Spacer()
                
                Button("Sign Out") {
                    authService.signOut()
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthService())
}
