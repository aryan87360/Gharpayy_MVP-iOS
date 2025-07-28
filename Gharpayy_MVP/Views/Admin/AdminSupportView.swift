//
//  AdminSupportView.swift
//  Gharpayy_MVP
//
//  Created by Aryan Sharma on 28/07/25.
//

import SwiftUI

struct AdminSupportView: View {
    @StateObject private var firebaseService = FirebaseService()
    @State private var supportTickets: [SupportTicket] = []
    @State private var isLoading = false
    @State private var selectedFilter = SupportFilter.all
    @State private var showingNewTicket = false
    
    enum SupportFilter: String, CaseIterable {
        case all = "All"
        case open = "Open"
        case inProgress = "In Progress"
        case resolved = "Resolved"
    }
    
    var filteredTickets: [SupportTicket] {
        switch selectedFilter {
        case .all:
            return supportTickets
        case .open:
            return supportTickets.filter { $0.status == .open }
        case .inProgress:
            return supportTickets.filter { $0.status == .inProgress }
        case .resolved:
            return supportTickets.filter { $0.status == .resolved }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(SupportFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                if isLoading {
                    Spacer()
                    ProgressView("Loading support tickets...")
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if filteredTickets.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "questionmark.circle")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    
                                    Text("No Support Tickets")
                                        .font(.title2)
                                        .fontWeight(.medium)
                                    
                                    Text("Support tickets will appear here")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.top, 60)
                            } else {
                                ForEach(filteredTickets) { ticket in
                                    SupportTicketCard(ticket: ticket, firebaseService: firebaseService) {
                                        await loadSupportTickets()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Support & Moderation")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Ticket") {
                        showingNewTicket = true
                    }
                }
            }
            .sheet(isPresented: $showingNewTicket) {
                NewSupportTicketView()
            }
            .task {
                await loadSupportTickets()
            }
            .refreshable {
                await loadSupportTickets()
            }
        }
    }
    
    private func loadSupportTickets() async {
        isLoading = true
        do {
            supportTickets = try await firebaseService.fetchSupportTickets()
        } catch {
            print("Error loading support tickets: \(error)")
        }
        isLoading = false
    }
}

struct SupportTicketCard: View {
    let ticket: SupportTicket
    let firebaseService: FirebaseService
    let onUpdate: () async -> Void
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ticket.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("Ticket #\(ticket.id.prefix(8))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(ticket.status.rawValue.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor(ticket.status))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    
                    Text(ticket.priority.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(priorityColor(ticket.priority))
                }
            }
            
            Text(ticket.description)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundColor(.primary)
            
            HStack {
                Label(ticket.category.rawValue, systemImage: categoryIcon(ticket.category))
                
                Spacer()
                
                Text(ticket.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            SupportTicketDetailView(ticket: ticket, firebaseService: firebaseService, onUpdate: onUpdate)
        }
    }
    
    private func statusColor(_ status: SupportTicketStatus) -> Color {
        switch status {
        case .open:
            return .orange
        case .inProgress:
            return .blue
        case .resolved:
            return .green
        }
    }
    
    private func priorityColor(_ priority: SupportPriority) -> Color {
        switch priority {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
    
    private func categoryIcon(_ category: SupportCategory) -> String {
        switch category {
        case .technical:
            return "gear"
        case .billing:
            return "creditcard"
        case .general:
            return "questionmark.circle"
        case .abuse:
            return "exclamationmark.triangle"
        }
    }
}

struct SupportTicketDetailView: View {
    let ticket: SupportTicket
    let firebaseService: FirebaseService
    let onUpdate: () async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var newResponse = ""
    @State private var isUpdating = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Ticket Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(ticket.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack {
                            Text("Ticket #\(ticket.id.prefix(8))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(ticket.status.rawValue.capitalized)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusColor(ticket.status))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        
                        HStack {
                            Label(ticket.category.rawValue, systemImage: categoryIcon(ticket.category))
                            
                            Spacer()
                            
                            Label(ticket.priority.rawValue.capitalized, systemImage: "flag")
                                .foregroundColor(priorityColor(ticket.priority))
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(ticket.description)
                            .font(.body)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Status Actions
                    if ticket.status != .resolved {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Actions")
                                .font(.headline)
                            
                            HStack(spacing: 12) {
                                if ticket.status == .open {
                                    Button("Start Progress") {
                                        updateTicketStatus(.inProgress)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                
                                Button("Mark Resolved") {
                                    updateTicketStatus(.resolved)
                                }
                                .buttonStyle(.bordered)
                                .tint(.green)
                            }
                        }
                    }
                    
                    // Response Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add Response")
                            .font(.headline)
                        
                        TextField("Enter your response...", text: $newResponse, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                        
                        Button("Send Response") {
                            sendResponse()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newResponse.isEmpty || isUpdating)
                    }
                }
                .padding()
            }
            .navigationTitle("Support Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func updateTicketStatus(_ status: SupportTicketStatus) {
        Task {
            isUpdating = true
            do {
                var updatedTicket = ticket
                updatedTicket.status = status
                updatedTicket.updatedAt = Date()
                
                try await firebaseService.updateSupportTicket(updatedTicket)
                await onUpdate()
                dismiss()
            } catch {
                print("Error updating ticket: \(error)")
            }
            isUpdating = false
        }
    }
    
    private func sendResponse() {
        Task {
            isUpdating = true
            do {
                // Here you would typically add the response to a responses collection
                // For now, we'll just update the ticket's updated date
                var updatedTicket = ticket
                updatedTicket.updatedAt = Date()
                
                try await firebaseService.updateSupportTicket(updatedTicket)
                newResponse = ""
                await onUpdate()
            } catch {
                print("Error sending response: \(error)")
            }
            isUpdating = false
        }
    }
    
    private func statusColor(_ status: SupportTicketStatus) -> Color {
        switch status {
        case .open:
            return .orange
        case .inProgress:
            return .blue
        case .resolved:
            return .green
        }
    }
    
    private func priorityColor(_ priority: SupportPriority) -> Color {
        switch priority {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
    
    private func categoryIcon(_ category: SupportCategory) -> String {
        switch category {
        case .technical:
            return "gear"
        case .billing:
            return "creditcard"
        case .general:
            return "questionmark.circle"
        case .abuse:
            return "exclamationmark.triangle"
        }
    }
}

struct NewSupportTicketView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firebaseService = FirebaseService()
    
    @State private var title = ""
    @State private var description = ""
    @State private var category = SupportCategory.general
    @State private var priority = SupportPriority.medium
    @State private var isCreating = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Ticket Information") {
                    TextField("Title", text: $title)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(SupportCategory.allCases, id: \.self) { category in
                            Text(category.rawValue.capitalized).tag(category)
                        }
                    }
                }
                
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(SupportPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue.capitalized).tag(priority)
                        }
                    }
                }
            }
            .navigationTitle("New Support Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createTicket()
                    }
                    .disabled(!isFormValid || isCreating)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !description.isEmpty
    }
    
    private func createTicket() {
        Task {
            isCreating = true
            do {
                let ticket = SupportTicket(
                    id: UUID().uuidString,
                    title: title,
                    description: description,
                    category: category,
                    priority: priority,
                    status: .open,
                    userId: "admin", // In a real app, this would be the current user ID
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                try await firebaseService.createSupportTicket(ticket)
                dismiss()
            } catch {
                print("Error creating ticket: \(error)")
            }
            isCreating = false
        }
    }
}

// MARK: - Support Models

struct SupportTicket: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var category: SupportCategory
    var priority: SupportPriority
    var status: SupportTicketStatus
    let userId: String
    let createdAt: Date
    var updatedAt: Date
}

enum SupportCategory: String, CaseIterable, Codable {
    case technical = "technical"
    case billing = "billing"
    case general = "general"
    case abuse = "abuse"
}

enum SupportPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

enum SupportTicketStatus: String, CaseIterable, Codable {
    case open = "open"
    case inProgress = "in_progress"
    case resolved = "resolved"
}

#Preview {
    AdminSupportView()
}
