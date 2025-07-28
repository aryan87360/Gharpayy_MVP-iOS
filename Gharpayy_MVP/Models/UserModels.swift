//
//  UserModels.swift
//  Gharpayy_MVP
//
//  Created by Aryan Sharma on 28/07/25.
//

import Foundation
import FirebaseFirestore

enum UserRole: String, CaseIterable, Codable {
    case tenant = "tenant"
    case owner = "owner"
    case admin = "admin"
    
    var displayName: String {
        switch self {
        case .tenant:
            return "Tenant"
        case .owner:
            return "PG Owner"
        case .admin:
            return "Admin"
        }
    }
}

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    var email: String
    var name: String
    var phoneNumber: String?
    var role: UserRole
    var profileImageURL: String?
    var isVerified: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

struct Tenant: Codable {
    var userId: String
    var preferences: TenantPreferences?
    var favoriteListings: [String] = []
    var bookingHistory: [String] = []
}

struct TenantPreferences: Codable {
    var maxRent: Double?
    var preferredLocations: [String] = []
    var requiredAmenities: [String] = []
    var roomType: RoomType?
}

struct Owner: Codable {
    var userId: String
    var businessName: String?
    var licenseNumber: String?
    var isLicenseVerified: Bool = false
    var properties: [String] = []
    var totalBookings: Int = 0
    var rating: Double = 0.0
}

enum RoomType: String, CaseIterable, Codable {
    case single = "single"
    case shared = "shared"
    case dormitory = "dormitory"
    
    var displayName: String {
        switch self {
        case .single:
            return "Single Room"
        case .shared:
            return "Shared Room"
        case .dormitory:
            return "Dormitory"
        }
    }
}
