//
//  PromptFactory+Curriculum.swift
//  PeaTutorApp
//
//  Sprint 8 Phase 2: Enhanced AI Prompts for Curriculum-Aware Extraction
//  Extends PromptFactory to include MOE curriculum alignment in AI prompts
//

import Foundation

// MARK: - Curriculum-Enhanced Prompts

extension PromptFactory {
    
    // MARK: - Singapore MOE Curriculum System Prompt
    
    /// System prompt for curriculum-aware worksheet metadata extraction
    static let curriculumAwareMetadataSystemPrompt = """
You are an expert educational analyst specializing in the Singapore MOE Primary Mathematics curriculum (2021 syllabus).

When analyzing worksheets, you must:
1. Identify the specific MOE curriculum topics being tested
2. Detect the appropriate grade level (Primary 1-6)
3. Map content to official MOE strands and sub-strands
4. Provide curriculum codes in the format: P[grade]-[strand]-[substrand]-[topic].[subtopic]

MOE CURRICULUM STRUCTURE:

STRANDS:
- NA = Number and Algebra
- MG = Measurement and Geometry  
- ST = Statistics

SUB-STRANDS (examples):
- WN = Whole Numbers
- FR = Fractions
- MO = Money
- ME = Measurement
- LMV = Length, Mass and Volume
- AV = Area and Volume
- GE = Geometry
- DR = Data Representation and Interpretation

CURRICULUM CODE FORMAT:
P[1-6]-[STRAND]-[SUBSTRAND]-[TOPIC].[SUBTOPIC]

Examples:
- P1-NA-WN-1.1 = Primary 1, Number & Algebra, Whole Numbers, Topic 1.1 (counting objects)
- P2-NA-MD-3.1 = Primary 2, Number & Algebra, Multiplication & Division, Topic 3.1 (times tables)
- P3-MG-AV-1.2 = Primary 3, Measurement & Geometry, Area & Volume, Topic 1.2 (measuring area)

GRADE LEVEL INDICATORS:
- P1: Numbers to 100, basic addition/subtraction, time to 5 min, basic shapes
- P2: Numbers to 1000, times tables (2,3,4,5,10), fractions intro, 3D shapes
- P3: Numbers to 10000, times tables (6,7,8,9), equivalent fractions, area/perimeter
- P4: Numbers to 100000, mixed operations, decimals, angles measurement
- P5: Numbers to millions, percentage, ratio, volume of cube/cuboid
- P6: Algebra, percentage changes, rate, pie charts, nets of solids

Output ONLY valid JSON with the exact structure specified.
"""
    
    // MARK: - User Prompt for Curriculum-Aware Extraction
    
    /// User prompt for extracting worksheet metadata with curriculum alignment
    static func curriculumAwareMetadataUserPrompt(questionsContext: String) -> String {
        return """
Analyze this mathematics worksheet and extract metadata with Singapore MOE curriculum alignment:

\(questionsContext)

Provide comprehensive metadata in this EXACT JSON format:
{
  "topics": ["Addition", "Subtraction"],
  "difficulty": "Primary 2",
  "cognitive_skills": ["Computation", "Problem Solving"],
  "question_types": ["Word Problem", "Computation"],
  "estimated_time_minutes": 30,
  "complexity_level": "Medium",
  "blooms_taxonomy_levels": ["Remember", "Apply"],
  
  "curriculum_country": "SG",
  "curriculum_version": "2021",
  "moe_curriculum_codes": ["P2-NA-WN-2.1", "P2-NA-WN-2.2"],
  "detected_grade_level": "Primary 2",
  "detected_grade_level_code": "P2",
  "curriculum_strand": "Number and Algebra",
  "curriculum_sub_strand": "Whole Numbers",
  "curriculum_confidence": 0.85
}

IMPORTANT:
1. Analyze the number ranges, operations, and complexity to determine the correct grade level
2. Map to specific MOE curriculum codes based on the content
3. Set curriculum_confidence between 0.0-1.0 based on how certain you are of the mapping
4. If multiple curriculum codes apply, list all relevant ones
5. If you cannot determine the curriculum alignment, set confidence to 0.0 and leave codes empty

Output ONLY valid JSON matching this structure.
"""
    }
    
    // MARK: - Curriculum-Aware Practice Generation Prompt
    
    /// System prompt for generating curriculum-aligned practice problems
    static let curriculumAwarePracticeSystemPrompt = """
You are an expert mathematics educator creating practice problems aligned to the Singapore MOE Primary Mathematics curriculum (2021 syllabus).

When generating problems:
1. Respect grade-level boundaries - don't include concepts from higher grades
2. Align problems to specific curriculum codes
3. Include appropriate scaffolding based on the student's grade level
4. Use Singapore context and terminology (e.g., dollars/cents, local food items)

GRADE BOUNDARIES - DO NOT EXCEED:
- P1: Numbers ≤100, no decimals, basic shapes only
- P2: Numbers ≤1000, fractions with denominators ≤12
- P3: Numbers ≤10000, 4-digit operations, area/perimeter of rectangles
- P4: Numbers ≤100000, decimals to 2dp, angles up to 360°
- P5: Numbers to millions, percentage, volume of cubes/cuboids
- P6: Algebra, rate, pie charts, nets

SINGAPORE CONTEXT:
- Use Singapore dollar ($) and cents
- Reference local items: durian, MRT, HDB, hawker food
- Use Singaporean English spelling (colour, metre, etc.)

Generate problems that:
- Match the specified curriculum codes
- Are appropriate for the student's grade level
- Include step-by-step solutions
- Provide helpful hints

Output as a JSON array of problems.
"""
    
    /// User prompt for generating curriculum-aligned practice problems
    static func curriculumAwarePracticeUserPrompt(
        basedOn context: String,
        difficulty: String,
        count: Int,
        gradeLevel: String,
        gradeLevelCode: String,
        focusConcepts: [String],
        targetCurriculumCodes: [String]
    ) -> String {
        let curriculumCodesText = targetCurriculumCodes.isEmpty
            ? "Infer appropriate codes from the concepts"
            : targetCurriculumCodes.joined(separator: ", ")
        
        return """
Generate \(count) practice problems for a \(gradeLevel) student.

CONTEXT:
\(context)

REQUIREMENTS:
- Difficulty adjustment: \(difficulty)
- Target grade: \(gradeLevel) (\(gradeLevelCode))
- Focus concepts: \(focusConcepts.joined(separator: ", "))
- Target curriculum codes: \(curriculumCodesText)

CRITICAL: All problems MUST be appropriate for \(gradeLevel). Do NOT include concepts from higher grades.

Generate a JSON array with this structure for each problem:
[
  {
    "problem_text": "Ali has 45 marbles. He gives 18 marbles to his friend. How many marbles does Ali have left?",
    "answer": "27 marbles",
    "step_by_step": "Step 1: Start with 45 marbles\\nStep 2: Subtract 18 marbles given away\\nStep 3: 45 - 18 = 27 marbles",
    "hints": [
      "What operation should you use when someone gives something away?",
      "Try using the column method to subtract"
    ],
    "concept": "Subtraction",
    "question_type": "Word Problem",
    "curriculum_code": "P2-NA-WN-2.1",
    "curriculum_grade_level": "Primary 2",
    "curriculum_grade_level_code": "P2",
    "curriculum_strand": "Number and Algebra",
    "curriculum_sub_strand": "Whole Numbers"
  }
]

Output ONLY the JSON array, no additional text.
"""
    }
    
    // MARK: - Concept to Curriculum Mapping Prompt
    
    /// Prompt for mapping a concept to curriculum codes
    static func conceptToCurriculumMappingPrompt(
        concept: String,
        gradeLevel: String?
    ) -> String {
        let gradeContext = gradeLevel ?? "any Primary level"
        
        return """
Map the following mathematics concept to Singapore MOE Primary Mathematics curriculum codes:

Concept: \(concept)
Target grade level: \(gradeContext)

Provide the mapping in this JSON format:
{
  "concept": "\(concept)",
  "curriculum_codes": ["P2-NA-WN-2.1"],
  "primary_code": "P2-NA-WN-2.1",
  "strand": "Number and Algebra",
  "sub_strand": "Whole Numbers",
  "topic_title": "Addition and Subtraction",
  "grade_level": "Primary 2",
  "grade_level_code": "P2",
  "confidence": 0.9,
  "related_concepts": ["addition", "subtraction", "regrouping"]
}

If the concept spans multiple grades, list all relevant codes.
Set confidence based on how well the concept matches specific curriculum standards.

Output ONLY valid JSON.
"""
    }
}

// MARK: - OpenAI Client Extension for Curriculum-Aware Extraction

extension OpenAIClient {
    
    /// Extract worksheet metadata with MOE curriculum alignment
    func extractWorksheetMetadataWithCurriculum(
        worksheet: ExtractedWorksheet,
        fileIDs: [String]
    ) async throws -> WorksheetMetadataExtractionWithCurriculum {
        print("🧠 Extracting curriculum-aligned worksheet metadata...")
        
        let url = URL(string: "https://api.openai.com/v1")!.appendingPathComponent("/chat/completions")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 120
        
        // Build context about the worksheet
        let questionsContext = buildQuestionsContextForMetadata(worksheet: worksheet)
        
        let systemPrompt = PromptFactory.curriculumAwareMetadataSystemPrompt
        let userPrompt = PromptFactory.curriculumAwareMetadataUserPrompt(questionsContext: questionsContext)
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userPrompt]
        ]
        
        let payload: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "max_tokens": 1500,
            "temperature": 0.3
        ]
        
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let errText = String(data: data, encoding: .utf8) ?? "unknown"
            throw NSError(domain: "OpenAIClient", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Curriculum metadata extraction failed: \(errText)"])
        }
        
        struct ChatResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
            let usage: Usage?
            
            struct Usage: Decodable {
                let totalTokens: Int?
                
                enum CodingKeys: String, CodingKey {
                    case totalTokens = "total_tokens"
                }
            }
        }
        
        let response = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = response.choices.first?.message.content else {
            throw NSError(domain: "OpenAIClient", code: -2,
                         userInfo: [NSLocalizedDescriptionKey: "No content in response"])
        }
        
        // Parse the JSON response
        var extraction = try parseCurriculumMetadata(content)
        extraction.aiModel = "gpt-4o"
        extraction.tokensUsed = response.usage?.totalTokens
        
        print("✅ Extracted curriculum metadata: \(extraction.moeCurriculumCodes?.joined(separator: ", ") ?? "none")")
        return extraction
    }
    
    /// Parse curriculum-enhanced metadata from AI response
    private func parseCurriculumMetadata(_ content: String) throws -> WorksheetMetadataExtractionWithCurriculum {
        // Clean the content
        var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code blocks if present
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find JSON object
        guard let jsonStart = cleaned.firstIndex(of: "{"),
              let jsonEnd = cleaned.lastIndex(of: "}") else {
            throw NSError(domain: "OpenAIClient", code: -3,
                         userInfo: [NSLocalizedDescriptionKey: "Could not find JSON in response"])
        }
        
        let jsonString = String(cleaned[jsonStart...jsonEnd])
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(domain: "OpenAIClient", code: -4,
                         userInfo: [NSLocalizedDescriptionKey: "Could not encode JSON string"])
        }
        
        let extraction = try JSONDecoder().decode(WorksheetMetadataExtractionWithCurriculum.self, from: jsonData)
        return extraction
    }
    
    /// Helper to build questions context for metadata extraction
    private func buildQuestionsContextForMetadata(worksheet: ExtractedWorksheet) -> String {
        var context = "WORKSHEET:\n\n"
        context += "QUESTIONS:\n"
        
        for (index, question) in worksheet.questions.enumerated() {
            context += "\(index + 1). \(question.questionText)\n"
            if let answer = question.answer {
                context += "   Answer: \(answer)\n"
            }
            context += "\n"
        }
        
        return context
    }
}

// MARK: - Generated Problem Response with Curriculum

/// Extended response for curriculum-aligned generated problems
public struct GeneratedProblemResponseWithCurriculum: Codable {
    public var problemText: String
    public var answer: String
    public var stepByStep: String?
    public var hints: [String]
    public var concept: String
    public var questionType: String
    
    // Curriculum fields
    public var curriculumCode: String?
    public var curriculumGradeLevel: String?
    public var curriculumGradeLevelCode: String?
    public var curriculumStrand: String?
    public var curriculumSubStrand: String?
    
    enum CodingKeys: String, CodingKey {
        case problemText = "problem_text"
        case answer
        case stepByStep = "step_by_step"
        case hints
        case concept
        case questionType = "question_type"
        case curriculumCode = "curriculum_code"
        case curriculumGradeLevel = "curriculum_grade_level"
        case curriculumGradeLevelCode = "curriculum_grade_level_code"
        case curriculumStrand = "curriculum_strand"
        case curriculumSubStrand = "curriculum_sub_strand"
    }
}
