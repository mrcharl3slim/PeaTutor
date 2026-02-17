//
//  PracticeSessionSummaryView.swift
//  PeaTutorApp
//
//  Sprint 7.4: AI-Powered Practice Generation
//  Summary view shown at the end of a practice session
//
//  Updated: Added assignment completion display
//

import SwiftUI

struct PracticeSessionSummaryView: View {
    @ObservedObject var viewModel: PracticeSessionViewModel
    @Environment(\.dismiss) private var dismiss
    
    var onDismiss: (() -> Void)?
    
    @State private var animateStats = false
    @State private var showConfetti = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Success Header
                headerSection
                
                // Assignment Completion Banner (if applicable)
                if viewModel.completedAssignment != nil {
                    assignmentCompletionBanner
                }
                
                // Score Card
                scoreCard
                
                // Detailed Stats
                statsGrid
                
                // Concepts Practiced
                conceptsSection
                
                // Curriculum Alignment (if applicable)
                if let assignment = viewModel.completedAssignment,
                   let codes = assignment.curriculumCodes, !codes.isEmpty {
                    curriculumSection(assignment: assignment)
                }
                
                // Problem Breakdown
                problemBreakdownSection
                
                // Actions
                actionsSection
            }
            .padding()
        }
        .navigationTitle("Practice Complete!")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    onDismiss?() ?? dismiss()
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                animateStats = true
            }
            
            if viewModel.sessionStats.accuracy >= 80 {
                showConfetti = true
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Emoji reaction based on performance
            Text(viewModel.sessionStats.scoreEmoji)
                .font(.system(size: 80))
                .scaleEffect(animateStats ? 1 : 0.5)
                .opacity(animateStats ? 1 : 0)
            
            Text(viewModel.sessionStats.encouragement)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            
            if let child = viewModel.child {
                Text("Great effort, \(child.displayName)!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Assignment Completion Banner
    
    private var assignmentCompletionBanner: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("Assignment Completed!")
                    .font(.headline)
                    .foregroundColor(.green)
                
                Spacer()
            }
            
            if let assignment = viewModel.completedAssignment {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(assignment.title)
                            .font(.subheadline.bold())
                        
                        Text(formatSourceType(assignment.sourceType))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Score badge
                    VStack(spacing: 2) {
                        Text(formatScore(assignment.score))
                            .font(.title3.bold())
                            .foregroundColor(.green)
                        Text("Score")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.1), Color.mint.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 2)
        )
    }
    
    // MARK: - Score Card
    
    private var scoreCard: some View {
        VStack(spacing: 16) {
            // Big Score Display
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 150, height: 150)
                
                Circle()
                    .trim(from: 0, to: animateStats ? viewModel.accuracy / 100 : 0)
                    .stroke(
                        LinearGradient(
                            colors: scoreGradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(Int(viewModel.accuracy))%")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor)
                    
                    Text("Accuracy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Score Breakdown
            HStack(spacing: 40) {
                VStack {
                    Text("\(viewModel.correctCount)")
                        .font(.title.bold())
                        .foregroundColor(.green)
                    Text("Correct")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(viewModel.totalAttempted - viewModel.correctCount)")
                        .font(.title.bold())
                        .foregroundColor(.red)
                    Text("Incorrect")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(viewModel.problems.count - viewModel.totalAttempted)")
                        .font(.title.bold())
                        .foregroundColor(.orange)
                    Text("Skipped")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
    }
    
    private var scoreGradientColors: [Color] {
        if viewModel.accuracy >= 80 {
            return [.green, .mint]
        } else if viewModel.accuracy >= 60 {
            return [.yellow, .orange]
        } else {
            return [.orange, .red]
        }
    }
    
    private var scoreColor: Color {
        if viewModel.accuracy >= 80 {
            return .green
        } else if viewModel.accuracy >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    // MARK: - Stats Grid
    
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatBox(
                title: "Time",
                value: formatTime(viewModel.sessionStats.totalTimeSeconds),
                icon: "clock.fill",
                color: .blue
            )
            
            StatBox(
                title: "Avg/Problem",
                value: formatTime(Int(viewModel.sessionStats.averageTimePerProblem)),
                icon: "timer",
                color: .purple
            )
            
            StatBox(
                title: "Hints Used",
                value: "\(viewModel.sessionStats.hintsUsed)",
                icon: "lightbulb.fill",
                color: .yellow
            )
        }
    }
    
    // MARK: - Concepts Section
    
    private var conceptsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Concepts Practiced")
                .font(.headline)
            
            let concepts = Set(viewModel.problems.map { $0.concept })
            
            FlowLayout5(spacing: 8) {
                ForEach(Array(concepts), id: \.self) { concept in
                    let conceptResults = viewModel.problemResults.filter { result in
                        viewModel.problems.first { $0.id == result.problemId }?.concept == concept
                    }
                    let correct = conceptResults.filter { $0.isCorrect }.count
                    let total = conceptResults.count
                    
                    ConceptResultChip(
                        concept: concept,
                        correct: correct,
                        total: total
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Curriculum Section
    
    private func curriculumSection(assignment: PracticeAssignment) -> some View {
        let codes = assignment.curriculumCodes ?? []
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "book.closed.fill")
                    .foregroundColor(.blue)
                Text("Curriculum Progress")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if let gradeLevel = assignment.curriculumGradeLevel {
                    HStack {
                        Text("Grade Level:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(gradeLevel)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                if !codes.isEmpty {
                    Text("Curriculum Codes Practiced:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    FlowLayout5(spacing: 6) {
                        ForEach(codes, id: \.self) { code in
                            Text(code ?? "No codesfound")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                        }
                    }
                }
                
                // Progress indicator
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("Your mastery for these topics has been updated!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Problem Breakdown
    
    private var problemBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Problem Results")
                    .font(.headline)
                
                Spacer()
                
                if hasIncorrectProblems {
                    Button(action: viewModel.retryIncorrect) {
                        Text("Retry Incorrect")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            ForEach(Array(viewModel.problemResults.enumerated()), id: \.offset) { index, result in
                ProblemResultRow(
                    problemNumber: index + 1,
                    result: result,
                    problem: viewModel.problems.first { $0.id == result.problemId }
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var hasIncorrectProblems: Bool {
        viewModel.problemResults.contains { !$0.isCorrect }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            if hasIncorrectProblems {
                Button(action: viewModel.retryIncorrect) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Practice Incorrect Problems Again")
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.orange)
                    .cornerRadius(12)
                }
            }
            
            Button(action: { onDismiss?() ?? dismiss() }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Finish Practice")
                }
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.green)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        }
        let minutes = seconds / 60
        let secs = seconds % 60
        return "\(minutes)m \(secs)s"
    }
    
    private func formatSourceType(_ sourceType: String) -> String {
        switch sourceType {
        case "prerequisite_gap": return "Prerequisite Gap"
        case "recommended": return "Recommended"
        case "weak_area": return "Weak Area"
        case "topic": return "Topic Practice"
        case "self_practice": return "Self Practice"
        default: return sourceType.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    private func formatScore(_ score: Double?) -> String {
        guard let score = score else { return "—" }
        return "\(Int(score))%"
    }
}

// MARK: - Supporting Views

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ConceptResultChip: View {
    let concept: String
    let correct: Int
    let total: Int
    
    var accuracy: Double {
        total > 0 ? Double(correct) / Double(total) : 0
    }
    
    var chipColor: Color {
        if accuracy >= 0.8 { return .green }
        if accuracy >= 0.6 { return .yellow }
        return .orange
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Text(concept)
                .font(.caption.bold())
            
            Text("\(correct)/\(total)")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.3))
                .cornerRadius(4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(chipColor.opacity(0.2))
        .foregroundColor(chipColor)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(chipColor.opacity(0.5), lineWidth: 1)
        )
    }
}

struct ProblemResultRow: View {
    let problemNumber: Int
    let result: PracticeResult
    let problem: PracticeProblem?
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    // Status Icon
                    Image(systemName: result.isCorrect ? "checkmark.circle.fill" : (result.studentAnswer == "[SKIPPED]" ? "forward.circle.fill" : "xmark.circle.fill"))
                        .foregroundColor(result.isCorrect ? .green : (result.studentAnswer == "[SKIPPED]" ? .orange : .red))
                    
                    // Problem Number
                    Text("Problem \(problemNumber)")
                        .font(.subheadline.bold())
                    
                    Spacer()
                    
                    // Hints indicator
                    if result.hintsUsed > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption2)
                            Text("\(result.hintsUsed)")
                                .font(.caption2)
                        }
                        .foregroundColor(.yellow)
                    }
                    
                    // Time
                    Text("\(result.timeSpentSeconds)s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded, let problem = problem {
                VStack(alignment: .leading, spacing: 8) {
                    // Problem text
                    Text(cleanLatex(problem.problemText))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Your answer:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(result.studentAnswer)
                                .font(.caption.bold())
                                .foregroundColor(result.isCorrect ? .green : .red)
                        }
                        
                        Spacer()
                        
                        if !result.isCorrect && result.studentAnswer != "[SKIPPED]" {
                            VStack(alignment: .trailing) {
                                Text("Correct answer:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(problem.answer)
                                    .font(.caption.bold())
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                .padding(.leading, 28)
            }
        }
        .padding()
        .background(
            result.isCorrect ? Color.green.opacity(0.05) : (result.studentAnswer == "[SKIPPED]" ? Color.orange.opacity(0.05) : Color.red.opacity(0.05))
        )
        .cornerRadius(8)
    }
    
    private func cleanLatex(_ text: String) -> String {
        var cleaned = text
        cleaned = cleaned.replacingOccurrences(of: "$", with: "")
        cleaned = cleaned.replacingOccurrences(of: "\\frac{", with: "")
        cleaned = cleaned.replacingOccurrences(of: "}{", with: "/")
        cleaned = cleaned.replacingOccurrences(of: "}", with: "")
        cleaned = cleaned.replacingOccurrences(of: "\\times", with: "×")
        return cleaned
    }
}

// MARK: - Flow Layout

struct FlowLayout5: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult2(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult2(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult2 {
        var positions: [CGPoint] = []
        var height: CGFloat = 0
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            height = y + rowHeight
        }
    }
}
