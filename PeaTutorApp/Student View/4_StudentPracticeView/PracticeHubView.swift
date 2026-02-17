//
//  PracticeHubView.swift
//  PeaTutorApp
//
//  Sprint 7.4: AI-Powered Practice Generation
//  Parent hub for managing practice across multiple children
//

import SwiftUI
import Amplify

struct PracticeHubView: View {
    let children: [UserProfile]
    
    @StateObject private var queryService = AnalyticsQueryService.shared
    @State private var selectedChild: UserProfile?
    @State private var childWeakAreas: [String: [ConceptMastery]] = [:]
    @State private var isLoading = false
    @State private var showingPracticeGeneration = false
    @State private var selectedConcepts: [String] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Child Selector (if multiple children)
                    if children.count > 1 {
                        childSelector
                    }
                    
                    // Quick Practice Options
                    if let child = effectiveSelectedChild {
                        quickPracticeSection(for: child)
                        
                        // Weak Areas Practice
                        if let weakAreas = childWeakAreas[child.userId], !weakAreas.isEmpty {
                            weakAreasSection(child: child, weakAreas: weakAreas)
                        }
                        
                        // Recent Practice History
                        recentPracticeSection(for: child)
                    }
                }
                .padding()
            }
            .navigationTitle("Practice Hub")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
            .sheet(isPresented: $showingPracticeGeneration) {
                if let child = effectiveSelectedChild {
                    PracticeGenerationView(
                        child: child,
                        concepts: selectedConcepts,
                        suggestedDifficulty: .similar
                    )
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var effectiveSelectedChild: UserProfile? {
        selectedChild ?? children.first
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading) {
                    Text("AI Practice Generator")
                        .font(.title2.bold())
                    
                    Text("Create personalized practice for your children")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                colors: [.purple.opacity(0.1), .blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    // MARK: - Child Selector
    
    private var childSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Child")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(children, id: \.userId) { child in
                        ChildSelectorCard(
                            child: child,
                            isSelected: selectedChild?.userId == child.userId || (selectedChild == nil && child.userId == children.first?.userId)
                        ) {
                            selectedChild = child
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Practice Section
    
    private func quickPracticeSection(for child: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Practice")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Practice Weak Areas
                QuickPracticeCard(
                    title: "Weak Areas",
                    description: "Target struggling concepts",
                    icon: "target",
                    color: .orange
                ) {
                    let concepts = childWeakAreas[child.userId]?.map { $0.concept } ?? []
                    selectedConcepts = concepts
                    showingPracticeGeneration = true
                }
                
                // Mixed Practice
                QuickPracticeCard(
                    title: "Mixed Practice",
                    description: "All concepts combined",
                    icon: "shuffle",
                    color: .blue
                ) {
                    selectedConcepts = []
                    showingPracticeGeneration = true
                }
                
                // Custom Practice
                NavigationLink(destination: ConceptPracticeGeneratorView(child: child)) {
                    QuickPracticeCardContent(
                        title: "By Concept",
                        description: "Choose specific topics",
                        icon: "list.bullet",
                        color: .green
                    )
                }
                
                // Challenge Mode
                QuickPracticeCard(
                    title: "Challenge",
                    description: "Harder problems",
                    icon: "flame.fill",
                    color: .red
                ) {
                    selectedConcepts = []
                    showingPracticeGeneration = true
                }
            }
        }
    }
    
    // MARK: - Weak Areas Section
    
    private func weakAreasSection(child: UserProfile, weakAreas: [ConceptMastery]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Needs Practice")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    selectedConcepts = weakAreas.map { $0.concept }
                    showingPracticeGeneration = true
                }) {
                    Text("Practice All")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .cornerRadius(8)
                }
            }
            
            ForEach(weakAreas.prefix(3), id: \.id) { mastery in
                WeakAreaRow(mastery: mastery) {
                    selectedConcepts = [mastery.concept]
                    showingPracticeGeneration = true
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Recent Practice Section
    
    private func recentPracticeSection(for child: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Practice")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: PracticeHistoryView(child: child)) {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // Placeholder for recent practice
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text("Practice history will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Load Data
    
    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        for child in children {
            do {
                let mastery = try await queryService.fetchConceptMastery(
                    studentId: child.userId,
                    classroomId: nil
                )
                
                // Filter to weak areas (< 60%)
                let weak = mastery.filter { $0.masteryPercentage < 60 }
                    .sorted { $0.masteryPercentage < $1.masteryPercentage }
                
                childWeakAreas[child.userId] = Array(weak)
            } catch {
                print("⚠️ Failed to load mastery for \(child.displayName): \(error)")
            }
        }
    }
}

// MARK: - Supporting Views

struct ChildSelectorCard: View {
    let child: UserProfile
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(child.initials)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    )
                
                Text(child.displayName)
                    .font(.subheadline.bold())
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickPracticeCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            QuickPracticeCardContent(
                title: title,
                description: description,
                icon: icon,
                color: color
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickPracticeCardContent: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
}

struct WeakAreaRow: View {
    let mastery: ConceptMastery
    let onPractice: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Progress Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                    .frame(width: 36, height: 36)
                
                Circle()
                    .trim(from: 0, to: mastery.masteryPercentage / 100)
                    .stroke(masteryColor, lineWidth: 3)
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(mastery.masteryPercentage))%")
                    .font(.caption2.bold())
                    .foregroundColor(masteryColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(mastery.concept)
                    .font(.subheadline.bold())
                
                Text("\(mastery.totalAttempts) attempts")
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
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var masteryColor: Color {
        if mastery.masteryPercentage >= 60 { return .yellow }
        if mastery.masteryPercentage >= 40 { return .orange }
        return .red
    }
}

// MARK: - Placeholder Views

struct ConceptPracticeGeneratorView: View {
    let child: UserProfile
    
    @StateObject private var queryService = AnalyticsQueryService.shared
    @State private var allConcepts: [ConceptMastery] = []
    @State private var selectedConcepts: Set<String> = []
    @State private var selectedDifficulty: PracticeDifficulty = .similar
    @State private var isLoading = false
    @State private var showingGeneration = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Concepts to Practice")
                        .font(.headline)
                    
                    Text("Choose one or more concepts, then select difficulty level")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Concept List
                if isLoading {
                    ProgressView()
                } else if allConcepts.isEmpty {
                    ContentUnavailableView(
                        "No Concepts Found",
                        systemImage: "book.closed",
                        description: Text("Complete some worksheets to see concepts")
                    )
                } else {
                    VStack(spacing: 8) {
                        ForEach(allConcepts, id: \.id) { mastery in
                            ConceptSelectionRow(
                                mastery: mastery,
                                isSelected: selectedConcepts.contains(mastery.concept)
                            ) {
                                if selectedConcepts.contains(mastery.concept) {
                                    selectedConcepts.remove(mastery.concept)
                                } else {
                                    selectedConcepts.insert(mastery.concept)
                                }
                            }
                        }
                    }
                }
                
                // Difficulty Selection
                if !selectedConcepts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Difficulty")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            ForEach(PracticeDifficulty.allCases) { difficulty in
                                Button(action: { selectedDifficulty = difficulty }) {
                                    Text(difficulty.displayName)
                                        .font(.subheadline.bold())
                                        .foregroundColor(selectedDifficulty == difficulty ? .white : .primary)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(
                                            Capsule()
                                                .fill(selectedDifficulty == difficulty ? difficulty.color : Color(.secondarySystemBackground))
                                        )
                                }
                            }
                        }
                    }
                    
                    // Generate Button
                    Button(action: { showingGeneration = true }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Generate Practice")
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("By Concept")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadConcepts()
        }
        .sheet(isPresented: $showingGeneration) {
            PracticeGenerationView(
                child: child,
                concepts: Array(selectedConcepts),
                suggestedDifficulty: selectedDifficulty
            )
        }
    }
    
    private func loadConcepts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            allConcepts = try await queryService.fetchConceptMastery(
                studentId: child.userId,
                classroomId: nil
            )
        } catch {
            print("⚠️ Failed to load concepts: \(error)")
        }
    }
}

struct ConceptSelectionRow: View {
    let mastery: ConceptMastery
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(mastery.concept)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    Text("\(Int(mastery.masteryPercentage))% mastery")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Mastery indicator
                Circle()
                    .fill(masteryColor)
                    .frame(width: 10, height: 10)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var masteryColor: Color {
        if mastery.masteryPercentage >= 80 { return .green }
        if mastery.masteryPercentage >= 60 { return .yellow }
        return .red
    }
}

struct PracticeHistoryView: View {
    let child: UserProfile
    
    var body: some View {
        VStack {
            ContentUnavailableView(
                "Coming Soon",
                systemImage: "clock.arrow.circlepath",
                description: Text("Practice history will be available here")
            )
        }
        .navigationTitle("Practice History")
    }
}
