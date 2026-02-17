//
//  PracticeGenerationService.swift
//  PeaTutorApp
//
//  Sprint 7.4 + Sprint 8 Phase 4: AI-Powered Practice Generation with Curriculum Integration
//  Centralized service for generating curriculum-aligned practice problems using OpenAI
//

import Foundation
import Amplify

@MainActor
class PracticeGenerationService: ObservableObject {
    static let shared = PracticeGenerationService()
    
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0
    @Published var lastError: String?
    
    // Curriculum services
    private let curriculumService = CurriculumService.shared
    private let mappingService = CurriculumMappingService.shared
    
    private init() {}
    
    // MARK: - Generate from Worksheet (Curriculum-Aware)
    
    /// Generate practice problems based on an existing worksheet with curriculum alignment
    func generateFromWorksheet(
        worksheet: Worksheet,
        difficulty: PracticeDifficulty,
        count: Int = 10,
        userId: String,
        studentGradeLevel: String? = nil
    ) async throws -> [PracticeProblem] {
        isGenerating = true
        generationProgress = 0
        lastError = nil
        defer { isGenerating = false }
        
        print("✨ Generating \(count) \(difficulty.displayName) curriculum-aligned practice problems from worksheet...")
        
        // Get worksheet metadata for context
        let metadata = try await fetchWorksheetMetadata(worksheetId: worksheet.id)
        
        // Extract questions from worksheet
        let questions = try extractQuestionsFromWorksheet(worksheet)
        
        let context = buildWorksheetContext(
            worksheet: worksheet,
            metadata: metadata,
            questions: questions
        )
        
        let concepts = metadata?.topics ?? extractConceptsFromQuestions(questions)
        
        // Determine grade level from metadata or student profile
        let detectedGradeLevel = metadata?.detectedGradeLevel ?? studentGradeLevel ?? "Primary 3"
        let gradeLevelCode = metadata?.detectedGradeLevelCode ??
            CurriculumService.gradeLevelToCode(detectedGradeLevel) ?? "P3"
        
        // Get curriculum codes from metadata or map from concepts
        var curriculumCodes = metadata?.moeCurriculumCodes?.compactMap { $0 } ?? []
        
        if curriculumCodes.isEmpty {
            // Map concepts to curriculum codes
            let mappingResult = try await mappingService.mapWorksheetToCurriculum(
                metadata: metadata ?? createMinimalMetadata(topics: concepts, difficulty: detectedGradeLevel, userId: userId),
                studentGradeLevel: detectedGradeLevel
            )
            curriculumCodes = mappingResult.curriculumCodes
        }
        
        generationProgress = 0.2
        
        let problems = try await generateCurriculumAlignedProblems(
            context: context,
            difficulty: difficulty,
            count: count,
            gradeLevel: detectedGradeLevel,
            gradeLevelCode: gradeLevelCode,
            concepts: concepts,
            curriculumCodes: curriculumCodes,
            sourceWorksheetId: worksheet.id,
            userId: userId
        )
        
        generationProgress = 1.0
        
        print("✅ Generated \(problems.count) curriculum-aligned practice problems")
        return problems
    }
    
    // MARK: - Generate for Concept (Curriculum-Aware)
    
    /// Generate practice problems for a specific concept with curriculum alignment
    func generateForConcept(
        concept: String,
        difficulty: PracticeDifficulty,
        count: Int = 10,
        sourceWorksheetId: String?,
        gradeLevel: String?,
        userId: String
    ) async throws -> [PracticeProblem] {
        isGenerating = true
        generationProgress = 0
        lastError = nil
        defer { isGenerating = false }
        
        print("✨ Generating \(count) \(difficulty.displayName) problems for concept: \(concept)")
        
        let targetGradeLevel = gradeLevel ?? "Primary 3"
        let gradeLevelCode = CurriculumService.gradeLevelToCode(targetGradeLevel) ?? "P3"
        
        // Map concept to curriculum code
        var curriculumCodes: [String] = []
        if let match = try await mappingService.mapConceptToCurriculum(
            concept: concept,
            gradeLevel: targetGradeLevel
        ) {
            curriculumCodes = [match.standard.curriculumCode]
            print("📚 Mapped '\(concept)' to curriculum code: \(match.standard.curriculumCode)")
        }
        
        let context = """
        Generate practice problems focusing on the concept: \(concept)
        These should be problems aligned to the Singapore MOE Primary Mathematics curriculum.
        Target grade level: \(targetGradeLevel)
        """
        
        generationProgress = 0.2
        
        let problems = try await generateCurriculumAlignedProblems(
            context: context,
            difficulty: difficulty,
            count: count,
            gradeLevel: targetGradeLevel,
            gradeLevelCode: gradeLevelCode,
            concepts: [concept],
            curriculumCodes: curriculumCodes,
            sourceWorksheetId: sourceWorksheetId,
            userId: userId
        )
        
        generationProgress = 1.0
        
        print("✅ Generated \(problems.count) practice problems for \(concept)")
        return problems
    }
    
    // MARK: - Generate for Curriculum Code
    
    /// Generate practice problems for specific curriculum codes
    func generateForCurriculumCodes(
        curriculumCodes: [String],
        difficulty: PracticeDifficulty,
        count: Int = 10,
        userId: String
    ) async throws -> [PracticeProblem] {
        isGenerating = true
        generationProgress = 0
        lastError = nil
        defer { isGenerating = false }
        
        print("✨ Generating \(count) problems for curriculum codes: \(curriculumCodes.joined(separator: ", "))")
        
        // Fetch curriculum standards for context
        let standards = try await curriculumService.fetchStandards(byCodes: curriculumCodes)
        
        guard !standards.isEmpty else {
            throw PracticeGenerationError.noConceptsToTarget
        }
        
        // Get grade level from first standard
        let gradeLevel = standards.first?.gradeLevel ?? "Primary 3"
        let gradeLevelCode = standards.first?.gradeLevelCode ?? "P3"
        
        // Build context from standards
        let standardsContext = standards.map { standard in
            """
            - \(standard.curriculumCode): \(standard.topicTitle)
              \(standard.subTopicDescription)
              Keywords: \(standard.keywords.joined(separator: ", "))
            """
        }.joined(separator: "\n")
        
        let context = """
        Generate practice problems for these Singapore MOE curriculum standards:
        
        \(standardsContext)
        
        Ensure problems align precisely to the specified curriculum codes.
        """
        
        let concepts = standards.map { $0.topicTitle }
        
        generationProgress = 0.2
        
        let problems = try await generateCurriculumAlignedProblems(
            context: context,
            difficulty: difficulty,
            count: count,
            gradeLevel: gradeLevel,
            gradeLevelCode: gradeLevelCode,
            concepts: concepts,
            curriculumCodes: curriculumCodes,
            sourceWorksheetId: nil,
            userId: userId
        )
        
        generationProgress = 1.0
        
        print("✅ Generated \(problems.count) curriculum-specific practice problems")
        return problems
    }
    
    // MARK: - Generate for Weak Areas (Curriculum-Aware)
    
    /// Generate practice problems targeting student's weak areas with curriculum alignment
    func generateForWeakAreas(
        studentId: String,
        classroomId: String?,
        count: Int = 10,
        userId: String
    ) async throws -> [PracticeProblem] {
        isGenerating = true
        generationProgress = 0
        lastError = nil
        defer { isGenerating = false }
        
        print("✨ Generating curriculum-aligned practice for weak areas for student: \(studentId)")
        
        // Fetch concept mastery data
        let queryService = AnalyticsQueryService.shared
        let conceptMastery = try await queryService.fetchConceptMastery(
            studentId: studentId,
            classroomId: classroomId
        )
        
        // Filter to weak concepts (< 60% mastery) with curriculum alignment
        let weakConceptsWithCurriculum = conceptMastery
            .filter { $0.masteryPercentage < 60 }
            .sorted { $0.masteryPercentage < $1.masteryPercentage }
            .prefix(5)
        
        guard !weakConceptsWithCurriculum.isEmpty else {
            // No weak areas - generate for developing concepts
            let developingConcepts = conceptMastery
                .filter { $0.masteryPercentage >= 60 && $0.masteryPercentage < 80 }
                .prefix(3)
            
            if developingConcepts.isEmpty {
                throw PracticeGenerationError.noConceptsToTarget
            }
            
            let concepts = developingConcepts.map { $0.concept }
            let codes = developingConcepts.compactMap { $0.curriculumCode }
            let gradeLevel = developingConcepts.first?.gradeLevel ?? "Primary 3"
            
            return try await generateCurriculumAlignedProblems(
                context: "Generate practice for developing concepts: \(concepts.joined(separator: ", "))",
                difficulty: .similar,
                count: count,
                gradeLevel: gradeLevel,
                gradeLevelCode: CurriculumService.gradeLevelToCode(gradeLevel) ?? "P3",
                concepts: concepts,
                curriculumCodes: codes,
                sourceWorksheetId: nil,
                userId: userId
            )
        }
        
        let weakConcepts = weakConceptsWithCurriculum.map { $0.concept }
        let curriculumCodes = weakConceptsWithCurriculum.compactMap { $0.curriculumCode }
        let gradeLevel = weakConceptsWithCurriculum.first?.gradeLevel ?? "Primary 3"
        let gradeLevelCode = CurriculumService.gradeLevelToCode(gradeLevel) ?? "P3"
        
        generationProgress = 0.2
        
        // Recommend easier difficulty for weak areas
        let recommendedDifficulty = PracticeDifficulty.easier
        
        // Check for prerequisite gaps
        var prerequisiteInfo = ""
        for mastery in weakConceptsWithCurriculum {
            if mastery.hasPrerequisiteGaps, let gaps = mastery.prerequisiteGaps {
                let gapCodes = gaps.compactMap { $0 }
                if !gapCodes.isEmpty {
                    prerequisiteInfo += "\n- \(mastery.concept) has prerequisite gaps: \(gapCodes.joined(separator: ", "))"
                }
            }
        }
        
        let context = """
        Generate practice problems to help a student improve in their weak areas.
        The student is struggling with: \(weakConcepts.joined(separator: ", "))
        \(prerequisiteInfo.isEmpty ? "" : "\nPrerequisite considerations:\(prerequisiteInfo)")
        
        Focus on building foundational understanding with clear, accessible problems.
        Include extra hints and detailed step-by-step solutions.
        Use Singapore context (SGD, local items, etc.).
        """
        
        let problems = try await generateCurriculumAlignedProblems(
            context: context,
            difficulty: recommendedDifficulty,
            count: count,
            gradeLevel: gradeLevel,
            gradeLevelCode: gradeLevelCode,
            concepts: Array(weakConcepts),
            curriculumCodes: curriculumCodes,
            sourceWorksheetId: nil,
            userId: userId
        )
        
        generationProgress = 1.0
        
        print("✅ Generated \(problems.count) curriculum-aligned practice problems for weak areas")
        return problems
    }
    
    // MARK: - Generate for Multiple Concepts (Curriculum-Aware)
    
    /// Generate practice problems for multiple concepts with curriculum alignment
    func generateForConcepts(
        concepts: [String],
        difficulty: PracticeDifficulty,
        count: Int = 10,
        gradeLevel: String? = nil,
        userId: String
    ) async throws -> [PracticeProblem] {
        isGenerating = true
        generationProgress = 0
        lastError = nil
        defer { isGenerating = false }
        
        print("✨ Generating \(count) problems for concepts: \(concepts.joined(separator: ", "))")
        
        let targetGradeLevel = gradeLevel ?? "Primary 3"
        let gradeLevelCode = CurriculumService.gradeLevelToCode(targetGradeLevel) ?? "P3"
        
        // Map all concepts to curriculum codes
        var allCurriculumCodes: [String] = []
        for concept in concepts {
            if let match = try await mappingService.mapConceptToCurriculum(
                concept: concept,
                gradeLevel: targetGradeLevel
            ) {
                allCurriculumCodes.append(match.standard.curriculumCode)
            }
        }
        
        let context = """
        Generate a mixed set of practice problems covering these concepts:
        \(concepts.enumerated().map { "- \($0.element)" }.joined(separator: "\n"))
        
        Distribute problems roughly evenly across all concepts.
        Align to Singapore MOE curriculum for \(targetGradeLevel).
        """
        
        generationProgress = 0.2
        
        let problems = try await generateCurriculumAlignedProblems(
            context: context,
            difficulty: difficulty,
            count: count,
            gradeLevel: targetGradeLevel,
            gradeLevelCode: gradeLevelCode,
            concepts: concepts,
            curriculumCodes: allCurriculumCodes,
            sourceWorksheetId: nil,
            userId: userId
        )
        
        generationProgress = 1.0
        return problems
    }
    
    // MARK: - Generate from Error Patterns (Curriculum-Aware)
    
    /// Generate practice problems targeting specific error patterns with curriculum alignment
    func generateForErrorPatterns(
        errorPatterns: [ErrorPattern],
        difficulty: PracticeDifficulty,
        count: Int = 5,
        gradeLevel: String? = nil,
        userId: String
    ) async throws -> [PracticeProblem] {
        isGenerating = true
        generationProgress = 0
        lastError = nil
        defer { isGenerating = false }
        
        print("✨ Generating curriculum-aligned practice for \(errorPatterns.count) error patterns...")
        
        let targetGradeLevel = gradeLevel ?? "Primary 3"
        let gradeLevelCode = CurriculumService.gradeLevelToCode(targetGradeLevel) ?? "P3"
        
        let errorDescriptions = errorPatterns.map { error in
            """
            - Error: \(error.errorType)
              Category: \(error.errorCategory)
              Description: \(error.description)
              Affected Concepts: \(error.affectedConcepts.joined(separator: ", "))
            """
        }.joined(separator: "\n")
        
        let context = """
        Generate practice problems specifically designed to help a student overcome these error patterns:
        
        \(errorDescriptions)
        
        Create problems that:
        1. Target the specific misconceptions causing these errors
        2. Include scaffolding to prevent common mistakes
        3. Build correct understanding step by step
        4. Use Singapore context (SGD, local references)
        """
        
        let concepts = errorPatterns.flatMap { $0.affectedConcepts }
        let uniqueConcepts = Array(Set(concepts))
        
        // Map concepts to curriculum codes
        var curriculumCodes: [String] = []
        for concept in uniqueConcepts {
            if let match = try await mappingService.mapConceptToCurriculum(
                concept: concept,
                gradeLevel: targetGradeLevel
            ) {
                curriculumCodes.append(match.standard.curriculumCode)
            }
        }
        
        generationProgress = 0.2
        
        // Use easier difficulty to help correct errors
        let adjustedDifficulty = difficulty == .harder ? .similar : difficulty
        
        let problems = try await generateCurriculumAlignedProblems(
            context: context,
            difficulty: adjustedDifficulty,
            count: count,
            gradeLevel: targetGradeLevel,
            gradeLevelCode: gradeLevelCode,
            concepts: uniqueConcepts,
            curriculumCodes: curriculumCodes,
            sourceWorksheetId: nil,
            userId: userId
        )
        
        generationProgress = 1.0
        
        print("✅ Generated \(problems.count) error-targeting curriculum-aligned practice problems")
        return problems
    }
    
    // MARK: - Core Curriculum-Aligned Generation Method
    
    private func generateCurriculumAlignedProblems(
        context: String,
        difficulty: PracticeDifficulty,
        count: Int,
        gradeLevel: String,
        gradeLevelCode: String,
        concepts: [String],
        curriculumCodes: [String],
        sourceWorksheetId: String?,
        userId: String
    ) async throws -> [PracticeProblem] {
        guard let client = OpenAIClient() else {
            throw PracticeGenerationError.openAIClientUnavailable
        }
        
        let adjustedGrade = difficulty.adjustedGradeLevel(from: gradeLevel)
        let adjustedGradeCode = CurriculumService.gradeLevelToCode(adjustedGrade) ?? gradeLevelCode
        
        // Call OpenAI API with curriculum-aware prompts
        let generatedProblems = try await client.generateCurriculumAwarePracticeProblems(
            context: context,
            difficulty: difficulty,
            count: count,
            gradeLevel: adjustedGrade,
            gradeLevelCode: adjustedGradeCode,
            concepts: concepts,
            targetCurriculumCodes: curriculumCodes
        )
        
        generationProgress = 0.7
        
        // Validate grade boundaries and convert to PracticeProblem models
        var savedProblems: [PracticeProblem] = []
        
        for (index, generated) in generatedProblems.enumerated() {
            // Validate grade boundary
            let validation = client.validateGradeBoundary(
                problem: generated,
                expectedGradeCode: adjustedGradeCode
            )
            
            if !validation.isValid {
                print("⚠️ Skipping problem due to grade boundary violation: \(validation.reason ?? "unknown")")
                continue
            }
            
            // Create PracticeProblem with curriculum fields
            let problem = PracticeProblem(
                sourceWorksheetId: sourceWorksheetId ?? "concept_based",
                sourceQuestionId: nil,
                userId: userId,
                problemText: generated.problemText,
                answer: generated.answer,
                stepByStep: generated.stepByStep ?? "",
                hints: generated.hints.map { Optional($0) },
                concept: generated.concept,
                difficultyLevel: difficulty.rawValue,
                questionType: generated.questionType,
                generatedFrom: sourceWorksheetId != nil ? "worksheet" : "concept",
                difficultyAdjustment: difficulty.rawValue,
                // Tracking fields
                timesUsed: 0,
                averageScore: nil,
                // Curriculum fields
                curriculumCode: generated.curriculumCode,
                curriculumGradeLevel: generated.curriculumGradeLevel,
                curriculumGradeLevelCode: generated.curriculumGradeLevelCode,
                curriculumStrand: generated.curriculumStrand,
                curriculumSubStrand: generated.curriculumSubStrand,
               
                generatedAt: Temporal.DateTime.now(),
                aiModel: "gpt-4o",
                tokensUsed: nil
            )
            
            do {
                try await Amplify.DataStore.save(problem)
                savedProblems.append(problem)
                generationProgress = 0.7 + (0.3 * Double(index + 1) / Double(generatedProblems.count))
            } catch {
                print("⚠️ Failed to save problem: \(error)")
                // Continue with other problems
            }
        }
        
        return savedProblems
    }
    
    // MARK: - Legacy Generation Method (Non-Curriculum)
    
    /// Generate problems without curriculum alignment (backward compatibility)
    private func generateProblems(
        context: String,
        difficulty: PracticeDifficulty,
        count: Int,
        gradeLevel: String,
        concepts: [String],
        sourceWorksheetId: String?,
        userId: String
    ) async throws -> [PracticeProblem] {
        guard let client = OpenAIClient() else {
            throw PracticeGenerationError.openAIClientUnavailable
        }
        
        let adjustedGrade = difficulty.adjustedGradeLevel(from: gradeLevel)
        
        // Call legacy OpenAI API
        let generatedProblems = try await client.generatePracticeProblems(
            context: context,
            difficulty: difficulty,
            count: count,
            gradeLevel: adjustedGrade,
            concepts: concepts
        )
        
        generationProgress = 0.7
        
        // Convert to PracticeProblem models and save
        var savedProblems: [PracticeProblem] = []
        
        for (index, generated) in generatedProblems.enumerated() {
            let problem = PracticeProblem(
                sourceWorksheetId: sourceWorksheetId ?? "concept_based",
                sourceQuestionId: nil,
                userId: userId,
                problemText: generated.problemText,
                answer: generated.answer,
                stepByStep: generated.stepByStep,
                hints: generated.hints.map { Optional($0) },
                concept: generated.concept,
                difficultyLevel: difficulty.rawValue,
                questionType: generated.questionType,
                generatedFrom: sourceWorksheetId != nil ? "worksheet" : "concept",
                difficultyAdjustment: difficulty.rawValue,
                timesUsed: 0,
                averageScore: nil,
                generatedAt: Temporal.DateTime.now(),
                aiModel: "gpt-4o",
                tokensUsed: nil
            )
            
            do {
                try await Amplify.DataStore.save(problem)
                savedProblems.append(problem)
                generationProgress = 0.7 + (0.3 * Double(index + 1) / Double(generatedProblems.count))
            } catch {
                print("⚠️ Failed to save problem: \(error)")
            }
        }
        
        return savedProblems
    }
    
    // MARK: - Helper Methods
    
    private func fetchWorksheetMetadata(worksheetId: String) async throws -> WorksheetMetadata? {
        let allMetadata = try await Amplify.DataStore.query(WorksheetMetadata.self)
        return allMetadata.first { $0.worksheet?.id == worksheetId }
    }
    
    private func extractQuestionsFromWorksheet(_ worksheet: Worksheet) throws -> [ExtractedQuestion] {
        guard let extractionData = worksheet.extractionResult?.data(using: .utf8),
              let extracted = try? JSONDecoder().decode(ExtractedWorksheet.self, from: extractionData) else {
            return []
        }
        return extracted.questions
    }
    
    private func buildWorksheetContext(
        worksheet: Worksheet,
        metadata: WorksheetMetadata?,
        questions: [ExtractedQuestion]
    ) -> String {
        var context = """
        Base this practice on the following worksheet:
        Title: \(worksheet.title)
        
        """
        
        if let meta = metadata {
            context += """
            Topics: \(meta.topics.joined(separator: ", "))
            Difficulty: \(meta.difficulty)
            Complexity: \(meta.complexityLevel ?? "Medium")
            Question Types: \(meta.questionTypes.joined(separator: ", "))
            """
            
            // Add curriculum info if available
            if let codes = meta.moeCurriculumCodes, !codes.isEmpty {
                let validCodes = codes.compactMap { $0 }
                context += "\nCurriculum Codes: \(validCodes.joined(separator: ", "))"
            }
            if let strand = meta.curriculumStrand {
                context += "\nStrand: \(strand)"
            }
            if let subStrand = meta.curriculumSubStrand {
                context += "\nSub-strand: \(subStrand)"
            }
            
            context += "\n\n"
        }
        
        if !questions.isEmpty {
            context += "Sample questions from worksheet:\n"
            for (index, question) in questions.prefix(5).enumerated() {
                context += "\(index + 1). \(question.questionText)\n"
                if !question.skillsTested.isEmpty {
                    context += "   Skills: \(question.skillsTested.joined(separator: ", "))\n"
                }
            }
        }
        
        return context
    }
    
    private func extractConceptsFromQuestions(_ questions: [ExtractedQuestion]) -> [String] {
        let allSkills = questions.flatMap { $0.skillsTested }
        return Array(Set(allSkills))
    }
    
    private func createMinimalMetadata(topics: [String], difficulty: String, userId: String) -> WorksheetMetadata {
        return WorksheetMetadata(
            userId: userId,
            topics: topics,
            difficulty: difficulty,
            cognitiveSkills: [],
            questionTypes: [],
            extractedAt: .now(),
            aiModel: "gpt-4o"
        )
    }
    
    // MARK: - Fetch Existing Problems
    
    /// Fetch previously generated problems for potential reuse
    func fetchExistingProblems(
        concept: String,
        difficulty: PracticeDifficulty,
        limit: Int = 10
    ) async throws -> [PracticeProblem] {
        let allProblems = try await Amplify.DataStore.query(PracticeProblem.self)
        
        return allProblems
            .filter { $0.concept == concept && $0.difficultyLevel == difficulty.rawValue }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Fetch problems by curriculum code
    func fetchProblemsForCurriculumCode(
        curriculumCode: String,
        limit: Int = 10
    ) async throws -> [PracticeProblem] {
        let allProblems = try await Amplify.DataStore.query(PracticeProblem.self)
        
        return allProblems
            .filter { $0.curriculumCode == curriculumCode }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Check if we have enough cached problems to avoid regeneration
    func hasCachedProblems(
        concept: String,
        difficulty: PracticeDifficulty,
        minCount: Int
    ) async -> Bool {
        do {
            let existing = try await fetchExistingProblems(
                concept: concept,
                difficulty: difficulty,
                limit: minCount
            )
            return existing.count >= minCount
        } catch {
            return false
        }
    }
    
    /// Check if we have cached problems for a curriculum code
    func hasCachedProblemsForCurriculum(
        curriculumCode: String,
        minCount: Int
    ) async -> Bool {
        do {
            let existing = try await fetchProblemsForCurriculumCode(
                curriculumCode: curriculumCode,
                limit: minCount
            )
            return existing.count >= minCount
        } catch {
            return false
        }
    }
}

// MARK: - Generated Problem Response

struct GeneratedProblemResponse: Codable {
    let problemText: String
    let answer: String
    let stepByStep: String
    let hints: [String]
    let concept: String
    let questionType: String
    
    enum CodingKeys: String, CodingKey {
        case problemText = "problem_text"
        case answer
        case stepByStep = "step_by_step"
        case hints
        case concept
        case questionType = "question_type"
    }
}

// MARK: - Errors

enum PracticeGenerationError: LocalizedError {
    case openAIClientUnavailable
    case generationFailed(String)
    case noConceptsToTarget
    case parsingFailed
    case saveFailed
    case gradeBoundaryViolation(String)
    
    var errorDescription: String? {
        switch self {
        case .openAIClientUnavailable:
            return "AI service is not available. Please check your connection."
        case .generationFailed(let reason):
            return "Failed to generate practice problems: \(reason)"
        case .noConceptsToTarget:
            return "No concepts found to generate practice for."
        case .parsingFailed:
            return "Failed to parse generated problems."
        case .saveFailed:
            return "Failed to save generated problems."
        case .gradeBoundaryViolation(let reason):
            return "Grade boundary violation: \(reason)"
        }
    }
}
