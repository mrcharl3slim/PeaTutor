//
//  AnalyticsService.swift
//  PeaTutorApp
//
//  Sprint 7.1 + Sprint 8 Phase 4: Deep Worksheet Analytics Engine with Curriculum Integration
//  Centralized service for calculating and managing student analytics with MOE curriculum alignment
//

import Foundation
import Amplify

@MainActor
class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    // Curriculum services
    private let curriculumService = CurriculumService.shared
    private let mappingService = CurriculumMappingService.shared
    
    private init() {}
    
    // MARK: - Curriculum-Aware Worksheet Metadata Extraction
    
    /// Extract and save worksheet metadata with MOE curriculum alignment
    func extractAndSaveWorksheetMetadata(
        worksheet: Worksheet,
        extractedWorksheet: ExtractedWorksheet,
        fileIDs: [String],
        studentGradeLevel: String? = nil
    ) async throws -> WorksheetMetadata {
        print("📊 Starting curriculum-aware worksheet metadata extraction...")
        
        guard let client = OpenAIClient() else {
            throw AnalyticsError.openAIClientUnavailable
        }
        
        // Extract metadata with curriculum alignment using AI
        let metadataResult = try await client.extractWorksheetMetadataWithCurriculum(
            worksheet: extractedWorksheet,
            fileIDs: fileIDs
        )
        
        // Create WorksheetMetadata from curriculum-aware extraction
        var metadata = WorksheetMetadata.fromCurriculumAware(
            userId: worksheet.userId,
            aiResult: metadataResult,
            worksheet: worksheet
        )
        
        // If curriculum confidence is low, try to enhance with mapping service
        if (metadataResult.curriculumConfidence ?? 0) < 0.5 {
            print("📚 Low curriculum confidence, enhancing with mapping service...")
            
            let mappingResult = try await mappingService.mapWorksheetToCurriculum(
                metadata: metadata,
                studentGradeLevel: studentGradeLevel
            )
            
            if mappingResult.hasMappings {
                metadata = metadata.withCurriculumMapping(
                    codes: mappingResult.curriculumCodes,
                    gradeLevel: mappingResult.detectedGradeLevel,
                    gradeLevelCode: mappingResult.detectedGradeLevelCode,
                    strand: mappingResult.primaryStrand,
                    subStrand: mappingResult.primarySubStrand,
                    confidence: mappingResult.confidence
                )
            }
        }
        
        try await Amplify.DataStore.save(metadata)
        print("✅ Curriculum-aware worksheet metadata saved")
        print("   Topics: \(metadata.topics.joined(separator: ", "))")
        print("   Curriculum codes: \(metadata.moeCurriculumCodes?.compactMap { $0 }.joined(separator: ", ") ?? "none")")
        print("   Grade level: \(metadata.detectedGradeLevel ?? "unknown")")
        print("   Confidence: \(Int((metadata.curriculumConfidence ?? 0) * 100))%")
        
        return metadata
    }
    
    /// Legacy method for backward compatibility (non-curriculum)
    func extractAndSaveWorksheetMetadataLegacy(
        worksheet: Worksheet,
        extractedWorksheet: ExtractedWorksheet,
        fileIDs: [String]
    ) async throws -> WorksheetMetadata {
        print("📊 Starting worksheet metadata extraction (legacy)...")
        
        guard let client = OpenAIClient() else {
            throw AnalyticsError.openAIClientUnavailable
        }
        
        // Extract metadata using basic AI
        let metadataResult = try await client.extractWorksheetMetadata(
            worksheet: extractedWorksheet,
            fileIDs: fileIDs
        )
        
        // Create and save WorksheetMetadata model
        let metadata = WorksheetMetadata.from(
            userId: worksheet.userId,
            aiResult: metadataResult,
            worksheet: worksheet
        )
        
        try await Amplify.DataStore.save(metadata)
        print("✅ Worksheet metadata saved: \(metadata.topics.joined(separator: ", "))")
        
        return metadata
    }
    
    // MARK: - Curriculum-Aware Concept Mastery Tracking
    
    /// Update concept mastery after student submits work with curriculum alignment
    func updateConceptMastery(
        studentId: String,
        classroomId: String?,
        feedback: FullWorksheetSolution,
        worksheet: Worksheet,
        metadata: WorksheetMetadata?
    ) async throws {
        print("📈 Updating curriculum-aligned concept mastery for student: \(studentId)")
        
        // Get concepts from worksheet metadata or extract from questions
        let concepts = metadata?.topics ?? extractConceptsFromWorksheet(worksheet)
        
        // Get curriculum codes if available
        let curriculumCodes = metadata?.moeCurriculumCodes?.compactMap { $0 } ?? []
        let gradeLevel = metadata?.detectedGradeLevel
        
        // Get student's performance on this worksheet
        let totalQuestions = feedback.totalQuestions
        let correctCount = feedback.overallScore
        
        // Update mastery for each concept
        for (index, concept) in concepts.enumerated() {
            // Try to get corresponding curriculum code
            let curriculumCode = index < curriculumCodes.count ? curriculumCodes[index] : nil
            
            try await updateConceptMasteryRecord(
                studentId: studentId,
                classroomId: classroomId,
                concept: concept,
                attempted: totalQuestions,
                correct: correctCount,
                difficulty: metadata?.complexityLevel ?? "Medium",
                gradeLevel: gradeLevel,
                curriculumCode: curriculumCode,
                curriculumStrand: metadata?.curriculumStrand,
                curriculumSubStrand: metadata?.curriculumSubStrand
            )
        }
        
        // Update curriculum progress summary
        if let grade = gradeLevel {
            try await updateStudentCurriculumProgress(
                studentId: studentId,
                classroomId: classroomId,
                gradeLevel: grade
            )
        }
        
        print("✅ Concept mastery updated for \(concepts.count) concept(s)")
    }
    
    /// Get or create concept mastery record and update it with curriculum alignment
    private func updateConceptMasteryRecord(
        studentId: String,
        classroomId: String?,
        concept: String,
        attempted: Int,
        correct: Int,
        difficulty: String,
        gradeLevel: String?,
        curriculumCode: String?,
        curriculumStrand: String?,
        curriculumSubStrand: String?
    ) async throws {
        // Query for existing concept mastery
        let allMastery = try await Amplify.DataStore.query(ConceptMastery.self)
        let existingMastery = allMastery.first { mastery in
            mastery.studentId == studentId &&
            mastery.concept == concept &&
            (classroomId == nil || mastery.classroomId == classroomId)
        }
        
        if var mastery = existingMastery {
            // Update existing record
            let isCorrect = correct >= Int(Double(attempted) * 0.7)
            let questionDifficulty = QuestionDifficulty(rawValue: difficulty) ?? .medium
            
            // Use extension method that returns new instance
            var updated = mastery.recordingAttempt(isCorrect: isCorrect, difficulty: questionDifficulty)
            
            // Calculate trend
            updated.trend = calculateTrend(mastery: updated)
            
            // Update recent questions count
            updated.recentQuestions = try await countRecentQuestions(
                studentId: studentId,
                concept: concept,
                days: 7
            )
            
            // Update curriculum alignment if provided and not already set
            if let code = curriculumCode, updated.curriculumCode == nil {
                updated = updated.withCurriculumAlignment(
                    curriculumCode: code,
                    strand: curriculumStrand,
                    subStrand: curriculumSubStrand,
                    topicTitle: concept,
                    prerequisitesMastered: nil,
                    prerequisiteGaps: nil
                )
            }
            
            try await Amplify.DataStore.save(updated)
            print("✅ Updated mastery for \(concept): \(Int(updated.masteryPercentage))%")
            
        } else {
            // Create new record
            let isCorrect = correct >= Int(Double(attempted) * 0.7)
            let questionDifficulty = QuestionDifficulty(rawValue: difficulty) ?? .medium
            
            // Check if we should use curriculum-aware creation
            if let code = curriculumCode {
                // Use curriculum-aware factory method
                var newMastery = ConceptMastery.createNewWithCurriculum(
                    studentId: studentId,
                    classroomId: classroomId,
                    concept: concept,
                    gradeLevel: gradeLevel,
                    curriculumCode: code,
                    curriculumStrand: curriculumStrand,
                    curriculumSubStrand: curriculumSubStrand,
                    curriculumTopicTitle: concept
                )
                
                // Record the first attempt
                let updated = newMastery.recordingAttempt(isCorrect: isCorrect, difficulty: questionDifficulty)
                
                try await Amplify.DataStore.save(updated)
                print("✅ Created curriculum-aligned mastery record for \(concept) [\(code)]")
                
            } else {
                // Use basic factory method
                let newMastery = ConceptMastery.createNew(
                    studentId: studentId,
                    classroomId: classroomId,
                    concept: concept,
                    gradeLevel: gradeLevel
                )
                
                // Record the first attempt
                var updated = newMastery.recordingAttempt(isCorrect: isCorrect, difficulty: questionDifficulty)
                
                // Try to map to curriculum
                if let match = try? await mappingService.mapConceptToCurriculum(
                    concept: concept,
                    gradeLevel: gradeLevel
                ) {
                    updated = updated.withCurriculumAlignment(
                        curriculumCode: match.standard.curriculumCode,
                        strand: match.standard.strand,
                        subStrand: match.standard.subStrand,
                        topicTitle: match.standard.topicTitle,
                        prerequisitesMastered: nil,
                        prerequisiteGaps: nil
                    )
                    print("📚 Auto-mapped concept to curriculum: \(match.standard.curriculumCode)")
                }
                
                try await Amplify.DataStore.save(updated)
                print("✅ Created new mastery record for \(concept)")
            }
        }
    }
    
    // MARK: - Student Curriculum Progress
    
    /// Update or create student curriculum progress summary
    func updateStudentCurriculumProgress(
        studentId: String,
        classroomId: String?,
        gradeLevel: String
    ) async throws {
        print("📊 Updating curriculum progress for \(gradeLevel)...")
        
        let gradeLevelCode = CurriculumService.gradeLevelToCode(gradeLevel) ?? "P3"
        
        // Get curriculum recommendation which includes progress data
        let recommendation = try await mappingService.getRecommendedPath(
            studentId: studentId,
            classroomId: classroomId,
            targetGradeLevel: gradeLevel
        )
        
        // Calculate strand progress
        let strandProgress = try await calculateStrandProgress(
            studentId: studentId,
            classroomId: classroomId,
            gradeLevel: gradeLevel
        )
        
        // Check for existing progress record
        let allProgress = try await Amplify.DataStore.query(StudentCurriculumProgress.self)
        let existingProgress = allProgress.first { progress in
            progress.studentId == studentId &&
            progress.gradeLevelCode == gradeLevelCode &&
            (classroomId == nil || progress.classroomId == classroomId)
        }
        
        if let existing = existingProgress {
            // Update existing
            var updated = existing
            updated.topicsAttempted = recommendation.masteredCount + recommendation.inProgressCount
            updated.topicsMastered = recommendation.masteredCount
            updated.topicsInProgress = recommendation.inProgressCount
            updated.topicsNotStarted = recommendation.notStartedCount
            updated.coveragePercentage = recommendation.coveragePercentage
            updated.masteryPercentage = recommendation.masteryPercentage
            updated.strandProgress = strandProgress
            updated.masteredTopicCodes = recommendation.masteredStandards.map { $0.curriculumCode }
            updated.inProgressTopicCodes = recommendation.inProgressStandards.map { $0.curriculumCode }
            updated.notStartedTopicCodes = recommendation.standardsWithPrerequisiteGaps.map { $0.curriculumCode }
            updated.prerequisiteGaps = recommendation.standardsWithPrerequisiteGaps.map { Optional($0.curriculumCode) }
            updated.recommendedNextTopics = recommendation.recommendedNextStandards.map { Optional($0.curriculumCode) }
            updated.lastCalculatedAt = .now()
            updated.lastUpdatedAt = .now()
            
            try await Amplify.DataStore.save(updated)
            print("✅ Updated curriculum progress: \(Int(recommendation.masteryPercentage))% mastery")
            
        } else {
            // Create new
            let newProgress = StudentCurriculumProgress(
                studentId: studentId,
                classroomId: classroomId,
                country: "SG",
                curriculumVersion: "2021",
                gradeLevel: gradeLevel,
                gradeLevelCode: gradeLevelCode,
                totalTopicsInGrade: recommendation.totalStandards,
                topicsAttempted: recommendation.masteredCount + recommendation.inProgressCount,
                topicsMastered: recommendation.masteredCount,
                topicsInProgress: recommendation.inProgressCount,
                topicsNotStarted: recommendation.notStartedCount,
                coveragePercentage: recommendation.coveragePercentage,
                masteryPercentage: recommendation.masteryPercentage,
                strandProgress: strandProgress,
                masteredTopicCodes: recommendation.masteredStandards.map { $0.curriculumCode },
                inProgressTopicCodes: recommendation.inProgressStandards.map { $0.curriculumCode },
                notStartedTopicCodes: recommendation.standardsWithPrerequisiteGaps.map { $0.curriculumCode },
                prerequisiteGaps: recommendation.standardsWithPrerequisiteGaps.map { Optional($0.curriculumCode) },
                recommendedNextTopics: recommendation.recommendedNextStandards.map { Optional($0.curriculumCode) },
                lastCalculatedAt: .now(),
                lastUpdatedAt: .now()
            )
            
            try await Amplify.DataStore.save(newProgress)
            print("✅ Created curriculum progress: \(Int(recommendation.masteryPercentage))% mastery")
        }
    }
    
    /// Calculate progress by strand
    private func calculateStrandProgress(
        studentId: String,
        classroomId: String?,
        gradeLevel: String
    ) async throws -> String {
        // Get all mastery records for student
        let allMastery = try await Amplify.DataStore.query(ConceptMastery.self)
        let studentMastery = allMastery.filter { mastery in
            mastery.studentId == studentId &&
            (classroomId == nil || mastery.classroomId == classroomId)
        }
        
        // Group by strand
        let groupedByStrand = studentMastery.groupedByCurriculumStrand()
        
        // Calculate average mastery per strand
        var strandResults: [String: Double] = [:]
        
        for (strand, records) in groupedByStrand {
            if !records.isEmpty {
                let avgMastery = records.reduce(0.0) { $0 + $1.masteryPercentage } / Double(records.count)
                strandResults[strand] = avgMastery
            }
        }
        
        // Format as JSON string
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        
        if let data = try? encoder.encode(strandResults),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        
        return "{}"
    }
    
    // MARK: - Error Pattern Detection
    
    /// Analyze and record error patterns from incorrect answers
    func analyzeAndRecordErrors(
        studentId: String,
        classroomId: String?,
        questionId: String,
        question: ExtractedQuestion,
        studentAnswer: String,
        feedback: String,
        isCorrect: Bool
    ) async throws {
        // Only analyze errors
        guard !isCorrect else { return }
        
        print("🔍 Analyzing error pattern for question: \(questionId)")
        
        guard let client = OpenAIClient() else {
            print("⚠️ OpenAI client unavailable, skipping error analysis")
            return
        }
        
        // Get AI analysis of the error
        guard let errorAnalysis = try await client.analyzeErrorPattern(
            question: question,
            studentAnswer: studentAnswer,
            isCorrect: isCorrect,
            existingFeedback: feedback
        ) else {
            print("⚠️ No error pattern detected")
            return
        }
        
        // Check if this error pattern already exists
        let allErrors = try await Amplify.DataStore.query(ErrorPattern.self)
        let existingError = allErrors.first { error in
            error.studentId == studentId &&
            error.errorType == errorAnalysis.errorType &&
            error.errorCategory == errorAnalysis.errorCategory &&
            !error.isResolved
        }
        
        if let error = existingError {
            // Update existing error pattern using extension method
            let updated = error.recordingOccurrence(questionId: questionId)
            try await Amplify.DataStore.save(updated)
            print("✅ Updated existing error pattern: \(updated.errorType)")
        } else {
            // Create new error pattern
            let newError = errorAnalysis.toErrorPattern(
                studentId: studentId,
                classroomId: classroomId,
                questionId: questionId
            )
            try await Amplify.DataStore.save(newError)
            print("✅ Created new error pattern: \(newError.errorType)")
        }
    }
    
    // MARK: - Student Analytics Summary
    
    /// Calculate comprehensive analytics summary for a student
    func calculateStudentSummary(
        studentId: String,
        classroomId: String?
    ) async throws -> StudentAnalyticsSummary {
        print("📊 Calculating analytics summary for student: \(studentId)")
        
        // Get all concept mastery records
        let allMastery = try await Amplify.DataStore.query(ConceptMastery.self)
        let conceptMastery = allMastery.filter { mastery in
            mastery.studentId == studentId &&
            (classroomId == nil || mastery.classroomId == classroomId)
        }
        
        // Get all error patterns
        let allErrors = try await Amplify.DataStore.query(ErrorPattern.self)
        let activeErrors = allErrors.filter { error in
            error.studentId == studentId &&
            !error.isResolved &&
            (classroomId == nil || error.classroomId == classroomId)
        }
        
        // Calculate overall metrics
        let totalAttempts = conceptMastery.reduce(0) { $0 + $1.totalAttempts }
        let totalCorrect = conceptMastery.reduce(0) { $0 + $1.correctAttempts }
        let overallAccuracy = totalAttempts > 0 ? (Double(totalCorrect) / Double(totalAttempts)) * 100 : 0.0
        
        // Categorize concepts by mastery level
        let masteredConcepts = conceptMastery.filter { $0.masteryPercentage >= 80 }.map { $0.concept }
        let developingConcepts = conceptMastery.filter { $0.masteryPercentage >= 60 && $0.masteryPercentage < 80 }.map { $0.concept }
        let needsWorkConcepts = conceptMastery.filter { $0.masteryPercentage < 60 }.map { $0.concept }
        
        // Get top strengths and weaknesses
        let sortedByMastery = conceptMastery.sorted { $0.masteryPercentage > $1.masteryPercentage }
        let topStrengths = sortedByMastery.prefix(3).map { $0.concept }
        let topWeaknesses = sortedByMastery.suffix(3).reversed().map { $0.concept }
        
        // Error analysis
        let highSeverityErrors = activeErrors.filter { $0.severity == "high" }.count
        let mediumSeverityErrors = activeErrors.filter { $0.severity == "medium" }.count
        let mostCommonErrors = activeErrors.sorted { (error1, error2) -> Bool in
            return error1.occurrenceCount > error2.occurrenceCount
        }.prefix(5).map { $0.errorType }
        
        // Get engagement metrics from StudentProgress
        let allProgress = try await Amplify.DataStore.query(StudentProgress.self)
        let progress = allProgress.first { $0.studentId == studentId &&
            (classroomId == nil || $0.classroom?.id == classroomId) }
        
        // Calculate cognitive profile
        let cognitiveProfile = calculateCognitiveProfile(conceptMastery: conceptMastery)
        
        // Create summary
        let summary = StudentAnalyticsSummary(
            studentId: studentId,
            classroomId: classroomId,
            overallProgress: calculateOverallProgress(conceptMastery: conceptMastery),
            totalQuestionsAttempted: totalAttempts,
            totalQuestionsCorrect: totalCorrect,
            overallAccuracy: overallAccuracy,
            masteredConcepts: masteredConcepts,
            developingConcepts: developingConcepts,
            needsWorkConcepts: needsWorkConcepts,
            topStrengths: topStrengths,
            topWeaknesses: topWeaknesses,
            mostCommonErrors: mostCommonErrors,
            highSeverityErrorCount: highSeverityErrors,
            mediumSeverityErrorCount: mediumSeverityErrors,
            currentStreak: progress?.currentStreak ?? 0,
            longestStreak: progress?.longestStreak ?? 0,
            practiceFrequency: calculatePracticeFrequency(progress: progress),
            computationScore: cognitiveProfile.computation,
            problemSolvingScore: cognitiveProfile.problemSolving,
            reasoningScore: cognitiveProfile.reasoning,
            accuracyScore: cognitiveProfile.accuracy,
            wordProblemScore: cognitiveProfile.wordProblems,
            lastCalculated: Temporal.DateTime.now(),
            lastUpdated: Temporal.DateTime.now()
        )
        
        print("✅ Analytics summary calculated")
        return summary
    }
    
    // MARK: - Batch Curriculum Alignment
    
    /// Align all unmapped concept mastery records to curriculum
    func alignAllMasteryToCurriculum(
        studentId: String,
        classroomId: String?
    ) async throws -> Int {
        return try await mappingService.batchUpdateMasteryWithCurriculum(
            studentId: studentId,
            classroomId: classroomId
        )
    }
    
    /// Align all worksheet metadata to curriculum
    func alignWorksheetMetadataToCurriculum(
        worksheetId: String,
        studentGradeLevel: String?
    ) async throws -> WorksheetMetadata? {
        let allMetadata = try await Amplify.DataStore.query(WorksheetMetadata.self)
        
        guard let metadata = allMetadata.first(where: { $0.worksheet?.id == worksheetId }) else {
            return nil
        }
        
        // Skip if already aligned with high confidence
        if let confidence = metadata.curriculumConfidence, confidence >= 0.7 {
            return metadata
        }
        
        return try await mappingService.updateMetadataWithCurriculum(
            metadata: metadata,
            studentGradeLevel: studentGradeLevel
        )
    }
    
    // MARK: - Helper Functions
    
    private func extractConceptsFromWorksheet(_ worksheet: Worksheet) -> [String] {
        // Parse extraction result to get concepts
        guard let extractionData = worksheet.extractionResult?.data(using: .utf8),
              let extracted = try? JSONDecoder().decode(ExtractedWorksheet.self, from: extractionData) else {
            return []
        }
        
        // Extract unique skills from all questions
        let allSkills = extracted.questions.flatMap { $0.skillsTested }
        return Array(Set(allSkills))
    }
    
    private func calculateOverallProgress(conceptMastery: [ConceptMastery]) -> Double {
        guard !conceptMastery.isEmpty else { return 0.0 }
        
        let totalMastery = conceptMastery.reduce(0.0) { $0 + $1.masteryPercentage }
        return totalMastery / Double(conceptMastery.count)
    }
    
    /// Calculate trend based on recent performance
    private func calculateTrend(mastery: ConceptMastery) -> String {
        // Simple trend calculation based on recent vs overall accuracy
        let overallAccuracy = mastery.accuracyRate
        
        // Get accuracy of last few attempts (simplified - in production, track individual attempts)
        // For now, assume if mastery is above 70%, trend is improving
        if mastery.masteryPercentage >= 80 {
            return "improving"
        } else if mastery.masteryPercentage >= 60 {
            return "stable"
        } else {
            return "declining"
        }
    }
    
    /// Count recent questions for a concept
    private func countRecentQuestions(
        studentId: String,
        concept: String,
        days: Int
    ) async throws -> Int {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        // Query recent submissions
        let submissions = try await Amplify.DataStore.query(
            FullWorksheetSolution.self,
            where: FullWorksheetSolution.keys.userId == studentId &&
                   FullWorksheetSolution.keys.submittedAt > Temporal.DateTime(cutoffDate)
        )
        
        // Count questions (simplified - would need to check worksheet topics)
        return submissions.reduce(0) { $0 + $1.totalQuestions }
    }
    
    private func calculateCognitiveProfile(conceptMastery: [ConceptMastery]) -> (
        computation: Double,
        problemSolving: Double,
        reasoning: Double,
        accuracy: Double,
        wordProblems: Double
    ) {
        // Simplified cognitive profile calculation
        // In production, this would be more sophisticated
        let avgMastery = conceptMastery.isEmpty ? 0.0 :
            conceptMastery.reduce(0.0) { $0 + $1.masteryPercentage } / Double(conceptMastery.count)
        
        return (
            computation: avgMastery * 0.95,
            problemSolving: avgMastery * 0.85,
            reasoning: avgMastery * 0.80,
            accuracy: avgMastery * 0.90,
            wordProblems: avgMastery * 0.75
        )
    }
    
    private func calculatePracticeFrequency(progress: StudentProgress?) -> String {
        guard let progress = progress else { return "Never" }
        
        // Calculate based on current streak - currentStreak is optional
        let currentStreak = progress.currentStreak ?? 0
        let totalSubmissions = progress.totalSubmissions
        
        if currentStreak >= 7 {
            return "Daily"
        } else if currentStreak >= 3 {
            return "Weekly"
        } else if totalSubmissions > 5 {
            return "Occasional"
        } else {
            return "Rarely"
        }
    }
}

// MARK: - Errors

enum AnalyticsError: LocalizedError {
    case openAIClientUnavailable
    case calculationFailed
    case insufficientData
    case curriculumMappingFailed
    
    var errorDescription: String? {
        switch self {
        case .openAIClientUnavailable:
            return "OpenAI client is not available"
        case .calculationFailed:
            return "Analytics calculation failed"
        case .insufficientData:
            return "Insufficient data for analytics"
        case .curriculumMappingFailed:
            return "Failed to map content to curriculum"
        }
    }
}

// MARK: - WorksheetMetadata Extension for Curriculum-Aware Creation

extension WorksheetMetadata {
    
    /// Create from curriculum-aware extraction result
    static func fromCurriculumAware(
        userId: String,
        aiResult: WorksheetMetadataExtractionWithCurriculum,
        worksheet: Worksheet
    ) -> WorksheetMetadata {
        return WorksheetMetadata(
            userId: userId,
            topics: aiResult.topics,
            difficulty: aiResult.difficulty,
            cognitiveSkills: aiResult.cognitiveSkills,
            questionTypes: aiResult.questionTypes,
            estimatedTimeMinutes: aiResult.estimatedTimeMinutes,
            complexityLevel: aiResult.complexityLevel,
            commonCoreStandards: nil,
            bloomsTaxonomyLevels: aiResult.bloomsTaxonomyLevels?.map { Optional($0) },
            worksheet: worksheet,
            // Curriculum fields
            curriculumCountry: aiResult.curriculumCountry,
            curriculumVersion: aiResult.curriculumVersion,
            moeCurriculumCodes: aiResult.moeCurriculumCodes?.map { Optional($0) },
            detectedGradeLevel: aiResult.detectedGradeLevel,
            detectedGradeLevelCode: aiResult.detectedGradeLevelCode,
            curriculumStrand: aiResult.curriculumStrand,
            curriculumSubStrand: aiResult.curriculumSubStrand,
            curriculumConfidence: aiResult.curriculumConfidence,
            curriculumMappedAt: .now(),
            extractedAt: .now(),
            aiModel: aiResult.aiModel ?? "gpt-4o",
            tokensUsed: aiResult.tokensUsed
        )
    }
    
    /// Update with curriculum mapping results
    func withCurriculumMapping(
        codes: [String],
        gradeLevel: String?,
        gradeLevelCode: String?,
        strand: String?,
        subStrand: String?,
        confidence: Double
    ) -> WorksheetMetadata {
        var updated = self
        updated.moeCurriculumCodes = codes.map { Optional($0) }
        updated.detectedGradeLevel = gradeLevel ?? self.detectedGradeLevel
        updated.detectedGradeLevelCode = gradeLevelCode ?? self.detectedGradeLevelCode
        updated.curriculumStrand = strand ?? self.curriculumStrand
        updated.curriculumSubStrand = subStrand ?? self.curriculumSubStrand
        updated.curriculumConfidence = confidence
        updated.curriculumMappedAt = .now()
        return updated
    }
}
