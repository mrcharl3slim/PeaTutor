//
//  FullWorksheetHistoryView.swift
//  PeaTutorApp
//
//  Sub-Sprint 3.4: Full Worksheet History UI
//

import SwiftUI
import Amplify

// MARK: - Full Worksheet History View
struct FullWorksheetHistoryView: View {
    @ObservedObject var viewModel: FullWorksheetFeedbackViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedFeedback: FullWorksheetFeedback?
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.feedbackHistory.isEmpty {
                    emptyStateView
                } else {
                    historyListView
                }
            }
            .navigationTitle("Worksheet History")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .sheet(item: $selectedFeedback) { feedback in
                FullWorksheetDetailView(feedback: feedback)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Worksheet Feedback Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Submit your complete worksheet to get comprehensive AI feedback")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - History List
    
    private var historyListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Overall stats
                overallStatsCard
                
                // Attempt history
                ForEach(viewModel.feedbackHistory) { feedback in
                    FullWorksheetHistoryCard(feedback: feedback)
                        .onTapGesture {
                            selectedFeedback = feedback
                        }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Overall Stats Card
    
    private var overallStatsCard: some View {
        VStack(spacing: 16) {
            Text("Your Progress")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                // Total attempts
                statBox(
                    value: "\(viewModel.feedbackHistory.count)",
                    label: "Attempts",
                    color: .blue
                )
                
                // Best score
                statBox(
                    value: "\(bestScore)/\(totalQuestions)",
                    label: "Best Score",
                    color: .green
                )
                
                // Average score
                statBox(
                    value: String(format: "%.1f", averageScore),
                    label: "Average",
                    color: .orange
                )
            }
            
            // Progress chart
            if viewModel.feedbackHistory.count > 1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Score Trend")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    progressChart
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func statBox(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var progressChart: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height: CGFloat = 100
            let points = viewModel.feedbackHistory.reversed().enumerated().map { index, feedback in
                CGPoint(
                    x: CGFloat(index) * (width / CGFloat(max(viewModel.feedbackHistory.count - 1, 1))),
                    y: height - (CGFloat(feedback.overallScore) / CGFloat(totalQuestions) * height)
                )
            }
            
            ZStack {
                // Background grid
                Path { path in
                    for i in 0...4 {
                        let y = CGFloat(i) * (height / 4)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                }
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                
                // Score line
                Path { path in
                    guard !points.isEmpty else { return }
                    path.move(to: points[0])
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(Color.blue, lineWidth: 2)
                
                // Score points
                ForEach(points.indices, id: \.self) { index in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .position(points[index])
                }
            }
        }
        .frame(height: 100)
    }
    
    private var bestScore: Int {
        viewModel.feedbackHistory.map { $0.overallScore }.max() ?? 0
    }
    
    private var averageScore: Double {
        guard !viewModel.feedbackHistory.isEmpty else { return 0 }
        let total = viewModel.feedbackHistory.reduce(0) { $0 + $1.overallScore }
        return Double(total) / Double(viewModel.feedbackHistory.count)
    }
    
    private var totalQuestions: Int {
        viewModel.feedbackHistory.first?.totalQuestions ?? 0
    }
}

// MARK: - Full Worksheet History Card
struct FullWorksheetHistoryCard: View {
    let feedback: FullWorksheetFeedback
    
    var body: some View {
        HStack(spacing: 12) {
            // Score badge
            ZStack {
                Circle()
                    .fill(scoreColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                VStack(spacing: 2) {
                    Text("\(feedback.overallScore)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor)
                    Text("/ \(feedback.totalQuestions)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Attempt #\(feedback.attemptNumber)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if feedback.isSynced {
                        Image(systemName: "checkmark.icloud.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Text(feedback.overallFeedback)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    statPill(
                        icon: "checkmark.circle.fill",
                        text: "\(feedback.completedQuestions.count) done",
                        color: .green
                    )
                    
                    if !feedback.questionsWithIssues.isEmpty {
                        statPill(
                            icon: "exclamationmark.triangle.fill",
                            text: "\(feedback.questionsWithIssues.count) need work",
                            color: .orange
                        )
                    }
                }
                
                Text(timeAgoText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func statPill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var scoreColor: Color {
        let percentage = Double(feedback.overallScore) / Double(feedback.totalQuestions)
        if percentage >= 0.7 { return .green }
        else if percentage >= 0.4 { return .orange }
        else { return .red }
    }
    
    private var timeAgoText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: feedback.timestamp, relativeTo: Date())
    }
}

// MARK: - Full Worksheet Detail View
struct FullWorksheetDetailView: View {
    let feedback: FullWorksheetFeedback
    @Environment(\.dismiss) var dismiss
    @State private var imageScale: CGFloat = 1.0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Solution image
                    if let uiImage = UIImage(data: feedback.solutionImage) {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                                .scaleEffect(imageScale)
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            imageScale = value.magnitude
                                        }
                                        .onEnded { _ in
                                            withAnimation(.spring()) {
                                                imageScale = 1.0
                                            }
                                        }
                                )
                            
                            if imageScale == 1.0 {
                                Text("Pinch to zoom")
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.6))
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                                    .padding(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Feedback content
                    VStack(spacing: 16) {
                        // Score header
                        scoreHeader
                        
                        // Overall feedback
                        feedbackSection
                        
                        // Questions breakdown
                        if !feedback.completedQuestions.isEmpty {
                            completedQuestionsSection
                        }
                        
                        if !feedback.questionsWithIssues.isEmpty {
                            issuesSection
                        }
                        
                        // Suggestions
                        if !feedback.suggestions.isEmpty {
                            suggestionsSection
                        }
                        
                        // Detailed feedback per question
                        if !feedback.detailedFeedback.isEmpty {
                            detailedFeedbackSection
                        }
                        
                        // Sync status
                        syncStatusView
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Worksheet Review")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
    
    // MARK: - View Components
    
    private var scoreHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Overall Score")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(feedback.overallScore)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(scoreColor)
                    Text("/ \(feedback.totalQuestions)")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Attempt #\(feedback.attemptNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(scoreColor.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var feedbackSection: some View {
        sectionCard(title: "Overall Feedback", icon: "bubble.left.fill", color: .blue) {
            Text(feedback.overallFeedback)
                .font(.body)
        }
    }
    
    private var completedQuestionsSection: some View {
        sectionCard(title: "Completed Questions", icon: "checkmark.circle.fill", color: .green) {
            Text(feedback.completedQuestions.joined(separator: ", "))
                .font(.subheadline)
        }
    }
    
    private var issuesSection: some View {
        sectionCard(title: "Questions Needing Work", icon: "exclamationmark.triangle.fill", color: .orange) {
            Text(feedback.questionsWithIssues.joined(separator: ", "))
                .font(.subheadline)
        }
    }
    
    private var suggestionsSection: some View {
        sectionCard(title: "Suggestions for Improvement", icon: "lightbulb.fill", color: .yellow) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(feedback.suggestions, id: \.self) { suggestion in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        Text(suggestion)
                            .font(.subheadline)
                    }
                }
            }
        }
    }
    
    private var detailedFeedbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Feedback")
                .font(.headline)
            
            ForEach(feedback.detailedFeedback, id: \.questionId) { detail in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(detail.questionId)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        if let isCorrect = detail.isCorrect {
                            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(isCorrect ? .green : .red)
                        }
                    }
                    
                    Text(detail.feedback)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var syncStatusView: some View {
        HStack(spacing: 8) {
            Image(systemName: feedback.isSynced ? "checkmark.icloud.fill" : "icloud.slash")
                .foregroundColor(feedback.isSynced ? .green : .orange)
            
            Text(feedback.isSynced ? "Synced to cloud" : "Sync pending")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func sectionCard<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }
            
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Computed Properties
    
    private var scoreColor: Color {
        let percentage = Double(feedback.overallScore) / Double(feedback.totalQuestions)
        if percentage >= 0.7 { return .green }
        else if percentage >= 0.4 { return .orange }
        else { return .red }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: feedback.timestamp)
    }
}

// MARK: - Preview
struct FullWorksheetHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = FullWorksheetFeedbackViewModel(
            worksheetId: "ws-123",
            questions: []
        )
        
        viewModel.feedbackHistory = [
            FullWorksheetFeedback(
                solutionImage: Data(),
                overallFeedback: "Great effort! Most questions are correct.",
                overallScore: 8,
                totalQuestions: 10,
                completedQuestions: ["Q1", "Q2", "Q3", "Q4", "Q5", "Q6", "Q7", "Q8"],
                questionsWithIssues: ["Q9", "Q10"],
                suggestions: ["Review quadratic formula", "Practice graphing"],
                detailedFeedback: [],
                timestamp: Date().addingTimeInterval(-3600),
                attemptNumber: 2,
                datastoreId: "sync-123"
            )
        ]
        
        return FullWorksheetHistoryView(viewModel: viewModel)
    }
}
