//
//  PracticeSessionView.swift
//  PeaTutorApp
//
//  Sprint 7.4: AI-Powered Practice Generation
//  Interactive practice session where student works through problems
//
//  Updated: Added PracticeAssignment support for assignment tracking
//

import SwiftUI
import Amplify

struct PracticeSessionView: View {
    @StateObject private var viewModel: PracticeSessionViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showExitConfirmation = false
    @State private var showStepByStep = false
    
    // Callback for when assignment is completed
    var onComplete: ((PracticeAssignment) -> Void)?
    
    // Standard initializer
    init(problems: [PracticeProblem], child: UserProfile?) {
        _viewModel = StateObject(wrappedValue: PracticeSessionViewModel(
            problems: problems,
            child: child
        ))
    }
    
    // Initializer with assignment support
    init(
        problems: [PracticeProblem],
        child: UserProfile?,
        assignment: PracticeAssignment?,
        onComplete: ((PracticeAssignment) -> Void)? = nil
    ) {
        self.onComplete = onComplete
        _viewModel = StateObject(wrappedValue: PracticeSessionViewModel(
            problems: problems,
            child: child,
            config: .default,
            assignment: assignment,
            onAssignmentComplete: onComplete
        ))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.sessionComplete {
                    PracticeSessionSummaryView(
                        viewModel: viewModel,
                        onDismiss: { dismiss() }
                    )
                } else {
                    VStack(spacing: 0) {
                        // Progress Header
                        progressHeader
                        
                        // Main Content
                        ScrollView {
                            VStack(spacing: 24) {
                                // Assignment Badge (if applicable)
                                if viewModel.hasAssignment {
                                    assignmentBadge
                                }
                                
                                // Problem Card
                                problemCard
                                
                                // Answer Input
                                answerInputSection
                                
                                // Hints Section
                                hintsSection
                                
                                // Feedback (shown after submit)
                                if viewModel.showFeedback {
                                    feedbackSection
                                }
                            }
                            .padding()
                        }
                        
                        // Bottom Action Bar
                        actionBar
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showExitConfirmation = true }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(viewModel.assignment?.title ?? "Practice")
                        .font(.headline)
                        .lineLimit(1)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    timerDisplay
                }
            }
            .alert("Exit Practice?", isPresented: $showExitConfirmation) {
                Button("Continue Practicing", role: .cancel) {}
                Button("Exit", role: .destructive) { 
                    // Save progress before exiting if there's an assignment
                    if viewModel.hasAssignment && viewModel.totalAttempted > 0 {
                        Task {
                            viewModel.completeSession()
                        }
                    }
                    dismiss() 
                }
            } message: {
                Text("Your progress will be saved, but you'll lose any unanswered problems.")
            }
            .sheet(isPresented: $showStepByStep) {
                if let problem = viewModel.currentProblem {
                    StepByStepSheet(problem: problem)
                }
            }
        }
    }
    
    // MARK: - Assignment Badge
    
    private var assignmentBadge: some View {
        HStack(spacing: 12) {
            Image(systemName: viewModel.assignment?.sourceTypeIcon ?? "sparkles")
                .foregroundColor(.purple)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.assignment?.sourceTypeDisplayName ?? "Practice")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let codes = viewModel.assignment?.curriculumCodesArray, !codes.isEmpty {
                    Text(codes.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            // Due date if set
            if let dueDate = viewModel.assignment?.dueDate {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Due")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formatDueDate(dueDate.foundationDate))
                        .font(.caption)
                        .foregroundColor(viewModel.assignment?.isOverdue == true ? .red : .orange)
                }
            }
        }
        .padding(12)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: 8) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * viewModel.completedProgress)
                }
            }
            .frame(height: 6)
            .cornerRadius(3)
            
            // Problem Counter
            HStack {
                Text("Problem \(viewModel.currentIndex + 1) of \(viewModel.problems.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Label("\(viewModel.correctCount)", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Label("\(viewModel.totalAttempted - viewModel.correctCount)", systemImage: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Timer Display
    
    private var timerDisplay: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
            Text(formatTime(viewModel.totalTimeSpent))
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
    
    // MARK: - Problem Card
    
    private var problemCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Problem Header
            HStack {
                if let problem = viewModel.currentProblem {
                    Text(problem.concept)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    
                    Text(problem.questionType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Difficulty indicator
                    DifficultyIndicator(level: problem.difficultyLevel)
                }
            }
            
            // Problem Text
            if let problem = viewModel.currentProblem {
                ProblemTextView(text: problem.problemText)
                    .font(.title3)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Answer Input
    
    private var answerInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Answer")
                .font(.headline)
            
            HStack {
                TextField("Enter your answer...", text: $viewModel.studentAnswer)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title3)
                    .disabled(viewModel.showFeedback)
                
                if viewModel.showFeedback {
                    Image(systemName: viewModel.isCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.isCorrect == true ? .green : .red)
                }
            }
        }
    }
    
    // MARK: - Hints Section
    
    private var hintsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Hints")
                    .font(.headline)
                
                Spacer()
                
                if viewModel.hasMoreHints && !viewModel.showFeedback {
                    Button(action: viewModel.revealNextHint) {
                        Text("Show Hint (\(viewModel.availableHints.count - viewModel.currentHintLevel) left)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if viewModel.visibleHints.isEmpty {
                Text("Tap 'Show Hint' if you need help")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(Array(viewModel.visibleHints.enumerated()), id: \.offset) { index, hint in
                    HintCard(hintNumber: index + 1, hint: hint)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Feedback Section
    
    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Correct/Incorrect Header
            HStack {
                Image(systemName: viewModel.isCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(viewModel.isCorrect == true ? .green : .red)
                
                Text(viewModel.isCorrect == true ? "Correct!" : "Not quite...")
                    .font(.title2.bold())
                    .foregroundColor(viewModel.isCorrect == true ? .green : .red)
                
                Spacer()
            }
            
            // Show correct answer if wrong
            if viewModel.isCorrect != true, let problem = viewModel.currentProblem {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Correct Answer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(problem.answer)
                        .font(.title3.bold())
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Step by Step button
            if viewModel.currentProblem?.stepByStep != nil {
                Button(action: { showStepByStep = true }) {
                    HStack {
                        Image(systemName: "list.number")
                        Text("View Step-by-Step Solution")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(
            (viewModel.isCorrect == true ? Color.green : Color.red).opacity(0.1)
        )
        .cornerRadius(16)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Action Bar
    
    private var actionBar: some View {
        VStack(spacing: 12) {
            Divider()
            
            HStack(spacing: 12) {
                if viewModel.showFeedback {
                    // After answering - show next/finish
                    if viewModel.isLastProblem {
                        Button(action: viewModel.completeSession) {
                            HStack {
                                Image(systemName: "flag.checkered")
                                Text("Finish Practice")
                            }
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                    } else {
                        Button(action: viewModel.nextProblem) {
                            HStack {
                                Text("Next Problem")
                                Image(systemName: "arrow.right")
                            }
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                    }
                } else {
                    // Before answering - show submit and skip
                    if viewModel.config.allowSkip {
                        Button(action: viewModel.skipProblem) {
                            Text("Skip")
                                .foregroundColor(.secondary)
                                .frame(width: 80)
                                .frame(height: 50)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                        }
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.submitAnswer()
                        }
                    }) {
                        HStack {
                            if viewModel.isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark.circle")
                                Text("Submit Answer")
                            }
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            viewModel.studentAnswer.isEmpty ? Color.gray : Color.blue
                        )
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.studentAnswer.isEmpty || viewModel.isSubmitting)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Difficulty Indicator

struct DifficultyIndicator: View {
    let level: String
    
    private var dots: Int {
        switch level.lowercased() {
        case "easier", "easy": return 1
        case "similar", "medium": return 2
        case "harder", "hard": return 3
        default: return 2
        }
    }
    
    private var color: Color {
        switch level.lowercased() {
        case "easier", "easy": return .green
        case "similar", "medium": return .orange
        case "harder", "hard": return .red
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index < dots ? color : color.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

// MARK: - Problem Text View (with LaTeX support)

struct ProblemTextView: View {
    let text: String
    
    var body: some View {
        // For now, simple text display
        // In production, integrate with LatexRenderer
        Text(cleanLatex(text))
            .lineSpacing(4)
    }
    
    private func cleanLatex(_ text: String) -> String {
        var cleaned = text
        // Simple LaTeX cleanup for display
        cleaned = cleaned.replacingOccurrences(of: "\\frac{", with: "")
        cleaned = cleaned.replacingOccurrences(of: "}{", with: "/")
        cleaned = cleaned.replacingOccurrences(of: "}", with: "")
        cleaned = cleaned.replacingOccurrences(of: "$", with: "")
        cleaned = cleaned.replacingOccurrences(of: "\\times", with: "×")
        cleaned = cleaned.replacingOccurrences(of: "\\div", with: "÷")
        cleaned = cleaned.replacingOccurrences(of: "\\pm", with: "±")
        return cleaned
    }
}

// MARK: - Hint Card

struct HintCard: View {
    let hintNumber: Int
    let hint: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.yellow)
                .frame(width: 24, height: 24)
                .overlay(
                    Text("\(hintNumber)")
                        .font(.caption.bold())
                        .foregroundColor(.black)
                )
            
            Text(hint)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Step by Step Sheet

struct StepByStepSheet: View {
    let problem: PracticeProblem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Problem
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Problem")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ProblemTextView(text: problem.problemText)
                            .font(.body)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Answer
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Answer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(problem.answer)
                            .font(.title2.bold())
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Step by Step
                    if let stepByStep = problem.stepByStep {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Solution Steps")
                                .font(.headline)
                            
                            ForEach(parseSteps(stepByStep), id: \.self) { step in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                    
                                    Text(step)
                                        .font(.body)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Step-by-Step Solution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func parseSteps(_ stepByStep: String) -> [String] {
        // Split by newlines and filter empty lines
        stepByStep
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
