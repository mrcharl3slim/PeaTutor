//
//  SyncStatusView.swift
//  PeaTutorApp
//
//  Sub-Sprint 3.4: Comprehensive sync monitoring
//

import SwiftUI
import Amplify

// MARK: - Sync Status View Model
@MainActor
class SyncStatusViewModel: ObservableObject {
    @Published var worksheetCount = 0
    @Published var feedbackCount = 0
    @Published var fullWorksheetCount = 0
    @Published var isRefreshing = false
    @Published var lastSyncTime: Date?
    @Published var syncErrors: [String] = []
    
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        do {
            // Count worksheets
            let worksheets = try await DataStoreService.shared.fetchWorksheets()
            worksheetCount = worksheets.count
            
            // Count all feedback across all worksheets
            var totalFeedback = 0
            var totalFullWorksheet = 0
            
            for worksheet in worksheets {
                let feedback = try await DataStoreService.shared.fetchAllFeedbackForWorksheet(
                    worksheetId: worksheet.id
                )
                totalFeedback += feedback.count
                
                let fullWorksheetSolutions = try await DataStoreService.shared.fetchFullWorksheetSolutions(
                    for: worksheet
                )
                totalFullWorksheet += fullWorksheetSolutions.count
            }
            
            feedbackCount = totalFeedback
            fullWorksheetCount = totalFullWorksheet
            lastSyncTime = Date()
            syncErrors = []
            
            print("✅ Sync status refreshed")
            print("📊 Worksheets: \(worksheetCount)")
            print("💬 Feedback: \(feedbackCount)")
            print("📄 Full worksheet solutions: \(fullWorksheetCount)")
            
        } catch {
            print("❌ Failed to refresh sync status: \(error)")
            syncErrors.append(error.localizedDescription)
        }
    }
}

// MARK: - Sync Status View
struct SyncStatusView: View {
    @StateObject private var viewModel = SyncStatusViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Sync overview section
                Section {
                    syncOverviewCard
                }
                
                // Synced content sections
                Section("Synced Content") {
                    syncStatRow(
                        icon: "doc.fill",
                        title: "Worksheets",
                        count: viewModel.worksheetCount,
                        color: .blue
                    )
                    
                    syncStatRow(
                        icon: "message.fill",
                        title: "Question Feedback",
                        count: viewModel.feedbackCount,
                        color: .purple
                    )
                    
                    syncStatRow(
                        icon: "doc.text.fill",
                        title: "Full Worksheet Solutions",
                        count: viewModel.fullWorksheetCount,
                        color: .green
                    )
                }
                
                // Last sync section
                if let lastSync = viewModel.lastSyncTime {
                    Section("Sync Information") {
                        HStack {
                            Text("Last Updated")
                            Spacer()
                            Text(timeAgo(from: lastSync))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Status")
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("Active")
                                    .foregroundColor(.green)
                            }
                            .font(.subheadline)
                        }
                    }
                }
                
                // Errors section
                if !viewModel.syncErrors.isEmpty {
                    Section("Sync Issues") {
                        ForEach(viewModel.syncErrors, id: \.self) { error in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(error)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // Help section
                Section("About Sync") {
                    VStack(alignment: .leading, spacing: 12) {
                        helpRow(
                            icon: "icloud.fill",
                            title: "Automatic Backup",
                            description: "All worksheets and feedback are automatically backed up to the cloud"
                        )
                        
                        Divider()
                        
                        helpRow(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Cross-Device Sync",
                            description: "Access your work from any device signed in to your account"
                        )
                        
                        Divider()
                        
                        helpRow(
                            icon: "lock.fill",
                            title: "Secure Storage",
                            description: "Your data is encrypted and stored securely on AWS"
                        )
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Sync Status")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.refresh()
            }
        }
    }
    
    // MARK: - Sync Overview Card
    
    private var syncOverviewCard: some View {
        VStack(spacing: 16) {
            // Icon and status
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "checkmark.icloud.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.green)
                }
                
                Text("All Synced")
                    .font(.headline)
                    .foregroundColor(.green)
            }
            
            // Stats grid
            HStack(spacing: 20) {
                statBox(
                    value: "\(viewModel.worksheetCount)",
                    label: "Worksheets",
                    color: .blue
                )
                
                statBox(
                    value: "\(viewModel.feedbackCount)",
                    label: "Feedback",
                    color: .purple
                )
                
                statBox(
                    value: "\(viewModel.fullWorksheetCount)",
                    label: "Reviews",
                    color: .green
                )
            }
            
            // Refresh button
            if viewModel.isRefreshing {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Button(action: { Task { await viewModel.refresh() } }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    private func statBox(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Sync Stat Row
    
    private func syncStatRow(icon: String, title: String, count: Int, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
            
            Spacer()
            
            HStack(spacing: 6) {
                Text("\(count)")
                    .font(.headline)
                    .foregroundColor(color)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
    
    // MARK: - Help Row
    
    private func helpRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helper
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Sync Status Button (for ContentView)
struct SyncStatusButton: View {
    @State private var showingSyncStatus = false
    
    var body: some View {
        Button(action: { showingSyncStatus = true }) {
            HStack(spacing: 6) {
                Image(systemName: "icloud.fill")
                    .font(.subheadline)
                Text("Sync")
                    .font(.subheadline)
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .sheet(isPresented: $showingSyncStatus) {
            SyncStatusView()
        }
    }
}

// MARK: - Preview
struct SyncStatusView_Previews: PreviewProvider {
    static var previews: some View {
        SyncStatusView()
    }
}
