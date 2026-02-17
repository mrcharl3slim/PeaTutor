//
//  CurriculumMappingService.swift
//  PeaTutorApp
//
//  Sprint 8 Phase 2: Curriculum Mapping Service
//  Maps AI-extracted topics and concepts to official MOE curriculum codes
//

import Foundation
import Amplify

// MARK: - CurriculumMappingService

@MainActor
class CurriculumMappingService: ObservableObject {
    static let shared = CurriculumMappingService()
    
    @Published var isMapping = false
    @Published var lastError: String?
    
    private let curriculumService = CurriculumService.shared
    
    private init() {}
    
    // MARK: - Map Worksheet Metadata to Curriculum
    
    /// Map extracted worksheet topics to MOE curriculum codes
    /// Returns updated metadata with curriculum alignment
    func mapWorksheetToCurriculum(
        metadata: WorksheetMetadata,
        studentGradeLevel: String? = nil
    ) async throws -> CurriculumMappingResult {
        isMapping = true
        defer { isMapping = false }
        
        print("📚 Mapping worksheet to curriculum...")
        
        // Extract keywords from topics
        let keywords = extractKeywordsFromTopics(metadata.topics)
        
        // Determine target grade level
        let targetGrade = studentGradeLevel ?? detectGradeFromDifficulty(metadata.difficulty)
        
        // Find matching curriculum standards
        let matches = try await curriculumService.mapTopicsToCurriculum(
            extractedTopics: keywords,
            gradeLevel: targetGrade,
            limit: 10
        )
        
        guard !matches.isEmpty else {
            return CurriculumMappingResult(
                curriculumCodes: [],
                detectedGradeLevel: targetGrade,
                detectedGradeLevelCode: CurriculumService.gradeLevelToCode(targetGrade ?? ""),
                primaryStrand: nil,
                primarySubStrand: nil,
                confidence: 0.0,
                matchedStandards: []
            )
        }
        
        // Get the best matches
        let topMatches = matches.prefix(5)
        let codes = topMatches.map { $0.standard.curriculumCode }
        let averageConfidence = topMatches.reduce(0.0) { $0 + $1.confidence } / Double(topMatches.count)
        
        // Determine primary strand and sub-strand from top match
        let topMatch = matches.first?.standard
        
        let result = CurriculumMappingResult(
            curriculumCodes: codes,
            detectedGradeLevel: topMatch?.gradeLevel ?? targetGrade,
            detectedGradeLevelCode: topMatch?.gradeLevelCode ?? CurriculumService.gradeLevelToCode(targetGrade ?? ""),
            primaryStrand: topMatch?.strand,
            primarySubStrand: topMatch?.subStrand,
            confidence: averageConfidence,
            matchedStandards: matches.map { CurriculumMatch(standard: $0.standard, confidence: $0.confidence) }
        )
        
        print("✅ Mapped to \(codes.count) curriculum codes with \(Int(averageConfidence * 100))% confidence")
        return result
    }
    
    /// Map a concept name to curriculum code
    func mapConceptToCurriculum(
        concept: String,
        gradeLevel: String? = nil
    ) async throws -> CurriculumMatch? {
        let keywords = extractKeywordsFromTopics([concept])
        
        let matches = try await curriculumService.mapTopicsToCurriculum(
            extractedTopics: keywords,
            gradeLevel: gradeLevel,
            limit: 1
        )
        
        guard let topMatch = matches.first else {
            return nil
        }
        
        return CurriculumMatch(
            standard: topMatch.standard,
            confidence: topMatch.confidence
        )
    }
    
    // MARK: - Update Models with Curriculum Mapping
    
    /// Update WorksheetMetadata with curriculum mapping
    func updateMetadataWithCurriculum(
        metadata: WorksheetMetadata,
        studentGradeLevel: String? = nil
    ) async throws -> WorksheetMetadata {
        let mapping = try await mapWorksheetToCurriculum(
            metadata: metadata,
            studentGradeLevel: studentGradeLevel
        )
        
        return metadata.withCurriculumMapping(
            codes: mapping.curriculumCodes,
            gradeLevel: mapping.detectedGradeLevel,
            gradeLevelCode: mapping.detectedGradeLevelCode,
            strand: mapping.primaryStrand,
            subStrand: mapping.primarySubStrand,
            confidence: mapping.confidence
        )
    }
    
    /// Update ConceptMastery with curriculum alignment
    func updateMasteryWithCurriculum(
        mastery: ConceptMastery
    ) async throws -> ConceptMastery {
        // Try to map the concept to curriculum
        guard let match = try await mapConceptToCurriculum(
            concept: mastery.concept,
            gradeLevel: mastery.gradeLevel
        ) else {
            return mastery
        }
        
        // Check prerequisites
        let prerequisites = try await curriculumService.findPrerequisites(
            for: match.standard.curriculumCode
        )
        
        // Determine if prerequisites are mastered (simplified - check if we have records)
        let prereqGaps = try await findPrerequisiteGaps(
            studentId: mastery.studentId,
            classroomId: mastery.classroomId,
            prerequisites: prerequisites
        )
        
        return mastery.withCurriculumAlignment(
            curriculumCode: match.standard.curriculumCode,
            strand: match.standard.strand,
            subStrand: match.standard.subStrand,
            topicTitle: match.standard.topicTitle,
            prerequisitesMastered: prereqGaps.isEmpty,
            prerequisiteGaps: prereqGaps
        )
    }
    
    // MARK: - Prerequisite Analysis
    
    /// Find prerequisite gaps for a student
    func findPrerequisiteGaps(
        studentId: String,
        classroomId: String?,
        prerequisites: [CurriculumStandard]
    ) async throws -> [String] {
        guard !prerequisites.isEmpty else { return [] }
        
        // Get student's existing mastery records
        let allMastery = try await Amplify.DataStore.query(ConceptMastery.self)
        let studentMastery = allMastery.filter { mastery in
            mastery.studentId == studentId &&
            (classroomId == nil || mastery.classroomId == classroomId)
        }
        
        // Get curriculum codes that student has mastered (80%+)
        let masteredCodes = Set(
            studentMastery
                .filter { $0.masteryPercentage >= 80 }
                .compactMap { $0.curriculumCode }
        )
        
        // Find prerequisites that are not mastered
        var gaps: [String] = []
        for prereq in prerequisites {
            if !masteredCodes.contains(prereq.curriculumCode) {
                gaps.append(prereq.curriculumCode)
            }
        }
        
        return gaps
    }
    
    /// Get recommended curriculum path for a student
    func getRecommendedPath(
        studentId: String,
        classroomId: String?,
        targetGradeLevel: String
    ) async throws -> CurriculumRecommendation {
        // Get all standards for the target grade
        let targetStandards = try await curriculumService.fetchStandards(forGrade: targetGradeLevel)
        
        // Get student's current mastery
        let allMastery = try await Amplify.DataStore.query(ConceptMastery.self)
        let studentMastery = allMastery.filter { mastery in
            mastery.studentId == studentId &&
            (classroomId == nil || mastery.classroomId == classroomId)
        }
        
        // Categorize standards
        var mastered: [CurriculumStandard] = []
        var inProgress: [CurriculumStandard] = []
        var notStarted: [CurriculumStandard] = []
        var hasPrerequisiteGaps: [CurriculumStandard] = []
        
        let masteryByCode = Dictionary(
            studentMastery.compactMap { m -> (String, ConceptMastery)? in
                guard let code = m.curriculumCode else { return nil }
                return (code, m)
            },
            uniquingKeysWith: { first, _ in first }
        )
        
        for standard in targetStandards {
            if let mastery = masteryByCode[standard.curriculumCode] {
                if mastery.masteryPercentage >= 80 {
                    mastered.append(standard)
                } else {
                    inProgress.append(standard)
                }
            } else {
                // Check if prerequisites are met
                let prereqCodes = standard.prerequisiteCodesClean
                if !prereqCodes.isEmpty {
                    let prereqsMet = prereqCodes.allSatisfy { code in
                        masteryByCode[code]?.masteryPercentage ?? 0 >= 80
                    }
                    if !prereqsMet {
                        hasPrerequisiteGaps.append(standard)
                    } else {
                        notStarted.append(standard)
                    }
                } else {
                    notStarted.append(standard)
                }
            }
        }
        
        // Recommend next topics (standards with prerequisites met, not yet started)
        let recommended = notStarted.sortedBySequence().prefix(5)
        
        return CurriculumRecommendation(
            targetGradeLevel: targetGradeLevel,
            totalStandards: targetStandards.count,
            masteredCount: mastered.count,
            inProgressCount: inProgress.count,
            notStartedCount: notStarted.count,
            prerequisiteGapCount: hasPrerequisiteGaps.count,
            masteredStandards: mastered,
            inProgressStandards: inProgress,
            recommendedNextStandards: Array(recommended),
            standardsWithPrerequisiteGaps: hasPrerequisiteGaps
        )
    }
    
    // MARK: - Helper Methods
    
    /// Extract keywords from topic names for matching
    private func extractKeywordsFromTopics(_ topics: [String]) -> [String] {
        var keywords: [String] = []
        
        for topic in topics {
            // Split by common separators and add individual words
            let words = topic
                .lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty && $0.count > 2 }
            
            keywords.append(contentsOf: words)
            
            // Also add the full topic as a phrase
            keywords.append(topic.lowercased())
        }
        
        return keywords
    }
    
    /// Detect grade level from difficulty string
    private func detectGradeFromDifficulty(_ difficulty: String) -> String? {
        let lowercased = difficulty.lowercased()
        
        // Check for explicit grade mentions
        if lowercased.contains("primary 1") || lowercased.contains("p1") || lowercased.contains("grade 1") {
            return "Primary 1"
        }
        if lowercased.contains("primary 2") || lowercased.contains("p2") || lowercased.contains("grade 2") {
            return "Primary 2"
        }
        if lowercased.contains("primary 3") || lowercased.contains("p3") || lowercased.contains("grade 3") {
            return "Primary 3"
        }
        if lowercased.contains("primary 4") || lowercased.contains("p4") || lowercased.contains("grade 4") {
            return "Primary 4"
        }
        if lowercased.contains("primary 5") || lowercased.contains("p5") || lowercased.contains("grade 5") {
            return "Primary 5"
        }
        if lowercased.contains("primary 6") || lowercased.contains("p6") || lowercased.contains("grade 6") {
            return "Primary 6"
        }
        
        return nil
    }
}

// MARK: - Supporting Types

public struct CurriculumMappingResult {
    public let curriculumCodes: [String]
    public let detectedGradeLevel: String?
    public let detectedGradeLevelCode: String?
    public let primaryStrand: String?
    public let primarySubStrand: String?
    public let confidence: Double
    public let matchedStandards: [CurriculumMatch]
    
    public var hasMappings: Bool {
        return !curriculumCodes.isEmpty
    }
    
    public var confidenceLevel: String {
        switch confidence {
        case 0.8...1.0: return "High"
        case 0.6..<0.8: return "Medium"
        case 0.4..<0.6: return "Low"
        default: return "Very Low"
        }
    }
}

public struct CurriculumMatch {
    public let standard: CurriculumStandard
    public let confidence: Double
    
    public var confidencePercentage: Int {
        return Int(confidence * 100)
    }
}

public struct CurriculumRecommendation {
    public let targetGradeLevel: String
    public let totalStandards: Int
    public let masteredCount: Int
    public let inProgressCount: Int
    public let notStartedCount: Int
    public let prerequisiteGapCount: Int
    
    public let masteredStandards: [CurriculumStandard]
    public let inProgressStandards: [CurriculumStandard]
    public let recommendedNextStandards: [CurriculumStandard]
    public let standardsWithPrerequisiteGaps: [CurriculumStandard]
    
    // Computed properties
    
    public var coveragePercentage: Double {
        guard totalStandards > 0 else { return 0 }
        return Double(masteredCount + inProgressCount) / Double(totalStandards) * 100
    }
    
    public var masteryPercentage: Double {
        guard totalStandards > 0 else { return 0 }
        return Double(masteredCount) / Double(totalStandards) * 100
    }
    
    public var hasRecommendations: Bool {
        return !recommendedNextStandards.isEmpty
    }
    
    public var summary: String {
        return "\(masteredCount)/\(totalStandards) standards mastered (\(Int(masteryPercentage))%)"
    }
}

// MARK: - Batch Operations

extension CurriculumMappingService {
    
    /// Map multiple worksheets to curriculum in batch
    func batchMapWorksheetsToCurriculum(
        metadataList: [WorksheetMetadata],
        studentGradeLevel: String? = nil
    ) async throws -> [(metadata: WorksheetMetadata, result: CurriculumMappingResult)] {
        var results: [(WorksheetMetadata, CurriculumMappingResult)] = []
        
        for metadata in metadataList {
            let result = try await mapWorksheetToCurriculum(
                metadata: metadata,
                studentGradeLevel: studentGradeLevel
            )
            results.append((metadata, result))
        }
        
        return results
    }
    
    /// Update all concept mastery records with curriculum alignment
    func batchUpdateMasteryWithCurriculum(
        studentId: String,
        classroomId: String?
    ) async throws -> Int {
        // Get all mastery records for student
        let allMastery = try await Amplify.DataStore.query(ConceptMastery.self)
        let studentMastery = allMastery.filter { mastery in
            mastery.studentId == studentId &&
            (classroomId == nil || mastery.classroomId == classroomId) &&
            mastery.curriculumCode == nil // Only update unmapped records
        }
        
        var updatedCount = 0
        
        for mastery in studentMastery {
            do {
                let updated = try await updateMasteryWithCurriculum(mastery: mastery)
                if updated.curriculumCode != nil {
                    try await Amplify.DataStore.save(updated)
                    updatedCount += 1
                }
            } catch {
                print("⚠️ Failed to update mastery \(mastery.id): \(error)")
            }
        }
        
        print("✅ Updated \(updatedCount) mastery records with curriculum alignment")
        return updatedCount
    }
}
