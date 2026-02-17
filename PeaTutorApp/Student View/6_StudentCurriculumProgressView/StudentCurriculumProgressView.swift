//
//  StudentCurriculumProgressView.swift
//  PeaTutorApp
//
//  Sprint 8 Phase 5: Curriculum Progress Views
//  Dedicated view showing student's mastery against MOE curriculum map
//

import SwiftUI
import Amplify

extension CurriculumStandard: Identifiable {}

struct StudentCurriculumProgressView: View {
    let studentId: String
    let studentName: String
    let classroomId: String?
    let gradeLevel: String
    
    @StateObject private var curriculumService = CurriculumService.shared
    @StateObject private var mappingService = CurriculumMappingService.shared
    
    // Data state
    @State private var curriculumProgress: StudentCurriculumProgress?
    @State private var conceptMastery: [ConceptMastery] = []
    @State private var curriculumStandards: [CurriculumStandard] = []
    @State private var recommendation: CurriculumRecommendation?
    
    // UI state
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedStrand: String? = nil
    @State private var showingTopicDetail: CurriculumStandard?
    
    private let gradeLevelCode: String
    
    init(studentId: String, studentName: String, classroomId: String?, gradeLevel: String) {
        self.studentId = studentId
        self.studentName = studentName
        self.classroomId = classroomId
        self.gradeLevel = gradeLevel
        self.gradeLevelCode = CurriculumService.gradeLevelToCode(gradeLevel) ?? "P3"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Progress Overview Card
                progressOverviewCard
                
                // Strand Progress Section
                //strandProgressSection
                
                // Topic Mastery Heat Map
                topicMasterySection
                
                // Prerequisite Gaps Warning
                /*if hasPrerequisiteGaps {
                    prerequisiteGapsSection
                }*/
                
                // Recommended Next Topics
                //recommendedTopicsSection
            }
            .padding()
        }
        .navigationTitle("Curriculum Progress")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadCurriculumProgress()
        }
        .refreshable {
            await loadCurriculumProgress()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .sheet(item: $showingTopicDetail) { standard in
            TopicDetailSheet(
                standard: standard,
                mastery: masteryForStandard(standard),
                studentId: studentId,
                classroomId: classroomId
            )
        }
    }
    
    // MARK: - Progress Overview Card
    
    private var progressOverviewCard: some View {
        VStack(spacing: 20) {
            // Header with grade level
            /*HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(studentName)
                        .font(.title2.bold())
                    
                    HStack(spacing: 8) {
                        Label(gradeLevel, systemImage: "graduationcap.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("â€¢")
                            .foregroundColor(.secondary)
                        
                        Text("MOE Mathematics")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Curriculum badge
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    Text("SG 2021")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()*/
            
            // Progress Rings
            HStack(spacing: 24) {
                // Coverage Ring
                ProgressRingView(
                    progress: curriculumProgress?.coveragePercentage ?? 0,
                    color: .blue,
                    label: "Coverage",
                    icon: "square.grid.2x2.fill"
                )
                
                // Mastery Ring
                ProgressRingView(
                    progress: curriculumProgress?.masteryPercentage ?? 0,
                    color: masteryColor,
                    label: "Mastery",
                    icon: "star.fill"
                )
            }
            
            // Quick Stats
            HStack(spacing: 0) {
                QuickStatItem(
                    value: "\(curriculumProgress?.topicsMastered ?? 0)",
                    label: "Mastered",
                    color: .green
                )
                
                Divider()
                    .frame(height: 40)
                
                QuickStatItem(
                    value: "\(curriculumProgress?.topicsInProgress ?? 0)",
                    label: "In Progress",
                    color: .orange
                )
                
                Divider()
                    .frame(height: 40)
                
                QuickStatItem(
                    value: "\(curriculumProgress?.topicsNotStarted ?? 0)",
                    label: "Not Started",
                    color: .gray
                )
                
                Divider()
                    .frame(height: 40)
                
                QuickStatItem(
                    value: "\(curriculumProgress?.totalTopicsInGrade ?? 0)",
                    label: "Total",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    private var masteryColor: Color {
        let mastery = curriculumProgress?.masteryPercentage ?? 0
        if mastery >= 70 { return .green }
        if mastery >= 50 { return .orange }
        return .red
    }
    
    // MARK: - Strand Progress Section
    
    private var strandProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress by Strand")
                .font(.title3.bold())
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(strandProgressData, id: \.strand) { data in
                        StrandProgressRow(
                            strandCode: data.strand,
                            strandName: strandDisplayName(data.strand),
                            progress: data.progress,
                            topicCount: data.topicCount,
                            masteredCount: data.masteredCount,
                            isSelected: selectedStrand == data.strand,
                            onTap: {
                                withAnimation {
                                    selectedStrand = selectedStrand == data.strand ? nil : data.strand
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    private var strandProgressData: [StrandProgress] {
        // Parse strand progress from JSON string
        guard let progressJson = curriculumProgress?.strandProgress,
              let data = progressJson.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: Double].self, from: data) else {
            // Return default strands with 0 progress
            return [
                StrandProgress(strand: "NA", progress: 0, topicCount: 0, masteredCount: 0),
                StrandProgress(strand: "MG", progress: 0, topicCount: 0, masteredCount: 0),
                StrandProgress(strand: "ST", progress: 0, topicCount: 0, masteredCount: 0)
            ]
        }
        
        // Get topic counts per strand from standards
        let strandTopicCounts = Dictionary(grouping: curriculumStandards) { $0.strandCode }
            .mapValues { $0.count }
        
        // Get mastered counts from mastery data
        let masteredByStrand = conceptMastery
            .filter { $0.masteryPercentage >= 80 }
            .compactMap { $0.curriculumStrand }
            .reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }
        
        return decoded.map { (strand, progress) in
            StrandProgress(
                strand: strand,
                progress: progress,
                topicCount: strandTopicCounts[strand] ?? 0,
                masteredCount: masteredByStrand[strand] ?? 0
            )
        }.sorted { $0.strand < $1.strand }
    }
    
    private func strandDisplayName(_ code: String) -> String {
        switch code {
        case "NA": return "Number and Algebra"
        case "MG": return "Measurement and Geometry"
        case "ST": return "Statistics"
        default: return code
        }
    }
    
    // MARK: - Topic Mastery Section
    
    private var topicMasterySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack {
                Text("Topic Mastery")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Legend
                HStack(spacing: 12) {
                    LegendItem3(color: .green, label: "Mastered")
                    LegendItem3(color: .orange, label: "Learning")
                    LegendItem3(color: .gray.opacity(0.3), label: "Not Started")
                }
            }
            
            // Filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterPill(
                            label: "All",
                            isSelected: selectedStrand == nil,
                            action: {
                                withAnimation {
                                    selectedStrand = nil
                                }
                            }
                        )
                        
                        ForEach(["NA", "MG", "ST"], id: \.self) { strand in
                            FilterPill(
                                label: strandDisplayName(strand),
                                isSelected: selectedStrand == strand,
                                action: {
                                    withAnimation {
                                        selectedStrand = strand
                                    }
                                }
                            )
                        }
                    }
                }
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                // Heat map grid
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 44, maximum: 60), spacing: 8)
                ], spacing: 8) {
                    ForEach(filteredStandards, id: \.id) { standard in
                        TopicMasteryCell(
                            standard: standard,
                            status: masteryStatusForStandard(standard),
                            onTap: {
                                showingTopicDetail = standard
                            }
                        )
                    }
                }
            }
            
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    private var filteredStandards: [CurriculumStandard] {
        if let strand = selectedStrand {
            return curriculumStandards.filter { $0.strandCode == strand }
        }
        return curriculumStandards
    }
    
    private func masteryStatusForStandard(_ standard: CurriculumStandard) -> MasteryStatus {
        // Check if we have mastery data for this standard
        if let mastery = conceptMastery.first(where: { $0.curriculumCode == standard.curriculumCode }) {
            if mastery.masteryPercentage >= 80 {
                return .mastered
            } else if mastery.masteryPercentage >= 40 {
                return .inProgress
            } else {
                return .emerging
            }
        }
        
        // Check mastered/in-progress topic codes from progress record
        if curriculumProgress?.masteredTopicCodes.contains(standard.curriculumCode) == true {
            return .mastered
        }
        if curriculumProgress?.inProgressTopicCodes.contains(standard.curriculumCode) == true {
            return .inProgress
        }
        
        return .notStarted
    }
    
    private func masteryForStandard(_ standard: CurriculumStandard) -> ConceptMastery? {
        return conceptMastery.first { $0.curriculumCode == standard.curriculumCode }
    }
    
    // MARK: - Prerequisite Gaps Section
    
    private var hasPrerequisiteGaps: Bool {
        guard let gaps = curriculumProgress?.prerequisiteGaps else { return false }
        return !gaps.compactMap { $0 }.isEmpty
    }
    
    private var prerequisiteGapsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Prerequisite Gaps")
                    .font(.title3.bold())
            }
            
            Text("These foundational topics need attention before moving forward:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            let gapCodes = curriculumProgress?.prerequisiteGaps?.compactMap { $0 } ?? []
            let gapStandards = curriculumStandards.filter { gapCodes.contains($0.curriculumCode) }
            
            VStack(spacing: 8) {
                ForEach(gapStandards, id: \.id) { standard in
                    PrerequisiteGapRow(
                        standard: standard,
                        onPractice: {
                            showingTopicDetail = standard
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Recommended Topics Section
    
    private var recommendedTopicsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Recommended Next")
                    .font(.title3.bold())
            }
            
            Text("Based on curriculum sequence and current progress:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let recommendation = recommendation {
                VStack(spacing: 8) {
                    ForEach(recommendation.recommendedNextStandards.prefix(5), id: \.id) { standard in
                        RecommendedTopicRow(
                            standard: standard,
                            onStart: {
                                showingTopicDetail = standard
                            }
                        )
                    }
                }
            } else {
                Text("Complete more topics to get personalized recommendations.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Load Data
    
    private func loadCurriculumProgress() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load curriculum standards for this grade
            curriculumStandards = try await curriculumService.fetchStandards(forGradeCode: gradeLevelCode)
            
            // Load concept mastery for student
            conceptMastery = try await Amplify.DataStore.query(ConceptMastery.self)
                .filter { $0.studentId == studentId && (classroomId == nil || $0.classroomId == classroomId) }
            
            // Load or calculate curriculum progress
            let allProgress = try await Amplify.DataStore.query(StudentCurriculumProgress.self)
            curriculumProgress = allProgress.first {
                $0.studentId == studentId &&
                $0.gradeLevelCode == gradeLevelCode &&
                (classroomId == nil || $0.classroomId == classroomId)
            }
            
            // Get recommendation
            recommendation = try await mappingService.getRecommendedPath(
                studentId: studentId,
                classroomId: classroomId,
                targetGradeLevel: gradeLevel
            )
            
            // If no progress record exists, calculate it
            if curriculumProgress == nil {
                try await AnalyticsService.shared.updateStudentCurriculumProgress(
                    studentId: studentId,
                    classroomId: classroomId,
                    gradeLevel: gradeLevel
                )
                
                // Reload
                let updatedProgress = try await Amplify.DataStore.query(StudentCurriculumProgress.self)
                curriculumProgress = updatedProgress.first {
                    $0.studentId == studentId &&
                    $0.gradeLevelCode == gradeLevelCode
                }
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Supporting Types

struct StrandProgress {
    let strand: String
    let progress: Double
    let topicCount: Int
    let masteredCount: Int
}

enum MasteryStatus {
    case mastered
    case inProgress
    case emerging
    case notStarted
    
    var color: Color {
        switch self {
        case .mastered: return .green
        case .inProgress: return .orange
        case .emerging: return .yellow
        case .notStarted: return .gray.opacity(0.3)
        }
    }
}

// MARK: - Progress Ring View

struct ProgressRingView: View {
    let progress: Double
    let color: Color
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 10)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: CGFloat(progress / 100))
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8), value: progress)
                
                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(color)
                    Text("\(Int(progress))%")
                        .font(.title2.bold())
                        .foregroundColor(color)
                }
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Quick Stat Item

struct QuickStatItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Strand Progress Row

struct StrandProgressRow: View {
    let strandCode: String
    let strandName: String
    let progress: Double
    let topicCount: Int
    let masteredCount: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    private var strandColor: Color {
        switch strandCode {
        case "NA": return .blue
        case "MG": return .green
        case "ST": return .purple
        default: return .gray
        }
    }
    
    private var strandIcon: String {
        switch strandCode {
        case "NA": return "number"
        case "MG": return "ruler"
        case "ST": return "chart.bar.fill"
        default: return "book"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Strand Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(strandColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: strandIcon)
                        .font(.title3)
                        .foregroundColor(strandColor)
                }
                
                // Strand Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(strandName)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    Text("\(masteredCount)/\(topicCount) topics")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Progress
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(progress))%")
                        .font(.headline)
                        .foregroundColor(strandColor)
                    
                    // Mini progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(strandColor.opacity(0.2))
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(strandColor)
                                .frame(width: geometry.size.width * CGFloat(progress / 100))
                        }
                    }
                    .frame(width: 60, height: 4)
                }
                
                Image(systemName: isSelected ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(isSelected ? strandColor.opacity(0.05) : Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Topic Mastery Cell

struct TopicMasteryCell: View {
    let standard: CurriculumStandard
    let status: MasteryStatus
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(status.color)
                    .frame(height: 44)
                    .overlay(
                        VStack(spacing: 2) {
                            Text("Topic")
                                .font(.system(size: 8))
                                .foregroundColor(status == .notStarted ? .gray.opacity(0.7) : .white.opacity(0.8))
                                                    
                            Text(standard.topicNumber.isEmpty ? "?" : standard.topicNumber)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(status == .notStarted ? .gray : .white)
                        }
                    )
                
                Text(standard.subStrand)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Legend Item

struct LegendItem3: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .cornerRadius(16)
        }
    }
}

// MARK: - Prerequisite Gap Row

struct PrerequisiteGapRow: View {
    let standard: CurriculumStandard
    let onPractice: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(standard.topicTitle)
                    .font(.subheadline.bold())
                
                Text(standard.curriculumCode)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onPractice) {
                Text("Practice")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Recommended Topic Row

struct RecommendedTopicRow: View {
    let standard: CurriculumStandard
    let onStart: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Text(standard.topicNumber.isEmpty ? "?" : standard.topicNumber)
                    .font(.caption.bold())
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(standard.topicTitle)
                    .font(.subheadline.bold())
                
                Text(standard.subTopicDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: onStart) {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Topic Detail Sheet

struct TopicDetailSheet: View {
    let standard: CurriculumStandard
    let mastery: ConceptMastery?
    let studentId: String
    let classroomId: String?
    
    @StateObject private var awsService = AWSService.shared
    @StateObject private var assignmentService = PracticeAssignmentService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var isGeneratingPractice = false
    @State private var generatedProblems: [PracticeProblem] = []
    @State private var showingPracticeSession = false
    @State private var showingAssignPractice = false
    @State private var targetStudent: UserProfile?
    
    @State private var isSavingAssignment = false
    @State private var createdAssignment: PracticeAssignment?
    @State private var errorMessage: String?
    @State private var showingError = false
    
    // Check if current user is parent or teacher (can assign)
    private var canAssignToOthers: Bool {
        guard let role = awsService.currentUserProfile?.userRole else { return false }
        return role == .parent || role == .teacher
    }

    private var isStudent: Bool {
        awsService.currentUserProfile?.userRole == .student
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(standard.curriculumCode)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue)
                                .cornerRadius(6)
                            
                            Spacer()
                            
                            if let mastery = mastery {
                                Text("\(Int(mastery.masteryPercentage))% Mastery")
                                    .font(.subheadline.bold())
                                    .foregroundColor(mastery.masteryPercentage >= 80 ? .green : .orange)
                            } else {
                                Text("Not Started")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text(standard.topicTitle)
                            .font(.title2.bold())
                        
                        Text(standard.subTopicDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Strand", value: standard.strand)
                        DetailRow(label: "Sub-strand", value: standard.subStrand)
                        DetailRow(label: "Grade", value: standard.gradeLevel)
                        
                        if !standard.keywords.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Keywords")
                                    .font(.subheadline.bold())
                                
                                FlowLayout4(spacing: 8) {
                                    ForEach(standard.keywords, id: \.self) { keyword in
                                        Text(keyword)
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        
                        let prereqs = standard.prerequisiteCodes?.compactMap { $0 } ?? []
                        if !prereqs.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Prerequisites")
                                    .font(.subheadline.bold())
                                
                                ForEach(prereqs, id: \.self) { code in
                                    HStack {
                                        Image(systemName: "arrow.right.circle")
                                            .foregroundColor(.orange)
                                        Text(code)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                    
                    // Generated Problems Section (shown after generation)
                    if !generatedProblems.isEmpty {
                        generatedProblemsSection
                    } else {
                        // Generate Button (shown before generation)
                        Button(action: generatePractice) {
                            HStack {
                                if isGeneratingPractice {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(isGeneratingPractice ? "Generating..." : "Generate Practice Problems")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isGeneratingPractice)
                    }
                }
                .padding()
            }
            .navigationTitle("Topic Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await loadTargetStudent()
            }
            .alert("Error", isPresented: $showingError) {  // ✅ ADD THIS ENTIRE ALERT
                Button("OK", role: .cancel) {}
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .fullScreenCover(isPresented: $showingPracticeSession) {
                PracticeSessionView(
                    problems: generatedProblems,
                    child: targetStudent,
                    assignment: createdAssignment,  // ✅ ADD THIS PARAMETER
                    onComplete: { completedAssignment in  // ✅ ADD THIS CALLBACK
                        // Assignment completed, dismiss
                        dismiss()
                    }
                )
            }
            .sheet(isPresented: $showingAssignPractice) {
                AssignPracticeView(
                    problems: generatedProblems,
                    sourceType: .topic,
                    curriculumCodes: [standard.curriculumCode],
                    curriculumGradeLevel: standard.gradeLevel,
                    targetConcepts: [standard.topicTitle],
                    targetChild: targetStudent,
                    classroom: nil,
                    onAssigned: { assignment in
                        dismiss()
                    }
                )
            }
        }
    }
    
    // MARK: - Generated Problems Section
    
    private var generatedProblemsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Practice Ready!")
                    .font(.headline)
                
                Spacer()
                
                Text("\(generatedProblems.count) problems")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Preview first few problems
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(generatedProblems.prefix(3).enumerated()), id: \.offset) { index, problem in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        
                        Text(cleanLatexForPreview(problem.problemText))
                            .font(.caption)
                            .lineLimit(2)
                    }
                }
                
                if generatedProblems.count > 3 {
                    Text("... and \(generatedProblems.count - 3) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            
            // Student: Show both Start Now and Save for Later
            if isStudent {
                // Start Practice Now Button
                Button(action: startPracticeNow) {  // ✅ CHANGED action
                    HStack {
                        if isSavingAssignment {  // ✅ ADD loading state
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "play.fill")
                        }
                        Text(isSavingAssignment ? "Saving..." : "Start Practice Now")  // ✅ CHANGED text
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isSavingAssignment)  // ✅ ADD disable state
                
                // Save for Later Button - ✅ ADD THIS ENTIRE BUTTON
                Button(action: saveForLater) {
                    HStack {
                        if isSavingAssignment {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        } else {
                            Image(systemName: "bookmark.fill")
                        }
                        Text(isSavingAssignment ? "Saving..." : "Save for Later")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                }
                .disabled(isSavingAssignment)
            }

            // Parent/Teacher: Show Assign Button
            if canAssignToOthers, let student = targetStudent {  // ✅ CHANGED from canAssign
                Button(action: { showingAssignPractice = true }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Assign to \(student.displayName)")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Helper Methods
    
    private func loadTargetStudent() async {
        do {
            print("🔍 Loading target student profile for studentId: \(studentId)")
            let profiles = try await Amplify.DataStore.query(UserProfile.self)
            print("   Found \(profiles.count) profiles in DataStore")
            
            targetStudent = profiles.first { $0.userId == studentId }
            
            if let student = targetStudent {
                print("   ✅ Found target student: \(student.displayName) (userId: \(student.userId))")
            } else {
                print("   ⚠️ Target student not found in DataStore, trying API...")
                
                // Try API fallback
                let request = GraphQLRequest<UserProfile>.list(
                    UserProfile.self,
                    where: UserProfile.keys.userId == studentId
                )
                let result = try await Amplify.API.query(request: request)
                
                switch result {
                case .success(let fetchedProfiles):
                    if let profile = fetchedProfiles.first {
                        targetStudent = profile
                        print("   ✅ Found in API: \(profile.displayName)")
                        // Save for offline access
                        try? await Amplify.DataStore.save(profile)
                    } else {
                        print("   ❌ Student not found in cloud either")
                    }
                case .failure(let error):
                    print("   ❌ API query failed: \(error)")
                }
            }
        } catch {
            print("❌ Failed to load student profile: \(error)")
        }
    }
    
    private func generatePractice() {
        isGeneratingPractice = true
        
        Task {
            do {
                let problems = try await PracticeGenerationService.shared.generateForCurriculumCodes(
                    curriculumCodes: [standard.curriculumCode],
                    difficulty: .similar,
                    count: 5,
                    userId: studentId
                )
                
                await MainActor.run {
                    generatedProblems = problems
                    isGeneratingPractice = false
                }
            } catch {
                await MainActor.run {
                    isGeneratingPractice = false
                }
            }
        }
    }
    
    private func startPracticeNow() {
        Task {
            isSavingAssignment = true
            defer { isSavingAssignment = false }
            
            do {
                guard let userId = awsService.currentUserId else {
                    throw PracticeAssignmentError.unauthorized
                }
                
                // Create assignment first
                let assignment = try await assignmentService.createAssignment(
                    assignedByUserId: userId,
                    assignedByRole: .student,
                    studentId: userId,
                    classroomId: classroomId,
                    title: "\(standard.topicTitle) Practice",
                    description: "Self-generated practice from curriculum browser",
                    dueDate: nil,
                    problems: generatedProblems,
                    sourceType: .topic,
                    curriculumCodes: [standard.curriculumCode],
                    curriculumGradeLevel: standard.gradeLevel,
                    targetConcepts: [standard.topicTitle]
                )
                
                print("✅ Created self-assignment for Start Now: \(assignment.id)")
                
                // Start the assignment immediately
                let startedAssignment = try await assignmentService.startAssignment(assignment)
                
                await MainActor.run {
                    createdAssignment = startedAssignment
                    showingPracticeSession = true
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }

    private func saveForLater() {
        Task {
            isSavingAssignment = true
            defer { isSavingAssignment = false }
            
            do {
                guard let userId = awsService.currentUserId else {
                    throw PracticeAssignmentError.unauthorized
                }
                
                // Create assignment for later
                let assignment = try await assignmentService.createAssignment(
                    assignedByUserId: userId,
                    assignedByRole: .student,
                    studentId: userId,
                    classroomId: classroomId,
                    title: "\(standard.topicTitle) Practice",
                    description: "Self-generated practice from curriculum browser",
                    dueDate: nil,
                    problems: generatedProblems,
                    sourceType: .topic,
                    curriculumCodes: [standard.curriculumCode],
                    curriculumGradeLevel: standard.gradeLevel,
                    targetConcepts: [standard.topicTitle]
                )
                
                print("✅ Saved assignment for later: \(assignment.id)")
                print("   studentId: \(assignment.studentId)")
                print("   title: \(assignment.title)")
                
                // Dismiss the sheet after successful save
                await MainActor.run {
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func cleanLatexForPreview(_ text: String) -> String {
        var cleaned = text
        cleaned = cleaned.replacingOccurrences(of: "$", with: "")
        cleaned = cleaned.replacingOccurrences(of: "\\frac{", with: "")
        cleaned = cleaned.replacingOccurrences(of: "}{", with: "/")
        cleaned = cleaned.replacingOccurrences(of: "}", with: "")
        cleaned = cleaned.replacingOccurrences(of: "\\times", with: "×")
        cleaned = cleaned.replacingOccurrences(of: "\\div", with: "÷")
        return cleaned
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
    }
}

// MARK: - Flow Layout (for keywords)

struct FlowLayout4: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var positions: [CGPoint] = []
        var height: CGFloat = 0
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            height = y + rowHeight
        }
    }
}
