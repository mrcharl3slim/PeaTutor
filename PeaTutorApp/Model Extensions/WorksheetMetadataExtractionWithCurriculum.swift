//
//  WorksheetMetadataExtraction+Curriculum.swift
//  PeaTutorApp
//
//  Sprint 8 Phase 2: Enhanced Worksheet Metadata with Curriculum Alignment
//  Extends WorksheetMetadataExtraction to include MOE curriculum mapping
//

import Foundation
import Amplify

// MARK: - Enhanced AI Extraction Result with Curriculum

/// Extended extraction result that includes MOE curriculum alignment
public struct WorksheetMetadataExtractionWithCurriculum: Codable {
    // Existing fields
    public var topics: [String]
    public var difficulty: String
    public var cognitiveSkills: [String]
    public var questionTypes: [String]
    public var estimatedTimeMinutes: Int?
    public var complexityLevel: String?
    public var commonCoreStandards: [String]?
    public var bloomsTaxonomyLevels: [String]?
    public var aiModel: String?
    public var tokensUsed: Int?
    
    // NEW: MOE Curriculum fields
    public var curriculumCountry: String?
    public var curriculumVersion: String?
    public var moeCurriculumCodes: [String]?
    public var detectedGradeLevel: String?
    public var detectedGradeLevelCode: String?
    public var curriculumStrand: String?
    public var curriculumSubStrand: String?
    public var curriculumConfidence: Double?
    
    enum CodingKeys: String, CodingKey {
        case topics
        case difficulty
        case cognitiveSkills = "cognitive_skills"
        case questionTypes = "question_types"
        case estimatedTimeMinutes = "estimated_time_minutes"
        case complexityLevel = "complexity_level"
        case commonCoreStandards = "common_core_standards"
        case bloomsTaxonomyLevels = "blooms_taxonomy_levels"
        case aiModel = "ai_model"
        case tokensUsed = "tokens_used"
        // Curriculum fields
        case curriculumCountry = "curriculum_country"
        case curriculumVersion = "curriculum_version"
        case moeCurriculumCodes = "moe_curriculum_codes"
        case detectedGradeLevel = "detected_grade_level"
        case detectedGradeLevelCode = "detected_grade_level_code"
        case curriculumStrand = "curriculum_strand"
        case curriculumSubStrand = "curriculum_sub_strand"
        case curriculumConfidence = "curriculum_confidence"
    }
    
    /// Convert from basic extraction (for backward compatibility)
    public init(from basic: WorksheetMetadataExtraction) {
        self.topics = basic.topics
        self.difficulty = basic.difficulty
        self.cognitiveSkills = basic.cognitiveSkills
        self.questionTypes = basic.questionTypes
        self.estimatedTimeMinutes = basic.estimatedTimeMinutes
        self.complexityLevel = basic.complexityLevel
        self.commonCoreStandards = basic.commonCoreStandards
        self.bloomsTaxonomyLevels = basic.bloomsTaxonomyLevels
        self.aiModel = basic.aiModel
        self.tokensUsed = basic.tokensUsed
        
        // Curriculum fields default to nil
        self.curriculumCountry = nil
        self.curriculumVersion = nil
        self.moeCurriculumCodes = nil
        self.detectedGradeLevel = nil
        self.detectedGradeLevelCode = nil
        self.curriculumStrand = nil
        self.curriculumSubStrand = nil
        self.curriculumConfidence = nil
    }
}

// MARK: - WorksheetMetadata Curriculum Extensions

extension WorksheetMetadata {
    
    /// Check if this metadata has curriculum alignment
    public var hasCurriculumAlignment: Bool {
        // Check the AI-extracted topics against known curriculum patterns
        // This is a computed property that works with existing data
        return moeCurriculumCodes?.isEmpty == false || curriculumCountry != nil
    }
    
    /// Get the primary curriculum code (first in the list)
    public var primaryCurriculumCode: String? {
        return moeCurriculumCodes?.compactMap { $0 }.first
    }
    
    /// Check if curriculum mapping is high confidence (>0.7)
    public var isHighConfidenceCurriculumMapping: Bool {
        guard let confidence = curriculumConfidence else { return false }
        return confidence >= 0.7
    }
    
    /// Get curriculum alignment summary for display
    public var curriculumAlignmentSummary: String? {
        guard let codes = moeCurriculumCodes, !codes.isEmpty else {
            return nil
        }
        
        var parts: [String] = []
        
        if let grade = detectedGradeLevel {
            parts.append(grade)
        }
        
        if let strand = curriculumStrand {
            parts.append(strand)
        }
        
        if let subStrand = curriculumSubStrand {
            parts.append(subStrand)
        }
        
        if parts.isEmpty {
            return "Aligned to \(codes.count) curriculum standard(s)"
        }
        
        return parts.joined(separator: " • ")
    }
    
    /// Get formatted curriculum codes for display
    public var formattedCurriculumCodes: String? {
        guard let codes = moeCurriculumCodes, !codes.isEmpty else {
            return nil
        }
        return codes.compactMap { $0 }.joined(separator: ", ")
    }
    
    /// Confidence level as descriptive text
    public var curriculumConfidenceLevel: String {
        guard let confidence = curriculumConfidence else {
            return "Not mapped"
        }
        
        switch confidence {
        case 0.8...1.0:
            return "High confidence"
        case 0.6..<0.8:
            return "Medium confidence"
        case 0.4..<0.6:
            return "Low confidence"
        default:
            return "Very low confidence"
        }
    }
    
    /// Confidence emoji for UI
    public var curriculumConfidenceEmoji: String {
        guard let confidence = curriculumConfidence else {
            return "❓"
        }
        
        switch confidence {
        case 0.8...1.0:
            return "✅"
        case 0.6..<0.8:
            return "🟡"
        case 0.4..<0.6:
            return "🟠"
        default:
            return "🔴"
        }
    }
}

// MARK: - Curriculum-Enhanced Factory Method

extension WorksheetMetadata {
    
    /// Create metadata from AI extraction result WITH curriculum alignment
    public static func fromWithCurriculum(
        userId: String,
        aiResult: WorksheetMetadataExtractionWithCurriculum,
        worksheet: Worksheet? = nil
    ) -> WorksheetMetadata {
        return WorksheetMetadata(
            userId: userId,
            topics: aiResult.topics,
            difficulty: aiResult.difficulty,
            cognitiveSkills: aiResult.cognitiveSkills,
            questionTypes: aiResult.questionTypes,
            estimatedTimeMinutes: aiResult.estimatedTimeMinutes,
            complexityLevel: aiResult.complexityLevel,
            commonCoreStandards: aiResult.commonCoreStandards?.compactMap { $0 },
            bloomsTaxonomyLevels: aiResult.bloomsTaxonomyLevels?.compactMap { $0 },
            // Relationship and metadata
            worksheet: worksheet,

            // Curriculum fields
            curriculumCountry: aiResult.curriculumCountry,
            curriculumVersion: aiResult.curriculumVersion,
            moeCurriculumCodes: aiResult.moeCurriculumCodes,
            detectedGradeLevel: aiResult.detectedGradeLevel,
            detectedGradeLevelCode: aiResult.detectedGradeLevelCode,
            curriculumStrand: aiResult.curriculumStrand,
            curriculumSubStrand: aiResult.curriculumSubStrand,
            curriculumConfidence: aiResult.curriculumConfidence,
            curriculumMappedAt: aiResult.moeCurriculumCodes != nil ? .now() : nil,
            
            extractedAt: .now(),
            aiModel: aiResult.aiModel ?? "gpt-4o",
            tokensUsed: aiResult.tokensUsed
        )
    }
    
}

// MARK: - Array Extensions for Curriculum Filtering

extension Array where Element == WorksheetMetadata {
    
    /// Filter metadata that has curriculum alignment
    public func withCurriculumAlignment() -> [WorksheetMetadata] {
        return filter { $0.hasCurriculumAlignment }
    }
    
    /// Filter by curriculum grade level
    public func forCurriculumGrade(_ gradeLevel: String) -> [WorksheetMetadata] {
        return filter { $0.detectedGradeLevel == gradeLevel }
    }
    
    /// Filter by curriculum grade code
    public func forCurriculumGradeCode(_ code: String) -> [WorksheetMetadata] {
        return filter { $0.detectedGradeLevelCode == code }
    }
    
    /// Filter by curriculum strand
    public func forCurriculumStrand(_ strand: String) -> [WorksheetMetadata] {
        return filter { $0.curriculumStrand == strand }
    }
    
    /// Filter by curriculum sub-strand
    public func forCurriculumSubStrand(_ subStrand: String) -> [WorksheetMetadata] {
        return filter { $0.curriculumSubStrand == subStrand }
    }
    
    /// Filter by curriculum code (any match)
    public func containingCurriculumCode(_ code: String) -> [WorksheetMetadata] {
        return filter { $0.moeCurriculumCodes?.contains(code) == true }
    }
    
    /// Filter by high confidence curriculum mapping
    public func highConfidenceCurriculumOnly() -> [WorksheetMetadata] {
        return filter { $0.isHighConfidenceCurriculumMapping }
    }
    
    /// Group by detected grade level
    public func groupedByCurriculumGrade() -> [String: [WorksheetMetadata]] {
        var grouped: [String: [WorksheetMetadata]] = [:]
        
        for metadata in self {
            let grade = metadata.detectedGradeLevel ?? "Unknown"
            grouped[grade, default: []].append(metadata)
        }
        
        return grouped
    }
    
    /// Group by curriculum strand
    public func groupedByCurriculumStrand() -> [String: [WorksheetMetadata]] {
        var grouped: [String: [WorksheetMetadata]] = [:]
        
        for metadata in self {
            let strand = metadata.curriculumStrand ?? "Unknown"
            grouped[strand, default: []].append(metadata)
        }
        
        return grouped
    }
    
    /// Get all unique curriculum codes across all metadata
    public func allCurriculumCodes() -> [String] {
        var codes = Set<String>()
        
        for metadata in self {
            if let metadataCodes = metadata.moeCurriculumCodes {
                codes.formUnion(metadataCodes.compactMap { $0 })
            }
        }
        
        return codes.sorted()
    }
}

// MARK: - Note: Schema Property Placeholders

// The following properties need to be added to the base WorksheetMetadata model
// These are placeholders showing what fields are expected after schema update

/*
 After running `amplify codegen models` with the updated schema,
 the WorksheetMetadata model should have these additional properties:
 
 public var curriculumCountry: String?
 public var curriculumVersion: String?
 public var moeCurriculumCodes: [String?]?
 public var detectedGradeLevel: String?
 public var detectedGradeLevelCode: String?
 public var curriculumStrand: String?
 public var curriculumSubStrand: String?
 public var curriculumConfidence: Double?
 public var curriculumMappedAt: Temporal.DateTime?
 */
