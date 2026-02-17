//
//  OpenAIClient.swift
//  PeaTutorApp
//
//  Complete version with all feedback methods
//

import Foundation
import UIKit
import PDFKit
import UniformTypeIdentifiers

class OpenAIClient {
    internal let apiKey: String
    private let baseURL = URL(string: "https://api.openai.com/v1")!
    private let urlSession: URLSession
    
    init?() {
        guard let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !key.isEmpty else {
            print("❌ OPENAI_API_KEY not found in environment")
            return nil
        }
        self.apiKey = key
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300
        self.urlSession = URLSession(configuration: config)
        
        print("✅ OpenAI client initialized")
    }
    
    // MARK: - Connection Test
    
    func testConnection() async throws -> String {
        let url = baseURL.appendingPathComponent("/chat/completions")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let config = PromptFactory.getConfig(for: .connectionTest)
        let payload: [String: Any] = [
            "model": config.model,
            "messages": [
                ["role": "user", "content": PromptFactory.connectionTestPrompt]
            ],
            "max_tokens": config.maxTokens,
            "temperature": config.temperature
        ]
        
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, resp) = try await urlSession.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let errText = String(data: data, encoding: .utf8) ?? "unknown"
            throw NSError(domain: "OpenAIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection test failed: \(errText)"])
        }
        
        return "✅ OpenAI API connection successful"
    }
    
    // Main method that handles both file upload and image processing
    func uploadFile(data: Data, filename: String, mimetype: String = "application/octet-stream", purpose: String = "assistants") async throws -> String {
        print("📤 Processing file: \(filename) (MIME: \(mimetype))")
        
        // Handle PDFs by converting to images
        if mimetype == "application/pdf" {
            print("📋 Converting PDF to images for vision processing...")
            let images = try convertPDFToImages(data: data)
            return "pdf_images:\(images.joined(separator: ","))"
        }
        
        // Handle image files (including camera captures) by converting to base64
        if mimetype.hasPrefix("image/") {
            print("🖼️ Converting image to base64 for vision processing...")
            let base64Image = data.base64EncodedString()
            return "image_base64:\(base64Image)"
        }
        
        // For other file types, try uploading to OpenAI (though we mainly expect images/PDFs)
        print("📁 Uploading non-image file to OpenAI...")
        return try await uploadFileToOpenAI(data: data, filename: filename, mimetype: mimetype, purpose: purpose)
    }
    
    // Convert PDF to base64 images using PDFKit
    private func convertPDFToImages(data: Data) throws -> [String] {
        guard let pdfDocument = PDFDocument(data: data) else {
            throw NSError(domain: "OpenAIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not create PDF document"])
        }
        
        var base64Images: [String] = []
        let pageCount = pdfDocument.pageCount
        
        print("📄 PDF has \(pageCount) pages, converting to images...")
        
        // Limit to first 10 pages to avoid token limits
        let maxPages = min(pageCount, 10)
        
        for pageIndex in 0..<maxPages {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            
            // Render page as image with high quality
            let pageRect = page.bounds(for: .mediaBox)
            let scaleFactor: CGFloat = 2.0 // High resolution
            let imageSize = CGSize(width: pageRect.width * scaleFactor, height: pageRect.height * scaleFactor)
            
            let renderer = UIGraphicsImageRenderer(size: imageSize)
            let image = renderer.image { context in
                UIColor.white.set()
                context.fill(CGRect(origin: .zero, size: imageSize))
                
                context.cgContext.translateBy(x: 0, y: imageSize.height)
                context.cgContext.scaleBy(x: scaleFactor, y: -scaleFactor)
                
                page.draw(with: .mediaBox, to: context.cgContext)
            }
            
            // Convert to base64
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                let base64String = imageData.base64EncodedString()
                base64Images.append(base64String)
                print("✅ Converted page \(pageIndex + 1) to image (\(imageData.count) bytes)")
            }
        }
        
        if base64Images.isEmpty {
            throw NSError(domain: "OpenAIClient", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not convert any PDF pages to images"])
        }
        
        print("🖼️ Successfully converted \(base64Images.count) pages to images")
        return base64Images
    }
    
    // Fallback upload method for non-image files
    private func uploadFileToOpenAI(data: Data, filename: String, mimetype: String, purpose: String) async throws -> String {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"purpose\"\r\n\r\n")
        body.appendString("\(purpose)\r\n")

        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimetype)\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
        body.appendString("--\(boundary)--\r\n")

        var req = URLRequest(url: baseURL.appendingPathComponent("/files"))
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        req.httpBody = body

        let (respData, resp) = try await urlSession.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let errText = String(data: respData, encoding: .utf8) ?? "unknown"
            throw NSError(domain: "OpenAIClient", code: (resp as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Upload failed: \(errText)"])
        }
        
        // Parse file ID
        if let obj = try? JSONSerialization.jsonObject(with: respData) as? [String:Any],
           let id = obj["id"] as? String {
            return id
        }
        throw NSError(domain: "OpenAIClient", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not parse upload response"])
    }


    // MARK: - File Processing
    
    func processFile(url: URL) async throws -> String {
        print("📄 Processing file: \(url.lastPathComponent)")
        
        let utType = UTType(filenameExtension: url.pathExtension)
        
        if utType == .pdf {
            return try await processPDF(url: url)
        } else if utType?.conforms(to: .image) == true {
            return try await processImage(url: url)
        } else {
            print("⚠️ Unsupported file type, treating as text")
            return try await processTextFile(url: url)
        }
    }
    
    private func processPDF(url: URL) async throws -> String {
        print("📑 Processing PDF...")
        
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "OpenAIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not access PDF file"])
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        guard let pdfDoc = PDFDocument(url: url) else {
            throw NSError(domain: "OpenAIClient", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not open PDF"])
        }
        
        let pageCount = pdfDoc.pageCount
        print("📊 PDF has \(pageCount) page(s)")
        
        var base64Images: [String] = []
        
        for pageIndex in 0..<min(pageCount, 20) {
            guard let page = pdfDoc.page(at: pageIndex) else { continue }
            
            let pageRect = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            
            let image = renderer.image { ctx in
                UIColor.white.set()
                ctx.fill(pageRect)
                ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
                ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }
            
            if let imageData = image.jpegData(compressionQuality: 0.95) {
                base64Images.append(imageData.base64EncodedString())
                print("📄 Converted page \(pageIndex + 1) to image")
            }
        }
        
        if base64Images.isEmpty {
            throw NSError(domain: "OpenAIClient", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not convert any PDF pages to images"])
        }
        
        print("🖼️ Successfully converted \(base64Images.count) pages to images")
        return "pdf_images:\(base64Images.joined(separator: ","))"
    }
    
    private func processImage(url: URL) async throws -> String {
        print("🖼️ Processing image...")
        
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "OpenAIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not access image file"])
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        guard let imageData = try? Data(contentsOf: url),
              let image = UIImage(data: imageData) else {
            throw NSError(domain: "OpenAIClient", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not load image"])
        }
        
        guard let jpegData = image.jpegData(compressionQuality: 0.95) else {
            throw NSError(domain: "OpenAIClient", code: -3, userInfo: [NSLocalizedDescriptionKey: "Could not convert image to JPEG"])
        }
        
        let base64 = jpegData.base64EncodedString()
        print("✅ Image processed: \(jpegData.count) bytes")
        
        return "image_base64:\(base64)"
    }
    
    private func processTextFile(url: URL) async throws -> String {
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "OpenAIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not access file"])
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let text = try String(contentsOf: url, encoding: .utf8)
        print("✅ Text file processed: \(text.count) characters")
        
        return "text:\(text)"
    }
    
    func processImage(_ image: UIImage) async throws -> String {
        print("📸 Processing captured image...")
        
        guard let imageData = image.jpegData(compressionQuality: 0.95) else {
            throw NSError(domain: "OpenAIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not convert image to JPEG"])
        }
        
        let base64 = imageData.base64EncodedString()
        print("✅ Captured image processed: \(imageData.count) bytes")
        
        return "image_base64:\(base64)"
    }
    
    // MARK: - Question Extraction
    
    func extractQuestions(fileIDs: [String], model: String = "gpt-4o") async throws -> ExtractedWorksheet {
        let url = baseURL.appendingPathComponent("/chat/completions")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var messages: [[String: Any]] = [
            [
                "role": "system",
                "content": "You are a precise extractor. Output valid JSON only, no commentary."
            ]
        ]
        
        var userContent: [[String: Any]] = [
            [
                "type": "text",
                "text": PromptFactory.extractionPrompt
            ]
        ]
        
        for fileID in fileIDs {
            print("📝 Processing fileID: \(fileID.prefix(20))...")
            
            if fileID.hasPrefix("pdf_images:") {
                let imagesString = String(fileID.dropFirst("pdf_images:".count))
                let base64Images = imagesString.components(separatedBy: ",")
                
                for (index, base64Image) in base64Images.enumerated() {
                    userContent.append([
                        "type": "image_url",
                        "image_url": [
                            "url": "data:image/jpeg;base64,\(base64Image)",
                            "detail": "high"
                        ]
                    ])
                    print("🖼️ Added PDF page \(index + 1) to vision request")
                }
            } else if fileID.hasPrefix("image_base64:") {
                let base64Image = String(fileID.dropFirst("image_base64:".count))
                
                userContent.append([
                    "type": "image_url",
                    "image_url": [
                        "url": "data:image/jpeg;base64,\(base64Image)",
                        "detail": "high"
                    ]
                ])
                print("📸 Added camera/image file to vision request")
            } else {
                print("⚠️ Unrecognized file ID format: \(fileID.prefix(20))... - skipping")
            }
        }
        
        messages.append([
            "role": "user",
            "content": userContent
        ])
        
        let config = PromptFactory.getConfig(for: .extraction)
        
        let payload: [String: Any] = [
            "model": config.model,
            "messages": messages,
            "max_tokens": config.maxTokens,
            "temperature": config.temperature
        ]
        
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        print("🤖 Making API request to: \(url)")
        print("🤖 Using model: \(config.model)")
        print("🤖 Processing \(fileIDs.count) file(s) with \(userContent.count - 1) images")
        
        let (data, resp) = try await performRequestWithRetry(request: req, maxRetries: 2)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let errText = String(data: data, encoding: .utf8) ?? "unknown"
            print("❌ API Error Response: \(errText)")
            throw NSError(domain: "OpenAIClient", code: (resp as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Chat Completions API error: \(errText)"])
        }
        
        struct ChatResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
                let finish_reason: String?
            }
            let choices: [Choice]
        }
        
        let response = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = response.choices.first?.message.content else {
            throw NSError(domain: "OpenAIClient", code: -3, userInfo: [NSLocalizedDescriptionKey: "No content in response"])
        }
        
        print("🤖 Raw API response length: \(content.count) characters")
        print("🤖 Response preview: \(content.prefix(200))...")
        
        return try parseExtractedContent(content)
    }
    
    private func parseExtractedContent(_ content: String) throws -> ExtractedWorksheet {
        let cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonStart = cleaned.range(of: "{")?.lowerBound ?? cleaned.startIndex
        let jsonEnd = cleaned.range(of: "}", options: .backwards)?.upperBound ?? cleaned.endIndex
        let jsonString = String(cleaned[jsonStart..<jsonEnd])
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(domain: "OpenAIClient", code: -4, userInfo: [NSLocalizedDescriptionKey: "Could not encode JSON string"])
        }
        
        let decoder = JSONDecoder()
        do {
            let parsed = try decoder.decode(ExtractedWorksheet.self, from: jsonData)
            print("✅ Successfully parsed \(parsed.questions.count) questions")
            return parsed
        } catch {
            print("❌ JSON parsing error: \(error)")
            print("📄 Raw JSON: \(jsonString.prefix(500))...")
            throw error
        }
    }
    
    // MARK: - Solution Feedback Analysis
    
    func analyzeSolutionImage(questionText: String, solutionImageData: Data) async throws -> AIFeedbackResult {
        let url = baseURL.appendingPathComponent("/chat/completions")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let base64Image = solutionImageData.base64EncodedString()
        
        let systemPrompt = PromptFactory.solutionFeedbackSystemPrompt
        let userPrompt = PromptFactory.solutionFeedbackUserPrompt(questionText: questionText)
        
        let messages: [[String: Any]] = [
            [
                "role": "system",
                "content": systemPrompt
            ],
            [
                "role": "user",
                "content": [
                    [
                        "type": "text",
                        "text": userPrompt
                    ],
                    [
                        "type": "image_url",
                        "image_url": [
                            "url": "data:image/jpeg;base64,\(base64Image)",
                            "detail": "high"
                        ]
                    ]
                ]
            ]
        ]
        
        let config = PromptFactory.getConfig(for: .solutionFeedback)
        
        let payload: [String: Any] = [
            "model": config.model,
            "messages": messages,
            "max_tokens": config.maxTokens,
            "temperature": config.temperature
        ]
        
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        print("🤖 Analyzing solution image with \(config.model)...")
        print("🤖 Question context: \(questionText.prefix(50))...")
        
        let (data, resp) = try await performRequestWithRetry(request: req, maxRetries: 2)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let errText = String(data: data, encoding: .utf8) ?? "unknown"
            throw NSError(domain: "OpenAIClient", code: (resp as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Solution analysis failed: \(errText)"])
        }
        
        struct ChatResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
                let finish_reason: String?
            }
            let choices: [Choice]
        }
        
        let response = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = response.choices.first?.message.content else {
            throw NSError(domain: "OpenAIClient", code: -3, userInfo: [NSLocalizedDescriptionKey: "No content in response"])
        }
        
        print("🤖 Solution feedback received: \(content.prefix(100))...")
        
        let result = try parseSolutionAnalysis(content)
        
        if result.feedback.lowercased().contains("can't see") || result.feedback.lowercased().contains("unclear") {
            print("⚠️ Image quality issue detected")
        } else if result.feedback.lowercased().contains("different") || result.feedback.lowercased().contains("doesn't appear") {
            print("⚠️ Irrelevant content detected")
        } else if result.isCorrect == true {
            print("✅ Correct solution detected")
        } else if result.isCorrect == false {
            print("📝 Solution needs improvement")
        }
        
        return result
    }
    
    private func parseSolutionAnalysis(_ content: String) throws -> AIFeedbackResult {
        let cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonStart = cleaned.range(of: "{")?.lowerBound ?? cleaned.startIndex
        let jsonEnd = cleaned.range(of: "}", options: .backwards)?.upperBound ?? cleaned.endIndex
        let jsonString = String(cleaned[jsonStart..<jsonEnd])
        
        guard let jsonData = jsonString.data(using: .utf8),
              let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return AIFeedbackResult(
                feedback: "I had trouble analyzing your image. Please make sure your written solution is clearly visible and try again.",
                isCorrect: nil,
                suggestions: ["Ensure good lighting", "Hold camera steady", "Frame your work clearly"]
            )
        }
        
        let feedback = jsonObject["feedback"] as? String ?? "I've reviewed your work. Please try uploading a clearer image if you'd like more specific feedback."
        let isCorrect = jsonObject["isCorrect"] as? Bool
        
        var suggestions = jsonObject["suggestions"] as? [String] ?? []
        
        if suggestions.isEmpty {
            if feedback.lowercased().contains("can't see") || feedback.lowercased().contains("unclear") {
                suggestions = ["Take a photo with better lighting", "Hold camera steady", "Make sure handwriting is visible"]
            } else if feedback.lowercased().contains("different") || feedback.lowercased().contains("doesn't appear") {
                suggestions = ["Check you're solving the correct question", "Upload your work for this specific problem"]
            } else if isCorrect == nil && !feedback.lowercased().contains("correct") {
                suggestions = ["Try writing more clearly", "Show all your work steps"]
            }
        }
        
        return AIFeedbackResult(feedback: feedback, isCorrect: isCorrect, suggestions: suggestions)
    }
    
    // MARK: - Full Worksheet Solution Analysis
    
    func analyzeFullWorksheetSolution(questions: [ExtractedQuestion], solutionImageData: Data) async throws -> WorksheetFeedbackResult {
        let url = baseURL.appendingPathComponent("/chat/completions")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let base64Image = solutionImageData.base64EncodedString()
        
        let questionsContext = buildQuestionsContext(questions: questions)
        
        let systemPrompt = PromptFactory.fullWorksheetFeedbackSystemPrompt
        let userPrompt = PromptFactory.fullWorksheetFeedbackUserPrompt(questionsContext: questionsContext)
        
        let messages: [[String: Any]] = [
            [
                "role": "system",
                "content": systemPrompt
            ],
            [
                "role": "user",
                "content": [
                    [
                        "type": "text",
                        "text": userPrompt
                    ],
                    [
                        "type": "image_url",
                        "image_url": [
                            "url": "data:image/jpeg;base64,\(base64Image)",
                            "detail": "high"
                        ]
                    ]
                ]
            ]
        ]
        
        let config = PromptFactory.getConfig(for: .fullWorksheetFeedback)
        
        let payload: [String: Any] = [
            "model": config.model,
            "messages": messages,
            "max_tokens": config.maxTokens,
            "temperature": config.temperature
        ]
        
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        print("🤖 Analyzing full worksheet solution with \(config.model)...")
        print("🤖 Analyzing \(questions.count) questions against submitted work")
        
        let (data, resp) = try await performRequestWithRetry(request: req, maxRetries: 2)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let errText = String(data: data, encoding: .utf8) ?? "unknown"
            throw NSError(domain: "OpenAIClient", code: (resp as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Full worksheet analysis failed: \(errText)"])
        }
        
        struct ChatResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
                let finish_reason: String?
            }
            let choices: [Choice]
        }
        
        let response = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = response.choices.first?.message.content else {
            throw NSError(domain: "OpenAIClient", code: -3, userInfo: [NSLocalizedDescriptionKey: "No content in response"])
        }
        
        print("🤖 Full worksheet feedback received: \(content.prefix(100))...")
        
        let result = try parseFullWorksheetAnalysis(content, totalQuestions: questions.count)
        
        print("📊 Overall score: \(result.overallScore)/\(questions.count) questions attempted")
        print("✅ Completed: \(result.completedQuestions.count), ❌ Issues: \(result.questionsWithIssues.count)")
        
        return result
    }
    
    private func buildQuestionsContext(questions: [ExtractedQuestion]) -> String {
        var context = "The worksheet contains \(questions.count) questions:\n\n"
        
        for (index, question) in questions.enumerated() {
            context += "**Question \(index + 1) [\(question.marks) marks]:** \(question.questionText)\n"
            
            if !question.subparts.isEmpty {
                for subpart in question.subparts {
                    context += "  - Part \(subpart.id) [\(subpart.marks) marks]: \(subpart.text)\n"
                }
            }
            
            context += "\n"
        }
        
        return context
    }
    
    private func parseFullWorksheetAnalysis(_ content: String, totalQuestions: Int) throws -> WorksheetFeedbackResult {
        let cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonStart = cleaned.range(of: "{")?.lowerBound ?? cleaned.startIndex
        let jsonEnd = cleaned.range(of: "}", options: .backwards)?.upperBound ?? cleaned.endIndex
        let jsonString = String(cleaned[jsonStart..<jsonEnd])
        
        guard let jsonData = jsonString.data(using: .utf8),
              let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return WorksheetFeedbackResult(
                overallFeedback: "I had trouble analyzing the full worksheet. Please make sure all your work is clearly visible and try again.",
                overallScore: 0,
                completedQuestions: [],
                questionsWithIssues: [],
                suggestions: ["Ensure good lighting", "Frame all your work in the photo", "Make handwriting legible"],
                detailedFeedback: []
            )
        }
        
        let overallFeedback = jsonObject["overall_feedback"] as? String ?? "Worksheet analysis completed."
        let overallScore = jsonObject["overall_score"] as? Int ?? 0
        let completedQuestions = jsonObject["completed_questions"] as? [String] ?? []
        let questionsWithIssues = jsonObject["questions_with_issues"] as? [String] ?? []
        let suggestions = jsonObject["suggestions"] as? [String] ?? []
        
        var detailedFeedback: [QuestionFeedback] = []
        if let feedbackArray = jsonObject["detailed_feedback"] as? [[String: Any]] {
            for feedbackItem in feedbackArray {
                if let questionId = feedbackItem["question_id"] as? String,
                   let feedback = feedbackItem["feedback"] as? String {
                    let isCorrect = feedbackItem["is_correct"] as? Bool
                    detailedFeedback.append(QuestionFeedback(
                        questionId: questionId,
                        feedback: feedback,
                        isCorrect: isCorrect
                    ))
                }
            }
        }
        
        return WorksheetFeedbackResult(
            overallFeedback: overallFeedback,
            overallScore: overallScore,
            completedQuestions: completedQuestions,
            questionsWithIssues: questionsWithIssues,
            suggestions: suggestions,
            detailedFeedback: detailedFeedback
        )
    }
    
    // MARK: - Retry Logic
    
    private func performRequestWithRetry(
        request: URLRequest,
        maxRetries: Int = 2,
        retryDelay: TimeInterval = 2.0
    ) async throws -> (Data, URLResponse) {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                if attempt > 0 {
                    print("🔄 Retry attempt \(attempt)/\(maxRetries) after \(retryDelay)s delay...")
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                }
                
                let (data, response) = try await urlSession.data(for: request)
                print("✅ Request succeeded on attempt \(attempt + 1)")
                return (data, response)
                
            } catch let error as NSError where error.code == NSURLErrorTimedOut {
                lastError = error
                print("⏱️ Request timed out on attempt \(attempt + 1)")
                
                if attempt == maxRetries {
                    print("❌ All retry attempts exhausted")
                    throw error
                }
            } catch {
                print("❌ Request failed with non-timeout error: \(error)")
                throw error
            }
        }
        
        throw lastError ?? NSError(
            domain: "OpenAIClient",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Request failed after \(maxRetries) retries"]
        )
    }
    
    // MARK: - OpenAI Client Curriculum Extensions
    /// Generate curriculum-aligned practice problems
    func generateCurriculumAlignedPracticeProblems(
        systemPrompt: String,
        userPrompt: String
    ) async throws -> [GeneratedProblemResponseWithCurriculum] {
        let url = URL(string: "https://api.openai.com/v1")!.appendingPathComponent("/chat/completions")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 120
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userPrompt]
        ]
        
        let payload: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "max_tokens": 8000,
            "temperature": 0.7
        ]
        
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        print("🤖 Generating curriculum-aligned practice problems...")
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let errText = String(data: data, encoding: .utf8) ?? "unknown"
            throw PracticeGenerationError.generationFailed(errText)
        }
        
        struct ChatResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }
        
        let response = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = response.choices.first?.message.content else {
            throw PracticeGenerationError.parsingFailed
        }
        
        // Parse JSON array from response
        let problems = try parseCurriculumAlignedProblems(content)
        
        print("✅ Parsed \(problems.count) curriculum-aligned practice problems")
        return problems
    }
    
    private func parseCurriculumAlignedProblems(_ content: String) throws -> [GeneratedProblemResponseWithCurriculum] {
        // Clean the content - remove markdown code blocks if present
        var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove ```json and ``` markers
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find JSON array
        guard let jsonStart = cleaned.firstIndex(of: "["),
              let jsonEnd = cleaned.lastIndex(of: "]") else {
            throw PracticeGenerationError.parsingFailed
        }
        
        let jsonString = String(cleaned[jsonStart...jsonEnd])
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw PracticeGenerationError.parsingFailed
        }
        
        let problems = try JSONDecoder().decode([GeneratedProblemResponseWithCurriculum].self, from: jsonData)
        return problems
    }
}

// MARK: - Data Extension

fileprivate extension Data {
    mutating func appendString(_ string: String) {
        if let d = string.data(using: .utf8) { append(d) }
    }
}

// MARK: - Result Types (PUBLIC)

public struct AIFeedbackResult {
    public let feedback: String
    public let isCorrect: Bool?
    public let suggestions: [String]
    
    public init(feedback: String, isCorrect: Bool?, suggestions: [String]) {
        self.feedback = feedback
        self.isCorrect = isCorrect
        self.suggestions = suggestions
    }
}

public struct WorksheetFeedbackResult {
    public let overallFeedback: String
    public let overallScore: Int
    public let completedQuestions: [String]
    public let questionsWithIssues: [String]
    public let suggestions: [String]
    public let detailedFeedback: [QuestionFeedback]
    
    public init(
        overallFeedback: String,
        overallScore: Int,
        completedQuestions: [String],
        questionsWithIssues: [String],
        suggestions: [String],
        detailedFeedback: [QuestionFeedback]
    ) {
        self.overallFeedback = overallFeedback
        self.overallScore = overallScore
        self.completedQuestions = completedQuestions
        self.questionsWithIssues = questionsWithIssues
        self.suggestions = suggestions
        self.detailedFeedback = detailedFeedback
    }
}

public struct QuestionFeedback: Codable, Identifiable {
    public let id = UUID()
    public let questionId: String
    public let feedback: String
    public let isCorrect: Bool?
    
    public init(questionId: String, feedback: String, isCorrect: Bool?) {
        self.questionId = questionId
        self.feedback = feedback
        self.isCorrect = isCorrect
    }
    
    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case feedback
        case isCorrect = "is_correct"
    }
}

// MARK: - Worksheet Metadata Extraction

extension OpenAIClient {
    
    /// Extract comprehensive metadata from worksheet for analytics
    /// This is called AFTER questions are extracted to add analytical metadata
    func extractWorksheetMetadata(
        worksheet: ExtractedWorksheet,
        fileIDs: [String]
    ) async throws -> WorksheetMetadataExtraction {
        print("🧠 Extracting worksheet metadata for analytics...")
        
        let url = baseURL.appendingPathComponent("/chat/completions")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build context about the worksheet
        let questionsContext = buildQuestionsContextForMetadata(worksheet: worksheet)
        
        let systemPrompt = """
You are an expert educational analyst specializing in mathematics curriculum and assessment.
Analyze the worksheet and provide comprehensive metadata in JSON format.

Output ONLY valid JSON with this exact structure:
{
  "topics": ["Addition", "Subtraction"],
  "difficulty": "Grade 4",
  "cognitive_skills": ["Computation", "Problem Solving"],
  "question_types": ["Word Problem", "Computation"],
  "estimated_time_minutes": 30,
  "complexity_level": "Medium",
  "common_core_standards": ["4.NBT.A.1"],
  "blooms_taxonomy_levels": ["Remember", "Apply"]
}
"""
        
        let userPrompt = """
Analyze this mathematics worksheet and extract metadata:

\(questionsContext)

Provide comprehensive metadata including:
1. Topics covered (e.g., "Addition", "Fractions", "Division")
2. Estimated grade level (e.g., "Grade 3", "Grade 4")
3. Cognitive skills required (e.g., "Computation", "Problem Solving", "Reasoning", "Visualization")
4. Question types present (e.g., "Multiple Choice", "Word Problem", "Show Your Work", "Fill in the blank")
5. Estimated completion time in minutes
6. Overall complexity level (Easy, Medium, Hard, Very Hard)
7. Common Core standards if identifiable (optional)
8. Bloom's Taxonomy levels (Remember, Understand, Apply, Analyze, Evaluate, Create)

Output ONLY valid JSON matching the structure provided.
"""
        
        var messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userPrompt]
        ]
        
        let payload: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "max_tokens": 1000,
            "temperature": 0.3
        ]
        
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        print("🤖 Requesting worksheet metadata from GPT-4o...")
        
        let (data, resp) = try await performRequestWithRetry(request: req, maxRetries: 2)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let errText = String(data: data, encoding: .utf8) ?? "unknown"
            print("❌ API Error Response: \(errText)")
            throw NSError(domain: "OpenAIClient", code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                         userInfo: [NSLocalizedDescriptionKey: "Metadata extraction failed: \(errText)"])
        }
        
        struct ChatResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }
        
        let response = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = response.choices.first?.message.content else {
            throw NSError(domain: "OpenAIClient", code: -3,
                         userInfo: [NSLocalizedDescriptionKey: "No content in response"])
        }
        
        print("✅ Metadata extraction response received")
        
        return try parseWorksheetMetadata(content)
    }
    
    private func buildQuestionsContextForMetadata(worksheet: ExtractedWorksheet) -> String {
        var context = "Worksheet with \(worksheet.questions.count) questions:\n\n"
        
        for (index, question) in worksheet.questions.enumerated() {
            context += "Question \(index + 1) [\(question.marks) marks]: \(question.questionText)\n"
            
            if !question.subparts.isEmpty {
                for subpart in question.subparts {
                    context += "  - Part \(subpart.id): \(subpart.text)\n"
                }
            }
            
            if !question.skillsTested.isEmpty {
                context += "  Skills: \(question.skillsTested.joined(separator: ", "))\n"
            }
            
            context += "\n"
        }
        
        return context
    }
    
    private func parseWorksheetMetadata(_ content: String) throws -> WorksheetMetadataExtraction {
        // Extract JSON from response
        let cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonStart = cleaned.range(of: "{")?.lowerBound ?? cleaned.startIndex
        let jsonEnd = cleaned.range(of: "}", options: .backwards)?.upperBound ?? cleaned.endIndex
        let jsonString = String(cleaned[jsonStart..<jsonEnd])
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(domain: "OpenAIClient", code: -4,
                         userInfo: [NSLocalizedDescriptionKey: "Could not encode JSON string"])
        }
        
        let decoder = JSONDecoder()
        do {
            var metadata = try decoder.decode(WorksheetMetadataExtraction.self, from: jsonData)
            metadata.aiModel = "gpt-4o"
            print("✅ Parsed worksheet metadata: \(metadata.topics.joined(separator: ", "))")
            return metadata
        } catch {
            print("❌ JSON parsing error: \(error)")
            print("📄 Raw JSON: \(jsonString)")
            throw error
        }
    }
}

// MARK: - Question Metadata Extraction

extension OpenAIClient {
    
    /// Extract detailed metadata for individual questions
    func extractQuestionMetadata(
        question: ExtractedQuestion,
        gradeLevel: String
    ) async throws -> QuestionMetadataExtraction {
        print("🔍 Extracting metadata for question: \(question.id)")
        
        let url = baseURL.appendingPathComponent("/chat/completions")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemPrompt = """
You are an educational assessment expert. Analyze this math question and provide detailed metadata.

Output ONLY valid JSON:
{
  "question_type": "Word Problem",
  "difficulty_level": "Medium",
  "cognitive_level": "Apply",
  "primary_concept": "Fractions",
  "secondary_concepts": ["Division", "Decimals"],
  "prerequisite_skills": ["Basic division", "Understanding fractions"],
  "common_mistakes": ["Forgetting to simplify", "Inverting wrong fraction"],
  "conceptual_challenges": ["Understanding division of fractions"],
  "has_multiple_steps": true,
  "requires_visualization": true,
  "is_word_problem": true
}
"""
        
        let userPrompt = """
Analyze this \(gradeLevel) mathematics question:

Question: \(question.questionText)
Points: \(question.marks)
Skills: \(question.skillsTested.joined(separator: ", "))

Provide detailed metadata:
1. Question type: Multiple Choice, Word Problem, Computation, Show Your Work, Fill in the blank
2. Difficulty level: Easy, Medium, Hard
3. Cognitive level (Bloom's): Remember, Understand, Apply, Analyze, Evaluate, Create
4. Primary mathematical concept
5. Secondary concepts (if any)
6. Prerequisite skills needed
7. Common mistakes students make
8. Conceptual challenges
9. Whether it requires multiple steps
10. Whether visualization would help
11. Whether it's a word problem

Output ONLY valid JSON.
"""
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userPrompt]
        ]
        
        let payload: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "max_tokens": 500,
            "temperature": 0.3
        ]
        
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, resp) = try await performRequestWithRetry(request: req, maxRetries: 2)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let errText = String(data: data, encoding: .utf8) ?? "unknown"
            throw NSError(domain: "OpenAIClient", code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                         userInfo: [NSLocalizedDescriptionKey: "Question metadata extraction failed: \(errText)"])
        }
        
        struct ChatResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }
        
        let response = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = response.choices.first?.message.content else {
            throw NSError(domain: "OpenAIClient", code: -3,
                         userInfo: [NSLocalizedDescriptionKey: "No content in response"])
        }
        
        return try parseQuestionMetadata(content)
    }
    
    private func parseQuestionMetadata(_ content: String) throws -> QuestionMetadataExtraction {
        let cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonStart = cleaned.range(of: "{")?.lowerBound ?? cleaned.startIndex
        let jsonEnd = cleaned.range(of: "}", options: .backwards)?.upperBound ?? cleaned.endIndex
        let jsonString = String(cleaned[jsonStart..<jsonEnd])
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(domain: "OpenAIClient", code: -4,
                         userInfo: [NSLocalizedDescriptionKey: "Could not encode JSON string"])
        }
        
        let decoder = JSONDecoder()
        do {
            let metadata = try decoder.decode(QuestionMetadataExtraction.self, from: jsonData)
            print("✅ Parsed question metadata: \(metadata.questionType), \(metadata.difficultyLevel)")
            return metadata
        } catch {
            print("❌ JSON parsing error: \(error)")
            throw error
        }
    }
}

// MARK: - Error Pattern Analysis

extension OpenAIClient {
    
    /// Analyze incorrect answer to identify error patterns
    func analyzeErrorPattern(
        question: ExtractedQuestion,
        studentAnswer: String,
        isCorrect: Bool,
        existingFeedback: String
    ) async throws -> ErrorPatternAnalysis? {
        // Only analyze if answer was incorrect
        guard !isCorrect else { return nil }
        
        print("🔍 Analyzing error pattern...")
        
        let url = baseURL.appendingPathComponent("/chat/completions")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemPrompt = """
You are a mathematics education specialist. Analyze this student's error and identify the pattern.

Output ONLY valid JSON:
{
  "error_type": "Conceptual Error",
  "error_category": "Fractions",
  "description": "Student struggles with fraction division",
  "root_cause": "Doesn't understand 'invert and multiply' rule",
  "remediation": "Use visual models like fraction circles",
  "affected_concepts": ["Fraction Division", "Reciprocals"],
  "severity": "high"
}
"""
        
        let userPrompt = """
Analyze this student error:

Question: \(question.questionText)
Skills tested: \(question.skillsTested.joined(separator: ", "))
Student's answer: \(studentAnswer)
Feedback given: \(existingFeedback)

Identify:
1. Error type: Careless Mistake, Conceptual Error, Procedural Error, Computation Error, Sign Error, etc.
2. Error category: The mathematical area (Fractions, Division, Word Problems, etc.)
3. Description: Brief explanation of the error
4. Root cause: Why the student likely made this error
5. Remediation: Suggested teaching strategy
6. Affected concepts: All concepts impacted by this error
7. Severity: low, medium, or high (based on impact on learning)

Output ONLY valid JSON.
"""
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userPrompt]
        ]
        
        let payload: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "max_tokens": 400,
            "temperature": 0.3
        ]
        
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, resp) = try await performRequestWithRetry(request: req, maxRetries: 2)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            // If error analysis fails, it's not critical - return nil
            print("⚠️ Error pattern analysis failed, continuing...")
            return nil
        }
        
        struct ChatResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }
        
        let response = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = response.choices.first?.message.content else {
            return nil
        }
        
        return try? parseErrorPattern(content)
    }
    
    private func parseErrorPattern(_ content: String) throws -> ErrorPatternAnalysis {
        let cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonStart = cleaned.range(of: "{")?.lowerBound ?? cleaned.startIndex
        let jsonEnd = cleaned.range(of: "}", options: .backwards)?.upperBound ?? cleaned.endIndex
        let jsonString = String(cleaned[jsonStart..<jsonEnd])
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(domain: "OpenAIClient", code: -4,
                         userInfo: [NSLocalizedDescriptionKey: "Could not encode JSON string"])
        }
        
        let decoder = JSONDecoder()
        let analysis = try decoder.decode(ErrorPatternAnalysis.self, from: jsonData)
        print("✅ Parsed error pattern: \(analysis.errorType)")
        return analysis
    }
}

// MARK: - OpenAI Client Extension

extension OpenAIClient {
    
    /// Generate practice problems using GPT-4
    func generatePracticeProblems(
        context: String,
        difficulty: PracticeDifficulty,
        count: Int,
        gradeLevel: String,
        concepts: [String]
    ) async throws -> [GeneratedProblemResponse] {
        let url = URL(string: "https://api.openai.com/v1")!.appendingPathComponent("/chat/completions")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 120
        
        let systemPrompt = PromptFactory.practiceGenerationSystemPrompt
        let userPrompt = PromptFactory.practiceGenerationUserPrompt(
            basedOn: context,
            difficulty: difficulty.rawValue,
            count: count,
            gradeLevel: gradeLevel,
            focusConcepts: concepts
        )
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userPrompt]
        ]
        
        let payload: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "max_tokens": 8000,
            "temperature": 0.7
        ]
        
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        print("🤖 Generating \(count) practice problems...")
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let errText = String(data: data, encoding: .utf8) ?? "unknown"
            throw PracticeGenerationError.generationFailed(errText)
        }
        
        struct ChatResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }
        
        let response = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = response.choices.first?.message.content else {
            throw PracticeGenerationError.parsingFailed
        }
        
        // Parse JSON array from response
        let problems = try parsePracticeProblems(content)
        
        print("✅ Parsed \(problems.count) practice problems")
        return problems
    }
    
    private func parsePracticeProblems(_ content: String) throws -> [GeneratedProblemResponse] {
        // Clean the content - remove markdown code blocks if present
        var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove ```json and ``` markers
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find JSON array
        guard let jsonStart = cleaned.firstIndex(of: "["),
              let jsonEnd = cleaned.lastIndex(of: "]") else {
            throw PracticeGenerationError.parsingFailed
        }
        
        let jsonString = String(cleaned[jsonStart...jsonEnd])
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw PracticeGenerationError.parsingFailed
        }
        
        let problems = try JSONDecoder().decode([GeneratedProblemResponse].self, from: jsonData)
        return problems
    }
}


// MARK: - Supporting Models

public struct QuestionMetadataExtraction: Codable {
    public var questionType: String
    public var difficultyLevel: String
    public var cognitiveLevel: String
    public var primaryConcept: String
    public var secondaryConcepts: [String]?
    public var prerequisiteSkills: [String]?
    public var commonMistakes: [String]?
    public var conceptualChallenges: [String]?
    public var hasMultipleSteps: Bool
    public var requiresVisualization: Bool
    public var isWordProblem: Bool
    
    enum CodingKeys: String, CodingKey {
        case questionType = "question_type"
        case difficultyLevel = "difficulty_level"
        case cognitiveLevel = "cognitive_level"
        case primaryConcept = "primary_concept"
        case secondaryConcepts = "secondary_concepts"
        case prerequisiteSkills = "prerequisite_skills"
        case commonMistakes = "common_mistakes"
        case conceptualChallenges = "conceptual_challenges"
        case hasMultipleSteps = "has_multiple_steps"
        case requiresVisualization = "requires_visualization"
        case isWordProblem = "is_word_problem"
    }
}

//
//  OpenAIClient+Curriculum.swift
//  PeaTutorApp
//
//  Sprint 8 Phase 4: Curriculum-Aware Practice Generation
//  Extension to OpenAIClient for curriculum-integrated AI operations
//

import Foundation

// MARK: - Curriculum-Aware Practice Generation

extension OpenAIClient {
    
    /// Generate practice problems with MOE curriculum alignment
    /// This method uses curriculum-aware prompts and returns problems with curriculum codes
    func generateCurriculumAwarePracticeProblems(
        context: String,
        difficulty: PracticeDifficulty,
        count: Int,
        gradeLevel: String,
        gradeLevelCode: String,
        concepts: [String],
        targetCurriculumCodes: [String] = []
    ) async throws -> [GeneratedProblemResponseWithCurriculum] {
        let url = URL(string: "https://api.openai.com/v1")!.appendingPathComponent("/chat/completions")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 120
        
        // Use curriculum-aware prompts
        let systemPrompt = PromptFactory.curriculumAwarePracticeSystemPrompt
        let userPrompt = PromptFactory.curriculumAwarePracticeUserPrompt(
            basedOn: context,
            difficulty: difficulty.rawValue,
            count: count,
            gradeLevel: gradeLevel,
            gradeLevelCode: gradeLevelCode,
            focusConcepts: concepts,
            targetCurriculumCodes: targetCurriculumCodes
        )
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userPrompt]
        ]
        
        let payload: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "max_tokens": 8000,
            "temperature": 0.7
        ]
        
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        print("🤖 Generating \(count) curriculum-aligned practice problems for \(gradeLevel)...")
        print("📚 Target curriculum codes: \(targetCurriculumCodes.isEmpty ? "Auto-detect" : targetCurriculumCodes.joined(separator: ", "))")
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let errText = String(data: data, encoding: .utf8) ?? "unknown"
            throw PracticeGenerationError.generationFailed(errText)
        }
        
        struct ChatResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }
        
        let response = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = response.choices.first?.message.content else {
            throw PracticeGenerationError.parsingFailed
        }
        
        // Parse JSON array with curriculum fields
        let problems = try parseCurriculumAwarePracticeProblems(content, expectedGradeCode: gradeLevelCode)
        
        print("✅ Parsed \(problems.count) curriculum-aligned practice problems")
        return problems
    }
    
    /// Parse practice problems with curriculum information
    private func parseCurriculumAwarePracticeProblems(
        _ content: String,
        expectedGradeCode: String
    ) throws -> [GeneratedProblemResponseWithCurriculum] {
        // Clean the content - remove markdown code blocks if present
        var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove ```json and ``` markers
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find JSON array
        guard let jsonStart = cleaned.firstIndex(of: "["),
              let jsonEnd = cleaned.lastIndex(of: "]") else {
            throw PracticeGenerationError.parsingFailed
        }
        
        let jsonString = String(cleaned[jsonStart...jsonEnd])
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw PracticeGenerationError.parsingFailed
        }
        
        var problems = try JSONDecoder().decode([GeneratedProblemResponseWithCurriculum].self, from: jsonData)
        
        // Validate and enforce grade boundaries
        problems = problems.map { problem in
            var validated = problem
            
            // Ensure curriculum grade code matches expected
            if let problemGradeCode = problem.curriculumGradeLevelCode,
               problemGradeCode != expectedGradeCode {
                print("⚠️ Grade mismatch detected: \(problemGradeCode) vs expected \(expectedGradeCode), adjusting...")
                validated.curriculumGradeLevelCode = expectedGradeCode
                validated.curriculumGradeLevel = Self.gradeCodeToGradeLevel(expectedGradeCode)
            }
            
            // Set defaults if missing
            if validated.curriculumGradeLevelCode == nil {
                validated.curriculumGradeLevelCode = expectedGradeCode
                validated.curriculumGradeLevel = Self.gradeCodeToGradeLevel(expectedGradeCode)
            }
            
            return validated
        }
        
        return problems
    }
    
    // MARK: - Local Helper Methods (avoid MainActor isolation issues)
    
    /// Convert grade code to grade level string (local version to avoid actor isolation)
    private static func gradeCodeToGradeLevel(_ code: String) -> String? {
        let mapping: [String: String] = [
            "P1": "Primary 1",
            "P2": "Primary 2",
            "P3": "Primary 3",
            "P4": "Primary 4",
            "P5": "Primary 5",
            "P6": "Primary 6"
        ]
        return mapping[code.uppercased()]
    }
}

// MARK: - Grade Boundary Validation

extension OpenAIClient {
    
    /// Validate that a problem is appropriate for a given grade level
    func validateGradeBoundary(
        problem: GeneratedProblemResponseWithCurriculum,
        expectedGradeCode: String
    ) -> (isValid: Bool, reason: String?) {
        // Check if curriculum code matches expected grade
        if let problemGradeCode = problem.curriculumGradeLevelCode {
            let expectedGradeNum = gradeCodeToNumber(expectedGradeCode)
            let problemGradeNum = gradeCodeToNumber(problemGradeCode)
            
            if problemGradeNum > expectedGradeNum {
                return (false, "Problem is from \(problemGradeCode) but student is in \(expectedGradeCode)")
            }
        }
        
        // Additional content-based validation could be added here
        // e.g., checking number ranges, operations, etc.
        
        return (true, nil)
    }
    
    private func gradeCodeToNumber(_ code: String) -> Int {
        switch code.uppercased() {
        case "P1": return 1
        case "P2": return 2
        case "P3": return 3
        case "P4": return 4
        case "P5": return 5
        case "P6": return 6
        default: return 0
        }
    }
}
