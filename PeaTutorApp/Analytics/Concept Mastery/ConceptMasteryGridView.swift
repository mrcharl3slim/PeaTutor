//
//  ConceptMasteryGridView.swift
//  PeaTutorApp
//
//  Sprint 7.2 - Phase 2: Concept Mastery Grid with expandable rows
//

import SwiftUI

struct ConceptMasteryGridView: View {
    let concepts: [ConceptMastery]
    let studentId: String
    let classroomId: String?
    
    @State private var expandedConceptId: String?
    @State private var sortOption: SortOption = .mastery
    @State private var showSortOptions = false
    
    enum SortOption: String, CaseIterable {
        case mastery = "Mastery %"
        case alphabetical = "A-Z"
        case recent = "Recent"
        case needsWork = "Needs Work"
        
        var icon: String {
            switch self {
            case .mastery:
                return "chart.bar.fill"
            case .alphabetical:
                return "textformat"
            case .recent:
                return "clock.fill"
            case .needsWork:
                return "exclamationmark.triangle.fill"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            header
            
            // Summary Cards
            if !concepts.isEmpty {
                summaryCards
            }
            
            // Concepts List
            if concepts.isEmpty {
                emptyState
            } else {
                conceptsList
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Concept Mastery")
                    .font(.title3.bold())
                
                Text("\(concepts.count) concept\(concepts.count == 1 ? "" : "s") tracked")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Sort Button
            Menu {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            sortOption = option
                        }
                    }) {
                        Label(option.rawValue, systemImage: option.icon)
                        if sortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: sortOption.icon)
                    Text(sortOption.rawValue)
                        .font(.subheadline)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Summary Cards
    
    private var summaryCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                SummaryCard(
                    title: "Mastered",
                    count: masteredCount,
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                SummaryCard(
                    title: "Developing",
                    count: developingCount,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange
                )
                
                SummaryCard(
                    title: "Emerging",
                    count: emergingCount,
                    icon: "arrow.up.circle",
                    color: Color(red: 1.0, green: 0.6, blue: 0.0)
                )
                
                SummaryCard(
                    title: "Needs Work",
                    count: needsWorkCount,
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
            }
        }
    }
    
    // MARK: - Concepts List
    
    private var conceptsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(sortedConcepts, id: \.id) { concept in
                ConceptMasteryRow(
                    concept: concept,
                    isExpanded: Binding(
                        get: { expandedConceptId == concept.id },
                        set: { isExpanded in
                            expandedConceptId = isExpanded ? concept.id : nil
                        }
                    )
                )
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        ContentUnavailableView(
            "No Concepts Tracked Yet",
            systemImage: "chart.bar",
            description: Text("Complete homework assignments to start tracking concept mastery")
        )
        .frame(height: 300)
    }
    
    // MARK: - Computed Properties
    
    private var sortedConcepts: [ConceptMastery] {
        switch sortOption {
        case .mastery:
            return concepts.sorted { $0.masteryPercentage > $1.masteryPercentage }
        case .alphabetical:
            return concepts.sorted { $0.concept < $1.concept }
        case .recent:
            return concepts.sorted { concept1, concept2 in
                guard let date1 = concept1.lastPracticed,
                      let date2 = concept2.lastPracticed else {
                    return concept1.lastPracticed != nil
                }
                return date1.foundationDate > date2.foundationDate
            }
        case .needsWork:
            return concepts.sorted { $0.masteryPercentage < $1.masteryPercentage }
        }
    }
    
    private var masteredCount: Int {
        concepts.filter { $0.masteryLevel == .mastered }.count
    }
    
    private var developingCount: Int {
        concepts.filter { $0.masteryLevel == .developing }.count
    }
    
    private var emergingCount: Int {
        concepts.filter { $0.masteryLevel == .emerging }.count
    }
    
    private var needsWorkCount: Int {
        concepts.filter { $0.masteryLevel == .needsWork }.count
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("\(count)")
                .font(.title2.bold())
                .foregroundColor(color)
        }
        .frame(width: 100)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

