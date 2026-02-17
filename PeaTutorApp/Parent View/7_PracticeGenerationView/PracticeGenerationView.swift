//
//  PracticeGenerationView.swift
//  PeaTutorApp
//
//  Sprint 7.4: AI-Powered Practice Generation
//  View for generating practice problems from a worksheet
//

import SwiftUI
import Amplify

struct PracticeGenerationView: View {
    let worksheet: Worksheet?
    let child: UserProfile?
    let concepts: [String]
    let initialDifficulty: PracticeDifficulty
    
    @StateObject private var generationService = PracticeGenerationService.shared
    @StateObject private var awsService = AWSService.shared
    
    @State private var selectedDifficulty: PracticeDifficulty
    @State private var problemCount: Int = 10
    @State private var generatedProblems: [PracticeProblem] = []
    @State private var showingPracticeSession = false
    @State private var showingAssignPractice = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var worksheetMetadata: WorksheetMetadata?
    
    @Environment(\.dismiss) private var dismiss
    
    // Check if current user is parent or teacher (can assign)
    private var canAssign: Bool {
        guard let role = awsService.currentUserProfile?.userRole else { return false }
        // Parents and teachers can assign, students cannot
        return role == .parent || role == .teacher
    }
    
    init(
        worksheet: Worksheet? = nil,
        child: UserProfile? = nil,
        concepts: [String] = [],
        suggestedDifficulty: PracticeDifficulty = .similar
    ) {
        self.worksheet = worksheet
        self.child = child
        self.concepts = concepts
        self.initialDifficulty = suggestedDifficulty
        _selectedDifficulty = State(initialValue: suggestedDifficulty)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Source Info Card
                    if let ws = worksheet {
                        worksheetInfoCard(ws)
                    } else if !concepts.isEmpty {
                        conceptsInfoCard
                    }
                    
                    // Difficulty Selection
                    difficultySelectionSection
                    
                    // Problem Count Selection
                    problemCountSection
                    
                    // Generate Button
                    generateButtonSection
                    
                    // Generated Problems Preview
                    if !generatedProblems.isEmpty {
                        generatedPreviewSection
                    }
                }
                .padding()
            }
            .navigationTitle("Generate Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await loadWorksheetMetadata()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .fullScreenCover(isPresented: $showingPracticeSession) {
                PracticeSessionView(
                    problems: generatedProblems,
                    child: child
                )
            }
            .sheet(isPresented: $showingAssignPractice) {
                AssignPracticeView(
                    problems: generatedProblems,
                    sourceType: worksheet != nil ? .topic : .recommended,
                    curriculumCodes: worksheetMetadata?.moeCurriculumCodes?.compactMap { $0 } ?? [],
                    curriculumGradeLevel: worksheetMetadata?.detectedGradeLevel ?? child?.gradeLevel,
                    targetConcepts: concepts.isEmpty ? (worksheetMetadata?.topics ?? []) : concepts,
                    targetChild: child,
                    classroom: nil,
                    onAssigned: { assignment in
                        dismiss()
                    }
                )
            }
        }
    }
    
    // MARK: - Worksheet Info Card
    
    private func worksheetInfoCard(_ worksheet: Worksheet) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Based on Worksheet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(worksheet.title)
                        .font(.headline)
                }
                
                Spacer()
                
                Image(systemName: "doc.text.fill")
                    .font(.title)
                    .foregroundColor(.blue.opacity(0.7))
            }
            
            if let metadata = worksheetMetadata {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        MetadataChip(
                            label: "Topics",
                            value: metadata.topics.prefix(2).joined(separator: ", "),
                            icon: "tag.fill"
                        )
                        
                        MetadataChip(
                            label: "Level",
                            value: metadata.difficulty,
                            icon: "chart.bar.fill"
                        )
                    }
                    
                    if let complexity = metadata.complexityLevel {
                        MetadataChip(
                            label: "Complexity",
                            value: complexity,
                            icon: "speedometer"
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
    
    // MARK: - Concepts Info Card
    
    private var conceptsInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Practice Focus")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Concept-Based Practice")
                        .font(.headline)
                }
                
                Spacer()
                
                Image(systemName: "lightbulb.fill")
                    .font(.title)
                    .foregroundColor(.yellow)
            }
            
            FlowLayout(spacing: 8) {
                ForEach(concepts, id: \.self) { concept in
                    Text(concept)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Difficulty Selection
    
    private var difficultySelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.purple)
                Text("Difficulty Level")
                    .font(.headline)
            }
            
            Text("Choose the difficulty that's right for your child")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                ForEach(PracticeDifficulty.allCases) { difficulty in
                    DifficultyCard(
                        difficulty: difficulty,
                        isSelected: selectedDifficulty == difficulty,
                        gradeLevel: worksheetMetadata?.difficulty ?? "Grade 5"
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedDifficulty = difficulty
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Problem Count Selection
    
    private var problemCountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "number.circle.fill")
                    .foregroundColor(.orange)
                Text("Number of Problems")
                    .font(.headline)
            }
            
            HStack(spacing: 12) {
                ForEach(PracticeGenerationConfig.availableCounts, id: \.self) { count in
                    Button(action: { problemCount = count }) {
                        Text("\(count)")
                            .font(.headline)
                            .foregroundColor(problemCount == count ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(problemCount == count ? Color.blue : Color(.secondarySystemBackground))
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Generate Button
    
    private var generateButtonSection: some View {
        VStack(spacing: 16) {
            Button(action: generatePractice) {
                HStack(spacing: 12) {
                    if generationService.isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "sparkles")
                    }
                    
                    Text(generationService.isGenerating ? "Generating..." : "Generate Practice Problems")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: generationService.isGenerating ? [.gray] : [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .disabled(generationService.isGenerating)
            
            if generationService.isGenerating {
                VStack(spacing: 8) {
                    ProgressView(value: generationService.generationProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    
                    Text("Creating personalized problems...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Generated Preview
    
    private var generatedPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Practice Set Generated!")
                    .font(.headline)
                
                Spacer()
                
                Text("\(generatedProblems.count) problems")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Preview")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(Array(generatedProblems.prefix(3).enumerated()), id: \.offset) { index, problem in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1).")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                            .frame(width: 24)
                        
                        Text(cleanLatexForPreview(problem.problemText))
                            .font(.subheadline)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }
                
                if generatedProblems.count > 3 {
                    Text("... and \(generatedProblems.count - 3) more problems")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            
            // Start Practice Button
            Button(action: { showingPracticeSession = true }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Practice Now")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.green)
                .cornerRadius(16)
            }
            
            // Assign Practice Button (for parents/teachers)
            if canAssign, let targetChild = child {
                Button(action: { showingAssignPractice = true }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Assign to \(targetChild.displayName)")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
            }
            
            // Tips
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text("**Tip:** Work through these together first, then let your child try similar problems independently.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.1), Color.mint.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 2)
        )
    }
    
    // MARK: - Actions
    
    private func loadWorksheetMetadata() async {
        guard let ws = worksheet else { return }
        
        do {
            let allMetadata = try await Amplify.DataStore.query(WorksheetMetadata.self)
            worksheetMetadata = allMetadata.first(where: { $0.worksheet?.id == ws.id })
        } catch {
            print("âš ï¸ Failed to load worksheet metadata: \(error)")
        }
    }
    
    private func generatePractice() {
        guard let userId = awsService.currentUserProfile?.userId else {
            errorMessage = "User not found"
            return
        }
        
        Task {
            do {
                if let ws = worksheet {
                    generatedProblems = try await generationService.generateFromWorksheet(
                        worksheet: ws,
                        difficulty: selectedDifficulty,
                        count: problemCount,
                        userId: userId
                    )
                } else if !concepts.isEmpty {
                    generatedProblems = try await generationService.generateForConcepts(
                        concepts: concepts,
                        difficulty: selectedDifficulty,
                        count: problemCount,
                        userId: userId
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func cleanLatexForPreview(_ text: String) -> String {
        // Simple cleanup for preview - remove LaTeX delimiters
        var cleaned = text
        cleaned = cleaned.replacingOccurrences(of: "$", with: "")
        cleaned = cleaned.replacingOccurrences(of: "\\frac{", with: "")
        cleaned = cleaned.replacingOccurrences(of: "}{", with: "/")
        cleaned = cleaned.replacingOccurrences(of: "}", with: "")
        cleaned = cleaned.replacingOccurrences(of: "\\times", with: "Ã—")
        cleaned = cleaned.replacingOccurrences(of: "\\div", with: "Ã·")
        return cleaned
    }
}

// MARK: - Difficulty Card

struct DifficultyCard: View {
    let difficulty: PracticeDifficulty
    let isSelected: Bool
    let gradeLevel: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Text(difficulty.icon)
                    .font(.system(size: 32))
                
                Text(difficulty.displayName)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(difficulty.shortDescription)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(difficulty.adjustedGradeLevel(from: gradeLevel))
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? difficulty.color : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Metadata Chip

struct MetadataChip: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout2: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                     y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + rowHeight
        }
    }
}
