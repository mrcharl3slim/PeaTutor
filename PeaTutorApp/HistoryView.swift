//
//  HistoryView.swift
//  PeaTutorApp
//
//  Created by Charles on Sprint 3.3
//

import SwiftUI
import SwiftData

// MARK: - History List View
struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var extractions: [ExtractionHistory] = []
    @State private var isLoading = true
    @State private var showingDeleteConfirmation = false
    @State private var extractionToDelete: ExtractionHistory?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading history...")
                    .onAppear {
                        loadHistory()
                    }
            } else if extractions.isEmpty {
                emptyStateView
            } else {
                historyListView
            }
        }
        .navigationTitle("Extraction History")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Clear All History", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Clear All History?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                deleteAllHistory()
            }
        } message: {
            Text("This will permanently delete all extraction history. This action cannot be undone.")
        }
        .refreshable {
            loadHistory()
        }
    }

    // MARK: - Stat Card
    struct StatCard: View {
        let icon: String
        let label: String
        let value: String
        let color: Color
        
        var body: some View {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 50, height: 50)
                    .background(color.opacity(0.1))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - History List
    private var historyListView: some View {
        List {
            // Summary Section
            Section {
                VStack(spacing: 12) {
                    StatCard(
                        icon: "doc.text.fill",
                        label: "Total Extractions",
                        value: "\(extractions.count)",
                        color: .blue
                    )
                    
                    StatCard(
                        icon: "questionmark.circle.fill",
                        label: "Questions Extracted",
                        value: "\(totalQuestions)",
                        color: .green
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            
            // History Items
            Section {
                ForEach(extractions) { extraction in
                    NavigationLink {
                        HistoryDetailView(extraction: extraction)
                    } label: {
                        HistoryRowView(extraction: extraction)
                    }
                }
                .onDelete(perform: deleteExtractions)
            } header: {
                Text("Recent Extractions")
            } footer: {
                Text("Swipe left to delete individual items")
                    .font(.caption)
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("No Extraction History")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your extracted worksheets will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {}) {
                Label("Extract Your First Worksheet", systemImage: "sparkles")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding()
    }
    
    // MARK: - Helper Computed Properties
    private var totalQuestions: Int {
        extractions.reduce(0) { $0 + $1.questionCount }
    }
    
    // MARK: - Data Operations

    private func loadHistory() {
        isLoading = true
        
        // Get current user
        let currentUser = AWSService.shared.currentUser
        print("📚 Loading history for user: \(currentUser?.username ?? "unknown")")
        
        // Configure HistoryManager with modelContext
        // Note: It's already configured in PeaTutorApp, but safe to call again
        if let userId = currentUser?.userId {
            HistoryManager.shared.configure(with: modelContext, userId: userId)
        }
        
        // Small delay to show loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            extractions = HistoryManager.shared.fetchAllExtractions()
            isLoading = false
            print("✅ Loaded \(extractions.count) extractions")
        }
    }
    
    private func deleteExtractions(at offsets: IndexSet) {
        for index in offsets {
            let extraction = extractions[index]
            HistoryManager.shared.deleteExtraction(extraction)
        }
        loadHistory() // Refresh list
    }
    
    private func deleteAllHistory() {
        HistoryManager.shared.deleteAllHistory()
        loadHistory() // Refresh list
    }
}

// MARK: - History Row View
struct HistoryRowView: View {
    let extraction: ExtractionHistory
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: "doc.text.fill")
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(extraction.sourceFilesSummary)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Label("\(extraction.questionCount)", systemImage: "number")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label(extraction.formattedDate, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - History Detail View
struct HistoryDetailView: View {
    let extraction: ExtractionHistory
    @Environment(\.dismiss) var dismiss
    @State private var datastoreWorksheetId: String?
    
    var body: some View {
        Group {
            if let worksheetRoot = extraction.getWorksheetRoot() {
                JSONPreviewView(result: worksheetRoot,savedWorksheetId: extraction.datastoreWorksheetId)
                .task {
                    // Try to find if this extraction exists in DataStore
                    await checkDataStore(worksheetRoot: worksheetRoot)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Unable to Load Extraction")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("This extraction data may be corrupted")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Go Back") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
        .navigationTitle("Extraction Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    private func checkDataStore(worksheetRoot: ExtractedWorksheet) async {
            do {
                // Try to find worksheet by the in-memory UUID
                if let worksheet = try await ExtractViewModel().fetchWorksheet(
                    id: worksheetRoot.id.uuidString
                ) {
                    datastoreWorksheetId = worksheet.id
                    print("✅ Found worksheet in DataStore: \(worksheet.id)")
                }
            } catch {
                print("⚠️ Worksheet not in DataStore (this is normal for old history)")
            }
        }
}

// MARK: - Preview
struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HistoryView()
                .modelContainer(for: ExtractionHistory.self, inMemory: true)
        }
    }
}
