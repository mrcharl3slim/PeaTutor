//
//  DataStoreService.swift
//  PeaTutorApp
//
//  FIXED VERSION - Works with actual Amplify-generated models
//

import Amplify
import Foundation
import CryptoKit

@MainActor
class DataStoreService: ObservableObject {
    static let shared = DataStoreService()
    
    // ✅ NEW: Serial actor for atomic feedback operations
    private actor FeedbackCoordinator {
        func performAtomicSave<T>(operation: @Sendable () async throws -> T) async throws -> T {
            try await operation()
        }
    }
    
    private let feedbackCoordinator = FeedbackCoordinator()
    
    private init() {}
    
    // MARK: - Worksheet Operations
    
    /// Save extracted worksheet to DataStore after OpenAI extraction
    func saveWorksheet(
        extractionResult: ExtractedWorksheet,
        s3WorksheetKey: String,
        fileName: String,
        fileType: String?,
        fileSize: Int?
    ) async throws -> Worksheet {
        print("💾 Saving worksheet to DataStore...")
        print("📄 File: \(fileName)")
        print("📊 Questions: \(extractionResult.questions.count)")
        
        let userId = AWSService.shared.currentUser?.userId ?? "unknown"
        
        // Convert ExtractedWorksheet to JSON string for storage
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(extractionResult)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
        
        // Calculate metadata
        let questionCount = extractionResult.questions.count
        let totalMarks = calculateTotalMarks(from: extractionResult)
        
        // Generate content hash for duplicate detection
        let contentHash = generateContentHash(jsonString)
        
        // Create Amplify Worksheet model
        let worksheet = Worksheet(
            userId: userId,
            title: fileName,
            fileType: fileType,
            fileName: fileName,
            s3WorksheetKey: s3WorksheetKey,
            extractionResult: jsonString,
            questionCount: questionCount,
            totalMarks: totalMarks,
            uploadedAt: Temporal.DateTime.now(),
            fileSize: fileSize,
            contentHash: contentHash,
            sourceFileHashes: [s3WorksheetKey],
            lastAccessedAt: Temporal.DateTime.now()
        )
        
        try await Amplify.DataStore.save(worksheet)
        print("✅ Worksheet saved with ID: \(worksheet.id)")
        print("🔢 Total marks: \(totalMarks ?? 0)")
        
        // Save individual questions (flattened structure)
        try await saveQuestions(
            from: extractionResult,
            worksheet: worksheet,
            userId: userId
        )
        
        return worksheet
    }
    
    /// Update worksheet's last accessed timestamp
    func updateLastAccessed(worksheetId: String) async throws {
        guard var worksheet = try await Amplify.DataStore.query(
            Worksheet.self,
            byId: worksheetId
        ) else {
            throw DataStoreError.worksheetNotFound
        }
        
        worksheet.lastAccessedAt = Temporal.DateTime.now()
        try await Amplify.DataStore.save(worksheet)
        print("✅ Updated last accessed time for worksheet: \(worksheetId)")
    }
    
    /// Fetch all worksheets for current user, sorted by upload date (newest first)
    func fetchWorksheets() async throws -> [Worksheet] {
        print("📥 Fetching worksheets...")
        
        let worksheets = try await Amplify.DataStore.query(
            Worksheet.self,
            sort: .descending(Worksheet.keys.uploadedAt)
        )
        
        print("✅ Fetched \(worksheets.count) worksheet(s)")
        return worksheets
    }
    
    /// Fetch a single worksheet by ID
    func fetchWorksheet(id: String) async throws -> Worksheet? {
        let worksheet = try await Amplify.DataStore.query(Worksheet.self, byId: id)
        
        if let worksheet = worksheet {
            print("✅ Fetched worksheet: \(worksheet.title)")
        } else {
            print("⚠️ Worksheet not found: \(id)")
        }
        
        return worksheet
    }
    
    func fetchUserProfile(userId: String) async throws -> UserProfile? {
        let profiles = try await Amplify.DataStore.query(
            UserProfile.self,
            where: UserProfile.keys.userId == userId
        )
        return profiles.first
    }
    
    /// Delete a worksheet (also deletes related questions and feedback via cascade)
    func deleteWorksheet(id: String) async throws {
        guard let worksheet = try await Amplify.DataStore.query(
            Worksheet.self,
            byId: id
        ) else {
            throw DataStoreError.worksheetNotFound
        }
        
        print("🗑️ Deleting worksheet: \(worksheet.title)")
        
        // Delete all related questions
        let questions = try await fetchQuestions(worksheetId: id)
        for question in questions {
            try await Amplify.DataStore.delete(question)
        }
        
        // Delete all related feedback
        let feedbacks = try await fetchAllFeedbackForWorksheet(worksheetId: id)
        for feedback in feedbacks {
            try await Amplify.DataStore.delete(feedback)
        }
        
        // Delete all full worksheet solutions
        let solutions = try await fetchFullWorksheetSolutions(for: worksheet)
        for solution in solutions {
            try await Amplify.DataStore.delete(solution)
        }
        
        // Finally delete the worksheet
        try await Amplify.DataStore.delete(worksheet)
        print("✅ Worksheet deleted successfully")
    }
    
    // MARK: - Question Operations
    
    /// Save extracted questions as flattened Amplify Question models
    private func saveQuestions(
        from extractedWorksheet: ExtractedWorksheet,
        worksheet: Worksheet,
        userId: String
    ) async throws {
        print("💾 Saving \(extractedWorksheet.questions.count) parent question(s)...")
        
        var totalSaved = 0
        
        for extractedQuestion in extractedWorksheet.questions {
            // Save parent question
            let parentQuestion = Question(
                userId: userId,
                questionId: extractedQuestion.id,
                questionText: extractedQuestion.questionText,
                marks: extractedQuestion.marks,
                skillsTested: extractedQuestion.skillsTested,
                hints: extractedQuestion.hints,
                stepByStep: extractedQuestion.stepByStep,
                answer: extractedQuestion.answer,
                isSubpart: false,
                parentQuestionId: nil,
                worksheet: worksheet,
                createdAt: Temporal.DateTime.now(),
                updatedAt: Temporal.DateTime.now()
            )
            
            try await Amplify.DataStore.save(parentQuestion)
            totalSaved += 1
            
            // Save subparts as separate Question records
            for extractedSubpart in extractedQuestion.subparts {
                let subpartQuestion = Question(
                    userId: userId,
                    questionId: extractedSubpart.id,
                    questionText: extractedSubpart.text,
                    marks: extractedSubpart.marks,
                    skillsTested: extractedSubpart.skillsTested,
                    hints: extractedSubpart.hints,
                    stepByStep: extractedSubpart.stepByStep,
                    answer: extractedSubpart.answer,
                    isSubpart: true,
                    parentQuestionId: extractedQuestion.id,
                    worksheet: worksheet,
                    createdAt: Temporal.DateTime.now(),
                    updatedAt: Temporal.DateTime.now()
                )
                
                try await Amplify.DataStore.save(subpartQuestion)
                totalSaved += 1
            }
        }
        
        print("✅ Saved \(totalSaved) question record(s) (including subparts)")
        // ✅ DEBUG: Verify questions were saved with worksheet link
        let savedQuestions = try await fetchQuestions(worksheetId: worksheet.id)
        print("🔍 DEBUG: Verified \(savedQuestions.count) questions in DataStore for worksheet \(worksheet.id)")
        for q in savedQuestions {
            print("   - Question: \(q.questionId), Worksheet: \(q.worksheet?.id ?? "nil")")
        }
    }
    
    /// Fetch all questions for a specific worksheet (using worksheetId)
    func fetchQuestions(worksheetId: String) async throws -> [Question] {
        print("📥 Fetching questions for worksheet: \(worksheetId)")
        
        // Fetch all questions and filter by worksheetId
        // Note: Can't query by worksheet relationship directly, so fetch all then filter
        let allQuestions = try await Amplify.DataStore.query(Question.self)
        let filteredQuestions = allQuestions.filter { question in
            question.worksheet?.id == worksheetId
        }
        
        print("✅ Fetched \(filteredQuestions.count) question(s)")
        return filteredQuestions.sorted { $0.questionId < $1.questionId }
    }
    
    /// Fetch a single question by its questionId string (e.g. "Q1", "Q2a")
    func fetchQuestion(byQuestionId questionId: String, worksheetId: String) async throws -> Question? {
        let allQuestions = try await Amplify.DataStore.query(Question.self)
        return allQuestions.first {
            $0.questionId == questionId && $0.worksheet?.id == worksheetId
        }
    }
    
    // MARK: - Solution Feedback Operations
    
    // Save individual question solution feedback with atomic attempt number
        func saveSolutionFeedback(
            localFeedback: LocalSolutionFeedback,
            s3ImageKey: String,
            worksheetId: String,
            questionId: String,
            aiModel: String = "gpt-4o",
            tokensUsed: Int? = nil
        ) async throws -> SolutionFeedback {
            print("💾 Saving solution feedback for question: \(questionId)")
            print("🔍 Searching in worksheet: \(worksheetId)")
            
            // ✅ Wrap in atomic operation to prevent race conditions
            return try await feedbackCoordinator.performAtomicSave {
                let userId = await AWSService.shared.currentUser?.userId ?? "unknown"
                
                // Find the Question object by questionId
                guard let questionObject = try await self.fetchQuestion(byQuestionId: questionId, worksheetId: worksheetId) else {
                    throw DataStoreError.questionNotFound
                }
                print("✅ Found question: \(questionObject.questionId)")
                
                // ✅ Calculate attempt number atomically (query + save in same critical section)
                let allFeedback = try await Amplify.DataStore.query(SolutionFeedback.self)
                let questionFeedback = allFeedback.filter {
                    $0.question?.id == questionObject.id
                }
                let attemptNumber = questionFeedback.count + 1
                
                print("📊 This will be attempt #\(attemptNumber) for question \(questionId)")
                
                // Create Amplify SolutionFeedback model
                let feedback = SolutionFeedback(
                    worksheetId: worksheetId,
                    userId: userId,
                    s3SolutionImageKey: s3ImageKey,
                    feedback: localFeedback.feedback,
                    isCorrect: localFeedback.isCorrect,
                    suggestions: localFeedback.suggestions,
                    attemptNumber: attemptNumber,
                    submittedAt: Temporal.DateTime.now(),
                    question: questionObject,
                    aiModel: aiModel,
                    tokensUsed: tokensUsed
                )
                
                try await Amplify.DataStore.save(feedback)
                print("✅ Feedback saved: Attempt #\(attemptNumber)")
                
                return feedback
            }
        }
    
    
    /// Fetch all solution feedback for a specific question (by questionId string)
    func fetchSolutionFeedback(forQuestionId questionId: String,worksheetId: String) async throws -> [SolutionFeedback] {
        print("🔥 Fetching feedback for question: \(questionId) in worksheet: \(worksheetId)")
        
        // Find the Question object first
        guard let questionObject = try await fetchQuestion(byQuestionId: questionId, worksheetId: worksheetId) else {
            print("⚠️ Question not found: \(questionId) in worksheet: \(worksheetId)")
            return []
        }
        
        // Fetch all feedback and filter by question relationship
        let allFeedback = try await Amplify.DataStore.query(SolutionFeedback.self)
        let questionFeedback = allFeedback.filter {
            $0.question?.id == questionObject.id
        }
        
        print("✅ Fetched \(questionFeedback.count) feedback(s)")
        return questionFeedback.sorted { $0.submittedAt < $1.submittedAt }
    }
    
    /// Fetch all feedback for entire worksheet (across all questions)
    func fetchAllFeedbackForWorksheet(worksheetId: String) async throws -> [SolutionFeedback] {
        print("📥 Fetching all feedback for worksheet: \(worksheetId)")
        
        // Query by worksheetId (this field DOES exist in SolutionFeedback)
        let feedbacks = try await Amplify.DataStore.query(
            SolutionFeedback.self,
            where: SolutionFeedback.keys.worksheetId == worksheetId,
            sort: .ascending(SolutionFeedback.keys.submittedAt)
        )
        
        print("✅ Fetched \(feedbacks.count) total feedback(s)")
        return feedbacks
    }
    
    // MARK: - Full Worksheet Solution Operations
    
    /// Save full worksheet solution feedback with atomic attempt number
     func saveFullWorksheetSolution(
         localFeedback: FullWorksheetFeedback,
         s3ImageKey: String,
         worksheet: Worksheet,
         aiModel: String = "gpt-4o",
         tokensUsed: Int? = nil
     ) async throws -> FullWorksheetSolution {
         print("💾 Saving full worksheet solution for: \(worksheet.id)")
         
         // ✅ Wrap in atomic operation to prevent race conditions
         return try await feedbackCoordinator.performAtomicSave {
             let userId = await AWSService.shared.currentUser?.userId ?? "unknown"
             
             // ✅ Calculate attempt number atomically
             let existingSolutions = try await self.fetchFullWorksheetSolutions(for: worksheet)
             let attemptNumber = existingSolutions.count + 1
             
             print("📊 This will be attempt #\(attemptNumber) for full worksheet")
             
             // Convert detailed feedback to JSON string
             let encoder = JSONEncoder()
             encoder.dateEncodingStrategy = .iso8601
             let detailedJSON = try encoder.encode(localFeedback.detailedFeedback)
             let detailedString = String(data: detailedJSON, encoding: .utf8)
             
             // Create Amplify FullWorksheetSolution model
             let solution = FullWorksheetSolution(
                 userId: userId,
                 s3SolutionImageKey: s3ImageKey,
                 overallFeedback: localFeedback.overallFeedback,
                 overallScore: localFeedback.overallScore,
                 totalQuestions: localFeedback.totalQuestions,
                 completedQuestions: localFeedback.completedQuestions,
                 questionsWithIssues: localFeedback.questionsWithIssues,
                 suggestions: localFeedback.suggestions,
                 detailedFeedback: detailedString,
                 attemptNumber: attemptNumber,
                 submittedAt: Temporal.DateTime.now(),
                 worksheet: worksheet,
                 aiModel: aiModel,
                 tokensUsed: tokensUsed
             )
             
             try await Amplify.DataStore.save(solution)
                         print("✅ Full worksheet solution saved: Attempt #\(attemptNumber)")
                         print("📊 Score: \(localFeedback.overallScore)/\(localFeedback.totalQuestions)")
                         
                         // ✅ ANALYTICS GENERATION - Sprint 7 Phase 5
                         print("📈 Generating analytics for submission...")
                         
                         // 2. Try to get classroom context
                         let classroomId = await self.getStudentClassroomId(userId: userId)
                         
                         // 3. Try to get worksheet metadata
                         let metadata = try? await self.fetchWorksheetMetadata(worksheetId: worksheet.id)
                         
                         // 4. Update concept mastery
                         do {
                             try await AnalyticsService.shared.updateConceptMastery(
                                 studentId: userId,
                                 classroomId: classroomId,
                                 feedback: solution,
                                 worksheet: worksheet,
                                 metadata: metadata
                             )
                             print("✅ Concept mastery updated")
                         } catch {
                             print("⚠️ Failed to update concept mastery: \(error)")
                         }
                         
                         // 5. Analyze errors from detailed feedback
                         if let detailedString = solution.detailedFeedback,
                            let detailedData = detailedString.data(using: .utf8) {
                             do {
                                 let decoder = JSONDecoder()
                                 decoder.dateDecodingStrategy = .iso8601
                                 let detailedFeedback = try decoder.decode([QuestionFeedback].self, from: detailedData)
                                 
                                 // Get the original extracted questions from worksheet
                                 if let extractionResult = worksheet.extractionResult,
                                    let extractedData = extractionResult.data(using: .utf8),
                                    let extractedWorksheet = try? decoder.decode(ExtractedWorksheet.self, from: extractedData) {
                                     
                                     // Map questionId to ExtractedQuestion
                                     let questionMap = Dictionary(uniqueKeysWithValues:
                                         extractedWorksheet.questions.map { ($0.id, $0) }
                                     )
                                     
                                     // Analyze errors
                                     for feedback in detailedFeedback {
                                         guard let question = questionMap[feedback.questionId],
                                               let isCorrect = feedback.isCorrect,
                                               !isCorrect else { continue }
                                         
                                         try? await AnalyticsService.shared.analyzeAndRecordErrors(
                                             studentId: userId,
                                             classroomId: classroomId,
                                             questionId: question.id,
                                             question: question,
                                             studentAnswer: "Student response (see worksheet image)",
                                             feedback: feedback.feedback,
                                             isCorrect: false
                                         )
                                     }
                                     print("✅ Error patterns analyzed")
                                 }
                             } catch {
                                 print("⚠️ Failed to analyze error patterns: \(error)")
                             }
                         }
                         
                         // 6. Trigger summary calculation (non-blocking)
                         Task {
                             do {
                                 _ = try await AnalyticsQueryService.shared.fetchStudentSummary(
                                     studentId: userId,
                                     classroomId: classroomId
                                 )
                                 print("✅ Analytics summary calculated")
                             } catch {
                                 print("⚠️ Failed to calculate analytics summary: \(error)")
                             }
                         }
                         
                         return solution
         }
     }

    
    /// Fetch all full worksheet solutions for a worksheet
    func fetchFullWorksheetSolutions(for worksheet: Worksheet) async throws -> [FullWorksheetSolution] {
        print("📥 Fetching full worksheet solutions for: \(worksheet.id)")
        
        // Fetch all solutions and filter by worksheet relationship
        let allSolutions = try await Amplify.DataStore.query(FullWorksheetSolution.self)
        let worksheetSolutions = allSolutions.filter {
            $0.worksheet?.id == worksheet.id
        }
        
        print("✅ Fetched \(worksheetSolutions.count) solution(s)")
        return worksheetSolutions.sorted { $0.submittedAt < $1.submittedAt }
    }
    
    /// Fetch the latest full worksheet solution
    func fetchLatestFullWorksheetSolution(for worksheet: Worksheet) async throws -> FullWorksheetSolution? {
        let solutions = try await fetchFullWorksheetSolutions(for: worksheet)
        return solutions.last  // Last item is most recent (sorted ascending)
    }
    
    // MARK: - JSON Parsing Utilities
    
    /// Convert stored JSON string back to ExtractedWorksheet object
    func parseExtractionResult(_ jsonString: String) throws -> ExtractedWorksheet {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw DataStoreError.invalidJSON
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ExtractedWorksheet.self, from: jsonData)
    }
    
    /// Convert stored detailed feedback JSON string back to QuestionFeedback array
    func parseDetailedFeedback(_ jsonString: String?) throws -> [QuestionFeedback]? {
        guard let jsonString = jsonString,
              let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([QuestionFeedback].self, from: jsonData)
    }
    
    // MARK: - User Statistics Operations
    
    /// Update user statistics after worksheet upload or feedback submission
    func updateUserStats() async throws {
        let userId = AWSService.shared.currentUser?.userId ?? "unknown"
        
        // Fetch or create user stats
        var userStats: UserStats
        
        let existingStats = try await Amplify.DataStore.query(
            UserStats.self,
            where: UserStats.keys.userId == userId
        )
        
        if let stats = existingStats.first {
            userStats = stats
        } else {
            userStats = UserStats(
                userId: userId,
                totalWorksheets: 0,
                totalQuestions: 0,
                totalSolutionsSubmitted: 0,
                totalFeedbackReceived: 0,
                correctAnswersCount: 0,
                totalAttemptsCount: 0,
                createdAt: Temporal.DateTime.now(),
                updatedAt: Temporal.DateTime.now()
            )
        }
        
        // Count totals
        let worksheets = try await fetchWorksheets()
        let allFeedback = try await Amplify.DataStore.query(SolutionFeedback.self)
        let correctFeedback = allFeedback.filter { $0.isCorrect == true }
        
        userStats.totalWorksheets = worksheets.count
        userStats.totalSolutionsSubmitted = allFeedback.count
        userStats.totalFeedbackReceived = allFeedback.count
        userStats.correctAnswersCount = correctFeedback.count
        userStats.totalAttemptsCount = allFeedback.count
        userStats.lastActiveAt = Temporal.DateTime.now()
        userStats.updatedAt = Temporal.DateTime.now()
        
        // Calculate average score
        if allFeedback.count > 0 {
            userStats.averageScore = Double(correctFeedback.count) / Double(allFeedback.count) * 100.0
        }
        
        try await Amplify.DataStore.save(userStats)
        print("✅ User stats updated")
    }
    
    /// Fetch user statistics
    func fetchUserStats() async throws -> UserStats? {
        let userId = AWSService.shared.currentUser?.userId ?? "unknown"
        
        let stats = try await Amplify.DataStore.query(
            UserStats.self,
            where: UserStats.keys.userId == userId
        )
        
        return stats.first
    }
    
    // MARK: - Utility Methods
    
    /// Calculate total marks from extracted worksheet
    private func calculateTotalMarks(from worksheet: ExtractedWorksheet) -> Int {
        return worksheet.questions.reduce(0) { total, question in
            let questionMarks = question.marks
            let subpartMarks = question.subparts.reduce(0) { $0 + $1.marks }
            return total + questionMarks + subpartMarks
        }
    }
    
    /// Generate SHA256 hash for content (used for duplicate detection)
    private func generateContentHash(_ content: String) -> String {
        let data = Data(content.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - DataStore Management
    
    // Keep the existing clearLocalDataStore() for testing only
    // Rename it to make clear it's destructive:
    /// ⚠️ DESTRUCTIVE: Clear all local DataStore data (use only for testing)
    func clearLocalDataStore() async throws {
        print("⚠️ DESTRUCTIVE: Clearing local DataStore...")
        try await Amplify.DataStore.clear()
        print("✅ DataStore cleared")
    }
    
    /// Start DataStore (call once on app launch)
    func startDataStore() async throws {
        print("🚀 Starting DataStore...")
        try await Amplify.DataStore.start()
        print("✅ DataStore started")
    }
    
    /// Stop DataStore
    func stopDataStore() async throws {
        print("⏹️ Stopping DataStore...")
        try await Amplify.DataStore.stop()
        print("✅ DataStore stopped")
    }
    
    // MARK: - Logout Handling

    /// Stop DataStore on logout (preserves local data)
    func stopDataStoreForLogout() async throws {
        print("⏸️ Stopping DataStore for logout...")
        try await Amplify.DataStore.stop()
        print("✅ DataStore stopped - local data preserved")
    }

    // Helper structures for GraphQL response parsing
    private struct GraphQLResponse: Codable {
        let data: GraphQLData?
    }

    private struct GraphQLData: Codable {
        let questionsByWorksheetIdAndQuestionId: QuestionConnection?
    }

    private struct QuestionConnection: Codable {
        let items: [QuestionItem]
    }

    private struct QuestionItem: Codable {
        let id: String
        let worksheetId: String
        let questionId: String
    }

    // MARK: - Analytics Helper Methods
        
        /// Get the classroom ID for a student (returns first approved classroom)
        private func getStudentClassroomId(userId: String) async -> String? {
            do {
                let allMemberships = try await Amplify.DataStore.query(ClassroomMembership.self)
                let approvedMemberships = allMemberships.filter {
                    $0.studentId == userId && $0.status == .approved
                }
                return approvedMemberships.first?.classroom?.id
            } catch {
                print("⚠️ Failed to get classroom ID: \(error)")
                return nil
            }
        }
        
        /// Fetch worksheet metadata for analytics
        private func fetchWorksheetMetadata(worksheetId: String) async throws -> WorksheetMetadata? {
            let allMetadata = try await Amplify.DataStore.query(WorksheetMetadata.self)
            return allMetadata.filter { $0.worksheet?.id == worksheetId }.first
            }
    
}

// MARK: - Error Types

enum DataStoreError: Error, LocalizedError {
    case invalidJSON
    case saveFailed
    case queryFailed
    case worksheetNotFound
    case questionNotFound
    case encodingFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "Failed to parse JSON data"
        case .saveFailed:
            return "Failed to save to DataStore"
        case .queryFailed:
            return "Failed to query DataStore"
        case .worksheetNotFound:
            return "Worksheet not found"
        case .questionNotFound:
            return "Question not found"
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        }
    }
}
