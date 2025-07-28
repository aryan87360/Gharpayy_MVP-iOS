//
//  PropertyModels.swift
//  Gharpayy_MVP
//
//  Created by Aryan Sharma on 28/07/25.
//

import Foundation
import FirebaseFirestore
import CoreLocation

struct PGListing: Codable, Identifiable {
    @DocumentID var id: String?
    var ownerId: String
    var title: String
    var description: String
    var address: Address
    var rent: Double
    var securityDeposit: Double
    var roomType: RoomType
    var totalRooms: Int
    var availableRooms: Int
    var amenities: [Amenity]
    var rules: [String]
    var images: [String] = []
    var isApproved: Bool = false
    var isActive: Bool = true
    var rating: Double = 0.0
    var reviewCount: Int = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

struct Address: Codable {
    var street: String
    var city: String
    var state: String
    var pincode: String
    var latitude: Double?
    var longitude: Double?
    
    var fullAddress: String {
        return "\(street), \(city), \(state) - \(pincode)"
    }
}

enum Amenity: String, CaseIterable, Codable {
    case wifi = "wifi"
    case ac = "ac"
    case parking = "parking"
    case laundry = "laundry"
    case meals = "meals"
    case gym = "gym"
    case security = "security"
    case powerBackup = "power_backup"
    case hotWater = "hot_water"
    case refrigerator = "refrigerator"
    case tv = "tv"
    case study = "study_room"
    
    var displayName: String {
        switch self {
        case .wifi:
            return "Wi-Fi"
        case .ac:
            return "Air Conditioning"
        case .parking:
            return "Parking"
        case .laundry:
            return "Laundry"
        case .meals:
            return "Meals"
        case .gym:
            return "Gym"
        case .security:
            return "24/7 Security"
        case .powerBackup:
            return "Power Backup"
        case .hotWater:
            return "Hot Water"
        case .refrigerator:
            return "Refrigerator"
        case .tv:
            return "TV"
        case .study:
            return "Study Room"
        }
    }
    
    var icon: String {
        switch self {
        case .wifi:
            return "wifi"
        case .ac:
            return "snowflake"
        case .parking:
            return "car"
        case .laundry:
            return "washer"
        case .meals:
            return "fork.knife"
        case .gym:
            return "dumbbell"
        case .security:
            return "shield"
        case .powerBackup:
            return "bolt"
        case .hotWater:
            return "drop.fill"
        case .refrigerator:
            return "refrigerator"
        case .tv:
            return "tv"
        case .study:
            return "book"
        }
    }
}

struct Booking: Codable, Identifiable {
    @DocumentID var id: String?
    var tenantId: String
    var listingId: String
    var ownerId: String
    var checkInDate: Date
    var checkOutDate: Date?
    var monthlyRent: Double
    var securityDeposit: Double
    var status: BookingStatus
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

enum BookingStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case confirmed = "confirmed"
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .confirmed:
            return "Confirmed"
        case .active:
            return "Active"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        }
    }
}

struct Review: Codable, Identifiable {
    @DocumentID var id: String?
    var tenantId: String
    var listingId: String
    var rating: Int
    var comment: String
    var createdAt: Date = Date()
}

struct Inquiry: Codable, Identifiable {
    @DocumentID var id: String?
    var tenantId: String
    var listingId: String
    var ownerId: String
    var message: String
    var isRead: Bool = false
    var response: String?
    var createdAt: Date = Date()
    var respondedAt: Date?
}
