//
//  QuestionDetailView.swift
//  PeaTutorApp
//
//  Sub-Sprint 3.4: Integrated with synced feedback system
//

import SwiftUI

struct QuestionDetailView: View {
    let question: ExtractedQuestion
    let questionNumber: Int
    let worksheetId: String
    
    @State private var showHints = false
    @State private var showSteps = false
    @State private var showAnswer = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Question header
                questionHeader
                
                // Question text
                questionTextSection
                
                // Solution feedback button (NEW - with history & sync)
                SolutionFeedbackButton(
                    questionId: question.id,
                    questionText: question.questionText,
                    worksheetId: worksheetId,
                    isSubpart: false
                )
                
                // Expandable sections
                if let hints = question.hints, !hints.isEmpty {
                    expandableSection(
                        title: "💡 Hints",
                        isExpanded: $showHints,
                        content: hints,
                        color: .orange
                    )
                }
                
                if let steps = question.stepByStep, !steps.isEmpty {
                    expandableSection(
                        title: "📝 Step-by-Step Solution",
                        isExpanded: $showSteps,
                        content: steps,
                        color: .blue
                    )
                }
                
                if let answer = question.answer, !answer.isEmpty {
                    expandableSection(
                        title: "✓ Answer",
                        isExpanded: $showAnswer,
                        content: answer,
                        color: .green
                    )
                }
                
                // Subparts
                if !question.subparts.isEmpty {
                    subpartsSection
                }
                
                // Question metadata
                metadataSection
            }
            .padding()
        }
        .navigationTitle("Question \(questionNumber)")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Question Header
    
    private var questionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Question \(questionNumber)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack {
                    Label("\(question.marks) marks", systemImage: "star.fill")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    
                    if !question.subparts.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(question.subparts.count) parts")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Question Text
    
    private var questionTextSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Question")
                .font(.headline)
                .foregroundColor(.secondary)
            
            SimpleLaTeXText(question.questionText, fontSize: 16)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Expandable Section
    
    private func expandableSection(
        title: String,
        isExpanded: Binding<Bool>,
        content: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { isExpanded.wrappedValue.toggle() }) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .foregroundColor(color)
                        .font(.subheadline)
                }
                .padding()
                .background(color.opacity(0.1))
                .cornerRadius(12)
            }
            
            if isExpanded.wrappedValue {
                SimpleLaTeXText(content, fontSize: 15)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isExpanded.wrappedValue)
    }
    
    // MARK: - Subparts Section
    
    private var subpartsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Parts")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ForEach(question.subparts.indices, id: \.self) { index in
                SubpartDetailView(
                    subpart: question.subparts[index],
                    subpartNumber: index + 1,
                    worksheetId: worksheetId
                )
            }
        }
    }
    
    // MARK: - Metadata Section
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Skills Tested")
                .font(.headline)
                .foregroundColor(.secondary)
            
            FlowLayout(spacing: 8) {
                ForEach(question.skillsTested, id: \.self) { skill in
                    Text(skill)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Subpart Detail View
struct SubpartDetailView: View {
    let subpart: ExtractedSubpart
    let subpartNumber: Int
    let worksheetId: String
    
    @State private var showHints = false
    @State private var showSteps = false
    @State private var showAnswer = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Subpart header
            HStack {
                Text("\(Character(UnicodeScalar(96 + subpartNumber)!))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.purple)
                    .clipShape(Circle())
                
                Text("\(subpart.marks) marks")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Subpart text
            SimpleLaTeXText(subpart.text, fontSize: 14)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(8)
            
            // Solution feedback for subpart (NEW - with history & sync)
            SolutionFeedbackButton(
                questionId: subpart.id,
                questionText: subpart.text,
                worksheetId: worksheetId,
                isSubpart: true
            )
            
            // Expandable sections
            VStack(spacing: 8) {
                if !subpart.hints.isEmpty {
                    miniExpandableSection(
                        title: "💡 Hints",
                        isExpanded: $showHints,
                        content: subpart.hints,
                        color: .orange
                    )
                }
                
                if !subpart.stepByStep.isEmpty {
                    miniExpandableSection(
                        title: "📝 Solution",
                        isExpanded: $showSteps,
                        content: subpart.stepByStep,
                        color: .blue
                    )
                }
                
                if !subpart.answer.isEmpty {
                    miniExpandableSection(
                        title: "✓ Answer",
                        isExpanded: $showAnswer,
                        content: subpart.answer,
                        color: .green
                    )
                }
            }
            
            // Skills
            if !subpart.skillsTested.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(subpart.skillsTested, id: \.self) { skill in
                        Text(skill)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.1))
                            .foregroundColor(.purple)
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
    
    private func miniExpandableSection(
        title: String,
        isExpanded: Binding<Bool>,
        content: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { isExpanded.wrappedValue.toggle() }) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(color)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(color.opacity(0.1))
                .cornerRadius(8)
            }
            
            if isExpanded.wrappedValue {
                SimpleLaTeXText(content, fontSize: 13)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .padding(.top, 6)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isExpanded.wrappedValue)
    }
}

// MARK: - Flow Layout (for skill tags)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: result.positions[index], proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize
        var positions: [CGPoint]
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var positions: [CGPoint] = []
            var size: CGSize = .zero
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)
                
                if currentX + subviewSize.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += subviewSize.width + spacing
                lineHeight = max(lineHeight, subviewSize.height)
                size.width = max(size.width, currentX - spacing)
            }
            
            size.height = currentY + lineHeight
            self.size = size
            self.positions = positions
        }
    }
}
