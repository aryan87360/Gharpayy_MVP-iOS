//
//  PGDetailView.swift
//  Gharpayy_MVP
//
//  Created by Aryan Sharma on 28/07/25.
//

import SwiftUI

struct PGDetailView: View {
    let listing: PGListing
    @StateObject private var firebaseService = FirebaseService()
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var reviews: [Review] = []
    @State private var showingBookingSheet = false
    @State private var showingInquirySheet = false
    @State private var isFavorite = false
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Images
                imageCarousel
                
                // Basic Info
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(listing.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            HStack {
                                Image(systemName: "location")
                                    .foregroundColor(.gray)
                                Text(listing.address.fullAddress)
                                    .foregroundColor(.secondary)
                            }
                            .font(.subheadline)
                        }
                        
                        Spacer()
                        
                        Button(action: toggleFavorite) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(isFavorite ? .red : .gray)
                                .font(.title2)
                        }
                    }
                    
                    // Price and Rating
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("₹\(Int(listing.rent))/month")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Text("+ ₹\(Int(listing.securityDeposit)) security deposit")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if listing.rating > 0 {
                            VStack(alignment: .trailing, spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text(String(format: "%.1f", listing.rating))
                                        .fontWeight(.semibold)
                                }
                                .font(.headline)
                                
                                Text("(\(listing.reviewCount) reviews)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Availability
                    HStack {
                        Image(systemName: listing.availableRooms > 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(listing.availableRooms > 0 ? .green : .red)
                        
                        Text("\(listing.availableRooms) of \(listing.totalRooms) rooms available")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(listing.roomType.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Description
                VStack(alignment: .leading, spacing: 12) {
                    Text("Description")
                        .font(.headline)
                    
                    Text(listing.description)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Amenities
                VStack(alignment: .leading, spacing: 12) {
                    Text("Amenities")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(listing.amenities, id: \.self) { amenity in
                            HStack(spacing: 8) {
                                Image(systemName: amenity.icon)
                                    .foregroundColor(.blue)
                                    .frame(width: 20)
                                
                                Text(amenity.displayName)
                                    .font(.subheadline)
                                
                                Spacer()
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                if !listing.rules.isEmpty {
                    Divider()
                    
                    // Rules
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rules & Regulations")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(listing.rules, id: \.self) { rule in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundColor(.blue)
                                    Text(rule)
                                        .font(.subheadline)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                if !reviews.isEmpty {
                    Divider()
                    
                    // Reviews
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reviews")
                            .font(.headline)
                        
                        ForEach(reviews.prefix(3)) { review in
                            ReviewCard(review: review)
                        }
                        
                        if reviews.count > 3 {
                            Button("View All Reviews") {
                                // Navigate to all reviews
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    if listing.availableRooms > 0 {
                        Button("Book Now") {
                            showingBookingSheet = true
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    } else {
                        Button("Join Waitlist") {
                            // Handle waitlist
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    
                    Button("Send Inquiry") {
                        showingInquirySheet = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingBookingSheet) {
            BookingSheet(listing: listing)
                .environmentObject(authService)
        }
        .sheet(isPresented: $showingInquirySheet) {
            InquirySheet(listing: listing)
                .environmentObject(authService)
        }
        .onAppear {
            loadReviews()
            checkIfFavorite()
        }
    }
    
    private var imageCarousel: some View {
        TabView {
            if listing.images.isEmpty {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 250)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No Images Available")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                    )
            } else {
                ForEach(listing.images, id: \.self) { imageURL in
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(ProgressView())
                    }
                    .frame(height: 250)
                    .clipped()
                }
            }
        }
        .frame(height: 250)
        .tabViewStyle(PageTabViewStyle())
    }
    
    private func loadReviews() {
        guard let listingId = listing.id else { return }
        
        Task {
            do {
                let fetchedReviews = try await firebaseService.fetchListingReviews(listingId: listingId)
                await MainActor.run {
                    self.reviews = fetchedReviews
                }
            } catch {
                print("Error loading reviews: \(error)")
            }
        }
    }
    
    private func checkIfFavorite() {
        // Implementation to check if listing is in favorites
        // This would require fetching user's favorites
    }
    
    private func toggleFavorite() {
        guard let userId = authService.currentUser?.id,
              let listingId = listing.id else { return }
        
        Task {
            do {
                if isFavorite {
                    try await firebaseService.removeFromFavorites(userId: userId, listingId: listingId)
                } else {
                    try await firebaseService.addToFavorites(userId: userId, listingId: listingId)
                }
                
                await MainActor.run {
                    isFavorite.toggle()
                }
            } catch {
                print("Error toggling favorite: \(error)")
            }
        }
    }
}


#Preview {
    NavigationView {
        PGDetailView(listing: PGListing(
            ownerId: "owner1",
            title: "Cozy PG near IT Park",
            description: "A comfortable and well-maintained PG accommodation perfect for working professionals.",
            address: Address(street: "123 Main Street", city: "Bangalore", state: "Karnataka", pincode: "560001"),
            rent: 15000,
            securityDeposit: 30000,
            roomType: .single,
            totalRooms: 20,
            availableRooms: 5,
            amenities: [.wifi, .ac, .meals, .laundry],
            rules: ["No smoking", "No loud music after 10 PM"],
            rating: 4.2,
            reviewCount: 15
        ))
    }
    .environmentObject(AuthService())
}
