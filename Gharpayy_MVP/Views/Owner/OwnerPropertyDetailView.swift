//
//  OwnerPropertyDetailView.swift
//  Gharpayy_MVP
//
//  Created by Aryan Sharma on 28/07/25.
//

import SwiftUI

struct OwnerPropertyDetailView: View {
    let property: PGListing
    @StateObject private var firebaseService = FirebaseService()
    @State private var bookings: [Booking] = []
    @State private var inquiries: [Inquiry] = []
    @State private var reviews: [Review] = []
    @State private var isLoading = false
    @State private var showingEditSheet = false
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Property Header
                VStack(alignment: .leading, spacing: 12) {
                    AsyncImage(url: URL(string: property.images.first ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(property.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(property.address.fullAddress)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("₹\(property.rent)/month")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                Text(String(format: "%.1f", property.rating))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        HStack {
                            Label("\(property.availableRooms) available", systemImage: "bed.double")
                            Spacer()
                            Label(property.roomType.rawValue, systemImage: "house")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Tabs
                Picker("Tabs", selection: $selectedTab) {
                    Text("Bookings").tag(0)
                    Text("Inquiries").tag(1)
                    Text("Reviews").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Tab Content
                Group {
                    if selectedTab == 0 {
                        BookingsTab(bookings: bookings)
                    } else if selectedTab == 1 {
                        InquiriesTab(inquiries: inquiries)
                    } else {
                        ReviewsTab(reviews: reviews)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Property Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditPropertyView(property: property)
        }
        .task {
            await loadData()
        }
    }
    
    private func loadData() async {
        isLoading = true
        do {
            async let bookingsTask = firebaseService.fetchBookingsForListing(listingId: property.id ?? "")
            async let inquiriesTask = firebaseService.fetchInquiriesForListing(listingId: property.id ?? "")
            async let reviewsTask = firebaseService.fetchListingReviews(listingId: property.id ?? "")
            
            bookings = try await bookingsTask
            inquiries = try await inquiriesTask
            reviews = try await reviewsTask
        } catch {
            print("Error loading data: \(error)")
        }
        isLoading = false
    }
}

struct BookingsTab: View {
    let bookings: [Booking]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Bookings")
                .font(.headline)
            
            if bookings.isEmpty {
                Text("No bookings yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(bookings) { booking in
                        BookingCard(booking: booking)
                    }
                }
            }
        }
    }
}

struct InquiriesTab: View {
    let inquiries: [Inquiry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Inquiries")
                .font(.headline)
            
            if inquiries.isEmpty {
                Text("No inquiries yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(inquiries) { inquiry in
                        InquiryCard(inquiry: inquiry)
                    }
                }
            }
        }
    }
}

struct ReviewsTab: View {
    let reviews: [Review]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reviews")
                .font(.headline)
            
            if reviews.isEmpty {
                Text("No reviews yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(reviews) { review in
                        ReviewCard(review: review)
                    }
                }
            }
        }
    }
}

struct BookingCard: View {
    let booking: Booking
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Booking #\((booking.id ?? "").prefix(8))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(booking.status.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(booking.status))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            
            Text("Check-in: \(booking.checkInDate, style: .date)")
                .font(.caption)
                .foregroundColor(.secondary)

        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func statusColor(_ status: BookingStatus) -> Color {
        switch status {
        case .pending:
            return .orange
        case .confirmed:
            return .green
        case .active:
            return .blue
        case .cancelled:
            return .red
        case .completed:
            return .gray
        }
    }
}

struct InquiryCard: View {
    let inquiry: Inquiry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Inquiry #\((inquiry.id ?? "").prefix(8))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(inquiry.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(inquiry.message)
                .font(.caption)
                .lineLimit(3)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ReviewCard: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < review.rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                Text(review.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(review.comment)
                .font(.caption)
                .lineLimit(3)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct EditPropertyView: View {
    let property: PGListing
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firebaseService = FirebaseService()
    
    @State private var title: String
    @State private var description: String
    @State private var rent: String
    @State private var availableRooms: String
    
    init(property: PGListing) {
        self.property = property
        self._title = State(initialValue: property.title)
        self._description = State(initialValue: property.description)
        self._rent = State(initialValue: String(property.rent))
        self._availableRooms = State(initialValue: String(property.availableRooms))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Pricing & Availability") {
                    TextField("Monthly Rent", text: $rent)
                        .keyboardType(.numberPad)
                    TextField("Available Rooms", text: $availableRooms)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Edit Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !description.isEmpty && !rent.isEmpty && !availableRooms.isEmpty
    }
    
    private func saveChanges() {
        Task {
            do {
                var updatedProperty = property
                updatedProperty.title = title
                updatedProperty.description = description
                updatedProperty.rent = Double(Int(rent) ?? Int(property.rent))
                updatedProperty.availableRooms = Int(availableRooms) ?? property.availableRooms
                
                try await firebaseService.updateListing(updatedProperty)
                dismiss()
            } catch {
                print("Error updating property: \(error)")
            }
        }
    }
}

