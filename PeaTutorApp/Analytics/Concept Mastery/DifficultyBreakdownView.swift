//
//  DifficultyBreakdownView.swift
//  PeaTutorApp
//
//  Sprint 7.2 - Phase 2: Performance breakdown by difficulty
//

import SwiftUI
import Amplify

struct DifficultyBreakdownView: View {
    let concept: ConceptMastery
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Performance by Difficulty")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Breakdown
            VStack(spacing: 10) {
                DifficultyRow(
                    difficulty: .easy,
                    attempted: concept.easyQuestions,
                    correct: concept.easyCorrect,
                    color: .green
                )
                
                DifficultyRow(
                    difficulty: .medium,
                    attempted: concept.mediumQuestions,
                    correct: concept.mediumCorrect,
                    color: .orange
                )
                
                DifficultyRow(
                    difficulty: .hard,
                    attempted: concept.hardQuestions,
                    correct: concept.hardCorrect,
                    color: .red
                )
            }
            
            // Summary Stats
            if concept.totalAttempts > 0 {
                Divider()
                    .padding(.vertical, 4)
                
                HStack(spacing: 20) {
                    StatPill(
                        label: "Total Attempts",
                        value: "\(concept.totalAttempts)",
                        icon: "arrow.triangle.2.circlepath"
                    )
                    
                    StatPill(
                        label: "Accuracy",
                        value: "\(Int(concept.accuracyRate))%",
                        icon: "target"
                    )
                    
                    if let lastPracticed = concept.lastPracticed {
                        StatPill(
                            label: "Last Practice",
                            value: formatLastPracticed(lastPracticed),
                            icon: "clock"
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func formatLastPracticed(_ date: Temporal.DateTime) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.day, .hour],
            from: date.foundationDate,
            to: Date()
        )
        
        if let days = components.day, days > 0 {
            return "\(days)d ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        } else {
            return "Today"
        }
    }
}

// MARK: - Difficulty Row

struct DifficultyRow: View {
    let difficulty: QuestionDifficulty
    let attempted: Int
    let correct: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Difficulty Label
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(difficulty.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .frame(width: 65, alignment: .leading)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    if attempted > 0 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(color)
                            .frame(
                                width: geometry.size.width * (Double(correct) / Double(attempted)),
                                height: 6
                            )
                    }
                }
            }
            .frame(height: 6)
            
            // Stats
            Text("\(correct)/\(attempted)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
            
            if attempted > 0 {
                Text("\(Int((Double(correct) / Double(attempted)) * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(color)
                    .frame(width: 35, alignment: .trailing)
            } else {
                Text("—")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 35, alignment: .trailing)
            }
        }
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.caption.bold())
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

