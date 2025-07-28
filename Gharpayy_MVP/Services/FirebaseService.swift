//
//  FirebaseService.swift
//  Gharpayy_MVP
//
//  Created by Aryan Sharma on 28/07/25.
//

import Foundation
import FirebaseFirestore
import Combine

class FirebaseService: ObservableObject {
    private let db = Firestore.firestore()
    
    // MARK: - PG Listings
    
    func createListing(_ listing: PGListing) async throws -> String {
        let docRef = try db.collection("listings").addDocument(from: listing)
        return docRef.documentID
    }
    
    func updateListing(_ listing: PGListing) async throws {
        guard let id = listing.id else { throw FirebaseError.invalidData }
        try db.collection("listings").document(id).setData(from: listing)
    }
    
    func deleteListing(id: String) async throws {
        try await db.collection("listings").document(id).delete()
    }
    
    func fetchListings(filters: ListingFilters? = nil) async throws -> [PGListing] {
        var query: Query = db.collection("listings")
            .whereField("isApproved", isEqualTo: true)
            .whereField("isActive", isEqualTo: true)
        
        if let filters = filters {
            if let maxRent = filters.maxRent {
                query = query.whereField("rent", isLessThanOrEqualTo: maxRent)
            }
            
            if let roomType = filters.roomType {
                query = query.whereField("roomType", isEqualTo: roomType.rawValue)
            }
            
            if let city = filters.city, !city.isEmpty {
                query = query.whereField("address.city", isEqualTo: city)
            }
        }
        
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: PGListing.self) }
    }
    
    func fetchListingById(_ id: String) async throws -> PGListing? {
        let document = try await db.collection("listings").document(id).getDocument()
        return try document.data(as: PGListing.self)
    }
    
    func fetchOwnerListings(ownerId: String) async throws -> [PGListing] {
        let snapshot = try await db.collection("listings")
            .whereField("ownerId", isEqualTo: ownerId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: PGListing.self) }
    }
    
    // MARK: - Bookings
    
    func createBooking(_ booking: Booking) async throws -> String {
        let docRef = try db.collection("bookings").addDocument(from: booking)
        
        // Update available rooms
        try await updateAvailableRooms(listingId: booking.listingId, increment: false)
        
        return docRef.documentID
    }
    
    func updateBooking(_ booking: Booking) async throws {
        guard let id = booking.id else { throw FirebaseError.invalidData }
        try db.collection("bookings").document(id).setData(from: booking)
    }
    
    func fetchBookingsForListing(listingId: String) async throws -> [Booking] {
        let snapshot = try await db.collection("bookings")
            .whereField("listingId", isEqualTo: listingId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: Booking.self) }
    }
    
    func fetchBookingsForUser(userId: String) async throws -> [Booking] {
        let snapshot = try await db.collection("bookings")
            .whereField("tenantId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: Booking.self) }
    }
    
    func fetchUserBookings(userId: String) async throws -> [Booking] {
        let snapshot = try await db.collection("bookings")
            .whereField("tenantId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: Booking.self) }
    }
    
    func fetchOwnerBookings(ownerId: String) async throws -> [Booking] {
        let snapshot = try await db.collection("bookings")
            .whereField("ownerId", isEqualTo: ownerId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: Booking.self) }
    }
    
    private func updateAvailableRooms(listingId: String, increment: Bool) async throws {
        let docRef = db.collection("listings").document(listingId)
        
        try await db.runTransaction { transaction, errorPointer in
            let document: DocumentSnapshot
            do {
                document = try transaction.getDocument(docRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let listing = try? document.data(as: PGListing.self) else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Unable to retrieve listing data"
                ])
                errorPointer?.pointee = error
                return nil
            }
            
            let newAvailableRooms = increment ? listing.availableRooms + 1 : listing.availableRooms - 1
            
            guard newAvailableRooms >= 0 && newAvailableRooms <= listing.totalRooms else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Invalid room count"
                ])
                errorPointer?.pointee = error
                return nil
            }
            
            transaction.updateData(["availableRooms": newAvailableRooms], forDocument: docRef)
            return nil
        }
    }
    
    func createInquiry(_ inquiry: Inquiry) async throws -> String {
        let docRef = try db.collection("inquiries").addDocument(from: inquiry)
        return docRef.documentID
    }
    
    func fetchInquiriesForListing(listingId: String) async throws -> [Inquiry] {
        let snapshot = try await db.collection("inquiries")
            .whereField("listingId", isEqualTo: listingId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: Inquiry.self) }
    }
    
    func fetchInquiriesForUser(userId: String) async throws -> [Inquiry] {
        let snapshot = try await db.collection("inquiries")
            .whereField("tenantId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: Inquiry.self) }
    }
    
    func addToFavorites(userId: String, listingId: String) async throws {
        let docRef = db.collection("tenants").document(userId)
        try await docRef.updateData([
            "favoriteListings": FieldValue.arrayUnion([listingId])
        ])
    }
    
    func removeFromFavorites(userId: String, listingId: String) async throws {
        let docRef = db.collection("tenants").document(userId)
        try await docRef.updateData([
            "favoriteListings": FieldValue.arrayRemove([listingId])
        ])
    }
    
    func fetchFavoriteListings(userId: String) async throws -> [PGListing] {
        let tenantDoc = try await db.collection("tenants").document(userId).getDocument()
        let tenant = try tenantDoc.data(as: Tenant.self)
        
        var favoriteListings: [PGListing] = []
        
        for listingId in tenant.favoriteListings {
            if let listing = try await fetchListingById(listingId) {
                favoriteListings.append(listing)
            }
        }
        
        return favoriteListings
    }
    
    // MARK: - Reviews
    
    func addReview(_ review: Review) async throws {
        try db.collection("reviews").addDocument(from: review)
        
        // Update listing rating
        try await updateListingRating(listingId: review.listingId)
    }
    
    func fetchListingReviews(listingId: String) async throws -> [Review] {
        let snapshot = try await db.collection("reviews")
            .whereField("listingId", isEqualTo: listingId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: Review.self) }
    }
    
    private func updateListingRating(listingId: String) async throws {
        let reviews = try await fetchListingReviews(listingId: listingId)
        let averageRating = reviews.isEmpty ? 0.0 : Double(reviews.map { $0.rating }.reduce(0, +)) / Double(reviews.count)
        
        try await db.collection("listings").document(listingId).updateData([
            "rating": averageRating,
            "reviewCount": reviews.count
        ])
    }
    
    // MARK: - Inquiries
    
    func fetchOwnerInquiries(ownerId: String) async throws -> [Inquiry] {
        let snapshot = try await db.collection("inquiries")
            .whereField("ownerId", isEqualTo: ownerId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: Inquiry.self) }
    }
    
    func respondToInquiry(inquiryId: String, response: String) async throws {
        try await db.collection("inquiries").document(inquiryId).updateData([
            "response": response,
            "isRead": true,
            "respondedAt": Timestamp()
        ])
    }
    
    // MARK: - Admin Functions
    
    func fetchPendingListings() async throws -> [PGListing] {
        let snapshot = try await db.collection("listings")
            .whereField("isApproved", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: PGListing.self) }
    }
    
    func approveListing(listingId: String) async throws {
        try await db.collection("listings").document(listingId).updateData([
            "isApproved": true,
            "updatedAt": Timestamp()
        ])
    }
    
    func rejectListing(listingId: String) async throws {
        try await db.collection("listings").document(listingId).updateData([
            "isApproved": false,
            "isActive": false,
            "updatedAt": Timestamp()
        ])
    }
    
    func fetchAllUsers() async throws -> [User] {
        let snapshot = try await db.collection("users").getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: User.self) }
    }
    
    // MARK: - Support Tickets
    
    func createSupportTicket(_ ticket: SupportTicket) async throws -> String {
        let docRef = try db.collection("support_tickets").addDocument(from: ticket)
        return docRef.documentID
    }
    
    func updateSupportTicket(_ ticket: SupportTicket) async throws {
        try db.collection("support_tickets").document(ticket.id).setData(from: ticket)
    }
    
    func fetchSupportTickets() async throws -> [SupportTicket] {
        let snapshot = try await db.collection("support_tickets")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: SupportTicket.self) }
    }
    
    func verifyOwnerLicense(ownerId: String) async throws {
        try await db.collection("owners").document(ownerId).updateData([
            "isLicenseVerified": true
        ])
        
        try await db.collection("users").document(ownerId).updateData([
            "isVerified": true
        ])
    }
    
    // MARK: - Image Management
    // Note: Image URLs will be provided directly (e.g., from external image hosting services)
    // or stored as base64 strings if needed for MVP
}

// MARK: - Supporting Types

struct ListingFilters {
    var maxRent: Double?
    var roomType: RoomType?
    var city: String?
    var amenities: [Amenity] = []
}

enum FirebaseError: Error, LocalizedError {
    case invalidData
    case documentNotFound
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data provided"
        case .documentNotFound:
            return "Document not found"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}
