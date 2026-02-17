//
//  SavedWorksheetsView.swift
//  PeaTutorApp
//
//  Display all worksheets saved to DataStore
//

import SwiftUI
import Amplify

struct SavedWorksheetsView: View {
    @StateObject private var vm = ExtractViewModel()
    @State private var worksheets: [Worksheet] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedWorksheet: Worksheet?
    @State private var showingWorksheet = false
    @State private var showingUpload = false
    
    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading worksheets...")
                        .foregroundColor(.secondary)
                }
            } else if worksheets.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("No Saved Worksheets")
                        .font(.headline)
                    
                    Text("Worksheets you extract will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                List {
                    ForEach(worksheets, id: \.id) { worksheet in
                        WorksheetRow(
                            worksheet: worksheet,
                            onDelete: {
                                deleteWorksheet(worksheet)
                            },
                            onOpen: {
                                openWorksheet(worksheet)
                            }
                        )
                    }
                }
                .refreshable {
                    await loadWorksheets()
                }
            }
        }
        .navigationTitle("Saved Worksheets")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingUpload = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await loadWorksheets()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .task {
            await loadWorksheets()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .sheet(isPresented: $showingWorksheet) {
            if let worksheet = selectedWorksheet,
               let extracted = try? vm.getQuestionsFromWorksheet(worksheet) {
                NavigationStack {
                    JSONPreviewView(result: extracted,savedWorksheetId: worksheet.id)
                        .navigationTitle(worksheet.title)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingWorksheet = false
                                }
                            }
                        }
                }
            }
        }
        // ✅ NEW: Sheet for uploading worksheet
        .sheet(isPresented: $showingUpload) {
                    NewWorksheetUploadView(
                        onWorksheetUploaded: { worksheet in
                            showingUpload = false
                            Task {
                                await loadWorksheets()
                            }
                        },
                        onCancel: {
                            showingUpload = false
                        }
                    )
                }
    }
    
    private func loadWorksheets() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            worksheets = try await vm.fetchAllWorksheets()
            print("✅ Loaded \(worksheets.count) worksheet(s)")
        } catch {
            errorMessage = "Failed to load worksheets: \(error.localizedDescription)"
            print("❌ Load error: \(error)")
        }
    }
    
    private func openWorksheet(_ worksheet: Worksheet) {
        selectedWorksheet = worksheet
        showingWorksheet = true
        
        // Mark as accessed
        Task {
            await vm.updateWorksheetAccess(worksheetId: worksheet.id)
        }
    }
    
    private func deleteWorksheet(_ worksheet: Worksheet) {
        Task {
            do {
                try await vm.deleteWorksheet(id: worksheet.id)
                await loadWorksheets() // Refresh list
                print("✅ Deleted worksheet: \(worksheet.title)")
            } catch {
                errorMessage = "Failed to delete: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Worksheet Row Component

struct WorksheetRow: View {
    let worksheet: Worksheet
    let onDelete: () -> Void
    let onOpen: () -> Void
    
    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40)
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(worksheet.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        Label("\(worksheet.questionCount ?? 0)", systemImage: "number")
                        Label("\(worksheet.totalMarks ?? 0)", systemImage: "star")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    // ✅ FIXED: uploadedAt is NOT optional
                    Text(worksheet.uploadedAt.foundationDate, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
    
    private var iconName: String {
        switch worksheet.fileType?.lowercased() {
        case "pdf": return "doc.richtext"
        case "docx": return "doc.text"
        case "jpg", "jpeg", "png": return "photo"
        default: return "doc"
        }
    }
}
