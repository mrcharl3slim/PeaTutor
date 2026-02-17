//
//  JSONPreviewView.swift
//  PeaTutorApp
//
//  Fixed for Sub-Sprint 3.4 compatibility
//

import SwiftUI

struct JSONPreviewView: View {
    let result: ExtractedWorksheet
    let savedWorksheetId: String?
    @State private var viewMode: ViewMode = .perQuestion
    
    enum ViewMode: String, CaseIterable {
        case perQuestion = "Per Question"
        case overview = "Overview"
        case listView = "List View"
    }

    var body: some View {
        VStack(spacing: 0) {
            // View Mode Picker
            Picker("View Mode", selection: $viewMode) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            // Content based on selected view mode
            switch viewMode {
            case .perQuestion:
                QuestionContainerView(
                    result: result,
                    worksheetId: savedWorksheetId ?? result.id.uuidString
                )
                
            case .overview:
                WorksheetOverviewView(result: result,savedWorksheetId: savedWorksheetId)
                
            case .listView:
                OriginalListView(result: result,savedWorksheetId: savedWorksheetId)
            }
        }
        .navigationTitle("Parsed Questions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Worksheet Overview View with Full Worksheet Feedback
struct WorksheetOverviewView: View {
    let result: ExtractedWorksheet
    let savedWorksheetId: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // FULL WORKSHEET SOLUTION SECTION (Prominent at top)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("Solution Feedback Options")
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // ✅ Use savedWorksheetId if available
                                        if let worksheetId = savedWorksheetId {
                                            FullWorksheetFeedbackButton(
                                                worksheetId: worksheetId,
                                                questions: result.questions
                                            )
                                            .padding(.horizontal)
                                        } else {
                                            // Show loading state while worksheet syncs
                                            HStack {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                                Text("Syncing worksheet to database...")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(12)
                                            .padding(.horizontal)
                                        }
                }
                .padding(.vertical, 8)
                
                Divider()
                    .padding(.horizontal)
                
                // Summary Card
                WorksheetSummaryCard(result: result)
                    .padding(.horizontal)
                
                // Skills Breakdown
                SkillsBreakdownCard(result: result)
                    .padding(.horizontal)
                
                // Quick Question List
                QuickQuestionsList(
                    questions: result.questions,
                    worksheetId: savedWorksheetId ?? result.id.uuidString
                )
                .padding(.horizontal)
                
                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Worksheet Summary Card
struct WorksheetSummaryCard: View {
    let result: ExtractedWorksheet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                Text("Worksheet Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 20) {
                summaryItem(
                    icon: "number.circle.fill",
                    title: "Questions",
                    value: "\(result.questions.count)",
                    color: .blue
                )
                
                summaryItem(
                    icon: "star.fill",
                    title: "Total Marks",
                    value: "\(totalMarks)",
                    color: .orange
                )
                
                summaryItem(
                    icon: "list.bullet",
                    title: "Parts",
                    value: "\(totalSubparts)",
                    color: .green
                )
            }
        }
        .padding(16)
        .background(Color.blue.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
        )
        .cornerRadius(12)
    }
    
    private func summaryItem(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var totalMarks: Int {
        result.questions.reduce(0) { total, question in
            let questionMarks = question.marks
            let subpartMarks = question.subparts.reduce(0) { $0 + $1.marks }
            return total + questionMarks + subpartMarks
        }
    }
    
    private var totalSubparts: Int {
        result.questions.reduce(0) { $0 + $1.subparts.count }
    }
}

// MARK: - Skills Breakdown Card
struct SkillsBreakdownCard: View {
    let result: ExtractedWorksheet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.green)
                Text("Skills Breakdown")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            let skillsCount = getSkillsCount()
            
            if skillsCount.isEmpty {
                Text("No skills detected")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(Array(skillsCount.keys.sorted()), id: \.self) { skill in
                        HStack {
                            Text(skill)
                                .font(.caption)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(skillsCount[skill] ?? 0)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.green.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1.5)
        )
        .cornerRadius(12)
    }
    
    private func getSkillsCount() -> [String: Int] {
        var skillsCount: [String: Int] = [:]
        
        for question in result.questions {
            for skill in question.skillsTested {
                skillsCount[skill, default: 0] += 1
            }
            for subpart in question.subparts {
                for skill in subpart.skillsTested {
                    skillsCount[skill, default: 0] += 1
                }
            }
        }
        
        return skillsCount
    }
}

// MARK: - Quick Questions List
struct QuickQuestionsList: View {
    let questions: [ExtractedQuestion]
    let worksheetId: String
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.number")
                    .foregroundColor(.purple)
                Text("Questions Quick View")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(questions.indices, id: \.self) { index in
                    NavigationLink {
                        QuestionDetailView(
                            question: questions[index],
                            questionNumber: index + 1,
                            worksheetId: worksheetId
                        )
                    } label: {
                        QuickQuestionRow(
                            question: questions[index],
                            questionNumber: index + 1
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
        .background(Color.purple.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1.5)
        )
        .cornerRadius(12)
    }
}

// MARK: - Quick Question Row
struct QuickQuestionRow: View {
    let question: ExtractedQuestion
    let questionNumber: Int
    
    var body: some View {
        HStack {
            Text("Q\(questionNumber)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.purple)
                .cornerRadius(16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(question.questionText.prefix(60) + (question.questionText.count > 60 ? "..." : ""))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack {
                    Text("[\(question.marks) marks]")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !question.subparts.isEmpty {
                        Text("• \(question.subparts.count) parts")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Original List View (for comparison/backup)
struct OriginalListView: View {
    let result: ExtractedWorksheet
    let savedWorksheetId: String?

    var body: some View {
        List {
            ForEach(result.questions.indices, id: \.self) { i in
                let q = result.questions[i]
                Section(header: originalQuestionHeader(for: q)) {
                    // Main question text
                    VStack(alignment: .leading, spacing: 12) {
                        if !q.questionText.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("QUESTION")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                SimpleLaTeXText(q.questionText, fontSize: 16)
                                    .padding(.leading, 4)
                            }
                        }
                        
                        // Show hints, steps, and answer for main question (if no subparts)
                        if q.subparts.isEmpty {
                            if let hints = q.hints, !hints.isEmpty {
                                LaTeXDisplayView(title: "Hints", content: hints, fontSize: 14)
                            }
                            if let steps = q.stepByStep, !steps.isEmpty {
                                LaTeXDisplayView(title: "Solution", content: steps, fontSize: 14)
                            }
                            if let answer = q.answer, !answer.isEmpty {
                                LaTeXDisplayView(title: "Answer", content: answer, fontSize: 14)
                            }
                        }
                        
                        // Show subparts if they exist
                        if !q.subparts.isEmpty {
                            ForEach(q.subparts.indices, id: \.self) { j in
                                let sp = q.subparts[j]
                                originalSubpartView(for: sp)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // Debug section
            Section("Debug Info") {
                Text("Total Questions: \(result.questions.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(result.questions.indices, id: \.self) { i in
                    let q = result.questions[i]
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(q.id): \(q.questionText.prefix(50))...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        if !q.subparts.isEmpty {
                            Text("  Subparts: \(q.subparts.count)")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }
    
    private func originalQuestionHeader(for question: ExtractedQuestion) -> some View {
        HStack {
            Text(question.id)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("[\(question.marks)]")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
            
            if !question.skillsTested.isEmpty {
                Text(question.skillsTested.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }
    
    private func originalSubpartView(for subpart: ExtractedSubpart) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Subpart header
            HStack {
                Text(subpart.id)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("[\(subpart.marks)]")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(3)
                
                if !subpart.skillsTested.isEmpty {
                    Text(subpart.skillsTested.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            // Subpart content
            if !subpart.text.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("QUESTION")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    SimpleLaTeXText(subpart.text, fontSize: 15)
                        .padding(.leading, 4)
                }
                .padding(.leading, 8)
            }
            
            if !subpart.hints.isEmpty {
                LaTeXDisplayView(title: "Hints", content: subpart.hints, fontSize: 13)
                    .padding(.leading, 8)
            }
            
            if !subpart.stepByStep.isEmpty {
                LaTeXDisplayView(title: "Solution", content: subpart.stepByStep, fontSize: 13)
                    .padding(.leading, 8)
            }
            
            if !subpart.answer.isEmpty {
                LaTeXDisplayView(title: "Answer", content: subpart.answer, fontSize: 13)
                    .padding(.leading, 8)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.vertical, 4)
    }
}


