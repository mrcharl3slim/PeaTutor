//
//  StepByStepText.swift
//  PeaTutorApp
//
//  Created by Charles on 27/9/25.
//

import SwiftUI

// MARK: - Step-by-Step Solution Formatter
struct StepByStepText: View {
    let content: String
    let fontSize: CGFloat
    
    init(_ content: String, fontSize: CGFloat = 16) {
        self.content = content
        self.fontSize = fontSize
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parseSteps(content), id: \.id) { step in
                StepView(step: step, fontSize: fontSize)
            }
        }
    }
    
    private func parseSteps(_ text: String) -> [StepItem] {
        var steps: [StepItem] = []
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try different parsing strategies
        if let numberedSteps = parseNumberedSteps(cleanText), !numberedSteps.isEmpty {
            steps = numberedSteps
        } else if let lineBreakSteps = parseLineBreakSteps(cleanText), !lineBreakSteps.isEmpty {
            steps = lineBreakSteps
        } else if let sentenceSteps = parseSentenceSteps(cleanText), !sentenceSteps.isEmpty {
            steps = sentenceSteps
        } else {
            // Fallback: treat as single step
            steps = [StepItem(id: UUID(), number: nil, content: cleanText)]
        }
        
        return steps
    }
    
    // Parse numbered steps like "1. Step one 2. Step two" or "Step 1: ... Step 2: ..."
    private func parseNumberedSteps(_ text: String) -> [StepItem]? {
        var steps: [StepItem] = []
        
        // Pattern 1: "1. content 2. content"
        let pattern1 = #"(\d+)\.\s*([^0-9]+?)(?=\d+\.|$)"#
        if let regex1 = try? NSRegularExpression(pattern: pattern1, options: []) {
            let matches = regex1.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            
            for match in matches {
                if let numberRange = Range(match.range(at: 1), in: text),
                   let contentRange = Range(match.range(at: 2), in: text) {
                    let number = String(text[numberRange])
                    let content = String(text[contentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    steps.append(StepItem(id: UUID(), number: number, content: content))
                }
            }
            
            if !steps.isEmpty { return steps }
        }
        
        // Pattern 2: "Step 1: content Step 2: content"
        let pattern2 = #"Step\s+(\d+):\s*([^S]+?)(?=Step\s+\d+:|$)"#
        if let regex2 = try? NSRegularExpression(pattern: pattern2, options: [.caseInsensitive]) {
            let matches = regex2.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            
            for match in matches {
                if let numberRange = Range(match.range(at: 1), in: text),
                   let contentRange = Range(match.range(at: 2), in: text) {
                    let number = String(text[numberRange])
                    let content = String(text[contentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    steps.append(StepItem(id: UUID(), number: number, content: content))
                }
            }
        }
        
        return steps.isEmpty ? nil : steps
    }
    
    // Parse steps separated by line breaks
    private func parseLineBreakSteps(_ text: String) -> [StepItem]? {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if lines.count > 1 {
            return lines.enumerated().map { index, line in
                StepItem(id: UUID(), number: "\(index + 1)", content: line)
            }
        }
        
        return nil
    }
    
    // Parse steps by mathematical flow indicators
    private func parseSentenceSteps(_ text: String) -> [StepItem]? {
        let stepIndicators = [
            "Given:", "First,", "Then,", "Next,", "Therefore,", "Hence,", "Finally,", "So,",
            "Now,", "We have:", "Since", "Because", "Using", "Applying", "Substituting"
        ]
        
        var steps: [StepItem] = []
        var currentStep = ""
        var stepNumber = 1
        
        // Split by sentence boundaries and look for indicators
        let sentences = text.components(separatedBy: ". ")
        
        for sentence in sentences {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if this sentence starts with a step indicator
            let startsWithIndicator = stepIndicators.contains { indicator in
                trimmed.lowercased().hasPrefix(indicator.lowercased())
            }
            
            if startsWithIndicator && !currentStep.isEmpty {
                // Save previous step
                steps.append(StepItem(id: UUID(), number: "\(stepNumber)", content: currentStep))
                stepNumber += 1
                currentStep = trimmed
            } else {
                if currentStep.isEmpty {
                    currentStep = trimmed
                } else {
                    currentStep += ". " + trimmed
                }
            }
        }
        
        // Add the last step
        if !currentStep.isEmpty {
            steps.append(StepItem(id: UUID(), number: "\(stepNumber)", content: currentStep))
        }
        
        return steps.count > 1 ? steps : nil
    }
}

// MARK: - Step Item Model
struct StepItem {
    let id: UUID
    let number: String?
    let content: String
}

// MARK: - Individual Step View
struct StepView: View {
    let step: StepItem
    let fontSize: CGFloat
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step number
            if let number = step.number {
                Text(number)
                    .font(.system(size: fontSize - 2, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.blue))
                    .padding(.top, 2)
            }
            
            // Step content
            VStack(alignment: .leading, spacing: 4) {
                SimpleLaTeXText(step.content, fontSize: fontSize)
                    .lineSpacing(3)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Enhanced Solution Cards with Step Formatting
struct StepByStepSolutionCard: View {
    let title: String
    let content: String
    let icon: String
    let backgroundColor: Color
    let borderColor: Color
    let fontSize: CGFloat
    
    init(title: String, content: String, icon: String, backgroundColor: Color, borderColor: Color, fontSize: CGFloat = 16) {
        self.title = title
        self.content = content
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.fontSize = fontSize
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: icon)
                    .foregroundColor(borderColor)
                Text(title.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(borderColor)
                Spacer()
            }
            
            // Step-by-step content
            StepByStepText(content, fontSize: fontSize)
        }
        .padding(16)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1.5)
        )
        .cornerRadius(12)
    }
}

// MARK: - Enhanced Solution Section for Subparts
struct StepByStepSolutionSection: View {
    let title: String
    let content: String
    let icon: String
    let color: Color
    let fontSize: CGFloat
    
    init(title: String, content: String, icon: String, color: Color, fontSize: CGFloat = 15) {
        self.title = title
        self.content = content
        self.icon = icon
        self.color = color
        self.fontSize = fontSize
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            // Step-by-step content
            StepByStepText(content, fontSize: fontSize)
                .padding(.leading, 4)
        }
        .padding(12)
        .background(color.opacity(0.08))
        .cornerRadius(8)
    }
}

// MARK: - Usage Examples and Preview
struct StepByStepExample: View {
    let exampleSolutions = [
        "1. Find the gradient: m = (y₂ - y₁)/(x₂ - x₁) = (11-3)/(6-2) = 8/4 = 2 2. Use point-slope form: y - y₁ = m(x - x₁) 3. Substitute values: y - 3 = 2(x - 2) 4. Simplify: y - 3 = 2x - 4 5. Final answer: y = 2x - 1",
        
        "Given: Line L has equation y = 2x - 5, Point P(4,3)\nFirst, find the slope of line L: m₁ = 2\nThen, find perpendicular slope: m₂ = -1/2\nNext, use point-slope form: y - 3 = -1/2(x - 4)\nFinally, simplify: y = -1/2x + 5",
        
        "Step 1: Identify the function f(x) = x²\nStep 2: Apply the power rule: d/dx[x^n] = nx^(n-1)\nStep 3: Calculate: d/dx[x²] = 2x^(2-1) = 2x\nStep 4: Therefore, f'(x) = 2x"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(exampleSolutions.indices, id: \.self) { index in
                    StepByStepSolutionCard(
                        title: "Solution \(index + 1)",
                        content: exampleSolutions[index],
                        icon: "list.number",
                        backgroundColor: Color.green.opacity(0.1),
                        borderColor: Color.green.opacity(0.4)
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Step-by-Step Examples")
    }
}
