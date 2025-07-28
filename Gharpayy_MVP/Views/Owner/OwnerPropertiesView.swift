//
//  OwnerPropertiesView.swift
//  Gharpayy_MVP
//
//  Created by Aryan Sharma on 28/07/25.
//

import SwiftUI

struct OwnerPropertiesView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var firebaseService = FirebaseService()
    @State private var properties: [PGListing] = []
    @State private var isLoading = false
    @State private var showingAddProperty = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading properties...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if properties.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "building.2.crop.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Properties Listed")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Add your first PG property to start receiving bookings")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Add Property") {
                            showingAddProperty = true
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(properties) { property in
                                NavigationLink(destination: OwnerPropertyDetailView(property: property)) {
                                    OwnerPropertyCard(property: property)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("My Properties")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddProperty = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddProperty) {
                AddPropertyView()
                    .environmentObject(authService)
                    .onDisappear {
                        loadProperties()
                    }
            }
            .onAppear {
                loadProperties()
            }
        }
    }
    
    private func loadProperties() {
        guard let ownerId = authService.currentUser?.id else { return }
        
        isLoading = true
        Task {
            do {
                let ownerProperties = try await firebaseService.fetchOwnerListings(ownerId: ownerId)
                await MainActor.run {
                    self.properties = ownerProperties
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

struct OwnerPropertyCard: View {
    let property: PGListing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status and approval indicator
            HStack {
                Text(property.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(property.isApproved ? "Approved" : "Pending")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(property.isApproved ? Color.green : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    
                    if !property.isActive {
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
            
            // Location
            HStack {
                Image(systemName: "location")
                    .foregroundColor(.gray)
                    .font(.caption)
                Text(property.address.city)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Key metrics
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("₹\(Int(property.rent))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("per month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(property.availableRooms)/\(property.totalRooms)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(property.availableRooms > 0 ? .green : .red)
                    Text("available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if property.rating > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", property.rating))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        Text("(\(property.reviewCount))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Room type and amenities count
            HStack {
                Text(property.roomType.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
                
                Spacer()
                
                Text("\(property.amenities.count) amenities")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct AddPropertyView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var firebaseService = FirebaseService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var pincode = ""
    @State private var rent = ""
    @State private var securityDeposit = ""
    @State private var roomType: RoomType = .single
    @State private var totalRooms = ""
    @State private var selectedAmenities: Set<Amenity> = []
    @State private var rules: [String] = [""]
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Basic Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Basic Information")
                            .font(.headline)
                        
                        CustomTextField(title: "Property Title", text: $title, placeholder: "e.g., Cozy PG near IT Park")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextEditor(text: $description)
                                .frame(minHeight: 100)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                    }
                    
                    // Address
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Address")
                            .font(.headline)
                        
                        CustomTextField(title: "Street Address", text: $street, placeholder: "Enter street address")
                        CustomTextField(title: "City", text: $city, placeholder: "Enter city")
                        CustomTextField(title: "State", text: $state, placeholder: "Enter state")
                        CustomTextField(title: "Pincode", text: $pincode, placeholder: "Enter pincode", keyboardType: .numberPad)
                    }
                    
                    // Pricing
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pricing")
                            .font(.headline)
                        
                        CustomTextField(title: "Monthly Rent (₹)", text: $rent, placeholder: "e.g., 15000", keyboardType: .numberPad)
                        CustomTextField(title: "Security Deposit (₹)", text: $securityDeposit, placeholder: "e.g., 30000", keyboardType: .numberPad)
                    }
                    
                    // Room Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Room Details")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Room Type")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Picker("Room Type", selection: $roomType) {
                                ForEach(RoomType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        CustomTextField(title: "Total Rooms", text: $totalRooms, placeholder: "e.g., 20", keyboardType: .numberPad)
                    }
                    
                    // Amenities
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Amenities")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(Amenity.allCases, id: \.self) { amenity in
                                Button(action: {
                                    if selectedAmenities.contains(amenity) {
                                        selectedAmenities.remove(amenity)
                                    } else {
                                        selectedAmenities.insert(amenity)
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: amenity.icon)
                                            .font(.caption)
                                        Text(amenity.displayName)
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                    .foregroundColor(selectedAmenities.contains(amenity) ? .white : .blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(selectedAmenities.contains(amenity) ? Color.blue : Color.blue.opacity(0.1))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    // Rules
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rules & Regulations")
                            .font(.headline)
                        
                        ForEach(rules.indices, id: \.self) { index in
                            HStack {
                                TextField("Enter rule", text: $rules[index])
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                if rules.count > 1 {
                                    Button(action: {
                                        rules.remove(at: index)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        
                        Button("Add Rule") {
                            rules.append("")
                        }
                        .foregroundColor(.blue)
                    }
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Add Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addProperty()
                    }
                    .disabled(isLoading || !isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty &&
        !description.isEmpty &&
        !street.isEmpty &&
        !city.isEmpty &&
        !state.isEmpty &&
        !pincode.isEmpty &&
        !rent.isEmpty &&
        !securityDeposit.isEmpty &&
        !totalRooms.isEmpty
    }
    
    private func addProperty() {
        guard let ownerId = authService.currentUser?.id,
              let rentValue = Double(rent),
              let depositValue = Double(securityDeposit),
              let roomsValue = Int(totalRooms) else {
            errorMessage = "Please check all fields and try again"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let address = Address(
            street: street,
            city: city,
            state: state,
            pincode: pincode
        )
        
        let listing = PGListing(
            ownerId: ownerId,
            title: title,
            description: description,
            address: address,
            rent: rentValue,
            securityDeposit: depositValue,
            roomType: roomType,
            totalRooms: roomsValue,
            availableRooms: roomsValue,
            amenities: Array(selectedAmenities),
            rules: rules.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        )
        
        Task {
            do {
                _ = try await firebaseService.createListing(listing)
                
                await MainActor.run {
                    self.isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to add property. Please try again."
                }
            }
        }
    }
}

#Preview {
    OwnerPropertiesView()
        .environmentObject(AuthService())
}
