//
//  AdminListingsView.swift
//  Gharpayy_MVP
//
//  Created by Aryan Sharma on 28/07/25.
//

import SwiftUI

struct AdminListingsView: View {
    @StateObject private var firebaseService = FirebaseService()
    @State private var pendingListings: [PGListing] = []
    @State private var isLoading = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // Tab Selector
                Picker("Listing Type", selection: $selectedTab) {
                    Text("Pending Approval").tag(0)
                    Text("All Listings").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                if isLoading {
                    ProgressView("Loading listings...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if pendingListings.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: selectedTab == 0 ? "checkmark.circle" : "list.clipboard")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text(selectedTab == 0 ? "No Pending Approvals" : "No Listings Found")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text(selectedTab == 0 ? "All listings have been reviewed" : "No listings available")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(pendingListings) { listing in
                                AdminListingCard(listing: listing) {
                                    loadPendingListings()
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Manage Listings")
            .onAppear {
                loadPendingListings()
            }
            .onChange(of: selectedTab) { _ in
                loadPendingListings()
            }
        }
    }
    
    private func loadPendingListings() {
        isLoading = true
        Task {
            do {
                let listings = selectedTab == 0 ? 
                    try await firebaseService.fetchPendingListings() :
                    try await firebaseService.fetchListings()
                
                await MainActor.run {
                    self.pendingListings = listings
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

struct AdminListingCard: View {
    let listing: PGListing
    @StateObject private var firebaseService = FirebaseService()
    let onUpdate: () -> Void
    
    @State private var isProcessing = false
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(.gray)
                            .font(.caption)
                        Text(listing.address.city)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(listing.isApproved ? "Approved" : "Pending")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(listing.isApproved ? Color.green : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    
                    if !listing.isActive {
                        Text("Inactive")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }
            }
            
            // Property details
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("₹\(Int(listing.rent))/month")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("\(listing.roomType.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(listing.totalRooms) rooms")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(listing.amenities.count) amenities")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Owner info
            Text("Owner ID: \(listing.ownerId)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(6)
            
            // Action buttons
            if !listing.isApproved {
                HStack(spacing: 12) {
                    Button("View Details") {
                        showingDetail = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button("Approve") {
                        approveListing()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isProcessing)
                    
                    Button("Reject") {
                        rejectListing()
                    }
                    .buttonStyle(RejectButtonStyle())
                    .disabled(isProcessing)
                }
            } else {
                Button("View Details") {
                    showingDetail = true
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .sheet(isPresented: $showingDetail) {
            PGDetailView(listing: listing)
        }
    }
    
    private func approveListing() {
        guard let listingId = listing.id else { return }
        
        isProcessing = true
        Task {
            do {
                try await firebaseService.approveListing(listingId: listingId)
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
    
    private func rejectListing() {
        guard let listingId = listing.id else { return }
        
        isProcessing = true
        Task {
            do {
                try await firebaseService.rejectListing(listingId: listingId)
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

struct RejectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red)
                    .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    AdminListingsView()
}
