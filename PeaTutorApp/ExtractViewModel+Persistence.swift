//
//  ExtractViewModel+Persistence.swift
//  PeaTutorApp
//
//  Sub-Sprint 3.3.2: Backend Sync - UI Helper Methods
//  Helper methods for UI to interact with saved worksheets
//

import Foundation
import Amplify

extension ExtractViewModel {
    
    // MARK: - Fetch Operations (for UI display)
    
    /// Fetch all saved worksheets to display in a list
    func fetchAllWorksheets() async throws -> [Worksheet] {
        let worksheets = try await DataStoreService.shared.fetchWorksheets()
        print("📥 ExtractVM: Fetched \(worksheets.count) worksheet(s) from DataStore")
        return worksheets
    }
    
    /// Fetch a specific worksheet by ID
    func fetchWorksheet(id: String) async throws -> Worksheet? {
        return try await DataStoreService.shared.fetchWorksheet(id: id)
    }
    
    /// Get the parsed questions from a saved worksheet
    /// Converts JSON string back to ExtractedWorksheet object
    func getQuestionsFromWorksheet(_ worksheet: Worksheet) throws -> ExtractedWorksheet? {
        guard let extractionResult = worksheet.extractionResult else {
            print("⚠️ No extraction result found in worksheet")
            return nil
        }
        return try DataStoreService.shared.parseExtractionResult(extractionResult)
    }
    
    /// Fetch all questions for a specific worksheet
    func fetchQuestions(worksheetId: String) async throws -> [Question] {
        return try await DataStoreService.shared.fetchQuestions(worksheetId: worksheetId)
    }
    
    // MARK: - Update Operations
    
    /// Update last accessed timestamp when user opens a worksheet
    func updateWorksheetAccess(worksheetId: String) async {
        do {
            try await DataStoreService.shared.updateLastAccessed(worksheetId: worksheetId)
            print("✅ ExtractVM: Updated last accessed for worksheet: \(worksheetId)")
        } catch {
            print("⚠️ ExtractVM: Failed to update last accessed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Delete Operations
    
    /// Delete a worksheet from DataStore (includes all related questions and feedback)
    func deleteWorksheet(id: String) async throws {
        try await DataStoreService.shared.deleteWorksheet(id: id)
        print("🗑️ ExtractVM: Deleted worksheet: \(id)")
    }
    
    // MARK: - Statistics
    
    /// Fetch user statistics for display in dashboard
    func fetchUserStats() async throws -> UserStats? {
        return try await DataStoreService.shared.fetchUserStats()
    }
    
    /// Manually refresh user statistics (called after major operations)
    func refreshUserStats() async {
        do {
            try await DataStoreService.shared.updateUserStats()
            print("✅ ExtractVM: User stats refreshed")
        } catch {
            print("⚠️ ExtractVM: Failed to refresh stats: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Sync Status
    
    /// Check if a worksheet has been synced to cloud
    /// (In a real implementation, you'd check DataStore sync status)
    func isWorksheetSynced(id: String) async -> Bool {
        do {
            let worksheet = try await fetchWorksheet(id: id)
            return worksheet != nil
        } catch {
            return false
        }
    }
}
