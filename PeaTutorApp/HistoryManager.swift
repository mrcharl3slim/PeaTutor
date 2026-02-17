//
//  HistoryManager.swift
//  PeaTutorApp
//
//  Created by Charles on Sprint 3.3
//

import Foundation
import SwiftData

@MainActor
class HistoryManager {
    static let shared = HistoryManager()
    
    private var modelContext: ModelContext?
    private var currentUserId: String?
    
    private init() {}
    
    // Set the model context (called from App or View)
    func configure(with context: ModelContext, userId: String) {
        self.modelContext = context
        self.currentUserId = userId
        print("✅ HistoryManager configured for user: \(userId)")
    }
    
    // ✅ NEW: Validate user context before operations
    private func validateUserContext() -> Bool {
        guard modelContext != nil, currentUserId != nil else {
            print("❌ HistoryManager: Not configured or no user logged in")
            return false
        }
        return true
    }

    // MARK: - Save Operations
    
    /// Save a new extraction to history
    func saveExtraction(
        _ result: ExtractedWorksheet,
        sourceFiles: [String],
        contentHash: String,
        sourceFileHashes: [String],
        datastoreWorksheetId: String? = nil)
    {
        guard validateUserContext() else {
            print("❌ User not validated")
            return
        }
        guard let context = modelContext, let userId = currentUserId else {
            print("❌ HistoryManager: ModelContext not configured")
            return
        }
        guard let history = ExtractionHistory.create(
            from: result,
            sourceFiles: sourceFiles,
            contentHash: contentHash,
            sourceFileHashes: sourceFileHashes,
            datastoreWorksheetId: datastoreWorksheetId,
            userId: userId
        ) else {
            print("❌ Failed to create ExtractionHistory")
            return
        }
        
        context.insert(history)
        
        do {
            try context.save()
            print("✅ Saved extraction to history for user \(userId): \(history.id)")
            print("📊 Questions: \(history.questionCount), Files: \(history.sourceFilesSummary)")
        } catch {
            print("❌ Failed to save extraction history: \(error)")
        }
    }
    
    // MARK: - Fetch Operations
    
    // ✅ UPDATED: Fetch only current user's extractions
    func fetchAllExtractions() -> [ExtractionHistory] {
        guard validateUserContext() else { return [] }
        guard let context = modelContext, let userId = currentUserId else {
            print("❌ HistoryManager: ModelContext not configured with current user")
            return []
        }
        
        let descriptor = FetchDescriptor<ExtractionHistory>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            let results = try context.fetch(descriptor)
            print("📚 Fetched \(results.count) extraction(s) for user: \(userId)")
            return results
        } catch {
            print("❌ Failed to fetch extraction history: \(error)")
            return []
        }
    }
    
    /// Fetch recent extractions (limit to n)
    func fetchRecentExtractions(limit: Int = 10) -> [ExtractionHistory] {
        let all = fetchAllExtractions()
        return Array(all.prefix(limit))
    }
    
    // MARK: - Delete Operations
    
    // ✅ UPDATED: Delete specific extraction (verify it belongs to current user)
    func deleteExtraction(_ history: ExtractionHistory) {
        guard validateUserContext() else { return }
        guard let context = modelContext, let userId = currentUserId else {
            print("❌ HistoryManager: ModelContext not configured")
            return
        }
        
        // ✅ Security check: Verify extraction belongs to current user
        guard history.userId == userId else {
            print("⚠️ Security: Attempted to delete extraction belonging to different user")
            return
        }
        
        context.delete(history)
        
        do {
            try context.save()
            print("🗑️ Deleted extraction: \(history.id)")
        } catch {
            print("❌ Failed to delete extraction: \(error)")
        }
    }
    
    // ✅ UPDATED: Delete all history for current user only
    func deleteAllHistory() {
        guard validateUserContext() else { return }
        guard let context = modelContext, let userId = currentUserId else {
            print("❌ HistoryManager: ModelContext not configured")
            return
        }
        
        let all = fetchAllExtractions()
        
        for history in all {
            context.delete(history)
        }
        
        do {
            try context.save()
            print("🗑️ Deleted all history for user \(userId) (\(all.count) items)")
        } catch {
            print("❌ Failed to delete all history: \(error)")
        }
    }

    // ✅ NEW: Reset internal state (but keep data in database)
    func resetForLogout() {
        print("🔄 HistoryManager: Resetting state for logout")
        // Just clear in-memory references, data stays in SwiftData
        modelContext = nil
        currentUserId = nil
    }
    
    // MARK: - Statistics
    
    /// Get total number of extractions
    func getTotalExtractionCount() -> Int {
        return fetchAllExtractions().count
    }
    
    /// Get total number of questions extracted across all history
    func getTotalQuestionCount() -> Int {
        return fetchAllExtractions().reduce(0) { $0 + $1.questionCount }
    }
    
    // MARK: - Duplicate Detection (Sub-Sprint 3.3.1)
        
    // ✅ UPDATED: Check duplicates only for current user
    func checkForDuplicate(contentHash: String) -> ExtractionHistory? {
        guard validateUserContext() else { return nil }
        guard let context = modelContext, let userId = currentUserId else {
            print("❌ HistoryManager: ModelContext not configured")
            return nil
        }
        
        guard !contentHash.isEmpty else {
            print("⚠️ HistoryManager: Empty hash provided")
            return nil
        }
        
        let descriptor = FetchDescriptor<ExtractionHistory>(
            predicate: #Predicate { $0.contentHash == contentHash && $0.userId == userId }
        )
        
        do {
            let results = try context.fetch(descriptor)
            if let duplicate = results.first {
                print("🔍 Found duplicate for user \(userId): \(duplicate.id)")
                print("📅 Original extracted on: \(duplicate.formattedDate)")
                print("📄 Files: \(duplicate.sourceFilesSummary)")
                return duplicate
            }
            return nil
        } catch {
            print("❌ Failed to check for duplicate: \(error)")
            return nil
        }
    }
    
    // ✅ UPDATED: Check partial duplicates for current user
    private func checkForPartialDuplicates(fileHashes: [String]) -> [ExtractionHistory] {
        guard validateUserContext() else { return [] }
        guard let context = modelContext, let userId = currentUserId else { return [] }
        
        var matches: [ExtractionHistory] = []
        
        let descriptor = FetchDescriptor<ExtractionHistory>(
            predicate: #Predicate { $0.userId == userId }  // ✅ Filter by userId
        )
        
        do {
            let allExtractions = try context.fetch(descriptor)
            
            for extraction in allExtractions {
                for fileHash in fileHashes {
                    if extraction.sourceFileHashes.contains(fileHash) {
                        matches.append(extraction)
                        break
                    }
                }
            }
        } catch {
            print("❌ Failed to check partial duplicates: \(error)")
        }
        
        return matches
    }
    
    // ✅ UPDATED: Perform duplicate check for current user
    func performDuplicateCheck(
        contentHash: String,
        fileHashes: [String]
    ) -> DuplicateCheckResult {
        guard validateUserContext() else {
            return .noDuplicate
        }
        
        // Check for exact duplicate (same combined hash)
        if let exactDuplicate = checkForDuplicate(contentHash: contentHash) {
            return .exactDuplicate(exactDuplicate)
        }
        
        // Check for partial duplicates (any file hash matches)
        let partialMatches = checkForPartialDuplicates(fileHashes: fileHashes)
        if !partialMatches.isEmpty {
            return .partialDuplicate(partialMatches)
        }
        
        return .noDuplicate
    }
}

// MARK: - Duplicate Check Result

enum DuplicateCheckResult {
    case noDuplicate
    case exactDuplicate(ExtractionHistory)
    case partialDuplicate([ExtractionHistory])
}
