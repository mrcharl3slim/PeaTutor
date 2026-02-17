//
//  WorksheetMetadata+Extensions.swift
//  PeaTutorApp
//
//  Sprint 7.1: Deep Worksheet Analytics Engine
//  Convenience methods for WorksheetMetadata
//

import Foundation
import Amplify

// MARK: - AI Extraction Result (temporary struct for API response)

public struct WorksheetMetadataExtraction: Codable {
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
    }
}

// MARK: - Convenience Initializers

extension WorksheetMetadata {
    /// Create metadata from AI extraction result
    /// Note: worksheet parameter establishes the worksheetId relationship
    public static func from(
        userId: String,
        aiResult: WorksheetMetadataExtraction,
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
            worksheet: worksheet,
            extractedAt: .now(),
            aiModel: aiResult.aiModel ?? "gpt-4o",
            tokensUsed: aiResult.tokensUsed
        )
    }
}

// MARK: - Computed Properties

extension WorksheetMetadata {
    /// Primary topic from the topics array
    public var primaryTopic: String {
        return topics.first ?? "General"
    }
    
    /// Formatted difficulty level for display
    public var difficultyDisplayText: String {
        return difficulty
    }
    
    /// Formatted estimated time for display
    public var estimatedTimeDisplayText: String {
        guard let minutes = estimatedTimeMinutes else {
            return "Not estimated"
        }
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hr"
            } else {
                return "\(hours) hr \(remainingMinutes) min"
            }
        }
    }
    
    /// Complexity emoji indicator
    public var complexityEmoji: String {
        switch complexityLevel?.lowercased() {
        case "easy": return "🟢"
        case "medium": return "🟡"
        case "hard": return "🟠"
        case "very hard": return "🔴"
        default: return "⚪️"
        }
    }
    
    /// Has standards alignment data
    public var hasStandardsAlignment: Bool {
        return (commonCoreStandards?.isEmpty == false) || (bloomsTaxonomyLevels?.isEmpty == false)
    }
}

// MARK: - Validation

extension WorksheetMetadata {
    /// Validate metadata completeness
    public var isComplete: Bool {
        return !topics.isEmpty &&
               !difficulty.isEmpty &&
               !cognitiveSkills.isEmpty &&
               !questionTypes.isEmpty
    }
    
    /// Get missing required fields
    public var missingFields: [String] {
        var missing: [String] = []
        
        if topics.isEmpty {
            missing.append("topics")
        }
        if difficulty.isEmpty {
            missing.append("difficulty")
        }
        if cognitiveSkills.isEmpty {
            missing.append("cognitiveSkills")
        }
        if questionTypes.isEmpty {
            missing.append("questionTypes")
        }
        
        return missing
    }
}

// MARK: - Display Helpers

extension WorksheetMetadata {
    /// Summary text for the metadata
    public var summaryText: String {
        let topicsText = topics.joined(separator: ", ")
        let time = estimatedTimeDisplayText
        let complexity = complexityLevel ?? "Unknown complexity"
        
        return "\(topicsText) • \(difficulty) • \(complexity) • ~\(time)"
    }
    
    /// Detailed description
    public var detailedDescription: String {
        var parts: [String] = []
        
        parts.append("Topics: \(topics.joined(separator: ", "))")
        parts.append("Difficulty: \(difficulty)")
        parts.append("Cognitive Skills: \(cognitiveSkills.joined(separator: ", "))")
        parts.append("Question Types: \(questionTypes.joined(separator: ", "))")
        
        if let time = estimatedTimeMinutes {
            parts.append("Estimated Time: \(estimatedTimeDisplayText)")
        }
        
        if let complexity = complexityLevel {
            parts.append("Complexity: \(complexity)")
        }
        
        if let standards = commonCoreStandards, !standards.isEmpty {
            let validStandards = standards.compactMap { $0 }
            if !validStandards.isEmpty {
                parts.append("Common Core: \(validStandards.joined(separator: ", "))")
            }
        }
        
        if let blooms = bloomsTaxonomyLevels, !blooms.isEmpty {
            let validBlooms = blooms.compactMap { $0 }
            if !validBlooms.isEmpty {
                parts.append("Bloom's Taxonomy: \(validBlooms.joined(separator: ", "))")
            }
        }
        
        return parts.joined(separator: "\n")
    }
}

// MARK: - Filtering Helpers

extension WorksheetMetadata {
    /// Check if metadata matches a topic
    public func matchesTopic(_ topic: String) -> Bool {
        return topics.contains { $0.localizedCaseInsensitiveContains(topic) }
    }
    
    /// Check if metadata matches a difficulty level
    public func matchesDifficulty(_ difficultyLevel: String) -> Bool {
        return difficulty.localizedCaseInsensitiveContains(difficultyLevel)
    }
    
    /// Check if metadata matches a complexity level
    public func matchesComplexity(_ complexity: String) -> Bool {
        guard let level = complexityLevel else { return false }
        return level.localizedCaseInsensitiveContains(complexity)
    }
    
    /// Check if estimated time is within range (in minutes)
    public func isWithinTimeRange(min: Int?, max: Int?) -> Bool {
        guard let time = estimatedTimeMinutes else { return false }
        
        if let minTime = min, time < minTime {
            return false
        }
        if let maxTime = max, time > maxTime {
            return false
        }
        
        return true
    }
}

// MARK: - Array Extensions

extension Array where Element == WorksheetMetadata {
    /// Group metadata by topic
    public func groupedByTopic() -> [String: [WorksheetMetadata]] {
        var grouped: [String: [WorksheetMetadata]] = [:]
        
        for metadata in self {
            for topic in metadata.topics {
                grouped[topic, default: []].append(metadata)
            }
        }
        
        return grouped
    }
    
    /// Group metadata by difficulty
    public func groupedByDifficulty() -> [String: [WorksheetMetadata]] {
        return Dictionary(grouping: self) { (metadata: WorksheetMetadata) -> String in
            return metadata.difficulty
        }
    }
    
    /// Filter by minimum complexity
    public func filterByComplexity(_ complexity: String) -> [WorksheetMetadata] {
        return self.filter { (metadata: WorksheetMetadata) -> Bool in
            metadata.complexityLevel?.localizedCaseInsensitiveContains(complexity) == true
        }
    }
    
    /// Get all unique topics
    public func getAllTopics() -> [String] {
        var allTopicsSet: Set<String> = []
        for metadata in self {
            for topic in metadata.topics {
                allTopicsSet.insert(topic)
            }
        }
        return allTopicsSet.sorted()
    }
    
    /// Get all unique difficulties
    public func getAllDifficulties() -> [String] {
        var allDifficultiesSet: Set<String> = []
        for metadata in self {
            allDifficultiesSet.insert(metadata.difficulty)
        }
        return allDifficultiesSet.sorted()
    }
}
