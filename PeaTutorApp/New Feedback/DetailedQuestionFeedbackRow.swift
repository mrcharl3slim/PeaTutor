//
//  DetailedQuestionFeedbackRow.swift
//  PeaTutorApp
//
//  Sprint 7: Reusable component for displaying question-level AI feedback
//

import SwiftUI

/// Displays detailed AI feedback for a single question
struct DetailedQuestionFeedbackRow: View {
    let feedback: QuestionFeedback
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with question ID and correctness indicator
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    // Question ID
                    Text(feedback.questionId)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Correctness indicator
                    if let isCorrect = feedback.isCorrect {
                        HStack(spacing: 4) {
                            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(isCorrect ? .green : .red)
                            Text(isCorrect ? "Correct" : "Incorrect")
                                .font(.caption.bold())
                                .foregroundColor(isCorrect ? .green : .red)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.orange)
                            Text("Review")
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                        }
                    }
                    
                    // Expand/collapse indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Feedback text (always visible)
            Text(feedback.feedback)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(isExpanded ? nil : 2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 1)
        )
    }
    
    private var backgroundColor: Color {
        if let isCorrect = feedback.isCorrect {
            return isCorrect ? Color.green.opacity(0.05) : Color.red.opacity(0.05)
        }
        return Color.orange.opacity(0.05)
    }
    
    private var borderColor: Color {
        if let isCorrect = feedback.isCorrect {
            return isCorrect ? Color.green.opacity(0.2) : Color.red.opacity(0.2)
        }
        return Color.orange.opacity(0.2)
    }
}
