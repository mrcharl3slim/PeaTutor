// File: PeaTutorApp/Utilities/PromptFactory.swift
// Updated: Field names now match ExtractedQuestion/ExtractedSubpart model exactly

import Foundation

enum PromptFactory {
    
    // MARK: - Question Extraction Prompt
    static let extractionPrompt: String = """
You are given one or more math worksheets (PDF, DOCX, or image).
Your task is to analyse every uploaded document and extract all questions into structured JSON, along with skills, hints, step-by-step solutions, and final answers.

Extraction & Solution Pipeline

Process all input files one by one.
Do not skip any document.
Merge results into a single JSON output.

Attempt direct text extraction.
If equations are in OMML (Word equations), convert to LaTeX.
If text is incomplete (only numbers, marks, gibberish, or missing math), automatically apply OCR to capture the full content.
Normalize all math notation into LaTeX.
Detect and split by question numbering.
Main questions: 1, 2, 3... or Q1, Q2....
Subparts: (a), (b), (c)... or i, ii, iii. Map roman to letters.
Preserve the hierarchy.
Extract marks from square brackets [ ] and assign them correctly.

For each question and subpart, generate:
- skillsTested → e.g., gradient, equation of line, parallel/perpendicular, midpoint, distance, simultaneous equations, inequalities, algebra, quadratic, differentiation, integration, trigonometry, general problem solving.
- hints → short guiding tips without solving completely.
- stepByStep → a worked-out solution in clear logical steps with LaTeX.
- answer → the final simplified result in LaTeX.

If a figure/diagram is referenced, include a short textual description: "[Diagram: ...]" or "[Diagram present but illegible]".

If a document cannot be parsed, append a placeholder object:
{
  "id": "QX",
  "questionText": "PARSE ERROR – could not extract this question",
  "marks": 0,
  "skillsTested": [],
  "subparts": [],
  "hints": "N/A",
  "stepByStep": "N/A",
  "answer": "N/A"
}

IDs
- Main: Q1, Q2, ... sequential across all uploaded files.
- Subpart: Q<number><letter> (e.g., Q2a). Never merge two distinct questions.

CRITICAL: You must return ONLY valid JSON. Do not include any markdown formatting, explanations, or extra text. Start your response with { and end with }.

Output Schema (return ONLY valid JSON; no extra text):
{
  "questions": [
    {
      "id": "Q<number>",
      "questionText": "<full question text with LaTeX>",
      "marks": <integer>,
      "skillsTested": ["<skill1>", "<skill2>", "..."],
      "subparts": [
        {
          "id": "Q<number><letter>",
          "text": "<subpart text with LaTeX>",
          "marks": <integer>,
          "skillsTested": ["<skill1>", "<skill2>", "..."],
          "hints": "<hint(s) to start solving>",
          "stepByStep": "<detailed step-by-step solution in LaTeX>",
          "answer": "<final simplified answer in LaTeX>"
        }
      ],
      "hints": "<if no subparts, provide hints here>",
      "stepByStep": "<if no subparts, provide step-by-step here>",
      "answer": "<if no subparts, provide final answer here>"
    }
  ]
}

FIELD NAME MAPPING - USE THESE EXACT NAMES:
Parent Question Fields (REQUIRED):
- "id" → string (e.g., "Q1")
- "questionText" → string (NOT "text")
- "marks" → integer
- "skillsTested" → array of strings (NOT "skills_tested")
- "subparts" → array of subpart objects
- "hints" → string or null
- "stepByStep" → string or null (NOT "step_by_step")
- "answer" → string or null

Subpart Fields (REQUIRED):
- "id" → string (e.g., "Q1a")
- "text" → string (subpart question text)
- "marks" → integer
- "skillsTested" → array of strings (NOT "skills_tested")
- "hints" → string (required, not null)
- "stepByStep" → string (required, not null) (NOT "step_by_step")
- "answer" → string (required, not null)

Remember: Return ONLY the JSON object above, nothing else. Use camelCase field names exactly as specified.
"""
    
    // MARK: - Solution Feedback System Prompt
    static let solutionFeedbackSystemPrompt: String = """
You are a helpful math tutor reviewing a student's written solution. Analyze the solution image and provide brief, constructive feedback.

Guidelines:
- Keep feedback concise (2-3 sentences max)
- Be encouraging and constructive
- Point out both correct steps and areas for improvement
- If the solution is correct, acknowledge it
- If there are errors, give specific hints without giving the full answer
- Use simple, student-friendly language

IMPORTANT: Check if the image contains relevant mathematical work:
- If the image is blank, unreadable, or contains no work: Set feedback to "I can't see any written work in this image. Please make sure your solution is clearly visible and try again."
- If the image contains non-mathematical content: Set feedback to "This doesn't appear to be a math solution. Please upload an image of your written work for this question."
- If the image contains work for a different question: Set feedback to "This appears to be work for a different problem. Please upload your solution for the current question."
- If the handwriting is too unclear to read: Set feedback to "Your handwriting is a bit hard to read. Try taking a clearer photo with better lighting."

Respond with JSON in this exact format:
{
  "feedback": "Brief feedback message",
  "isCorrect": true/false/null,
  "suggestions": ["suggestion1", "suggestion2"]
}

For invalid/irrelevant content, always set isCorrect to null and provide helpful suggestions for getting back on track.
"""
    
    // MARK: - Solution Feedback User Prompt Generator
    static func solutionFeedbackUserPrompt(questionText: String) -> String {
        return """
Question: \(questionText)

Please analyze this student's written solution and provide constructive feedback.
"""
    }
    
    // MARK: - Full Worksheet Feedback System Prompt
    static let fullWorksheetFeedbackSystemPrompt: String = """
You are a helpful math tutor reviewing a student's complete worksheet solution. Analyze all the work shown in the image and provide comprehensive feedback across all questions.

Guidelines:
- Review the entire worksheet holistically
- Identify which questions were attempted and which were skipped
- Provide an overall assessment of the work quality
- Give specific feedback for questions with issues
- Be encouraging about correct work
- Point out patterns of errors if any
- Keep feedback constructive and student-friendly

IMPORTANT: Check image quality and content:
- If the image is blank, unreadable, or contains no work: Set overall_feedback to "I can't see any written work in this image. Please make sure your solutions are clearly visible and try again."
- If the image contains non-mathematical content: Set overall_feedback to "This doesn't appear to be a math worksheet. Please upload an image of your completed math work."
- If the handwriting is too unclear to read: Set overall_feedback to "Your handwriting is difficult to read. Try taking a clearer photo with better lighting."

Respond with JSON in this exact format:
{
  "overall_feedback": "Brief summary of overall performance (2-3 sentences)",
  "overall_score": <number of questions attempted out of total>,
  "completed_questions": ["Q1", "Q2", ...],
  "questions_with_issues": ["Q3", "Q4", ...],
  "suggestions": ["suggestion1", "suggestion2", ...],
  "detailed_feedback": [
    {
      "question_id": "Q1",
      "feedback": "Specific feedback for this question",
      "is_correct": true/false/null
    }
  ]
}

For invalid/unclear content, set overall_score to 0, empty arrays for questions, and provide helpful suggestions.
"""
    
    // MARK: - Full Worksheet Feedback User Prompt Generator
    static func fullWorksheetFeedbackUserPrompt(questionsContext: String) -> String {
        return """
\(questionsContext)

Please analyze this student's complete worksheet solution image and provide comprehensive feedback covering all questions.
"""
    }
    
    // MARK: - API Connection Test Prompt
    static let connectionTestPrompt: String = "Say 'API connection successful'"
    
    // MARK: - Prompt Configuration
    struct PromptConfig {
        let maxTokens: Int
        let temperature: Double
        let model: String
        
        static let extraction = PromptConfig(maxTokens: 16000, temperature: 0.1, model: "gpt-4o")
        static let solutionFeedback = PromptConfig(maxTokens: 300, temperature: 0.3, model: "gpt-4o")
        static let fullWorksheetFeedback = PromptConfig(maxTokens: 16000, temperature: 0.3, model: "gpt-4o")
        static let connectionTest = PromptConfig(maxTokens: 10, temperature: 0.1, model: "gpt-3.5-turbo")
    }
    
    static func getConfig(for promptType: PromptType) -> PromptConfig {
        switch promptType {
        case .extraction:
            return .extraction
        case .solutionFeedback:
            return .solutionFeedback
        case .fullWorksheetFeedback:
            return .fullWorksheetFeedback
        case .connectionTest:
            return .connectionTest
        }
    }
}

// MARK: - Prompt Types
enum PromptType {
    case extraction
    case solutionFeedback
    case fullWorksheetFeedback
    case connectionTest
}

// MARK: - Prompt Validation
extension PromptFactory {
    
    /// Validate that prompts contain required elements
    static func validatePrompts() -> [String] {
        var issues: [String] = []
        
        // Validate extraction prompt
        if !extractionPrompt.contains("JSON") {
            issues.append("Extraction prompt missing JSON requirement")
        }
        if !extractionPrompt.contains("LaTeX") {
            issues.append("Extraction prompt missing LaTeX instruction")
        }
        if !extractionPrompt.contains("questionText") {
            issues.append("Extraction prompt missing questionText field")
        }
        if !extractionPrompt.contains("skillsTested") {
            issues.append("Extraction prompt missing skillsTested field")
        }
        if !extractionPrompt.contains("stepByStep") {
            issues.append("Extraction prompt missing stepByStep field")
        }
        
        // Validate feedback prompt
        if !solutionFeedbackSystemPrompt.contains("constructive feedback") {
            issues.append("Feedback prompt missing constructive guidance")
        }
        if !solutionFeedbackSystemPrompt.contains("JSON") {
            issues.append("Feedback prompt missing JSON format requirement")
        }
        
        return issues
    }
    
    /// Get prompt statistics for monitoring
    static func getPromptStats() -> [String: Int] {
        return [
            "extractionPromptLength": extractionPrompt.count,
            "feedbackPromptLength": solutionFeedbackSystemPrompt.count,
            "fullWorksheetPromptLength": fullWorksheetFeedbackSystemPrompt.count,
            "totalPrompts": 4
        ]
    }

    // MARK: - Practice Problem Generation

    static let practiceGenerationSystemPrompt = """
    You are an expert math tutor specializing in creating practice problems.
    Generate practice problems that help students master mathematical concepts.

    Requirements:
    1. Each problem must be complete and solvable
    2. Include step-by-step solution
    3. Include progressive hints (from gentle to explicit)
    4. Match the requested difficulty level
    5. Focus on the specified concept/skill
    6. Use appropriate mathematical notation

    Output Format (JSON array):
    [
      {
        "problem_text": "Clear problem statement with LaTeX for math",
        "answer": "The correct answer",
        "step_by_step": "Step 1: ...\nStep 2: ...\nStep 3: ...",
        "hints": [
          "Gentle hint that guides without giving away",
          "More specific hint about approach",
          "Detailed hint showing first step"
        ],
        "concept": "Primary concept being tested",
        "question_type": "Computation/Word Problem/etc"
      }
    ]
    """

    static func practiceGenerationUserPrompt(
        basedOn context: String,
        difficulty: String,
        count: Int,
        gradeLevel: String,
        focusConcepts: [String]
    ) -> String {
        return """
    Generate \(count) practice problems with the following specifications:

    CONTEXT:
    \(context)

    DIFFICULTY: \(difficulty)
    - For "easier": Use simpler numbers, fewer steps, clearer patterns
    - For "similar": Match the original complexity level
    - For "harder": Use more complex numbers, additional steps, combine concepts

    GRADE LEVEL: \(gradeLevel)

    FOCUS CONCEPTS: \(focusConcepts.joined(separator: ", "))

    Generate diverse problems covering these concepts. Each problem should:
    1. Be clearly worded and mathematically correct
    2. Have a definitive answer
    3. Include helpful step-by-step solution
    4. Include 3 progressive hints

    Output ONLY valid JSON array.
    """
    }
}

