//
//  ErrorPatternsListView.swift
//  PeaTutorApp
//
//  Sprint 7.2 Phase 4: Error Patterns List View
//  Comprehensive error pattern tracking and visualization for teacher analytics
//

import SwiftUI
import Amplify

// MARK: - Main Error Patterns List View

struct ErrorPatternsListView: View {
    let errors: [ErrorPattern]
    let studentId: String
    let classroomId: String?
    
    @State private var expandedErrorId: String?
    @State private var filterSeverity: ErrorSeverity?
    @State private var sortOption: SortOption = .severity
    @State private var showResolvedErrors = false
    
    enum SortOption: String, CaseIterable {
        case severity = "Severity"
        case frequency = "Frequency"
        case recent = "Most Recent"
        
        var icon: String {
            switch self {
            case .severity: return "exclamationmark.triangle.fill"
            case .frequency: return "arrow.up.arrow.down"
            case .recent: return "clock.fill"
            }
        }
    }
    
    var filteredAndSortedErrors: [ErrorPattern] {
        var filtered = errors
        
        // Filter by resolved status
        if !showResolvedErrors {
            filtered = filtered.filter { $0.isActive }
        }
        
        // Filter by severity
        if let severity = filterSeverity {
            filtered = filtered.filter { $0.severityLevel == severity }
        }
        
        // Sort
        switch sortOption {
        case .severity:
            filtered.sort { error1, error2 in
                if error1.severityLevel.priority != error2.severityLevel.priority {
                    return error1.severityLevel.priority > error2.severityLevel.priority
                }
                return error1.occurrenceCount > error2.occurrenceCount
            }
        case .frequency:
            filtered.sort { $0.occurrenceCount > $1.occurrenceCount }
        case .recent:
            filtered.sort { $0.lastSeen.foundationDate > $1.lastSeen.foundationDate }
        }
        
        return filtered
    }
    
    var severityCounts: (high: Int, medium: Int, low: Int) {
        let high = errors.filter { $0.severityLevel == .high && $0.isActive }.count
        let medium = errors.filter { $0.severityLevel == .medium && $0.isActive }.count
        let low = errors.filter { $0.severityLevel == .low && $0.isActive }.count
        return (high, medium, low)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with counts
            headerSection
            
            // Filters and sorting
            if !errors.isEmpty {
                filtersSection
            }
            
            // Error list or empty state
            if filteredAndSortedErrors.isEmpty {
                if errors.isEmpty {
                    emptyState
                } else {
                    noResultsState
                }
            } else {
                errorsList
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Error Patterns")
                .font(.title3.bold())
            
            if !errors.isEmpty {
                HStack(spacing: 12) {
                    // High severity count
                    SeverityCountBadge(
                        count: severityCounts.high,
                        severity: .high,
                        isSelected: filterSeverity == .high
                    ) {
                        withAnimation {
                            filterSeverity = filterSeverity == .high ? nil : .high
                        }
                    }
                    
                    // Medium severity count
                    SeverityCountBadge(
                        count: severityCounts.medium,
                        severity: .medium,
                        isSelected: filterSeverity == .medium
                    ) {
                        withAnimation {
                            filterSeverity = filterSeverity == .medium ? nil : .medium
                        }
                    }
                    
                    // Low severity count
                    SeverityCountBadge(
                        count: severityCounts.low,
                        severity: .low,
                        isSelected: filterSeverity == .low
                    ) {
                        withAnimation {
                            filterSeverity = filterSeverity == .low ? nil : .low
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Filters Section
    
    private var filtersSection: some View {
        VStack(spacing: 12) {
            // Sort options
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        SortButton(
                            option: option,
                            isSelected: sortOption == option
                        ) {
                            withAnimation {
                                sortOption = option
                            }
                        }
                    }
                }
            }
            
            // Show resolved toggle
            Toggle(isOn: $showResolvedErrors) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text("Show resolved errors")
                        .font(.subheadline)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Errors List
    
    private var errorsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredAndSortedErrors, id: \.id) { error in
                ErrorPatternCard(
                    error: error,
                    isExpanded: expandedErrorId == error.id
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        expandedErrorId = expandedErrorId == error.id ? nil : error.id
                    }
                }
            }
        }
    }
    
    // MARK: - Empty States
    
    private var emptyState: some View {
        ContentUnavailableView(
            "No Error Patterns Detected",
            systemImage: "checkmark.circle.fill",
            description: Text("Great work! No recurring error patterns found.\nKeep up the excellent progress!")
        )
        .foregroundColor(.green)
        .frame(height: 300)
    }
    
    private var noResultsState: some View {
        ContentUnavailableView(
            "No Matching Errors",
            systemImage: "line.3.horizontal.decrease.circle",
            description: Text("Try adjusting your filters to see more results")
        )
        .frame(height: 200)
    }
}

// MARK: - Error Pattern Card

struct ErrorPatternCard: View {
    let error: ErrorPattern
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main card content
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 12) {
                    // Header row
                    HStack(alignment: .top, spacing: 12) {
                        // Error icon
                        Image(systemName: errorIcon)
                            .font(.title2)
                            .foregroundColor(severityColor)
                            .frame(width: 40)
                        
                        // Error info
                        VStack(alignment: .leading, spacing: 6) {
                            Text(error.errorType)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(error.errorCategory)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Expand icon
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                    }
                    
                    // Severity and count badges
                    HStack(spacing: 8) {
                        SeverityBadge(severity: error.severityLevel)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "repeat")
                                .font(.caption2)
                            Text(error.occurrenceCountFormatted)
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(6)
                        
                        if error.isResolved {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                Text("Resolved")
                                    .font(.caption)
                            }
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(6)
                        }
                        
                        Spacer()
                        
                        Text(error.lastSeenFormatted)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded details
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(severityColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Expanded Content
    
    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 16) {
                // Description
                DetailSection(
                    icon: "text.alignleft",
                    title: "Description",
                    iconColor: .blue
                ) {
                    Text(error.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Root cause if available
                if let rootCause = error.rootCause, !rootCause.isEmpty {
                    DetailSection(
                        icon: "lightbulb.fill",
                        title: "Root Cause",
                        iconColor: .orange
                    ) {
                        Text(rootCause)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Remediation if available
                if let remediation = error.remediation, !remediation.isEmpty {
                    DetailSection(
                        icon: "heart.text.square.fill",
                        title: "Recommended Intervention",
                        iconColor: .green
                    ) {
                        Text(remediation)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Affected concepts
                if !error.affectedConcepts.isEmpty {
                    DetailSection(
                        icon: "tag.fill",
                        title: "Affected Concepts",
                        iconColor: .purple
                    ) {
                        FlowLayout1(spacing: 8) {
                            ForEach(error.affectedConcepts, id: \.self) { concept in
                                Text(concept)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemPurple).opacity(0.1))
                                    .foregroundColor(.purple)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // Timeline
                TimelineSection(error: error)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    // MARK: - Helper Properties
    
    private var errorIcon: String {
        switch error.errorCategory.lowercased() {
        case "computation":
            return "plus.slash.minus"
        case "fractions":
            return "divide"
        case "decimals":
            return "point.3.connected.trianglepath.dotted"
        case "algebra":
            return "x.squareroot"
        case "geometry":
            return "triangle"
        case "word problems":
            return "text.book.closed"
        case "measurement":
            return "ruler"
        default:
            return "exclamationmark.triangle"
        }
    }
    
    private var severityColor: Color {
        switch error.severityLevel {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .blue
        }
    }
}

// MARK: - Detail Section

struct DetailSection<Content: View>: View {
    let icon: String
    let title: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.subheadline.bold())
            }
            
            content()
        }
    }
}

// MARK: - Timeline Section

struct TimelineSection: View {
    let error: ErrorPattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("Timeline")
                    .font(.subheadline.bold())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                TimelineItem(
                    icon: "calendar.badge.plus",
                    text: "First detected",
                    date: error.firstSeen.foundationDate
                )
                
                TimelineItem(
                    icon: "calendar",
                    text: "Last seen",
                    date: error.lastSeen.foundationDate
                )
                
                if let resolvedAt = error.resolvedAt {
                    TimelineItem(
                        icon: "checkmark.circle.fill",
                        text: "Resolved",
                        date: resolvedAt.foundationDate,
                        color: .green
                    )
                }
            }
        }
    }
}

struct TimelineItem: View {
    let icon: String
    let text: String
    let date: Date
    var color: Color = .secondary
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(dateFormatter.string(from: date))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Severity Badge

struct SeverityBadge: View {
    let severity: ErrorSeverity
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: severity.icon)
                .font(.caption2)
            Text(severity.displayName)
                .font(.caption)
        }
        .foregroundColor(textColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .cornerRadius(6)
    }
    
    private var textColor: Color {
        switch severity {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .blue
        }
    }
    
    private var backgroundColor: Color {
        switch severity {
        case .high:
            return Color.red.opacity(0.1)
        case .medium:
            return Color.orange.opacity(0.1)
        case .low:
            return Color.blue.opacity(0.1)
        }
    }
}

// MARK: - Severity Count Badge

struct SeverityCountBadge: View {
    let count: Int
    let severity: ErrorSeverity
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: severity.icon)
                        .font(.caption)
                    Text("\(count)")
                        .font(.headline)
                }
                
                Text(severity.rawValue.capitalized)
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .white : textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? activeColor : backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(activeColor, lineWidth: isSelected ? 2 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var textColor: Color {
        switch severity {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .blue
        }
    }
    
    private var activeColor: Color {
        switch severity {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .blue
        }
    }
    
    private var backgroundColor: Color {
        switch severity {
        case .high:
            return Color.red.opacity(0.1)
        case .medium:
            return Color.orange.opacity(0.1)
        case .low:
            return Color.blue.opacity(0.1)
        }
    }
}

// MARK: - Sort Button

struct SortButton: View {
    let option: ErrorPatternsListView.SortOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: option.icon)
                    .font(.caption)
                Text(option.rawValue)
                    .font(.subheadline)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout1: Layout {
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
            subview.place(at: result.positions[index], proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var positions: [CGPoint] = []
        var size: CGSize = .zero
        
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
            }
            
            self.size = CGSize(
                width: maxWidth,
                height: y + lineHeight
            )
        }
    }
}
