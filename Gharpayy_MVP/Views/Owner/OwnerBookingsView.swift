//
//  OwnerBookingsView.swift
//  Gharpayy_MVP
//
//  Created by Aryan Sharma on 28/07/25.
//

import SwiftUI

struct OwnerBookingsView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var firebaseService = FirebaseService()
    @State private var bookings: [Booking] = []
    @State private var inquiries: [Inquiry] = []
    @State private var isLoading = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // Tab Picker
                Picker("Tabs", selection: $selectedTab) {
                    Text("Bookings").tag(0)
                    Text("Inquiries").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                if isLoading {
                    Spacer()
                    ProgressView("Loading...")
                    Spacer()
                } else {
                    if selectedTab == 0 {
                        BookingsListView(bookings: bookings, firebaseService: firebaseService)
                    } else {
                        InquiriesListView(inquiries: inquiries, firebaseService: firebaseService)
                    }
                }
            }
            .navigationTitle("Bookings & Inquiries")
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
        }
    }
    
    private func loadData() async {
        guard let userId = authService.currentUser?.id else { return }
        
        isLoading = true
        do {
            // Get all properties owned by this user
            let ownedProperties = try await firebaseService.fetchOwnerListings(ownerId: userId)
            
            var allBookings: [Booking] = []
            var allInquiries: [Inquiry] = []
            
            // Fetch bookings and inquiries for each property
            for property in ownedProperties {
                let propertyBookings = try await firebaseService.fetchBookingsForListing(listingId: property.id ?? "")
                let propertyInquiries = try await firebaseService.fetchInquiriesForListing(listingId: property.id ?? "")
                
                allBookings.append(contentsOf: propertyBookings)
                allInquiries.append(contentsOf: propertyInquiries)
            }
            
            bookings = allBookings.sorted { $0.createdAt > $1.createdAt }
            inquiries = allInquiries.sorted { $0.createdAt > $1.createdAt }
        } catch {
            print("Error loading data: \(error)")
        }
        isLoading = false
    }
}

struct BookingsListView: View {
    let bookings: [Booking]
    let firebaseService: FirebaseService
    @State private var showingBookingDetail: Booking?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if bookings.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No Bookings Yet")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Your property bookings will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(bookings) { booking in
                        OwnerBookingCard(booking: booking, firebaseService: firebaseService)
                            .onTapGesture {
                                showingBookingDetail = booking
                            }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .sheet(item: $showingBookingDetail) { booking in
            BookingDetailView(booking: booking, firebaseService: firebaseService)
        }
    }
}

struct InquiriesListView: View {
    let inquiries: [Inquiry]
    let firebaseService: FirebaseService
    @State private var showingInquiryDetail: Inquiry?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if inquiries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No Inquiries Yet")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Customer inquiries will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(inquiries) { inquiry in
                        OwnerInquiryCard(inquiry: inquiry)
                            .onTapGesture {
                                showingInquiryDetail = inquiry
                            }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }

    }
}

struct OwnerBookingCard: View {
    let booking: Booking
    let firebaseService: FirebaseService
    @State private var propertyTitle = "Loading..."
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(propertyTitle)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("Booking #\(booking.id?.prefix(8))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(booking.status.rawValue.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor(booking.status))
                        .foregroundColor(.white)
                        .clipShape(Capsule())

                }
            }
            
            HStack {
                Label(booking.checkInDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                
                Spacer()
                

            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task {
            await loadPropertyTitle()
        }
    }
    
    private func loadPropertyTitle() async {
        do {
            if let property = try await firebaseService.fetchListingById(booking.listingId) {
                propertyTitle = property.title
            }
        } catch {
            propertyTitle = "Unknown Property"
        }
    }
    
    private func statusColor(_ status: BookingStatus) -> Color {
        switch status {
        case .pending:
            return .orange
        case .confirmed:
            return .green
        case .cancelled:
            return .red
        case .completed:
            return .blue
        case .active:
            return .purple
        }
    }
}

struct OwnerInquiryCard: View {
    let inquiry: Inquiry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Inquiry #\(inquiry.id?.prefix(8))")
                    .font(.headline)
                
                Spacer()
                
                Text(inquiry.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(inquiry.message)
                .font(.subheadline)
                .lineLimit(3)
                .foregroundColor(.primary)
            
            HStack {
                Label("Tenant Inquiry", systemImage: "person.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct BookingDetailView: View {
    let booking: Booking
    let firebaseService: FirebaseService
    @Environment(\.dismiss) private var dismiss
    @State private var property: PGListing?
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if isLoading {
                        ProgressView("Loading details...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Property Info
                        if let property = property {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Property")
                                    .font(.headline)
                                
                                Text(property.title)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text(property.address.fullAddress)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Booking Details
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Booking Details")
                                .font(.headline)
                            
                            DetailRow(title: "Booking ID", value: booking.id ?? "")
                            DetailRow(title: "Status", value: booking.status.rawValue.capitalized)
                            DetailRow(title: "Check-in Date", value: booking.checkInDate.formatted(date: .long, time: .omitted))

                            DetailRow(title: "Created", value: booking.createdAt.formatted(date: .long, time: .shortened))
                        }
                        
                        // Action Buttons
                        if booking.status == .pending {
                            VStack(spacing: 12) {
                                Button(action: {
                                    confirmBooking()
                                }) {
                                    Text("Confirm Booking")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                
                                Button(action: {
                                    cancelBooking()
                                }) {
                                    Text("Cancel Booking")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Booking Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadPropertyDetails()
            }
        }
    }
    
    private func loadPropertyDetails() async {
        do {
            property = try await firebaseService.fetchListingById(booking.listingId)
        } catch {
            print("Error loading property: \(error)")
        }
        isLoading = false
    }
    
    private func confirmBooking() {
        Task {
            do {
                var updatedBooking = booking
                updatedBooking.status = .confirmed
                try await firebaseService.updateBooking(updatedBooking)
                dismiss()
            } catch {
                print("Error confirming booking: \(error)")
            }
        }
    }
    
    private func cancelBooking() {
        Task {
            do {
                var updatedBooking = booking
                updatedBooking.status = .cancelled
                try await firebaseService.updateBooking(updatedBooking)
                dismiss()
            } catch {
                print("Error cancelling booking: \(error)")
            }
        }
    }
}

//struct InquiryDetailView: View {
//    let inquiry: Inquiry
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        NavigationView {
//            ScrollView {
//                VStack(alignment: .leading, spacing: 20) {
//                    VStack(alignment: .leading, spacing: 12) {
//                        Text("Inquiry Details")
//                            .font(.headline)
//                        
//                        DetailRow(title: "Inquiry ID", value: inquiry.id ?? "")
//                        DetailRow(title: "Date", value: inquiry.createdAt.formatted(date: .long, time: .shortened))
//                    }
//                    
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text("Message")
//                            .font(.headline)
//                        
//                        Text(inquiry.message)
//                            .font(.body)
//                            .padding()
//                            .background(Color(.systemGray6))
//                            .clipShape(RoundedRectangle(cornerRadius: 8))
//                    }
//                }
//                .padding()
//            }
//            .navigationTitle("Inquiry")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Done") {
//                        dismiss()
//                    }
//                }
//            }
//        }
//    }
//}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    OwnerBookingsView()
        .environmentObject(AuthService())
}
