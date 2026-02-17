//
//  CurriculumStrandProgressView.swift
//  PeaTutorApp
//
//  Reusable curriculum progress view showing strand and sub-strand progress
//  Can be used by: Students, Parents, Teachers
//
//  Usage:
//  - Student (in class): CurriculumStrandProgressView(studentId: userId, classroomId: classId, gradeLevel: classroom.gradeLevel)
//  - Parent (viewing child): CurriculumStrandProgressView(studentId: childId, classroomId: classId, gradeLevel: child.gradeLevel, studentName: child.name)
//  - Teacher (viewing student): CurriculumStrandProgressView(studentId: studentId, classroomId: classId, gradeLevel: classroom.gradeLevel, studentName: studentName)
//

import SwiftUI
import Amplify

// MARK: - Curriculum Strand Progress View (Reusable)

struct CurriculumStrandProgressView: View {
    // Required
    let studentId: String
    let gradeLevel: String
    
    // Optional
    let classroomId: String?
    let studentName: String?
    let showHeader: Bool
    let accentColor: Color
    
    // State
    @StateObject private var curriculumService = CurriculumService.shared
    @State private var progress: StudentCurriculumProgress?
    @State private var curriculumStandards: [CurriculumStandard] = []
    @State private var isLoading = false
    @State private var expandedStrands: Set<String> = []
    @State private var errorMessage: String?
    
    private var gradeLevelCode: String {
        CurriculumService.gradeLevelToCode(gradeLevel) ?? "P1"
    }
    
    // MARK: - Initializers
    
    /// Full initializer with all options
    init(
        studentId: String,
        classroomId: String? = nil,
        gradeLevel: String,
        studentName: String? = nil,
        showHeader: Bool = true,
        accentColor: Color = .blue
    ) {
        self.studentId = studentId
        self.classroomId = classroomId
        self.gradeLevel = gradeLevel
        self.studentName = studentName
        self.showHeader = showHeader
        self.accentColor = accentColor
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header (optional)
                if showHeader {
                    headerView
                }
                
                // Progress Overview
                if isLoading {
                    loadingView
                } else if let progress = progress {
                    progressOverviewCard(progress)
                    strandAndSubStrandSection(progress)
                } else {
                    emptyStateView
                }
                
                // View Full Details Link
                fullDetailsLink
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .task {
            await loadData()
        }
        .refreshable {
            await loadData()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack(spacing: 12) {
            Image(systemName: "graduationcap.fill")
                .font(.title2)
                .foregroundColor(accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                if let name = studentName {
                    Text("\(name)'s Curriculum")
                        .font(.headline)
                } else {
                    Text("MOE Curriculum")
                        .font(.headline)
                }
                Text(gradeLevel)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("Singapore")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading curriculum progress...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Progress Overview Card
    
    private func progressOverviewCard(_ progress: StudentCurriculumProgress) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                // Coverage Ring
                ProgressRing(
                    value: progress.coveragePercentage,
                    label: "Coverage",
                    color: .blue
                )
                
                // Mastery Ring
                ProgressRing(
                    value: progress.masteryPercentage,
                    label: "Mastery",
                    color: progress.masteryPercentage >= 70 ? .green :
                           progress.masteryPercentage >= 50 ? .orange : .red
                )
                
                Spacer()
                
                // Topic Stats
                VStack(alignment: .leading, spacing: 8) {
                    TopicStatRow(icon: "checkmark.circle.fill", color: .green,
                                 value: progress.topicsMastered, label: "Mastered")
                    TopicStatRow(icon: "arrow.triangle.2.circlepath", color: .orange,
                                 value: progress.topicsInProgress, label: "In Progress")
                    TopicStatRow(icon: "circle.dashed", color: .gray,
                                 value: progress.topicsNotStarted, label: "Not Started")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Strand and SubStrand Section
    
    private func strandAndSubStrandSection(_ progress: StudentCurriculumProgress) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress by Topic")
                .font(.headline)
            
            let strandGroups = groupedByStrand()
            
            if strandGroups.isEmpty {
                Text("No curriculum standards found for \(gradeLevel)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(strandGroups.keys.sorted(), id: \.self) { strandCode in
                    if let strandData = strandGroups[strandCode] {
                        StrandSectionView(
                            strandCode: strandCode,
                            strandName: strandData.name,
                            subStrands: strandData.subStrands,
                            progress: progress,
                            isExpanded: expandedStrands.contains(strandCode),
                            accentColor: accentColor
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                if expandedStrands.contains(strandCode) {
                                    expandedStrands.remove(strandCode)
                                } else {
                                    expandedStrands.insert(strandCode)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Group Standards
    
    private func groupedByStrand() -> [String: StrandGroupData] {
        var result: [String: StrandGroupData] = [:]
        
        let byStrand = Dictionary(grouping: curriculumStandards) { $0.strandCode }
        
        for (strandCode, standards) in byStrand {
            let strandName = standards.first?.strand ?? strandCode
            let bySubStrand = Dictionary(grouping: standards) { $0.subStrandCode }
            
            var subStrands: [SubStrandGroupData] = []
            for (subStrandCode, subStrandStandards) in bySubStrand {
                let subStrandName = subStrandStandards.first?.subStrand ?? subStrandCode
                subStrands.append(SubStrandGroupData(
                    code: subStrandCode,
                    name: subStrandName,
                    topics: subStrandStandards.sorted { $0.sequenceOrder < $1.sequenceOrder }
                ))
            }
            
            subStrands.sort { ($0.topics.first?.sequenceOrder ?? 0) < ($1.topics.first?.sequenceOrder ?? 0) }
            result[strandCode] = StrandGroupData(name: strandName, subStrands: subStrands)
        }
        
        return result
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Curriculum Data Yet")
                .font(.headline)
            
            if let name = studentName {
                Text("\(name) needs to complete homework and practice to see curriculum progress.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Complete homework and practice to see your progress against the MOE curriculum.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Full Details Link
    
    private var fullDetailsLink: some View {
        NavigationLink {
            StudentCurriculumProgressView(
                studentId: studentId,
                studentName: studentName ?? "Student",
                classroomId: classroomId,
                gradeLevel: gradeLevel
            )
        } label: {
            HStack {
                Image(systemName: "list.bullet.rectangle.portrait")
                    .foregroundColor(accentColor)
                
                Text("View Detailed Curriculum Map")
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Load Data
    
    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load curriculum standards for this grade
            curriculumStandards = try await curriculumService.fetchStandards(forGradeCode: gradeLevelCode)
            
            // Load student progress
            let allProgress = try await Amplify.DataStore.query(StudentCurriculumProgress.self)
            
            if let classroomId = classroomId {
                progress = allProgress.first {
                    $0.studentId == studentId &&
                    $0.classroomId == classroomId &&
                    $0.gradeLevelCode == gradeLevelCode
                }
            } else {
                progress = allProgress.first {
                    $0.studentId == studentId &&
                    $0.gradeLevelCode == gradeLevelCode
                }
            }
            
            // Auto-expand first strand if we have data
            if let firstStrand = groupedByStrand().keys.sorted().first {
                expandedStrands.insert(firstStrand)
            }
        } catch {
            errorMessage = "Failed to load curriculum data: \(error.localizedDescription)"
            print("⚠️ Failed to load curriculum data: \(error)")
        }
    }
}

// MARK: - Data Types

struct StrandGroupData {
    let name: String
    var subStrands: [SubStrandGroupData]
}

struct SubStrandGroupData: Identifiable {
    let code: String
    let name: String
    let topics: [CurriculumStandard]
    
    var id: String { code }
}

// MARK: - Progress Ring Component

struct ProgressRing: View {
    let value: Double
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(value, 100) / 100))
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(value))%")
                    .font(.title3.bold())
                    .foregroundColor(color)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Topic Stat Row

struct TopicStatRow: View {
    let icon: String
    let color: Color
    let value: Int
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text("\(value)")
                .font(.subheadline.bold())
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Strand Section View

struct StrandSectionView: View {
    let strandCode: String
    let strandName: String
    let subStrands: [SubStrandGroupData]
    let progress: StudentCurriculumProgress
    let isExpanded: Bool
    let accentColor: Color
    let onToggle: () -> Void
    
    private var strandColor: Color {
        switch strandCode {
        case "NA": return .blue
        case "MG": return .green
        case "ST": return .purple
        default: return accentColor
        }
    }
    
    private var strandProgress: Double {
        let allTopicCodes = subStrands.flatMap { $0.topics.map { $0.curriculumCode } }
        guard !allTopicCodes.isEmpty else { return 0 }
        
        let masteredCount = allTopicCodes.filter { progress.masteredTopicCodes.contains($0) }.count
        return Double(masteredCount) / Double(allTopicCodes.count) * 100
    }
    
    private var totalTopics: Int {
        subStrands.reduce(0) { $0 + $1.topics.count }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Strand Header (tappable)
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    // Strand Icon
                    ZStack {
                        Circle()
                            .fill(strandColor.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Text(strandCode)
                            .font(.caption.bold())
                            .foregroundColor(strandColor)
                    }
                    
                    // Strand Name
                    VStack(alignment: .leading, spacing: 2) {
                        Text(strandName)
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        
                        Text("\(subStrands.count) sub-topics • \(totalTopics) topics")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Progress
                    Text("\(Int(strandProgress))%")
                        .font(.subheadline.bold())
                        .foregroundColor(strandColor)
                    
                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(strandColor.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(strandColor)
                        .frame(width: geometry.size.width * CGFloat(strandProgress / 100))
                }
            }
            .frame(height: 6)
            
            // Expanded Content - SubStrands
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(subStrands) { subStrand in
                        SubStrandRowView(
                            subStrand: subStrand,
                            progress: progress,
                            strandColor: strandColor
                        )
                    }
                }
                .padding(.top, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 8)
        
        Divider()
    }
}

// MARK: - SubStrand Row View

struct SubStrandRowView: View {
    let subStrand: SubStrandGroupData
    let progress: StudentCurriculumProgress
    let strandColor: Color
    
    private var topicCodes: [String] {
        subStrand.topics.map { $0.curriculumCode }
    }
    
    private var masteredCount: Int {
        topicCodes.filter { progress.masteredTopicCodes.contains($0) }.count
    }
    
    private var inProgressCount: Int {
        topicCodes.filter { progress.inProgressTopicCodes.contains($0) }.count
    }
    
    private var notStartedCount: Int {
        topicCodes.count - masteredCount - inProgressCount
    }
    
    private var subStrandProgress: Double {
        guard !topicCodes.isEmpty else { return 0 }
        return Double(masteredCount) / Double(topicCodes.count) * 100
    }
    
    private var statusColor: Color {
        if subStrandProgress >= 80 { return .green }
        if subStrandProgress >= 50 { return .orange }
        if subStrandProgress > 0 { return .blue }
        return .gray
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                // SubStrand name
                VStack(alignment: .leading, spacing: 2) {
                    Text(subStrand.name)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    // Topic count breakdown
                    HStack(spacing: 8) {
                        if masteredCount > 0 {
                            Label("\(masteredCount)", systemImage: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        if inProgressCount > 0 {
                            Label("\(inProgressCount)", systemImage: "arrow.triangle.2.circlepath")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        if notStartedCount > 0 {
                            Label("\(notStartedCount)", systemImage: "circle.dashed")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                // Progress percentage
                Text("\(Int(subStrandProgress))%")
                    .font(.caption.bold())
                    .foregroundColor(statusColor)
            }
            
            // Mini progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(statusColor)
                        .frame(width: geometry.size.width * CGFloat(subStrandProgress / 100))
                }
            }
            .frame(height: 4)
            .padding(.leading, 20)
        }
        .padding(.vertical, 8)
        .padding(.leading, 20)
    }
}
