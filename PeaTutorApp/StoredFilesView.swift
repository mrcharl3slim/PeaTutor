//
//  StoredFilesView.swift
//  PeaTutorApp
//
//  Created by Charles on 11/10/25.
//

import SwiftUI
import Amplify

// MARK: - Stored Files View
struct StoredFilesView: View {
    @StateObject private var aws = AWSService.shared
    @State private var worksheets: [StorageListResult.Item] = []
    @State private var solutions: [StorageListResult.Item] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showingError = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "cloud.fill")
                            .foregroundColor(.blue)
                        Text("Cloud Storage")
                            .font(.headline)
                    }
                    
                    Text("Files automatically backed up to AWS S3")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section("Worksheets") {
                if isLoading {
                    HStack {
                        ProgressView()
                        Text("Loading...")
                            .foregroundColor(.secondary)
                    }
                } else if worksheets.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.badge.clock")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No worksheets uploaded yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Upload a worksheet to see it here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(worksheets, id: \.key) { item in
                        FileRowView(item: item)
                    }
                }
            }
            
            Section("Solution Images") {
                if isLoading {
                    HStack {
                        ProgressView()
                        Text("Loading...")
                            .foregroundColor(.secondary)
                    }
                } else if solutions.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.clock")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No solutions uploaded yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Capture a solution to see it here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(solutions, id: \.key) { item in
                        FileRowView(item: item)
                    }
                }
            }
            
            if !isLoading && !worksheets.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Files: \(worksheets.count + solutions.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        let totalSize = (worksheets + solutions).compactMap { $0.size }.reduce(0, +)
                        Text("Total Size: \(ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Cloud Storage")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task {
                        await loadFiles()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .refreshable {
            await loadFiles()
        }
        .task {
            await loadFiles()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadFiles() async {
        isLoading = true
        errorMessage = ""
        
        do {
            print("📂 Loading files from S3...")
            worksheets = try await aws.listWorksheets()
            solutions = try await aws.listSolutions()
            print("✅ Loaded \(worksheets.count) worksheets and \(solutions.count) solutions")
        } catch {
            print("❌ Error loading files: \(error)")
            errorMessage = "Failed to load files: \(error.localizedDescription)"
            showingError = true
        }
        
        isLoading = false
    }
}

// MARK: - File Row View
struct FileRowView: View {
    let item: StorageListResult.Item
    
    var body: some View {
        HStack(spacing: 12) {
            // File icon
            Image(systemName: fileIcon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 40)
            
            // File info
            VStack(alignment: .leading, spacing: 4) {
                Text(fileName)
                    .font(.subheadline)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    if let size = item.size {
                        Label(
                            ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file),
                            systemImage: "doc"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    if let lastModified = item.lastModified {
                        Label(
                            lastModified.formatted(date: .abbreviated, time: .shortened),
                            systemImage: "clock"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var fileName: String {
        // Extract filename from key (remove path)
        let components = item.key.split(separator: "/")
        return String(components.last ?? "Unknown file")
    }
    
    private var fileIcon: String {
        let key = item.key.lowercased()
        if key.hasSuffix(".pdf") {
            return "doc.richtext.fill"
        } else if key.hasSuffix(".jpg") || key.hasSuffix(".jpeg") || key.hasSuffix(".png") {
            return "photo.fill"
        } else if key.hasSuffix(".docx") {
            return "doc.text.fill"
        } else {
            return "doc.fill"
        }
    }
    
    private var iconColor: Color {
        let key = item.key.lowercased()
        if key.hasSuffix(".pdf") {
            return .red
        } else if key.hasSuffix(".jpg") || key.hasSuffix(".jpeg") || key.hasSuffix(".png") {
            return .blue
        } else if key.hasSuffix(".docx") {
            return .blue
        } else {
            return .gray
        }
    }
}

// MARK: - Preview
struct StoredFilesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StoredFilesView()
        }
    }
}
