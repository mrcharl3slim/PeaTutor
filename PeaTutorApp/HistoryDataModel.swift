//
//  HistoryDataModel.swift
//  PeaTutorApp
//
//  Created by Charles on Sprint 3.3
//

import Foundation
import SwiftData

// MARK: - Extraction History Model
@Model
final class ExtractionHistory {
    var id: UUID
    var timestamp: Date
    var sourceFileNames: [String]
    var questionCount: Int
    var previewText: String
    var questionsData: Data // Encoded WorksheetRoot
    // ✅ NEW: User isolation field
    var userId: String
    // Hash fields for duplicate detection
    var contentHash: String
    var sourceFileHashes: [String]
    var datastoreWorksheetId: String?
    // Computed properties for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    var sourceFilesSummary: String {
        if sourceFileNames.isEmpty {
            return "No files"
        } else if sourceFileNames.count == 1 {
            return sourceFileNames[0]
        } else {
            return "\(sourceFileNames[0]) +\(sourceFileNames.count - 1) more"
        }
    }
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        sourceFileNames: [String],
        questionCount: Int,
        previewText: String,
        questionsData: Data,
        userId: String,
        contentHash: String = "",
        sourceFileHashes: [String] = [],
        datastoreWorksheetId: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.sourceFileNames = sourceFileNames
        self.questionCount = questionCount
        self.previewText = previewText
        self.questionsData = questionsData
        self.userId = userId
        self.contentHash = contentHash
        self.sourceFileHashes = sourceFileHashes
        self.datastoreWorksheetId = datastoreWorksheetId
    }
    
    // Helper to decode WorksheetRoot
    func getWorksheetRoot() -> ExtractedWorksheet? {
        try? JSONDecoder().decode(ExtractedWorksheet.self, from: questionsData)
    }
    
    // Helper to create from WorksheetRoot
    static func create(
        from result: ExtractedWorksheet,
        sourceFiles: [String],
        contentHash: String,
        sourceFileHashes: [String],
        datastoreWorksheetId: String? = nil,
        userId: String
        ) -> ExtractionHistory? {
        guard let data = try? JSONEncoder().encode(result) else {
            return nil
        }
        
            let previewText = result.questions.first?.questionText.prefix(100).description ?? "No preview available"
        
        return ExtractionHistory(
            sourceFileNames: sourceFiles,
            questionCount: result.questions.count,
            previewText: previewText,
            questionsData: data,
            userId: userId,
            contentHash: contentHash,
            sourceFileHashes: sourceFileHashes,
            datastoreWorksheetId: datastoreWorksheetId
        )
    }
}
