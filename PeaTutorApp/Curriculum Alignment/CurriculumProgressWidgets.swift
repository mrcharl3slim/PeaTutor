//
//  CurriculumProgressWidgets.swift
//  PeaTutorApp
//
//  Sprint 8 Phase 5: Curriculum Progress Widgets
//  Reusable curriculum progress components for embedding in dashboards
//

import SwiftUI
import Amplify

// MARK: - Compact Curriculum Progress Card (for Student Dashboard)

struct CurriculumProgressCard: View {
    let studentId: String
    let classroomId: String?
    let gradeLevel: String
    
    @State private var progress: StudentCurriculumProgress?
    @State private var isLoading = false
    
    private var gradeLevelCode: String {
        CurriculumService.gradeLevelToCode(gradeLevel) ?? "P3"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "book.closed.fill")
                    .foregroundColor(.blue)
                Text("Curriculum Progress")
                    .font(.headline)
                
                Spacer()
                
                Text(gradeLevel)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let progress = progress {
                // Progress bars
                VStack(spacing: 12) {
                    CurriculumProgressBar(
                        label: "Coverage",
                        value: progress.coveragePercentage,
                        color: .blue,
                        detail: "\(progress.topicsAttempted)/\(progress.totalTopicsInGrade) topics"
                    )
                    
                    CurriculumProgressBar(
                        label: "Mastery",
                        value: progress.masteryPercentage,
                        color: progress.masteryPercentage >= 70 ? .green : .orange,
                        detail: "\(progress.topicsMastered) mastered"
                    )
                }
                
                // Quick strand indicators
                HStack(spacing: 8) {
                    StrandIndicator(code: "NA", name: "Numbers", progress: strandProgress("NA"))
                    StrandIndicator(code: "MG", name: "Geometry", progress: strandProgress("MG"))
                    StrandIndicator(code: "ST", name: "Statistics", progress: strandProgress("ST"))
                }
                
            } else {
                // No data state
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("No curriculum data yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        .task {
            await loadProgress()
        }
    }
    
    private func strandProgress(_ strand: String) -> Double {
        guard let progressJson = progress?.strandProgress,
              let data = progressJson.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: Double].self, from: data) else {
            return 0
        }
        return decoded[strand] ?? 0
    }
    
    private func loadProgress() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let allProgress = try await Amplify.DataStore.query(StudentCurriculumProgress.self)
            progress = allProgress.first {
                $0.studentId == studentId &&
                $0.gradeLevelCode == gradeLevelCode &&
                (classroomId == nil || $0.classroomId == classroomId)
            }
        } catch {
            print("⚠️ Failed to load curriculum progress: \(error)")
        }
    }
}

// MARK: - Curriculum Progress Bar

struct CurriculumProgressBar: View {
    let label: String
    let value: Double
    let color: Color
    let detail: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(value))%")
                    .font(.caption.bold())
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(value / 100))
                        .animation(.spring(response: 0.5), value: value)
                }
            }
            .frame(height: 8)
            
            Text(detail)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Strand Indicator

struct StrandIndicator: View {
    let code: String
    let name: String
    let progress: Double
    
    private var color: Color {
        switch code {
        case "NA": return .blue
        case "MG": return .green
        case "ST": return .purple
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 3)
                    .frame(width: 36, height: 36)
                
                Circle()
                    .trim(from: 0, to: CGFloat(progress / 100))
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                
                Text(code)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(color)
            }
            
            Text(name)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Teacher Class Curriculum Overview Card

struct ClassCurriculumOverviewCard: View {
    let classroomId: String
    let gradeLevel: String
    
    @State private var studentProgresses: [StudentCurriculumProgress] = []
    @State private var isLoading = false
    
    private var gradeLevelCode: String {
        CurriculumService.gradeLevelToCode(gradeLevel) ?? "P3"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.blue)
                Text("Class Curriculum Progress")
                    .font(.headline)
                
                Spacer()
                
                Text("\(studentProgresses.count) students")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if studentProgresses.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("No curriculum data yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                // Class averages
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        ClassMetricView(
                            label: "Avg Coverage",
                            value: averageCoverage,
                            color: .blue
                        )
                        
                        ClassMetricView(
                            label: "Avg Mastery",
                            value: averageMastery,
                            color: averageMastery >= 70 ? .green : .orange
                        )
                    }
                    
                    // Distribution
                    HStack(spacing: 8) {
                        DistributionBar(
                            label: "Ahead",
                            count: studentsAhead,
                            total: studentProgresses.count,
                            color: .green
                        )
                        DistributionBar(
                            label: "On Track",
                            count: studentsOnTrack,
                            total: studentProgresses.count,
                            color: .blue
                        )
                        DistributionBar(
                            label: "Behind",
                            count: studentsBehind,
                            total: studentProgresses.count,
                            color: .orange
                        )
                    }
                }
                
                // Common gaps
                if !commonGaps.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Common Gaps")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        
                        ForEach(commonGaps.prefix(3), id: \.self) { gap in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text(gap)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        .task {
            await loadClassProgress()
        }
    }
    
    private var averageCoverage: Double {
        guard !studentProgresses.isEmpty else { return 0 }
        return studentProgresses.reduce(0) { $0 + $1.coveragePercentage } / Double(studentProgresses.count)
    }
    
    private var averageMastery: Double {
        guard !studentProgresses.isEmpty else { return 0 }
        return studentProgresses.reduce(0) { $0 + $1.masteryPercentage } / Double(studentProgresses.count)
    }
    
    private var studentsAhead: Int {
        studentProgresses.filter { $0.masteryPercentage >= 80 }.count
    }
    
    private var studentsOnTrack: Int {
        studentProgresses.filter { $0.masteryPercentage >= 50 && $0.masteryPercentage < 80 }.count
    }
    
    private var studentsBehind: Int {
        studentProgresses.filter { $0.masteryPercentage < 50 }.count
    }
    
    private var commonGaps: [String] {
        // Find curriculum codes that appear in multiple students' prerequisite gaps
        var gapCounts: [String: Int] = [:]
        
        for progress in studentProgresses {
            for gap in progress.prerequisiteGaps ?? [] {
                if let gapCode = gap {
                    gapCounts[gapCode, default: 0] += 1
                }
            }
        }
        
        return gapCounts
            .filter { $0.value >= 2 } // At least 2 students have this gap
            .sorted { $0.value > $1.value }
            .map { $0.key }
    }
    
    private func loadClassProgress() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let allProgress = try await Amplify.DataStore.query(StudentCurriculumProgress.self)
            studentProgresses = allProgress.filter {
                $0.classroomId == classroomId &&
                $0.gradeLevelCode == gradeLevelCode
            }
        } catch {
            print("⚠️ Failed to load class curriculum progress: \(error)")
        }
    }
}

// MARK: - Class Metric View

struct ClassMetricView: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Int(value))%")
                .font(.title2.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Distribution Bar

struct DistributionBar: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total) * 100
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.headline)
                .foregroundColor(color)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(height: 6)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}


// MARK: - Parent Stat Item

struct ParentStatItem: View {
    let value: String
    let label: String
    let emoji: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(emoji)
                    .font(.caption)
                Text(value)
                    .font(.title3.bold())
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Mini Strand Progress (for compact displays)

struct MiniStrandProgress: View {
    let strandCode: String
    let progress: Double
    
    private var color: Color {
        switch strandCode {
        case "NA": return .blue
        case "MG": return .green
        case "ST": return .purple
        default: return .gray
        }
    }
    
    private var name: String {
        switch strandCode {
        case "NA": return "Numbers"
        case "MG": return "Geometry"
        case "ST": return "Statistics"
        default: return strandCode
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(progress / 100))
                }
            }
            .frame(height: 6)
            
            Text("\(Int(progress))%")
                .font(.caption2)
                .foregroundColor(color)
                .frame(width: 30, alignment: .trailing)
        }
    }
}
