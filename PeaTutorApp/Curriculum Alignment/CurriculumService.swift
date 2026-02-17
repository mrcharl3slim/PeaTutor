//
//  CurriculumService.swift
//  PeaTutorApp
//
//  Sprint 8: Curriculum Standards Integration
//  Service for managing curriculum data, seeding, and topic mapping
//

import Foundation
import Amplify

// MARK: - CurriculumService

@MainActor
class CurriculumService: ObservableObject {
    static let shared = CurriculumService()
    
    // MARK: - Published State
    
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var seedingProgress: Double = 0
    
    // MARK: - Cached Data
    
    private var cachedStandards: [CurriculumStandard] = []
    private var cacheLoadedAt: Date?
    private let cacheExpiryInterval: TimeInterval = 3600 // 1 hour
    
    private init() {}
    
    // MARK: - Fetch All Standards
    
    /// Fetch all curriculum standards from DataStore
    func fetchAllStandards(forceRefresh: Bool = false) async throws -> [CurriculumStandard] {
        // Return cached if valid
        if !forceRefresh,
           !cachedStandards.isEmpty,
           let loadedAt = cacheLoadedAt,
           Date().timeIntervalSince(loadedAt) < cacheExpiryInterval {
            return cachedStandards
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let standards = try await Amplify.DataStore.query(CurriculumStandard.self)
        
        // Update cache
        cachedStandards = standards
        cacheLoadedAt = Date()
        
        print("📚 Loaded \(standards.count) curriculum standards")
        return standards
    }
    
    /// Fetch standards for a specific grade level
    func fetchStandards(forGrade gradeLevel: String) async throws -> [CurriculumStandard] {
        let allStandards = try await fetchAllStandards()
        return allStandards.forGrade(gradeLevel).sortedBySequence()
    }
    
    /// Fetch standards for a specific grade code (P1, P2, etc.)
    func fetchStandards(forGradeCode code: String) async throws -> [CurriculumStandard] {
        let allStandards = try await fetchAllStandards()
        return allStandards.forGradeCode(code).sortedBySequence()
    }
    
    /// Fetch a single standard by its curriculum code
    func fetchStandard(byCode code: String) async throws -> CurriculumStandard? {
        let allStandards = try await fetchAllStandards()
        return allStandards.first { $0.curriculumCode == code }
    }
    
    /// Fetch standards for multiple codes
    func fetchStandards(byCodes codes: [String]) async throws -> [CurriculumStandard] {
        let allStandards = try await fetchAllStandards()
        let codesSet = Set(codes)
        return allStandards.filter { codesSet.contains($0.curriculumCode) }
    }
    
    // MARK: - Topic Mapping
    
    /// Map extracted topics/keywords to curriculum codes
    /// Returns array of (standard, confidence) tuples sorted by confidence
    func mapTopicsToCurriculum(
        extractedTopics: [String],
        gradeLevel: String? = nil,
        limit: Int = 5
    ) async throws -> [(standard: CurriculumStandard, confidence: Double)] {
        let allStandards = try await fetchAllStandards()
        
        // Prepare search keywords from extracted topics
        let searchKeywords = extractedTopics.flatMap { topic in
            topic.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty && $0.count > 2 }
        }
        
        let matches = allStandards.findMatches(
            for: searchKeywords,
            gradeLevel: gradeLevel,
            threshold: 0.2
        )
        
        return Array(matches.prefix(limit))
    }
    
    /// Find prerequisites for a given curriculum code
    func findPrerequisites(for curriculumCode: String) async throws -> [CurriculumStandard] {
        guard let standard = try await fetchStandard(byCode: curriculumCode),
              let prereqCodes = standard.prerequisiteCodes,
              !prereqCodes.isEmpty else {
            return []
        }
        
        // Convert [String?] to [String] by filtering out nils
        let cleanCodes = prereqCodes.compactMap { $0 }
        guard !cleanCodes.isEmpty else { return [] }
        
        return try await fetchStandards(byCodes: cleanCodes)
    }
    
    /// Find what standards build on this one (reverse lookup)
    func findDependentStandards(for curriculumCode: String) async throws -> [CurriculumStandard] {
        let allStandards = try await fetchAllStandards()
        
        return allStandards.filter { standard in
            // Check if this standard's prerequisites contain the given code
            guard let prereqCodes = standard.prerequisiteCodes else { return false }
            return prereqCodes.compactMap { $0 }.contains(curriculumCode)
        }.sortedBySequence()
    }
    
    // MARK: - Progress Calculation
    
    /// Get summary of curriculum coverage for a grade
    func getGradeSummary(gradeCode: String) async throws -> GradeCurriculumSummary {
        let standards = try await fetchStandards(forGradeCode: gradeCode)
        
        let strandBreakdown = Dictionary(grouping: standards) { $0.strand }
            .mapValues { standards in
                (total: standards.count, topics: standards.uniqueTopics().count)
            }
        
        return GradeCurriculumSummary(
            gradeCode: gradeCode,
            totalStandards: standards.count,
            totalTopics: standards.uniqueTopics().count,
            strands: strandBreakdown.map { (strand: $0.key, standardCount: $0.value.total, topicCount: $0.value.topics) }
        )
    }
    
    // MARK: - Seeding from JSON
    
    /// Seed curriculum standards from bundled JSON file
    /// This should be called once during app setup or when curriculum updates
    func seedFromBundledJSON(filename: String = "SG_MOE_Mathematics_P1_P3_Seed_Data") async throws {
        isLoading = true
        seedingProgress = 0
        lastError = nil
        
        defer {
            isLoading = false
        }
        
        print("🌱 Starting curriculum seeding from \(filename).json...")
        
        // Load JSON from bundle
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            lastError = "Curriculum seed file not found in bundle"
            throw CurriculumError.seedFileNotFound
        }
        
        let data = try Data(contentsOf: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let levels = json["levels"] as? [[String: Any]] else {
            lastError = "Invalid curriculum seed JSON format"
            throw CurriculumError.invalidSeedFormat
        }
        
        // Parse and save standards
        var allStandards: [CurriculumStandard] = []
        var globalSequence = 0
        
        for level in levels {
            guard let gradeLevel = level["gradeLevel"] as? String,
                  let gradeLevelCode = level["gradeLevelCode"] as? String,
                  let strands = level["strands"] as? [[String: Any]] else {
                continue
            }
            
            for strand in strands {
                guard let strandName = strand["strand"] as? String,
                      let strandCode = strand["strandCode"] as? String,
                      let subStrands = strand["subStrands"] as? [[String: Any]] else {
                    continue
                }
                
                for subStrand in subStrands {
                    guard let subStrandName = subStrand["subStrand"] as? String,
                          let subStrandCode = subStrand["subStrandCode"] as? String,
                          let topics = subStrand["topics"] as? [[String: Any]] else {
                        continue
                    }
                    
                    for topic in topics {
                        guard let topicNumber = topic["topicNumber"] as? String,
                              let topicTitle = topic["topicTitle"] as? String,
                              let subTopics = topic["subTopics"] as? [[String: Any]] else {
                            continue
                        }
                        
                        for subTopic in subTopics {
                            if let standard = CurriculumStandard.from(
                                json: subTopic,
                                gradeLevel: gradeLevel,
                                gradeLevelCode: gradeLevelCode,
                                strand: strandName,
                                strandCode: strandCode,
                                subStrand: subStrandName,
                                subStrandCode: subStrandCode,
                                topicNumber: topicNumber,
                                topicTitle: topicTitle
                            ) {
                                allStandards.append(standard)
                                globalSequence += 1
                            }
                        }
                    }
                }
            }
        }
        
        print("📊 Parsed \(allStandards.count) curriculum standards")
        
        // Save to DataStore in batches
        let batchSize = 20
        let totalBatches = (allStandards.count + batchSize - 1) / batchSize
        
        for (batchIndex, batch) in allStandards.chunked(into: batchSize).enumerated() {
            for standard in batch {
                try await Amplify.DataStore.save(standard)
            }
            
            seedingProgress = Double(batchIndex + 1) / Double(totalBatches)
            print("🌱 Seeded batch \(batchIndex + 1)/\(totalBatches)")
        }
        
        // Clear cache to force refresh
        cachedStandards = []
        cacheLoadedAt = nil
        
        print("✅ Curriculum seeding complete: \(allStandards.count) standards")
    }
    
    /// Check if curriculum data is already seeded
    func isCurriculumSeeded() async -> Bool {
        do {
            let count = try await Amplify.DataStore.query(CurriculumStandard.self)
            return count.count > 0
        } catch {
            return false
        }
    }
    
    /// Clear all curriculum data (for re-seeding)
    func clearCurriculumData() async throws {
        let standards = try await Amplify.DataStore.query(CurriculumStandard.self)
        
        for standard in standards {
            try await Amplify.DataStore.delete(standard)
        }
        
        cachedStandards = []
        cacheLoadedAt = nil
        
        print("🗑️ Cleared \(standards.count) curriculum standards")
    }
}

// MARK: - Supporting Types

struct GradeCurriculumSummary {
    let gradeCode: String
    let totalStandards: Int
    let totalTopics: Int
    let strands: [(strand: String, standardCount: Int, topicCount: Int)]
    
    var strandSummary: String {
        strands.map { "\($0.strand): \($0.topicCount) topics (\($0.standardCount) objectives)" }
            .joined(separator: "\n")
    }
}

enum CurriculumError: Error, LocalizedError {
    case seedFileNotFound
    case invalidSeedFormat
    case standardNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .seedFileNotFound:
            return "Curriculum seed file not found in app bundle"
        case .invalidSeedFormat:
            return "Invalid curriculum seed JSON format"
        case .standardNotFound(let code):
            return "Curriculum standard not found: \(code)"
        }
    }
}

// MARK: - Array Chunking Extension

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Grade Level Helpers

extension CurriculumService {
    
    /// Convert grade level string to curriculum code
    static func gradeLevelToCode(_ gradeLevel: String) -> String? {
        let mapping: [String: String] = [
            "Primary 1": "P1",
            "Primary 2": "P2",
            "Primary 3": "P3",
            "Primary 4": "P4",
            "Primary 5": "P5",
            "Primary 6": "P6"
        ]
        return mapping[gradeLevel]
    }
    
    /// Convert curriculum code to grade level string
    static func codeToGradeLevel(_ code: String) -> String? {
        let mapping: [String: String] = [
            "P1": "Primary 1",
            "P2": "Primary 2",
            "P3": "Primary 3",
            "P4": "Primary 4",
            "P5": "Primary 5",
            "P6": "Primary 6"
        ]
        return mapping[code]
    }
    
    /// Get all supported grade levels
    static let supportedGradeLevels = [
        "Primary 1", "Primary 2", "Primary 3",
        "Primary 4", "Primary 5", "Primary 6"
    ]
    
    /// Get all supported grade codes
    static let supportedGradeCodes = ["P1", "P2", "P3", "P4", "P5", "P6"]
    
    /// Get strand display names
    static let strandDisplayNames: [String: String] = [
        "NA": "Number and Algebra",
        "MG": "Measurement and Geometry",
        "ST": "Statistics"
    ]
}
