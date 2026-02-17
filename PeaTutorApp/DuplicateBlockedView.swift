//
//  DuplicateBlockedView.swift
//  PeaTutorApp
//
//  Sub-Sprint 3.3.1: Duplicate detection UI
//  UPDATED Sprint 5: Added callbacks for homework workflow
//  FIXED: Compatible with existing project structure
//

import SwiftUI

struct DuplicateBlockedView: View {
    let duplicateExtraction: ExtractionHistory
    let onUseExisting: () -> Void
    let onReExtract: () -> Void
    let onCancel: () -> Void
    
    @State private var showingHistory = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Warning icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            // Title
            Text("Duplicate Detected")
                .font(.title.bold())
            
            // Message
            VStack(spacing: 8) {
                Text("This worksheet was already extracted")
                    .font(.headline)
                
                Text("Original upload: \(duplicateExtraction.formattedDate)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            
            // Duplicate info card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(duplicateExtraction.sourceFilesSummary)
                            .font(.subheadline.bold())
                            .lineLimit(2)
                        Text("\(duplicateExtraction.questionCount) questions extracted")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            
            // Action buttons
            VStack(spacing: 12) {
                // Primary: Use existing
                Button {
                    onUseExisting()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Use Existing Worksheet")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // Secondary: View in history (navigate to HistoryView)
                Button {
                    showingHistory = true
                } label: {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("View in History")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                
                // Tertiary: Re-extract
                Button {
                    onReExtract()
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Extract Anyway (Uses API)")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(12)
                }
                
                // Cancel
                Button("Cancel", role: .cancel) {
                    onCancel()
                }
                .foregroundColor(.secondary)
            }
            
            // Info message
            Text("Using the existing worksheet saves API calls and time")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.3), radius: 20)
        .sheet(isPresented: $showingHistory) {
            // Use your existing HistoryView instead of creating a new one
            NavigationView {
                HistoryView()
                    .navigationTitle("History")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                showingHistory = false
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - Partial Duplicate Alert View (Keep existing for backwards compatibility)
struct PartialDuplicateBlockedView: View {
    let duplicates: [ExtractionHistory]
    let totalFiles: Int
    let onOpenHistory: () -> Void
    let onDismiss: () -> Void
    
    var duplicateCount: Int {
        duplicates.count
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            // Title
            VStack(spacing: 8) {
                Text("Some Files Already Extracted")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("\(duplicateCount) of \(totalFiles) files have been processed before")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Duplicate Files List
            VStack(alignment: .leading, spacing: 8) {
                ForEach(duplicates.prefix(3)) { extraction in
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(extraction.sourceFilesSummary)
                                .font(.subheadline)
                                .lineLimit(1)
                            Text(extraction.formattedDate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if duplicates.count > 3 {
                    Text("... and \(duplicates.count - 3) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 24)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.08))
            .cornerRadius(12)
            
            // Info message
            Text("Please check your history before uploading duplicate files.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Buttons
            VStack(spacing: 12) {
                Button(action: onOpenHistory) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("View History")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
                }
                
                Button(action: onDismiss) {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Preview (Fixed to match your ExtractionHistory initializer)
#Preview {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        
        DuplicateBlockedView(
            duplicateExtraction: ExtractionHistory(
                sourceFileNames: ["worksheet.pdf"],
                questionCount: 5,
                previewText: "Find the gradient of the line...",
                questionsData: Data(),
                userId: "test123",
                contentHash: "abc123",
                sourceFileHashes: ["hash1"]
            ),
            onUseExisting: {
                print("Use existing")
            },
            onReExtract: {
                print("Re-extract")
            },
            onCancel: {
                print("Cancel")
            }
        )
        .frame(maxWidth: 400)
        .padding()
    }
}
