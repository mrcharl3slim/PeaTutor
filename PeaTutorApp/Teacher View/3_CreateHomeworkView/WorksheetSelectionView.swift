//
//  WorksheetSelectionView.swift
//  PeaTutorApp
//
//  Sprint 5 Phase 1: Browse and select existing worksheets for homework
//

import SwiftUI
import Amplify

struct WorksheetSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var awsService = AWSService.shared
    
    let onWorksheetSelected: (Worksheet) -> Void
    
    @State private var worksheets: [Worksheet] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .recentFirst
    
    enum SortOrder: String, CaseIterable {
        case recentFirst = "Recent First"
        case oldestFirst = "Oldest First"
        case mostQuestions = "Most Questions"
        case alphabetical = "A-Z"
    }
    
    var filteredWorksheets: [Worksheet] {
        let filtered = worksheets.filter { worksheet in
            searchText.isEmpty || worksheet.title.localizedCaseInsensitiveContains(searchText)
        }
        
        return sortWorksheets(filtered, by: sortOrder)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView("Loading worksheets...")
                } else if worksheets.isEmpty {
                    emptyStateView
                } else {
                    worksheetListView
                }
            }
            .navigationTitle("Select Worksheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search worksheets")
            .task {
                await loadWorksheets()
            }
        }
    }
    
    // MARK: - Worksheet List View
    
    private var worksheetListView: some View {
        VStack(spacing: 0) {
            // Sort picker
            Picker("Sort", selection: $sortOrder) {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Text(order.rawValue).tag(order)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Worksheet list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredWorksheets, id: \.id) { worksheet in
                        WorksheetSelectionCard(worksheet: worksheet) {
                            onWorksheetSelected(worksheet)
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            
            // Results count
            if !searchText.isEmpty {
                Text("\(filteredWorksheets.count) result(s)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Worksheets Yet")
                .font(.title2.bold())
            
            Text("Upload a worksheet first to assign it as homework")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                dismiss()
            } label: {
                Text("Upload Worksheet")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Load Worksheets
    
    private func loadWorksheets() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let userId = awsService.currentUserId else {
            print("❌ No current user")
            return
        }
        
        do {
            let fetchedWorksheets = try await Amplify.DataStore.query(
                Worksheet.self,
                where: Worksheet.keys.userId == userId
            )
            
            await MainActor.run {
                worksheets = fetchedWorksheets
                print("✅ Loaded \(worksheets.count) worksheets")
            }
        } catch {
            print("❌ Failed to load worksheets: \(error)")
        }
    }
    
    // MARK: - Sort Worksheets
    
    private func sortWorksheets(_ worksheets: [Worksheet], by order: SortOrder) -> [Worksheet] {
        switch order {
        case .recentFirst:
            return worksheets.sorted { $0.uploadedAt.foundationDate > $1.uploadedAt.foundationDate }
        case .oldestFirst:
            return worksheets.sorted { $0.uploadedAt.foundationDate < $1.uploadedAt.foundationDate }
        case .mostQuestions:
            return worksheets.sorted { ($0.questionCount ?? 0) > ($1.questionCount ?? 0) }
        case .alphabetical:
            return worksheets.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }
}

// MARK: - Worksheet Selection Card

struct WorksheetSelectionCard: View {
    let worksheet: Worksheet
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "doc.text.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(worksheet.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        Label("\(worksheet.questionCount ?? 0) questions", 
                              systemImage: "list.number")
                        
                        if let marks = worksheet.totalMarks {
                            Label("\(marks) marks", 
                                  systemImage: "star.fill")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Text(formatDate(worksheet.uploadedAt.foundationDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    WorksheetSelectionView { worksheet in
        print("Selected: \(worksheet.title)")
    }
}
