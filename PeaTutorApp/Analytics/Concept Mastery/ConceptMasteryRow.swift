//
//  ConceptMasteryRow.swift
//  PeaTutorApp
//
//  Sprint 7.2 - Phase 2: Individual expandable concept row
//

import SwiftUI

struct ConceptMasteryRow: View {
    let concept: ConceptMastery
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Row (always visible)
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isExpanded.toggle()
                }
            }) {
                mainRow
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded Content (conditional)
            if isExpanded {
                expandedContent
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95, anchor: .top)
                            .combined(with: .opacity),
                        removal: .scale(scale: 0.95, anchor: .top)
                            .combined(with: .opacity)
                    ))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        )
    }
    
    // MARK: - Main Row
    
    private var mainRow: some View {
        HStack(spacing: 12) {
            // Concept Name
            Text(concept.concept)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
                .frame(width: 100, alignment: .leading)
            
            // Progress Bar
            MasteryProgressBar(
                percentage: concept.masteryPercentage,
                showPercentage: true,
                height: 8
            )
            
            // Trend
            TrendIndicator(
                trend: concept.trendDirection,
                size: 14
            )
            
            // Recent Count
            Text("\(concept.recentQuestions) recent")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 65, alignment: .trailing)
            
            // Expand/Collapse Chevron
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .rotationEffect(.degrees(isExpanded ? 0 : 0))
                .animation(.spring(response: 0.3), value: isExpanded)
        }
    }
    
    // MARK: - Expanded Content
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
                .padding(.vertical, 8)
            
            // Quick Stats
            quickStats
            
            // Difficulty Breakdown
            DifficultyBreakdownView(concept: concept)
            
            // Recommendations
            if concept.masteryPercentage < 60 {
                recommendationsSection
            }
            
            // Strengths & Weaknesses
            if let strengths = concept.strengthAreas, !strengths.isEmpty {
                strengthsSection(strengths)
            }
            
            if let improvements = concept.improvementAreas, !improvements.isEmpty {
                improvementsSection(improvements)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Quick Stats
    
    private var quickStats: some View {
        HStack(spacing: 16) {
            QuickStat(
                icon: "target",
                label: "Mastery",
                value: concept.masteryLevel.rawValue,
                color: masteryLevelColor
            )
            
            QuickStat(
                icon: "percent",
                label: "Accuracy",
                value: "\(Int(concept.accuracyRate))%",
                color: .blue
            )
            
            QuickStat(
                icon: "clock",
                label: "Last Practiced",
                value: concept.lastPracticedFormatted,
                color: .orange
            )
        }
    }
    
    // MARK: - Recommendations Section
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Recommendations")
                    .font(.subheadline.bold())
            }
            
            VStack(alignment: .leading, spacing: 6) {
                if concept.masteryPercentage < 40 {
                    RecommendationRow(
                        icon: "exclamationmark.triangle.fill",
                        text: "Needs focused intervention - consider one-on-one support",
                        color: .red
                    )
                } else if concept.masteryPercentage < 60 {
                    RecommendationRow(
                        icon: "arrow.up.circle.fill",
                        text: "Shows understanding but needs more practice",
                        color: .orange
                    )
                }
                
                if concept.hardQuestions > 0 && concept.hardCorrect == 0 {
                    RecommendationRow(
                        icon: "star.fill",
                        text: "Start with easier problems to build confidence",
                        color: .blue
                    )
                }
                
                RecommendationRow(
                    icon: "doc.text.fill",
                    text: "Assign practice problems to improve mastery",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Strengths Section
    
    private func strengthsSection(_ strengths: [String?]) -> some View {
        let validStrengths = strengths.compactMap { $0 }
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Strengths")
                    .font(.subheadline.bold())
            }
            
            ForEach(validStrengths.indices, id: \.self) { index in
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 4, height: 4)
                    Text(validStrengths[index])
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Improvements Section
    
    private func improvementsSection(_ improvements: [String?]) -> some View {
        let validImprovements = improvements.compactMap { $0 }
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.orange)
                Text("Areas for Improvement")
                    .font(.subheadline.bold())
            }
            
            ForEach(validImprovements.indices, id: \.self) { index in
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 4, height: 4)
                    Text(validImprovements[index])
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Helpers
    
    private var masteryLevelColor: Color {
        switch concept.masteryLevel {
        case .mastered:
            return .green
        case .developing:
            return .orange
        case .emerging:
            return Color(red: 1.0, green: 0.6, blue: 0.0)
        case .needsWork:
            return .red
        }
    }
}

// MARK: - Quick Stat Component

struct QuickStat: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.caption.bold())
                .lineLimit(1)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Recommendation Row

struct RecommendationRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
