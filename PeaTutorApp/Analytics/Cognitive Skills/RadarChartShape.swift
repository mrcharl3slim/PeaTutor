//
//  RadarChartShape.swift
//  PeaTutorApp
//
//  Sprint 7.2 - Phase 3: Custom radar/spider chart shape
//

import SwiftUI
import Darwin

/// Custom Shape that draws a radar/spider chart
struct RadarChartShape: Shape {
    let values: [Double] // 0-100 for each axis
    let maxValue: Double = 100.0
    
    func path(in rect: CGRect) -> Path {
        guard values.count >= 3 else { return Path() }
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * 0.85 // Leave margin
        let angleStep = (2 * .pi) / Double(values.count)
        
        var path = Path()
        
        // Draw the filled polygon
        for (index, value) in values.enumerated() {
            let angle = CGFloat(angleStep * Double(index) - .pi / 2) // Start from top
            let normalizedValue = CGFloat(value / maxValue)
            let distance = radius * normalizedValue
            
            let point = CGPoint(
                x: center.x + distance * CoreGraphics.cos(angle),
                y: center.y + distance * CoreGraphics.sin(angle)
            )
            
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        path.closeSubpath()
        
        return path
    }
}

/// Grid lines for the radar chart background
struct RadarGridShape: Shape {
    let numberOfAxes: Int
    let numberOfLevels: Int
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * 0.85
        let angleStep = (2 * .pi) / Double(numberOfAxes)
        
        var path = Path()
        
        // Draw concentric polygons (grid levels)
        for level in 1...numberOfLevels {
            let levelRadius = CGFloat(radius * (Double(level) / Double(numberOfLevels)))
            
            for index in 0..<numberOfAxes {
                let angle = CGFloat(angleStep * Double(index) - .pi / 2)
                let point = CGPoint(
                    x: center.x + levelRadius * CoreGraphics.cos(angle),
                    y: center.y + levelRadius * CoreGraphics.sin(angle)
                )
                
                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
        }
        
        // Draw axis lines
        for index in 0..<numberOfAxes {
            let angle = CGFloat(angleStep * Double(index) - .pi / 2)
            let endPoint = CGPoint(
                x: center.x + radius * CoreGraphics.cos(angle),
                y: center.y + radius * CoreGraphics.sin(angle)
            )
            
            path.move(to: center)
            path.addLine(to: endPoint)
        }
        
        return path
    }
}
