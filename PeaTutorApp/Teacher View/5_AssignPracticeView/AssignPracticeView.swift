//
//  AssignPracticeView.swift
//  PeaTutorApp
//
//  View for configuring and assigning AI-generated practice problems
//  Supports teachers, parents, and students (self-practice)
//

import SwiftUI
import Amplify

struct AssignPracticeView: View {
    // Input: Generated problems
    let problems: [PracticeProblem]
    let sourceType: PracticeAssignment.SourceType
    let curriculumCodes: [String]
    let curriculumGradeLevel: String?
    let targetConcepts: [String]
    
    // For parent/teacher: target student
    let targetChild: UserProfile?
    
    // For teacher: classroom context
    let classroom: Classroom?
    
    // Callbacks
    var onAssigned: ((PracticeAssignment) -> Void)?
    var onStartNow: (([PracticeProblem], PracticeAssignment?) -> Void)?
    
    @StateObject private var awsService = AWSService.shared
    @StateObject private var assignmentService = PracticeAssignmentService.shared
    
    @Environment(\.dismiss) private var dismiss
    
    // Form state
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
    
    // UI state
    @State private var isAssigning = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    // Current user role
    private var currentUserRole: UserRole? {
        awsService.currentUserProfile?.userRole
    }
    
    private var isStudent: Bool {
        currentUserRole == .student
    }
    
    private var isParent: Bool {
        currentUserRole == .parent
    }
    
    private var isTeacher: Bool {
        currentUserRole == .teacher
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Problems Preview Section
                problemsPreviewSection
                
                // Curriculum Context Section
                curriculumContextSection
                
                // Assignment Details Section
                assignmentDetailsSection
                
                // Due Date Section (optional)
                dueDateSection
                
                // Target Section (for teachers/parents)
                if !isStudent {
                    targetSection
                }
                
                // Action Buttons Section
                actionButtonsSection
            }
            .navigationTitle("Assign Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .disabled(isAssigning)
            .overlay {
                if isAssigning {
                    loadingOverlay
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
            .onAppear {
                setupDefaultTitle()
            }
        }
    }
    
    // MARK: - Problems Preview Section
    
    private var problemsPreviewSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                    Text("Generated Practice Problems")
                        .font(.headline)
                    Spacer()
                    Text("\(problems.count) problems")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Preview cards
                VStack(spacing: 8) {
                    ForEach(problems.prefix(3), id: \.id) { problem in
                        ProblemPreviewRow(problem: problem)
                    }
                    
                    if problems.count > 3 {
                        Text("... and \(problems.count - 3) more problems")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                
                // Difficulty info
                if let difficulty = problems.first?.difficultyLevel {
                    HStack {
                        Text("Difficulty:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(difficulty.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(difficultyColor(difficulty).opacity(0.2))
                            .foregroundColor(difficultyColor(difficulty))
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Curriculum Context Section
    
    private var curriculumContextSection: some View {
        Section("Curriculum Alignment") {
            // Source type badge
            HStack {
                Text("Source")
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: sourceTypeIcon)
                        .font(.caption)
                    Text(sourceTypeDisplayName)
                        .font(.subheadline)
                }
                .foregroundColor(sourceTypeColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(sourceTypeColor.opacity(0.15))
                .cornerRadius(8)
            }
            
            // Grade level
            if let grade = curriculumGradeLevel {
                HStack {
                    Text("Grade Level")
                    Spacer()
                    Text(grade)
                        .foregroundColor(.secondary)
                }
            }
            
            // Curriculum codes
            if !curriculumCodes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Curriculum Codes")
                        .font(.subheadline)
                    
                    FlowLayoutAssign(spacing: 6) {
                        ForEach(curriculumCodes, id: \.self) { code in
                            Text(code)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                        }
                    }
                }
            }
            
            // Target concepts
            if !targetConcepts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Concepts")
                        .font(.subheadline)
                    
                    FlowLayoutAssign(spacing: 6) {
                        ForEach(targetConcepts, id: \.self) { concept in
                            Text(concept)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(6)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Assignment Details Section
    
    private var assignmentDetailsSection: some View {
        Section("Assignment Details") {
            TextField("Title", text: $title)
                .font(.headline)
            
            TextField("Instructions (optional)", text: $description, axis: .vertical)
                .lineLimit(2...4)
        }
    }
    
    // MARK: - Due Date Section
    
    private var dueDateSection: some View {
        Section {
            Toggle("Set Due Date", isOn: $hasDueDate.animation())
            
            if hasDueDate {
                DatePicker(
                    "Due Date",
                    selection: $dueDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
        } footer: {
            if !hasDueDate {
                Text("Without a due date, this practice can be completed anytime")
            }
        }
    }
    
    // MARK: - Target Section
    
    private var targetSection: some View {
        Section("Assign To") {
            if isParent, let child = targetChild {
                // Parent assigning to linked child
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(child.initials)
                                .font(.headline)
                                .foregroundColor(.blue)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(child.displayName)
                            .font(.headline)
                        if let grade = child.gradeLevel {
                            Text("Grade \(grade)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            } else if isTeacher {
                // Teacher assigning to classroom
                if let classroom = classroom {
                    HStack(spacing: 12) {
                        Image(systemName: "person.3.fill")
                            .font(.title2)
                            .foregroundColor(.purple)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(classroom.className)
                                .font(.headline)
                            Text("All students in class")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                } else if let child = targetChild {
                    // Teacher assigning to specific student
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(child.initials)
                                    .font(.headline)
                                    .foregroundColor(.purple)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(child.displayName)
                                .font(.headline)
                            Text("Individual assignment")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        Section {
            if isStudent {
                // Student options: Start Now or Save for Later
                Button(action: startPracticeNow) {
                    HStack {
                        Spacer()
                        Image(systemName: "play.fill")
                        Text("Start Practice Now")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .listRowBackground(Color.blue)
                .foregroundColor(.white)
                
                Button(action: saveForLater) {
                    HStack {
                        Spacer()
                        Image(systemName: "bookmark.fill")
                        Text("Save for Later")
                        Spacer()
                    }
                }
            } else {
                // Teacher/Parent: Assign button
                Button(action: assignPractice) {
                    HStack {
                        Spacer()
                        Image(systemName: "paperplane.fill")
                        Text(assignButtonText)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(!canAssign)
                .listRowBackground(canAssign ? Color.blue : Color.gray)
                .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text(isStudent ? "Saving..." : "Assigning...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(30)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
        }
    }
    
    // MARK: - Computed Properties
    
    private var canAssign: Bool {
        !title.isEmpty && !problems.isEmpty
    }
    
    private var assignButtonText: String {
        if isParent, let child = targetChild {
            return "Assign to \(child.displayName)"
        } else if isTeacher, let classroom = classroom {
            return "Assign to \(classroom.className)"
        } else if let child = targetChild {
            return "Assign to \(child.displayName)"
        }
        return "Assign Practice"
    }
    
    private var sourceTypeDisplayName: String {
        switch sourceType {
        case .prerequisiteGap: return "Prerequisite Gap"
        case .recommended: return "Recommended"
        case .weakArea: return "Weak Area"
        case .topic: return "Topic Practice"
        case .selfPractice: return "Self Practice"
        }
    }
    
    private var sourceTypeIcon: String {
        switch sourceType {
        case .prerequisiteGap: return "exclamationmark.triangle.fill"
        case .recommended: return "lightbulb.fill"
        case .weakArea: return "chart.line.downtrend.xyaxis"
        case .topic: return "book.fill"
        case .selfPractice: return "person.fill"
        }
    }
    
    private var sourceTypeColor: Color {
        switch sourceType {
        case .prerequisiteGap: return .orange
        case .recommended: return .yellow
        case .weakArea: return .red
        case .topic: return .blue
        case .selfPractice: return .purple
        }
    }
    
    // MARK: - Actions
    
    private func setupDefaultTitle() {
        if title.isEmpty {
            if !targetConcepts.isEmpty {
                title = "\(targetConcepts.first ?? "Practice") Practice"
            } else if !curriculumCodes.isEmpty {
                title = "\(curriculumCodes.first ?? "Practice") Practice"
            } else {
                title = "\(sourceTypeDisplayName) Practice"
            }
        }
    }
    
    private func startPracticeNow() {
        Task {
            isAssigning = true
            defer { isAssigning = false }
            
            do {
                guard let userId = awsService.currentUserId else {
                    throw PracticeAssignmentError.unauthorized
                }
                
                // Create self-assignment
                let assignment = try await assignmentService.createAssignment(
                    assignedByUserId: userId,
                    assignedByRole: .student,
                    studentId: userId,
                    classroomId: nil,
                    title: title,
                    description: description.isEmpty ? nil : description,
                    dueDate: nil,
                    problems: problems,
                    sourceType: sourceType,
                    curriculumCodes: curriculumCodes.isEmpty ? nil : curriculumCodes,
                    curriculumGradeLevel: curriculumGradeLevel,
                    targetConcepts: targetConcepts.isEmpty ? nil : targetConcepts
                )
                
                // Start the assignment
                let startedAssignment = try await assignmentService.startAssignment(assignment)
                
                dismiss()
                onStartNow?(problems, startedAssignment)
                
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func saveForLater() {
        Task {
            isAssigning = true
            defer { isAssigning = false }
            
            do {
                guard let userId = awsService.currentUserId else {
                    throw PracticeAssignmentError.unauthorized
                }
                
                // Create self-assignment (saved for later)
                let assignment = try await assignmentService.createAssignment(
                    assignedByUserId: userId,
                    assignedByRole: .student,
                    studentId: userId,
                    classroomId: nil,
                    title: title,
                    description: description.isEmpty ? nil : description,
                    dueDate: hasDueDate ? dueDate : nil,
                    problems: problems,
                    sourceType: sourceType,
                    curriculumCodes: curriculumCodes.isEmpty ? nil : curriculumCodes,
                    curriculumGradeLevel: curriculumGradeLevel,
                    targetConcepts: targetConcepts.isEmpty ? nil : targetConcepts
                )
                
                dismiss()
                onAssigned?(assignment)
                
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func assignPractice() {
        Task {
            isAssigning = true
            defer { isAssigning = false }
            
            do {
                guard let assignerId = awsService.currentUserId else {
                    throw PracticeAssignmentError.unauthorized
                }
                
                let role: PracticeAssignment.AssignerRole = isTeacher ? .teacher : .parent
                
                print("📝 assignPractice called:")
                print("   assignerId: \(assignerId)")
                print("   role: \(role)")
                print("   isTeacher: \(isTeacher)")
                print("   classroom: \(classroom?.id ?? "nil")")
                print("   targetChild: \(targetChild?.userId ?? "nil") - \(targetChild?.displayName ?? "nil")")
                print("   problems count: \(problems.count)")
                
                if isTeacher, let classroom = classroom {
                    // Assign to all students in classroom
                    print("   → Creating class assignment for classroom: \(classroom.id)")
                    let assignments = try await assignmentService.createClassAssignments(
                        teacherId: assignerId,
                        classroomId: classroom.id,
                        title: title,
                        description: description.isEmpty ? nil : description,
                        dueDate: hasDueDate ? dueDate : nil,
                        problems: problems,
                        sourceType: sourceType,
                        curriculumCodes: curriculumCodes.isEmpty ? nil : curriculumCodes,
                        curriculumGradeLevel: curriculumGradeLevel,
                        targetConcepts: targetConcepts.isEmpty ? nil : targetConcepts
                    )
                    
                    print("   ✅ Created \(assignments.count) class assignments")
                    dismiss()
                    if let firstAssignment = assignments.first {
                        onAssigned?(firstAssignment)
                    }
                } else if let student = targetChild {
                    // Assign to specific student
                    print("   → Creating individual assignment for student: \(student.userId)")
                    let assignment = try await assignmentService.createAssignment(
                        assignedByUserId: assignerId,
                        assignedByRole: role,
                        studentId: student.userId,
                        classroomId: classroom?.id,
                        title: title,
                        description: description.isEmpty ? nil : description,
                        dueDate: hasDueDate ? dueDate : nil,
                        problems: problems,
                        sourceType: sourceType,
                        curriculumCodes: curriculumCodes.isEmpty ? nil : curriculumCodes,
                        curriculumGradeLevel: curriculumGradeLevel,
                        targetConcepts: targetConcepts.isEmpty ? nil : targetConcepts
                    )
                    
                    print("   ✅ Created assignment: \(assignment.id)")
                    print("      studentId: \(assignment.studentId)")
                    print("      classroomId: \(assignment.classroomId ?? "nil")")
                    dismiss()
                    onAssigned?(assignment)
                } else {
                    print("   ❌ No target student! targetChild is nil and not a teacher with classroom")
                    errorMessage = "No target student selected"
                    showingError = true
                }
                
            } catch {
                print("   ❌ Assignment failed: \(error)")
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "easier", "easy": return .green
        case "similar", "medium": return .orange
        case "harder", "hard": return .red
        default: return .gray
        }
    }
}

// MARK: - Problem Preview Row

struct ProblemPreviewRow: View {
    let problem: PracticeProblem
    
    var body: some View {
        HStack(spacing: 12) {
            // Concept badge
            Text(problem.concept)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .cornerRadius(4)
            
            // Problem text preview
            Text(cleanProblemText(problem.problemText))
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func cleanProblemText(_ text: String) -> String {
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

// MARK: - Flow Layout for Tags

struct FlowLayoutAssign: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResultAssign(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResultAssign(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                     y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResultAssign {
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
