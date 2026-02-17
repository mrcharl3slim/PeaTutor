//
//  MasteryProgressBar.swift
//  PeaTutorApp
//
//  Sprint 7.2 - Phase 2: Reusable progress bar for concept mastery
//

import SwiftUI

struct MasteryProgressBar: View {
    let percentage: Double
    let showPercentage: Bool
    let height: CGFloat
    
    init(
        percentage: Double,
        showPercentage: Bool = true,
        height: CGFloat = 10
    ) {
        self.percentage = percentage
        self.showPercentage = showPercentage
        self.height = height
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: height)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(masteryGradient)
                        .frame(
                            width: geometry.size.width * (min(percentage, 100) / 100),
                            height: height
                        )
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: percentage)
                }
            }
            .frame(height: height)
            
            // Percentage Text
            if showPercentage {
                Text("\(Int(percentage))%")
                    .font(.subheadline.bold())
                    .foregroundColor(masteryColor)
                    .frame(width: 45, alignment: .trailing)
            }
        }
    }
    
    // MARK: - Color Coding
    
    /// Color based on mastery level (matches MasteryLevel enum)
    private var masteryColor: Color {
        switch percentage {
        case 80...100:
            return .green
        case 60..<80:
            return .orange
        case 40..<60:
            return Color(red: 1.0, green: 0.6, blue: 0.0) // Darker orange
        default:
            return .red
        }
    }
    
    /// Gradient for smoother appearance
    private var masteryGradient: LinearGradient {
        let color = masteryColor
        return LinearGradient(
            colors: [color.opacity(0.8), color],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Preview

#Preview("Progress Levels") {
    VStack(spacing: 20) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mastered (95%)")
                .font(.caption)
            MasteryProgressBar(percentage: 95)
        }
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Developing (72%)")
                .font(.caption)
            MasteryProgressBar(percentage: 72)
        }
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Emerging (48%)")
                .font(.caption)
            MasteryProgressBar(percentage: 48)
        }
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Needs Work (25%)")
                .font(.caption)
            MasteryProgressBar(percentage: 25)
        }
        
        VStack(alignment: .leading, spacing: 8) {
            Text("No Percentage Label")
                .font(.caption)
            MasteryProgressBar(percentage: 67, showPercentage: false, height: 6)
        }
    }
    .padding()
}
