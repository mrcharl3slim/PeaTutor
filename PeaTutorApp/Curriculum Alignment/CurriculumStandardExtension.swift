//
//  CurriculumStandardExtensions.swift
//  PeaTutorApp
//
//  Sprint 8: Extensions for CurriculumStandard
//  Provides factory methods, filtering, sorting, and matching utilities
//

import Foundation
import Amplify

// MARK: - CurriculumStandard Factory Methods

extension CurriculumStandard {
    
    /// Create a CurriculumStandard from JSON sub-topic data with parent context
    static func from(
        json subTopic: [String: Any],
        gradeLevel: String,
        gradeLevelCode: String,
        strand: String,
        strandCode: String,
        subStrand: String,
        subStrandCode: String,
        topicNumber: String,
        topicTitle: String
    ) -> CurriculumStandard? {
        guard let subTopicCode = subTopic["subTopicCode"] as? String,
              let description = subTopic["description"] as? String else {
            return nil
        }
        
        // Build curriculum code: P[grade]-[strandCode]-[subStrandCode]-[topicNumber].[subTopicCode]
        let curriculumCode = "\(gradeLevelCode)-\(strandCode)-\(subStrandCode)-\(topicNumber).\(subTopicCode)"
        
        // Parse optional fields
        let keywords = (subTopic["keywords"] as? [String]) ?? []
        let sequenceOrder = subTopic["sequenceOrder"] as? Int ?? 0
        let prerequisiteCodes = subTopic["prerequisiteCodes"] as? [String?]
        let bulletPoints = subTopic["bulletPoints"] as? [String?]
        let notes = subTopic["notes"] as? String
        
        return CurriculumStandard(
            country: "SG",
            curriculumName: "MOE Primary Mathematics",
            curriculumVersion: "2021",
            gradeLevel: gradeLevel,
            gradeLevelCode: gradeLevelCode,
            strand: strand,
            strandCode: strandCode,
            subStrand: subStrand,
            subStrandCode: subStrandCode,
            topicNumber: topicNumber,
            topicTitle: topicTitle,
            subTopicCode: subTopicCode,
            subTopicDescription: description,
            curriculumCode: curriculumCode,
            keywords: keywords,
            sequenceOrder: sequenceOrder,
            prerequisiteCodes: prerequisiteCodes,
            bulletPoints: bulletPoints,
            notes: notes,
            isActive: true
        )
    }
}

// MARK: - Array Extension for CurriculumStandard Filtering

extension Array where Element == CurriculumStandard {
    
    /// Filter standards by grade level (e.g., "Primary 1")
    func forGrade(_ gradeLevel: String) -> [CurriculumStandard] {
        filter { $0.gradeLevel == gradeLevel }
    }
    
    /// Filter standards by grade code (e.g., "P1")
    func forGradeCode(_ code: String) -> [CurriculumStandard] {
        filter { $0.gradeLevelCode == code }
    }
    
    /// Filter standards by strand code (e.g., "NA", "MG", "ST")
    func forStrand(_ strandCode: String) -> [CurriculumStandard] {
        filter { $0.strandCode == strandCode }
    }
    
    /// Filter standards by sub-strand code
    func forSubStrand(_ subStrandCode: String) -> [CurriculumStandard] {
        filter { $0.subStrandCode == subStrandCode }
    }
    
    /// Sort standards by sequence order
    func sortedBySequence() -> [CurriculumStandard] {
        sorted { $0.sequenceOrder < $1.sequenceOrder }
    }
    
    /// Get unique topic titles
    func uniqueTopics() -> [String] {
        let topics: [String] = self.map { $0.topicTitle }
        let uniqueSet: Set<String> = Set(topics)
        return uniqueSet.sorted()
    }

    /// Get unique sub-topic codes
    func uniqueSubTopics() -> [String] {
        let codes: [String] = self.map { $0.subTopicCode }
        let uniqueSet: Set<String> = Set(codes)
        return uniqueSet.sorted()
    }

    /// Get unique strand names
    func uniqueStrands() -> [String] {
        let strands: [String] = self.map { $0.strand }
        let uniqueSet: Set<String> = Set(strands)
        return uniqueSet.sorted()
    }

    /// Get unique sub-strand names
    func uniqueSubStrands() -> [String] {
        let subStrands: [String] = self.map { $0.subStrand }
        let uniqueSet: Set<String> = Set(subStrands)
        return uniqueSet.sorted()
    }
    
    /// Find matching standards based on keywords with confidence scoring
    /// Returns array of (standard, confidence) tuples sorted by confidence descending
    func findMatches(
        for searchKeywords: [String],
        gradeLevel: String? = nil,
        threshold: Double = 0.2
    ) -> [(standard: CurriculumStandard, confidence: Double)] {
        let lowercaseKeywords = searchKeywords.map { $0.lowercased() }
        
        var matches: [(standard: CurriculumStandard, confidence: Double)] = []
        
        for standard in self {
            // Skip if grade level filter is specified and doesn't match
            if let grade = gradeLevel, standard.gradeLevel != grade && standard.gradeLevelCode != grade {
                continue
            }
            
            // Calculate match score based on keywords
            let standardKeywords = standard.keywords.map { $0.lowercased() }
            let topicWords = standard.topicTitle.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
            let descriptionWords = standard.subTopicDescription.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
            
            let allStandardWords = Set(standardKeywords + topicWords + descriptionWords)
            
            var matchCount = 0
            for keyword in lowercaseKeywords {
                if allStandardWords.contains(keyword) {
                    matchCount += 2 // Exact match
                } else if allStandardWords.contains(where: { $0.contains(keyword) || keyword.contains($0) }) {
                    matchCount += 1 // Partial match
                }
            }
            
            guard !lowercaseKeywords.isEmpty else { continue }
            
            let confidence = Double(matchCount) / Double(lowercaseKeywords.count * 2)
            
            if confidence >= threshold {
                matches.append((standard: standard, confidence: confidence))
            }
        }
        
        // Sort by confidence descending
        return matches.sorted { $0.confidence > $1.confidence }
    }
    
    /// Group standards by strand
    func groupedByStrand() -> [String: [CurriculumStandard]] {
        Dictionary(grouping: self) { $0.strand }
    }
    
    /// Group standards by grade level
    func groupedByGrade() -> [String: [CurriculumStandard]] {
        Dictionary(grouping: self) { $0.gradeLevel }
    }
    
    /// Group standards by topic
    func groupedByTopic() -> [String: [CurriculumStandard]] {
        Dictionary(grouping: self) { $0.topicTitle }
    }
}

// MARK: - CurriculumStandard Display Helpers

extension CurriculumStandard {
    
    /// Human-readable display name
    var displayName: String {
        "\(topicTitle) - \(subTopicDescription)"
    }
    
    /// Short display code with description
    var shortDisplay: String {
        "\(curriculumCode): \(subTopicDescription)"
    }
    
    /// Full hierarchical path
    var fullPath: String {
        "\(gradeLevel) > \(strand) > \(subStrand) > \(topicTitle)"
    }
    
    /// Get non-nil prerequisite codes as String array
    var prerequisiteCodesClean: [String] {
        prerequisiteCodes?.compactMap { $0 } ?? []
    }
    
    /// Get non-nil bullet points as String array
    var bulletPointsClean: [String] {
        bulletPoints?.compactMap { $0 } ?? []
    }
}
