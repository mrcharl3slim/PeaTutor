//
//  CurriculumBrowserView.swift
//  PeaTutorApp
//
//  Sprint 8: Curriculum Standards Integration
//  View for browsing and exploring curriculum standards
//

import SwiftUI
import Amplify

// MARK: - Main Browser View

struct CurriculumBrowserView: View {
    @StateObject private var curriculumService = CurriculumService.shared
    
    @State private var selectedGrade: String = "Primary 1"
    @State private var standards: [CurriculumStandard] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedStrand: String?
    @State private var searchText = ""
    
    private let grades = CurriculumService.supportedGradeLevels
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Grade selector
                gradePicker
                
                // Strand filter
                strandFilterBar
                
                // Content
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else if filteredStandards.isEmpty {
                    emptyView
                } else {
                    standardsList
                }
            }
            .navigationTitle("MOE Syllabus")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search topics...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Seed Curriculum Data") {
                            Task { await seedData() }
                        }
                        Button("Refresh", role: .none) {
                            Task { await loadStandards(forceRefresh: true) }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .task {
            await loadStandards()
        }
        .onChange(of: selectedGrade) { _, _ in
            Task { await loadStandards() }
        }
    }
    
    // MARK: - Subviews
    
    private var gradePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(grades, id: \.self) { grade in
                    Button {
                        selectedGrade = grade
                    } label: {
                        Text(grade.replacingOccurrences(of: "Primary ", with: "P"))
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedGrade == grade ? Color.blue : Color(.systemGray5))
                            .foregroundColor(selectedGrade == grade ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
    
    private var strandFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All strands option
                Button {
                    selectedStrand = nil
                } label: {
                    Label("All", systemImage: "square.grid.2x2")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedStrand == nil ? Color.blue.opacity(0.15) : Color(.systemGray6))
                        .foregroundColor(selectedStrand == nil ? .blue : .secondary)
                        .cornerRadius(16)
                }
                
                // Strand buttons
                ForEach(uniqueStrands, id: \.self) { strand in
                    Button {
                        selectedStrand = strand
                    } label: {
                        HStack(spacing: 4) {
                            Text(strandEmoji(for: strand))
                            Text(strandShortName(strand))
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedStrand == strand ? strandColor(for: strand).opacity(0.15) : Color(.systemGray6))
                        .foregroundColor(selectedStrand == strand ? strandColor(for: strand) : .secondary)
                        .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.secondarySystemBackground))
    }
    
    private var standardsList: some View {
        List {
            ForEach(groupedByTopic, id: \.0) { topicCode, topicStandards in
                Section {
                    ForEach(topicStandards, id: \.id) { standard in
                        CurriculumStandardRow(standard: standard)
                    }
                } header: {
                    if let first = topicStandards.first {
                        HStack {
                            Text(strandEmoji(for: first.strand))
                            Text(first.topicTitle)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(first.subStrand)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading curriculum...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text(error)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task { await loadStandards(forceRefresh: true) }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No curriculum data found")
                .foregroundColor(.secondary)
            Text("Tap the menu to seed curriculum data")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var uniqueStrands: [String] {
        Array(Set(standards.map { $0.strand })).sorted()
    }
    
    private var filteredStandards: [CurriculumStandard] {
        var result = standards
        
        // Filter by strand
        if let strand = selectedStrand {
            result = result.filter { $0.strand == strand }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            result = result.filter { standard in
                let query = searchText.lowercased()
                return standard.topicTitle.lowercased().contains(query) ||
                       standard.subTopicDescription.lowercased().contains(query) ||
                       standard.curriculumCode.lowercased().contains(query) ||
                       standard.keywords.contains { $0.lowercased().contains(query) }
            }
        }
        
        return result.sortedBySequence()
    }
    
    private var groupedByTopic: [(String, [CurriculumStandard])] {
        let grouped = Dictionary(grouping: filteredStandards) { $0.topicTitle }
        return grouped.sorted { $0.value.first?.sequenceOrder ?? 0 < $1.value.first?.sequenceOrder ?? 0 }
    }
    
    // MARK: - Helper Functions
    
    private func strandEmoji(for strand: String) -> String {
        switch strand {
        case "Number and Algebra": return "🔢"
        case "Measurement and Geometry": return "📐"
        case "Statistics": return "📊"
        default: return "📚"
        }
    }
    
    private func strandShortName(_ strand: String) -> String {
        switch strand {
        case "Number and Algebra": return "Number"
        case "Measurement and Geometry": return "Geometry"
        case "Statistics": return "Stats"
        default: return strand
        }
    }
    
    private func strandColor(for strand: String) -> Color {
        switch strand {
        case "Number and Algebra": return .blue
        case "Measurement and Geometry": return .green
        case "Statistics": return .purple
        default: return .gray
        }
    }
    
    // MARK: - Data Loading
    
    private func loadStandards(forceRefresh: Bool = false) async {
        isLoading = true
        errorMessage = nil
        
        do {
            standards = try await curriculumService.fetchStandards(forGrade: selectedGrade)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func seedData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await curriculumService.seedFromBundledJSON()
            await loadStandards(forceRefresh: true)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Standard Row View

struct CurriculumStandardRow: View {
    let standard: CurriculumStandard
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main content
            HStack(alignment: .top) {
                Text(standard.subTopicCode)
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)
                    .frame(width: 32, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(standard.subTopicDescription)
                        .font(.subheadline)
                    
                    // Bullet points if present
                    if !standard.bulletPointsClean.isEmpty {
                        ForEach(standard.bulletPointsClean, id: \.self) { point in
                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text(point)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Expand button for details
                Button {
                    withAnimation { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    // Curriculum code
                    HStack {
                        Label("Code", systemImage: "number")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(standard.curriculumCode)
                            .font(.caption.monospaced())
                            .foregroundColor(.blue)
                    }
                    
                    // Keywords
                    if !standard.keywords.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Keywords", systemImage: "tag")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            FlowLayout3(spacing: 4) {
                                ForEach(standard.keywords, id: \.self) { keyword in
                                    Text(keyword)
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    // Prerequisites
                    let prereqs = standard.prerequisiteCodesClean
                    if !prereqs.isEmpty {
                        HStack(alignment: .top) {
                            Label("Prerequisites", systemImage: "arrow.up.left")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                ForEach(prereqs, id: \.self) { code in
                                    Text(code)
                                        .font(.caption2.monospaced())
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                    
                    // Notes
                    if let notes = standard.notes {
                        HStack(alignment: .top) {
                            Label("Note", systemImage: "info.circle")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Flow Layout for Keywords

struct FlowLayout3: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + lineHeight
        }
    }
}
