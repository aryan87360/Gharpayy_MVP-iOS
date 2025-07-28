//
//  BookingSheet.swift
//  Gharpayy_MVP
//
//  Created by Aryan Sharma on 28/07/25.
//

import SwiftUI

struct BookingSheet: View {
    let listing: PGListing
    @EnvironmentObject var authService: AuthService
    @StateObject private var firebaseService = FirebaseService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var checkInDate = Date()
    @State private var isLoading = false
    @State private var showingSuccess = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text("Book Your Stay")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(listing.title)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Booking Details
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Check-in Date")
                            .font(.headline)
                        
                        DatePicker("", selection: $checkInDate, in: Date()..., displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                    }
                    
                    // Cost Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cost Breakdown")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Monthly Rent")
                                Spacer()
                                Text("₹\(Int(listing.rent))")
                            }
                            
                            HStack {
                                Text("Security Deposit")
                                Spacer()
                                Text("₹\(Int(listing.securityDeposit))")
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Total Amount")
                                    .fontWeight(.bold)
                                Spacer()
                                Text("₹\(Int(listing.rent + listing.securityDeposit))")
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                        }
                        .font(.subheadline)
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Book Button
                Button(action: bookRoom) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Confirm Booking")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isLoading)
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
            .navigationTitle("Book Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Booking Confirmed!", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your booking request has been submitted successfully. The owner will contact you soon.")
        }
    }
    
    private func bookRoom() {
        guard let userId = authService.currentUser?.id,
              let listingId = listing.id else {
            errorMessage = "Unable to process booking. Please try again."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let booking = Booking(
            tenantId: userId,
            listingId: listingId,
            ownerId: listing.ownerId,
            checkInDate: checkInDate,
            monthlyRent: listing.rent,
            securityDeposit: listing.securityDeposit,
            status: .pending
        )
        
        Task {
            do {
                _ = try await firebaseService.createBooking(booking)
                
                await MainActor.run {
                    self.isLoading = false
                    self.showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to create booking. Please try again."
                }
            }
        }
    }
}

struct InquirySheet: View {
    let listing: PGListing
    @EnvironmentObject var authService: AuthService
    @StateObject private var firebaseService = FirebaseService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var message = ""
    @State private var isLoading = false
    @State private var showingSuccess = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text("Send Inquiry")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(listing.title)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Message Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Message")
                        .font(.headline)
                    
                    TextEditor(text: $message)
                        .frame(minHeight: 120)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    
                    Text("Ask about availability, amenities, or any other questions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Send Button
                Button(action: sendInquiry) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Send Inquiry")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
            .navigationTitle("Send Inquiry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Inquiry Sent!", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your inquiry has been sent to the property owner. They will respond soon.")
        }
    }
    
    private func sendInquiry() {
        guard let userId = authService.currentUser?.id,
              let listingId = listing.id else {
            errorMessage = "Unable to send inquiry. Please try again."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let inquiry = Inquiry(
            tenantId: userId,
            listingId: listingId,
            ownerId: listing.ownerId,
            message: message.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        Task {
            do {
                _ = try await firebaseService.createInquiry(inquiry)
                
                await MainActor.run {
                    self.isLoading = false
                    self.showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to send inquiry. Please try again."
                }
            }
        }
    }
}

#Preview {
    BookingSheet(listing: PGListing(
        ownerId: "owner1",
        title: "Cozy PG near IT Park",
        description: "A comfortable PG",
        address: Address(street: "123 Main Street", city: "Bangalore", state: "Karnataka", pincode: "560001"),
        rent: 15000,
        securityDeposit: 30000,
        roomType: .single,
        totalRooms: 20,
        availableRooms: 5,
        amenities: [.wifi, .ac],
        rules: []
    ))
    .environmentObject(AuthService())
}
