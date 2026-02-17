//
//  FeedbackHistoryView.swift
//  PeaTutorApp
//
//  Sub-Sprint 3.4: Feedback History UI
//

import SwiftUI
import Amplify

// MARK: - Feedback History View
struct FeedbackHistoryView: View {
    @ObservedObject var viewModel: SolutionFeedbackViewModel
    let questionId: String
    @Environment(\.dismiss) var dismiss
    @State private var selectedFeedback: LocalSolutionFeedback?
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.feedbackHistory.isEmpty {
                    emptyStateView
                } else {
                    historyListView
                }
            }
            .navigationTitle("Feedback History")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .sheet(item: $selectedFeedback) { feedback in
                FeedbackDetailView(feedback: feedback)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Feedback Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Submit your solution to get AI feedback")
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
                // Stats card
                statsCard
                
                // History items
                ForEach(viewModel.feedbackHistory) { feedback in
                    FeedbackHistoryCard(feedback: feedback)
                        .onTapGesture {
                            selectedFeedback = feedback
                        }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Stats Card
    
    private var statsCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Attempts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.feedbackHistory.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Success Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(successRateText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(successRateColor)
                }
            }
            
            // Progress indicator
            if correctCount > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(correctCount) correct")
                            .font(.caption2)
                        Spacer()
                        Text("\(incorrectCount) need work")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.red.opacity(0.2))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(Color.green)
                                .frame(
                                    width: geometry.size.width * CGFloat(correctCount) / CGFloat(viewModel.feedbackHistory.count),
                                    height: 8
                                )
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var correctCount: Int {
        viewModel.feedbackHistory.filter { $0.isCorrect == true }.count
    }
    
    private var incorrectCount: Int {
        viewModel.feedbackHistory.filter { $0.isCorrect == false }.count
    }
    
    private var successRateText: String {
        guard !viewModel.feedbackHistory.isEmpty else { return "0%" }
        let rate = (Double(correctCount) / Double(viewModel.feedbackHistory.count)) * 100
        return String(format: "%.0f%%", rate)
    }
    
    private var successRateColor: Color {
        let rate = Double(correctCount) / Double(viewModel.feedbackHistory.count)
        if rate >= 0.7 { return .green }
        else if rate >= 0.4 { return .orange }
        else { return .red }
    }
}

// MARK: - Feedback History Card
struct FeedbackHistoryCard: View {
    let feedback: LocalSolutionFeedback
    
    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: statusIcon)
                    .font(.title3)
                    .foregroundColor(statusColor)
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
                
                Text(feedback.feedback)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
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
    
    private var statusIcon: String {
        if feedback.isCorrect == true {
            return "checkmark.circle.fill"
        } else if feedback.isCorrect == false {
            return "xmark.circle.fill"
        } else {
            return "info.circle.fill"
        }
    }
    
    private var statusColor: Color {
        if feedback.isCorrect == true {
            return .green
        } else if feedback.isCorrect == false {
            return .red
        } else {
            return .orange
        }
    }
    
    private var timeAgoText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: feedback.timestamp, relativeTo: Date())
    }
}

// MARK: - Feedback Detail View
struct FeedbackDetailView: View {
    let feedback: LocalSolutionFeedback
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
                            
                            // Pinch hint
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
                    
                    // Feedback info
                    VStack(spacing: 16) {
                        // Status header
                        HStack {
                            Image(systemName: statusIcon)
                                .font(.title)
                                .foregroundColor(statusColor)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(statusText)
                                    .font(.headline)
                                    .foregroundColor(statusColor)
                                
                                Text("Attempt #\(feedback.attemptNumber) • \(formattedDate)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(statusColor.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Feedback text
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Feedback")
                                .font(.headline)
                            
                            Text(feedback.feedback)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        
                        // Suggestions
                        if !feedback.suggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Suggestions for Improvement")
                                    .font(.headline)
                                
                                ForEach(feedback.suggestions, id: \.self) { suggestion in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "lightbulb.fill")
                                            .foregroundColor(.orange)
                                        
                                        Text(suggestion)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.orange.opacity(0.05))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // Sync status
                        HStack(spacing: 8) {
                            Image(systemName: feedback.isSynced ? "checkmark.icloud.fill" : "icloud.slash")
                                .foregroundColor(feedback.isSynced ? .green : .orange)
                            
                            Text(feedback.isSynced ? "Synced to cloud" : "Sync pending")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Solution Detail")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
    
    private var statusIcon: String {
        if feedback.isCorrect == true {
            return "checkmark.circle.fill"
        } else if feedback.isCorrect == false {
            return "xmark.circle.fill"
        } else {
            return "info.circle.fill"
        }
    }
    
    private var statusColor: Color {
        if feedback.isCorrect == true {
            return .green
        } else if feedback.isCorrect == false {
            return .red
        } else {
            return .orange
        }
    }
    
    private var statusText: String {
        if feedback.isCorrect == true {
            return "Correct! ✓"
        } else if feedback.isCorrect == false {
            return "Needs Improvement"
        } else {
            return "Review Feedback"
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: feedback.timestamp)
    }
}

// MARK: - Preview
struct FeedbackHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = SolutionFeedbackViewModel(
            questionId: "Q1",
            questionText: "Solve for x: 2x + 3 = 7",
            worksheetId: "worksheet-123"
        )
        
        // Add sample data
        viewModel.feedbackHistory = [
            LocalSolutionFeedback(
                solutionImage: Data(),
                feedback: "Great work! Your solution is correct.",
                isCorrect: true,
                suggestions: [],
                timestamp: Date().addingTimeInterval(-3600),
                attemptNumber: 3,
                datastoreId: "sync-123"
            ),
            LocalSolutionFeedback(
                solutionImage: Data(),
                feedback: "Almost there! Check your algebra in step 2.",
                isCorrect: false,
                suggestions: ["Review subtraction rules", "Double-check your arithmetic"],
                timestamp: Date().addingTimeInterval(-7200),
                attemptNumber: 2,
                datastoreId: "sync-456"
            )
        ]
        
        return FeedbackHistoryView(viewModel: viewModel, questionId: "Q1")
    }
}
