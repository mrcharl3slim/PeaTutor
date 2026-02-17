//
//  CognitiveSkillsRadarView.swift
//  PeaTutorApp
//
//  Sprint 7.2 - Phase 3: Cognitive skills radar chart visualization
//

import SwiftUI

struct CognitiveSkillsRadarView: View {
    let profile: CognitiveProfile
    
    @State private var animateChart = false
    @State private var selectedSkill: Int? = nil
    
    // Skill definitions
    private let skills: [(name: String, icon: String, color: Color, description: String)] = [
        (
            "Computation",
            "plus.forwardslash.minus",
            .blue,
            "Basic arithmetic operations and numerical calculations"
        ),
        (
            "Word Problems",
            "text.book.closed",
            .purple,
            "Reading comprehension and translating text to mathematical operations"
        ),
        (
            "Problem Solving",
            "lightbulb.fill",
            .orange,
            "Breaking down complex problems into manageable steps"
        ),
        (
            "Reasoning",
            "brain.head.profile",
            .green,
            "Logical thinking, pattern recognition, and abstract concepts"
        ),
        (
            "Accuracy",
            "target",
            .red,
            "Attention to detail and consistent correct execution"
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                header
                
                // Radar Chart
                radarChart
                
                // Overall Assessment
                overallAssessment
                
                // Skill Breakdown
                skillBreakdown
            }
            .padding()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animateChart = true
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cognitive Skills Profile")
                .font(.title3.bold())
            
            Text("5-dimensional analysis of mathematical abilities")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Radar Chart
    
    private var radarChart: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background Grid
                RadarGridShape(numberOfAxes: 5, numberOfLevels: 4)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                
                // Grid Labels (0%, 25%, 50%, 75%, 100%)
                gridLabels
                
                // Data Polygon
                RadarChartShape(values: animateChart ? profileValues : Array(repeating: 0, count: 5))
                    .fill(
                        RadialGradient(
                            colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                
                RadarChartShape(values: animateChart ? profileValues : Array(repeating: 0, count: 5))
                    .stroke(Color.blue, lineWidth: 3)
                
                // Data Points
                dataPoints
                
                // Axis Labels
                axisLabels
            }
            .frame(height: 320)
            .frame(maxWidth: .infinity)
            
            // Legend
            legend
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Grid Labels
    
    private var gridLabels: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 * 0.85
            
            ForEach(1...4, id: \.self) { level in
                let value = level * 25
                let labelRadius = radius * (Double(level) / 4.0)
                
                Text("\(value)%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .position(
                        x: center.x + labelRadius + 15,
                        y: center.y
                    )
            }
        }
    }
    
    // MARK: - Data Points
    
    private var dataPoints: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 * 0.85
            let angleStep = (2 * Double.pi) / 5
            
            ForEach(0..<5, id: \.self) { index in
                let value = animateChart ? profileValues[index] : 0
                let angle = angleStep * Double(index) - Double.pi / 2
                let distance = radius * (value / 100.0)
                
                Circle()
                    .fill(skills[index].color)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .position(
                        x: center.x + distance * cos(angle),
                        y: center.y + distance * sin(angle)
                    )
            }
        }
    }
    
    // MARK: - Axis Labels
    
    private var axisLabels: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 * 0.85
            let labelDistance = radius + 35
            let angleStep = (2 * Double.pi) / 5
            
            ForEach(0..<5, id: \.self) { index in
                let angle = angleStep * Double(index) - Double.pi / 2
                
                VStack(spacing: 4) {
                    Image(systemName: skills[index].icon)
                        .font(.caption)
                        .foregroundColor(skills[index].color)
                    
                    Text(skills[index].name)
                        .font(.caption2.bold())
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 70)
                .position(
                    x: center.x + labelDistance * cos(angle),
                    y: center.y + labelDistance * sin(angle)
                )
            }
        }
    }
    
    // MARK: - Legend
    
    private var legend: some View {
        HStack(spacing: 16) {
            ForEach(0..<5, id: \.self) { index in
                HStack(spacing: 4) {
                    Circle()
                        .fill(skills[index].color)
                        .frame(width: 8, height: 8)
                    
                    Text("\(Int(profileValues[index]))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Overall Assessment
    
    private var overallAssessment: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Overall Assessment")
                    .font(.subheadline.bold())
            }
            
            Text(overallAssessmentText)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Strengths & Weaknesses
            HStack(spacing: 12) {
                // Top Strength
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("Strongest")
                            .font(.caption.bold())
                    }
                    
                    Text(topStrength.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                
                // Needs Focus
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Focus Area")
                            .font(.caption.bold())
                    }
                    
                    Text(needsFocus.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Skill Breakdown
    
    private var skillBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Breakdown")
                .font(.subheadline.bold())
            
            ForEach(0..<5, id: \.self) { index in
                SkillDetailCard(
                    skill: skills[index].name,
                    value: profileValues[index],
                    icon: skills[index].icon,
                    color: skills[index].color,
                    description: skills[index].description
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var profileValues: [Double] {
        [
            profile.computation,
            profile.wordProblems,
            profile.problemSolving,
            profile.reasoning,
            profile.accuracy
        ]
    }
    
    private var topStrength: (name: String, value: Double) {
        let maxIndex = profileValues.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
        return (skills[maxIndex].name, profileValues[maxIndex])
    }
    
    private var needsFocus: (name: String, value: Double) {
        let minIndex = profileValues.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
        return (skills[minIndex].name, profileValues[minIndex])
    }
    
    private var averageScore: Double {
        profileValues.reduce(0, +) / Double(profileValues.count)
    }
    
    private var overallAssessmentText: String {
        switch averageScore {
        case 80...100:
            return "Excellent overall cognitive profile. This student demonstrates strong mathematical abilities across all skill areas. Continue challenging them with advanced problems."
        case 60..<80:
            return "Good cognitive profile with solid foundational skills. Focus on strengthening \(needsFocus.name.lowercased()) while maintaining progress in other areas."
        case 40..<60:
            return "Developing cognitive skills with room for growth. Provide targeted support in \(needsFocus.name.lowercased()) and reinforce concepts through varied practice."
        default:
            return "Cognitive skills need focused intervention. Recommend one-on-one tutoring with emphasis on \(needsFocus.name.lowercased()) and building confidence through scaffolded practice."
        }
    }
}
