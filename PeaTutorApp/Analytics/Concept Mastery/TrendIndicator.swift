//
//  TrendIndicator.swift
//  PeaTutorApp
//
//  Sprint 7.2 - Phase 2: Trend indicator for concept mastery
//

import SwiftUI

struct TrendIndicator: View {
    let trend: TrendDirection
    let showLabel: Bool
    let size: CGFloat
    
    init(
        trend: TrendDirection,
        showLabel: Bool = false,
        size: CGFloat = 16
    ) {
        self.trend = trend
        self.showLabel = showLabel
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trend.icon)
                .font(.system(size: size, weight: .semibold))
                .foregroundColor(trend.color1)
            
            if showLabel {
                Text(trend.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(trend.color1)
            }
        }
    }
}

// MARK: - TrendDirection Color Extension

extension TrendDirection {
    var color1: Color {
        switch self {
        case .up:
            return .green
        case .stable:
            return .gray
        case .down:
            return .red
        }
    }
}

