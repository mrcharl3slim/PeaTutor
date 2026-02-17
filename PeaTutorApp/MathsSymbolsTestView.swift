//
//  MathsSymbolsTestView.swift
//  PeaTutorApp
//
//  Created by Charles on 27/9/25.
//

import SwiftUI

// MARK: - Test View for Math Symbol Rendering
struct MathSymbolsTestView: View {
    let integrationExamples = [
        "\\int x^2 dx",
        "\\int_{0}^{1} x^2 dx",
        "\\iint_{D} f(x,y) \\,dx\\,dy",
        "\\iiint_{V} f(x,y,z) \\,dx\\,dy\\,dz",
        "\\oint_{C} \\mathbf{F} \\cdot d\\mathbf{r}",
        "\\int_{-\\infty}^{\\infty} e^{-x^2} dx = \\sqrt{\\pi}",
        "\\frac{d}{dx}\\int_{a}^{x} f(t) dt = f(x)",
        "\\int \\frac{1}{x} dx = \\ln|x| + C",
        "\\int_{0}^{\\pi} \\sin(x) dx = 2",
        "\\lim_{n \\to \\infty} \\sum_{i=1}^{n} \\frac{1}{n} f\\left(\\frac{i}{n}\\right) = \\int_{0}^{1} f(x) dx"
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section("Integration Symbols Test") {
                    ForEach(integrationExamples.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("LaTeX: \(integrationExamples[index])")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                            
                            SimpleLaTeXText(integrationExamples[index], fontSize: 16)
                                .padding(.leading, 4)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Common Math Symbols") {
                    Group {
                        mathSymbolRow("Greek Letters", "\\alpha \\beta \\gamma \\delta \\theta \\pi \\sigma \\omega")
                        mathSymbolRow("Relations", "\\leq \\geq \\neq \\approx \\equiv \\propto")
                        mathSymbolRow("Operators", "\\pm \\times \\div \\cdot \\ast \\circ")
                        mathSymbolRow("Arrows", "\\rightarrow \\Rightarrow \\leftrightarrow \\mapsto")
                        mathSymbolRow("Set Theory", "\\in \\subset \\cap \\cup \\emptyset")
                        mathSymbolRow("Logic", "\\land \\lor \\neg \\exists \\forall")
                        mathSymbolRow("Calculus", "\\partial \\nabla \\infty \\sum \\prod")
                    }
                }
            }
            .navigationTitle("Math Symbols Test")
        }
    }
    
    private func mathSymbolRow(_ title: String, _ latex: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("LaTeX: \(latex)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
            
            SimpleLaTeXText(latex, fontSize: 16)
                .padding(.leading, 4)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Usage Instructions
/*
To test the math rendering, add this to your ContentView temporarily:

1. Add this button to ContentView:
```swift
NavigationLink {
    MathSymbolsTestView()
} label: {
    Label("Test Math Symbols", systemImage: "function")
}
```

2. Or present it as a sheet:
```swift
.sheet(isPresented: $showingMathTest) {
    MathSymbolsTestView()
}
```
*/

// MARK: - Preview
struct MathSymbolsTestView_Previews: PreviewProvider {
    static var previews: some View {
        MathSymbolsTestView()
    }
}
