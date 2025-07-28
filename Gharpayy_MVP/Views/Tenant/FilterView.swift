//
//  FilterView.swift
//  Gharpayy_MVP
//
//  Created by Aryan Sharma on 28/07/25.
//

import SwiftUI

struct FilterView: View {
    @Binding var filters: ListingFilters
    @Environment(\.dismiss) private var dismiss
    let onApply: () -> Void
    
    @State private var tempFilters: ListingFilters
    
    init(filters: Binding<ListingFilters>, onApply: @escaping () -> Void) {
        self._filters = filters
        self.onApply = onApply
        self._tempFilters = State(initialValue: filters.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Price Range
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Maximum Rent")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("₹0")
                                Spacer()
                                Text("₹50,000")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            
                            Slider(
                                value: Binding(
                                    get: { tempFilters.maxRent ?? 50000 },
                                    set: { tempFilters.maxRent = $0 }
                                ),
                                in: 0...50000,
                                step: 1000
                            )
                            .accentColor(.blue)
                            
                            Text("₹\(Int(tempFilters.maxRent ?? 50000))/month")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Divider()
                    
                    // Room Type
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Room Type")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(RoomType.allCases, id: \.self) { roomType in
                                Button(action: {
                                    if tempFilters.roomType == roomType {
                                        tempFilters.roomType = nil
                                    } else {
                                        tempFilters.roomType = roomType
                                    }
                                }) {
                                    Text(roomType.displayName)
                                        .font(.subheadline)
                                        .foregroundColor(tempFilters.roomType == roomType ? .white : .blue)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(tempFilters.roomType == roomType ? Color.blue : Color.blue.opacity(0.1))
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    Divider()
                    
                    // City
                    VStack(alignment: .leading, spacing: 12) {
                        Text("City")
                            .font(.headline)
                        
                        TextField("Enter city name", text: Binding(
                            get: { tempFilters.city ?? "" },
                            set: { tempFilters.city = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    Divider()
                    
                    // Amenities
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Amenities")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(Amenity.allCases, id: \.self) { amenity in
                                Button(action: {
                                    if tempFilters.amenities.contains(amenity) {
                                        tempFilters.amenities.removeAll { $0 == amenity }
                                    } else {
                                        tempFilters.amenities.append(amenity)
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: amenity.icon)
                                            .font(.caption)
                                        Text(amenity.displayName)
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                    .foregroundColor(tempFilters.amenities.contains(amenity) ? .white : .blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(tempFilters.amenities.contains(amenity) ? Color.blue : Color.blue.opacity(0.1))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        tempFilters = ListingFilters()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        filters = tempFilters
                        onApply()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    FilterView(filters: .constant(ListingFilters())) {
        // Preview action
    }
}
