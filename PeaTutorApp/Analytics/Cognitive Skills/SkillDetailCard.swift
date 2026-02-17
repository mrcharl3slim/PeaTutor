//
//  SkillDetailCard.swift
//  PeaTutorApp
//
//  Sprint 7.2 - Phase 3: Individual skill detail card
//

import SwiftUI

struct SkillDetailCard: View {
    let skill: String
    let value: Double
    let icon: String
    let color: Color
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(skill)
                        .font(.subheadline.bold())
                    
                    Text(performanceLevel)
                        .font(.caption)
                        .foregroundColor(performanceLevelColor)
                }
                
                Spacer()
                
                Text("\(Int(value))%")
                    .font(.title3.bold())
                    .foregroundColor(color)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * (min(value, 100) / 100),
                            height: 8
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: value)
                }
            }
            .frame(height: 8)
            
            // Description
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Performance Level
    
    private var performanceLevel: String {
        switch value {
        case 80...100:
            return "Excellent"
        case 60..<80:
            return "Good"
        case 40..<60:
            return "Developing"
        default:
            return "Needs Work"
        }
    }
    
    private var performanceLevelColor: Color {
        switch value {
        case 80...100:
            return .green
        case 60..<80:
            return .orange
        case 40..<60:
            return Color(red: 1.0, green: 0.6, blue: 0.0)
        default:
            return .red
        }
    }
}
