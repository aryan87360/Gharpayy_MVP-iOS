//
//  TenantHomeView.swift
//  Gharpayy_MVP
//
//  Created by Aryan Sharma on 28/07/25.
//

import SwiftUI

struct TenantHomeView: View {
    @StateObject private var firebaseService = FirebaseService()
    @State private var listings: [PGListing] = []
    @State private var filteredListings: [PGListing] = []
    @State private var isLoading = false
    @State private var showingFilters = false
    @State private var searchText = ""
    @State private var filters = ListingFilters()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText, onSearchButtonClicked: applyFilters)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Filter Button
                HStack {
                    Button(action: { showingFilters = true }) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                            Text("Filters")
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    Text("\(filteredListings.count) PGs found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Listings
                if isLoading {
                    Spacer()
                    ProgressView("Loading PGs...")
                    Spacer()
                } else if filteredListings.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "house.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No PGs found")
                            .font(.title2)
                            .fontWeight(.medium)
                        Text("Try adjusting your filters")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredListings) { listing in
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
            .navigationTitle("Browse PGs")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingFilters) {
                FilterView(filters: $filters, onApply: applyFilters)
            }
            .onAppear {
                loadListings()
            }
            .onChange(of: searchText) { _ in
                applyFilters()
            }
        }
    }
    
    private func loadListings() {
        isLoading = true
        Task {
            do {
                let fetchedListings = try await firebaseService.fetchListings()
                await MainActor.run {
                    self.listings = fetchedListings
                    self.filteredListings = fetchedListings
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
        var filtered = listings
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { listing in
                listing.title.localizedCaseInsensitiveContains(searchText) ||
                listing.address.city.localizedCaseInsensitiveContains(searchText) ||
                listing.address.fullAddress.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Price filter
        if let maxRent = filters.maxRent {
            filtered = filtered.filter { $0.rent <= maxRent }
        }
        
        // Room type filter
        if let roomType = filters.roomType {
            filtered = filtered.filter { $0.roomType == roomType }
        }
        
        // City filter
        if let city = filters.city, !city.isEmpty {
            filtered = filtered.filter { $0.address.city.localizedCaseInsensitiveContains(city) }
        }
        
        // Amenities filter
        if !filters.amenities.isEmpty {
            filtered = filtered.filter { listing in
                filters.amenities.allSatisfy { amenity in
                    listing.amenities.contains(amenity)
                }
            }
        }
        
        filteredListings = filtered
    }
}

struct SearchBar: View {
    @Binding var text: String
    var onSearchButtonClicked: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search PGs, locations...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .onSubmit {
                    onSearchButtonClicked()
                }
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    onSearchButtonClicked()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PGListingCard: View {
    let listing: PGListing
    @StateObject private var firebaseService = FirebaseService()
    @EnvironmentObject var authService: AuthService
    @State private var isFavorite = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .cornerRadius(12)
                
                if listing.images.isEmpty {
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No Image")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                } else {
                    AsyncImage(url: URL(string: listing.images.first ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
                }
                
                // Favorite button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: toggleFavorite) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(isFavorite ? .red : .white)
                                .font(.system(size: 20))
                                .padding(8)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                    Spacer()
                }
                .padding(12)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(listing.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if listing.rating > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", listing.rating))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.gray)
                        .font(.caption)
                    Text(listing.address.city)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    Text("₹\(Int(listing.rent))/month")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text(listing.roomType.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                }
                
                // Amenities
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(listing.amenities.prefix(4)), id: \.self) { amenity in
                            HStack(spacing: 4) {
                                Image(systemName: amenity.icon)
                                    .font(.caption2)
                                Text(amenity.displayName)
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                        }
                        
                        if listing.amenities.count > 4 {
                            Text("+\(listing.amenities.count - 4) more")
                                .font(.caption2)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
                
                HStack {
                    Text("\(listing.availableRooms) of \(listing.totalRooms) rooms available")
                        .font(.caption)
                        .foregroundColor(listing.availableRooms > 0 ? .green : .red)
                    
                    Spacer()
                    
                    if listing.reviewCount > 0 {
                        Text("(\(listing.reviewCount) reviews)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
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
    TenantHomeView()
        .environmentObject(AuthService())
}
