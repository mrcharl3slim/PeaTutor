// File: PeaTutorApp/Models/Models.swift
// Updated to avoid conflicts with Amplify models
// Fixed: Custom decoding for ExtractedWorksheet to handle missing 'id' field

import Foundation

// MARK: - Extracted Data Models (from OpenAI)
// These represent the JSON structure returned by GPT-4o Vision extraction

public struct ExtractedWorksheet: Codable, Identifiable {
    public var id: UUID
    public var questions: [ExtractedQuestion]
    
    // Custom coding keys - id is not in JSON
    enum CodingKeys: String, CodingKey {
        case questions
    }
    
    // Custom decoder - generates UUID locally since GPT doesn't provide it
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.questions = try container.decode([ExtractedQuestion].self, forKey: .questions)
        self.id = UUID() // Generate UUID locally
    }
    
    // Custom encoder - only encode questions
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(questions, forKey: .questions)
    }
    
    // For manual initialization (backward compatibility)
    public init(id: UUID = UUID(), questions: [ExtractedQuestion]) {
        self.id = id
        self.questions = questions
    }
}

public struct ExtractedQuestion: Codable, Identifiable {
    public var id: String
    public var questionText: String
    public var marks: Int
    public var skillsTested: [String]
    public var subparts: [ExtractedSubpart]
    public var hints: String?
    public var stepByStep: String?
    public var answer: String?
    public var uuid = UUID()
    
    // Support old JSON format if needed
    enum CodingKeys: String, CodingKey {
        case id, questionText, marks, skillsTested, subparts, hints, stepByStep, answer
    }
    
    // Custom decoder to handle optional fields gracefully
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        self.questionText = try container.decode(String.self, forKey: .questionText)
        self.marks = try container.decode(Int.self, forKey: .marks)
        self.skillsTested = try container.decodeIfPresent([String].self, forKey: .skillsTested) ?? []
        self.subparts = try container.decodeIfPresent([ExtractedSubpart].self, forKey: .subparts) ?? []
        self.hints = try container.decodeIfPresent(String.self, forKey: .hints)
        self.stepByStep = try container.decodeIfPresent(String.self, forKey: .stepByStep)
        self.answer = try container.decodeIfPresent(String.self, forKey: .answer)
        self.uuid = UUID()
    }
    
    // Custom encoder
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(questionText, forKey: .questionText)
        try container.encode(marks, forKey: .marks)
        try container.encode(skillsTested, forKey: .skillsTested)
        try container.encode(subparts, forKey: .subparts)
        try container.encodeIfPresent(hints, forKey: .hints)
        try container.encodeIfPresent(stepByStep, forKey: .stepByStep)
        try container.encodeIfPresent(answer, forKey: .answer)
    }
    
    // Manual initializer for creating questions programmatically
    public init(
        id: String,
        questionText: String,
        marks: Int,
        skillsTested: [String] = [],
        subparts: [ExtractedSubpart] = [],
        hints: String? = nil,
        stepByStep: String? = nil,
        answer: String? = nil
    ) {
        self.id = id
        self.questionText = questionText
        self.marks = marks
        self.skillsTested = skillsTested
        self.subparts = subparts
        self.hints = hints
        self.stepByStep = stepByStep
        self.answer = answer
        self.uuid = UUID()
    }
}

public struct ExtractedSubpart: Codable, Identifiable {
    public var id: String
    public var text: String
    public var marks: Int
    public var skillsTested: [String]
    public var hints: String
    public var stepByStep: String
    public var answer: String
    public var uuid = UUID()
    
    enum CodingKeys: String, CodingKey {
        case id, text, marks, skillsTested, hints, stepByStep, answer
    }
    
    // Custom decoder to handle optional fields gracefully
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        self.text = try container.decode(String.self, forKey: .text)
        self.marks = try container.decode(Int.self, forKey: .marks)
        self.skillsTested = try container.decodeIfPresent([String].self, forKey: .skillsTested) ?? []
        self.hints = try container.decodeIfPresent(String.self, forKey: .hints) ?? "No hints available"
        self.stepByStep = try container.decodeIfPresent(String.self, forKey: .stepByStep) ?? "No steps available"
        self.answer = try container.decodeIfPresent(String.self, forKey: .answer) ?? "No answer available"
        self.uuid = UUID()
    }
    
    // Custom encoder
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(marks, forKey: .marks)
        try container.encode(skillsTested, forKey: .skillsTested)
        try container.encode(hints, forKey: .hints)
        try container.encode(stepByStep, forKey: .stepByStep)
        try container.encode(answer, forKey: .answer)
    }
    
    // Manual initializer for creating subparts programmatically
    public init(
        id: String,
        text: String,
        marks: Int,
        skillsTested: [String] = [],
        hints: String = "No hints available",
        stepByStep: String = "No steps available",
        answer: String = "No answer available"
    ) {
        self.id = id
        self.text = text
        self.marks = marks
        self.skillsTested = skillsTested
        self.hints = hints
        self.stepByStep = stepByStep
        self.answer = answer
        self.uuid = UUID()
    }
}

// MARK: - Type Aliases for Backward Compatibility
// Allows existing code to continue working with minimal changes

@available(*, deprecated, renamed: "ExtractedWorksheet")
public typealias WorksheetRoot = ExtractedWorksheet

@available(*, deprecated, message: "Use ExtractedQuestion for parsing, Amplify's Question for DataStore")
public typealias LocalQuestion = ExtractedQuestion

@available(*, deprecated, renamed: "ExtractedSubpart")
public typealias Subpart = ExtractedSubpart
