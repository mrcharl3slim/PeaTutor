//
//  LatexRenderer.swift
//  PeaTutorApp
//
//  Created by Charles on 27/9/25.
//

import SwiftUI
import Foundation

// MARK: - Enhanced LaTeX to Unicode Text Converter
struct SimpleLaTeXText: View {
    let text: String
    let fontSize: CGFloat
    
    init(_ text: String, fontSize: CGFloat = 16) {
        self.text = text
        self.fontSize = fontSize
    }
    
    var body: some View {
        Text(processLaTeX(text))
            .font(.system(size: fontSize))
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private func processLaTeX(_ input: String) -> String {
        var result = input
        
        // Remove LaTeX delimiters
        result = result.replacingOccurrences(of: "$$", with: "")
        result = result.replacingOccurrences(of: "$", with: "")
        result = result.replacingOccurrences(of: "\\[", with: "")
        result = result.replacingOccurrences(of: "\\]", with: "")
        result = result.replacingOccurrences(of: "\\(", with: "")
        result = result.replacingOccurrences(of: "\\)", with: "")
        
        // Process complex patterns first (order matters!)
        result = processIntegrationBounds(result)
        result = processFractions(result)
        result = processLimits(result)
        
        // Convert common LaTeX commands to Unicode
        let conversions: [(String, String)] = [
            // INTEGRATION SYMBOLS (Enhanced)
            ("\\\\iiint", "∭"),      // Triple integral
            ("\\\\iint", "∬"),       // Double integral
            ("\\\\oint", "∮"),       // Contour integral
            ("\\\\oiint", "∯"),      // Surface integral
            ("\\\\oiiint", "∰"),     // Volume integral
            ("\\\\int", "∫"),        // Basic integral
            
            // DIFFERENTIAL NOTATION
            ("\\\\,dx", " dx"),
            ("\\\\,dy", " dy"),
            ("\\\\,dt", " dt"),
            ("\\\\,du", " du"),
            ("\\\\,dv", " dv"),
            ("\\\\,dr", " dr"),
            ("\\\\,d\\\\theta", " dθ"),
            ("\\\\,d\\\\phi", " dφ"),
            
            // LIMITS AND BOUNDS
            ("\\\\lim", "lim"),
            ("\\\\sup", "sup"),
            ("\\\\inf", "inf"),
            ("\\\\max", "max"),
            ("\\\\min", "min"),
            
            // GREEK LETTERS (Complete set)
            ("\\\\Alpha", "Α"), ("\\\\alpha", "α"),
            ("\\\\Beta", "Β"), ("\\\\beta", "β"),
            ("\\\\Gamma", "Γ"), ("\\\\gamma", "γ"),
            ("\\\\Delta", "Δ"), ("\\\\delta", "δ"),
            ("\\\\Epsilon", "Ε"), ("\\\\epsilon", "ε"), ("\\\\varepsilon", "ε"),
            ("\\\\Zeta", "Ζ"), ("\\\\zeta", "ζ"),
            ("\\\\Eta", "Η"), ("\\\\eta", "η"),
            ("\\\\Theta", "Θ"), ("\\\\theta", "θ"), ("\\\\vartheta", "ϑ"),
            ("\\\\Iota", "Ι"), ("\\\\iota", "ι"),
            ("\\\\Kappa", "Κ"), ("\\\\kappa", "κ"),
            ("\\\\Lambda", "Λ"), ("\\\\lambda", "λ"),
            ("\\\\Mu", "Μ"), ("\\\\mu", "μ"),
            ("\\\\Nu", "Ν"), ("\\\\nu", "ν"),
            ("\\\\Xi", "Ξ"), ("\\\\xi", "ξ"),
            ("\\\\Omicron", "Ο"), ("\\\\omicron", "ο"),
            ("\\\\Pi", "Π"), ("\\\\pi", "π"), ("\\\\varpi", "ϖ"),
            ("\\\\Rho", "Ρ"), ("\\\\rho", "ρ"), ("\\\\varrho", "ϱ"),
            ("\\\\Sigma", "Σ"), ("\\\\sigma", "σ"), ("\\\\varsigma", "ς"),
            ("\\\\Tau", "Τ"), ("\\\\tau", "τ"),
            ("\\\\Upsilon", "Υ"), ("\\\\upsilon", "υ"),
            ("\\\\Phi", "Φ"), ("\\\\phi", "φ"), ("\\\\varphi", "φ"),
            ("\\\\Chi", "Χ"), ("\\\\chi", "χ"),
            ("\\\\Psi", "Ψ"), ("\\\\psi", "ψ"),
            ("\\\\Omega", "Ω"), ("\\\\omega", "ω"),
            
            // MATH OPERATORS
            ("\\\\cdot", "·"),
            ("\\\\times", "×"),
            ("\\\\div", "÷"),
            ("\\\\pm", "±"),
            ("\\\\mp", "∓"),
            ("\\\\ast", "∗"),
            ("\\\\star", "⋆"),
            ("\\\\circ", "∘"),
            ("\\\\bullet", "•"),
            
            // RELATIONS
            ("\\\\leq", "≤"), ("\\\\le", "≤"),
            ("\\\\geq", "≥"), ("\\\\ge", "≥"),
            ("\\\\neq", "≠"), ("\\\\ne", "≠"),
            ("\\\\approx", "≈"),
            ("\\\\equiv", "≡"),
            ("\\\\sim", "∼"),
            ("\\\\simeq", "≃"),
            ("\\\\cong", "≅"),
            ("\\\\propto", "∝"),
            ("\\\\ll", "≪"),
            ("\\\\gg", "≫"),
            
            // SPECIAL SYMBOLS
            ("\\\\infty", "∞"),
            ("\\\\partial", "∂"),
            ("\\\\nabla", "∇"),
            ("\\\\sqrt", "√"),
            ("\\\\angle", "∠"),
            ("\\\\degree", "°"),
            ("\\\\prime", "′"),
            ("\\\\backprime", "‵"),
            
            // SUMMATION AND PRODUCTS
            ("\\\\sum", "∑"),
            ("\\\\prod", "∏"),
            ("\\\\coprod", "∐"),
            
            // ARROWS
            ("\\\\rightarrow", "→"), ("\\\\to", "→"),
            ("\\\\Rightarrow", "⇒"),
            ("\\\\leftarrow", "←"), ("\\\\gets", "←"),
            ("\\\\Leftarrow", "⇐"),
            ("\\\\leftrightarrow", "↔"),
            ("\\\\Leftrightarrow", "⇔"),
            ("\\\\uparrow", "↑"),
            ("\\\\Uparrow", "⇑"),
            ("\\\\downarrow", "↓"),
            ("\\\\Downarrow", "⇓"),
            ("\\\\updownarrow", "↕"),
            ("\\\\Updownarrow", "⇕"),
            ("\\\\mapsto", "↦"),
            ("\\\\longmapsto", "⟼"),
            
            // SET THEORY
            ("\\\\in", "∈"),
            ("\\\\notin", "∉"),
            ("\\\\ni", "∋"),
            ("\\\\notni", "∌"),
            ("\\\\subset", "⊂"),
            ("\\\\supset", "⊃"),
            ("\\\\subseteq", "⊆"),
            ("\\\\supseteq", "⊇"),
            ("\\\\nsubseteq", "⊈"),
            ("\\\\nsupseteq", "⊉"),
            ("\\\\cap", "∩"),
            ("\\\\cup", "∪"),
            ("\\\\emptyset", "∅"),
            ("\\\\varnothing", "∅"),
            ("\\\\setminus", "∖"),
            
            // LOGIC
            ("\\\\land", "∧"), ("\\\\wedge", "∧"),
            ("\\\\lor", "∨"), ("\\\\vee", "∨"),
            ("\\\\neg", "¬"), ("\\\\lnot", "¬"),
            ("\\\\exists", "∃"),
            ("\\\\nexists", "∄"),
            ("\\\\forall", "∀"),
            ("\\\\top", "⊤"),
            ("\\\\bot", "⊥"),
            
            // SPACES AND FORMATTING
            ("\\\\;", " "),        // thick space
            ("\\\\:", " "),        // medium space
            ("\\\\,", " "),        // thin space
            ("\\\\!", ""),         // negative thin space
            ("\\\\quad", "  "),    // quad space
            ("\\\\qquad", "    "), // double quad space
            ("\\\\ ", " "),        // normal space
            
            // TEXT FORMATTING
            ("\\\\text\\{([^}]+)\\}", "$1"),
            ("\\\\mathrm\\{([^}]+)\\}", "$1"),
            ("\\\\mathbf\\{([^}]+)\\}", "$1"),
            ("\\\\mathit\\{([^}]+)\\}", "$1"),
            ("\\\\mathcal\\{([^}]+)\\}", "$1"),
            ("\\\\mathfrak\\{([^}]+)\\}", "$1"),
            ("\\\\mathbb\\{([^}]+)\\}", "$1"),
            
            // TRIGONOMETRIC FUNCTIONS
            ("\\\\sin", "sin"),
            ("\\\\cos", "cos"),
            ("\\\\tan", "tan"),
            ("\\\\sec", "sec"),
            ("\\\\csc", "csc"),
            ("\\\\cot", "cot"),
            ("\\\\arcsin", "arcsin"),
            ("\\\\arccos", "arccos"),
            ("\\\\arctan", "arctan"),
            ("\\\\sinh", "sinh"),
            ("\\\\cosh", "cosh"),
            ("\\\\tanh", "tanh"),
            
            // LOGARITHMS
            ("\\\\log", "log"),
            ("\\\\ln", "ln"),
            ("\\\\lg", "lg"),
            
            // MISC FUNCTIONS
            ("\\\\exp", "exp"),
            ("\\\\det", "det"),
            ("\\\\gcd", "gcd"),
            ("\\\\lcm", "lcm"),
        ]
        
        // Apply regex-based conversions
        for (pattern, replacement) in conversions {
            if pattern.contains("(") {
                // Use regex for patterns with capture groups
                result = result.replacingOccurrences(
                    of: pattern,
                    with: replacement,
                    options: .regularExpression
                )
            } else {
                // Simple string replacement
                result = result.replacingOccurrences(of: pattern, with: replacement)
            }
        }
        
        // Handle superscripts and subscripts
        result = convertScripts(result)
        
        // Clean up extra braces
        result = result.replacingOccurrences(of: "{", with: "")
        result = result.replacingOccurrences(of: "}", with: "")
        
        // Remove any remaining backslashes
        result = result.replacingOccurrences(of: "\\", with: "")
        
        return result
    }
    
    private func processFractions(_ input: String) -> String {
        var result = input
        
        // Handle \frac{numerator}{denominator}
        let fracPattern = "\\\\(?:frac|tfrac|dfrac)\\{([^{}]+(?:\\{[^{}]*\\}[^{}]*)*)\\}\\{([^{}]+(?:\\{[^{}]*\\}[^{}]*)*)\\}"
        
        result = result.replacingOccurrences(
            of: fracPattern,
            with: "($1)/($2)",
            options: .regularExpression
        )
        
        return result
    }
    
    private func processIntegrationBounds(_ input: String) -> String {
        var result = input
        
        // Handle integration with bounds: \int_{lower}^{upper}
        let integralBoundsPattern = "\\\\(i*int|oint)_\\{([^}]+)\\}\\^\\{([^}]+)\\}"
        
        result = result.replacingOccurrences(
            of: integralBoundsPattern,
            with: "∫[$2→$3]",
            options: .regularExpression
        )
        
        // Handle integration without bounds but with limits
        let integralPattern = "\\\\(i*int|oint)"
        result = result.replacingOccurrences(
            of: integralPattern,
            with: "∫",
            options: .regularExpression
        )
        
        return result
    }
    
    private func processLimits(_ input: String) -> String {
        var result = input
        
        // Handle \lim_{x \to a}
        let limPattern = "\\\\lim_\\{([^}]+)\\}"
        result = result.replacingOccurrences(
            of: limPattern,
            with: "lim[$1]",
            options: .regularExpression
        )
        
        // Handle \sum_{i=1}^{n}
        let sumPattern = "\\\\sum_\\{([^}]+)\\}\\^\\{([^}]+)\\}"
        result = result.replacingOccurrences(
            of: sumPattern,
            with: "∑[$1→$2]",
            options: .regularExpression
        )
        
        // Handle \prod_{i=1}^{n}
        let prodPattern = "\\\\prod_\\{([^}]+)\\}\\^\\{([^}]+)\\}"
        result = result.replacingOccurrences(
            of: prodPattern,
            with: "∏[$1→$2]",
            options: .regularExpression
        )
        
        return result
    }
    
    private func convertScripts(_ input: String) -> String {
        var result = input
        
        // Superscripts
        let superscripts = [
            "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",
            "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹",
            "+": "⁺", "-": "⁻", "=": "⁼", "(": "⁽", ")": "⁾",
            "n": "ⁿ", "i": "ⁱ", "x": "ˣ", "y": "ʸ"
        ]
        
        // Subscripts
        let subscripts = [
            "0": "₀", "1": "₁", "2": "₂", "3": "₃", "4": "₄",
            "5": "₅", "6": "₆", "7": "₇", "8": "₈", "9": "₉",
            "+": "₊", "-": "₋", "=": "₌", "(": "₍", ")": "₎",
            "a": "ₐ", "e": "ₑ", "h": "ₕ", "i": "ᵢ", "j": "ⱼ",
            "k": "ₖ", "l": "ₗ", "m": "ₘ", "n": "ₙ", "o": "ₒ",
            "p": "ₚ", "r": "ᵣ", "s": "ₛ", "t": "ₜ", "u": "ᵤ",
            "v": "ᵥ", "x": "ₓ"
        ]
        
        // Convert simple superscripts like x^2, x^{2}
        for (char, sup) in superscripts {
            result = result.replacingOccurrences(of: "^{\(char)}", with: sup)
            result = result.replacingOccurrences(of: "^\(char)", with: sup)
        }
        
        // Convert simple subscripts like x_1, x_{1}
        for (char, sub) in subscripts {
            result = result.replacingOccurrences(of: "_{\(char)}", with: sub)
            result = result.replacingOccurrences(of: "_\(char)", with: sub)
        }
        
        // Handle multi-character super/subscripts
        result = convertMultiCharacterScripts(result)
        
        return result
    }
    
    private func convertMultiCharacterScripts(_ input: String) -> String {
        var result = input
        
        // Convert multi-character superscripts like x^{123} to ^(123)
        let superPattern = "\\^\\{([^}]+)\\}"
        result = result.replacingOccurrences(
            of: superPattern,
            with: "^($1)",
            options: .regularExpression
        )
        
        // Convert multi-character subscripts like x_{abc} to _(abc)
        let subPattern = "_\\{([^}]+)\\}"
        result = result.replacingOccurrences(
            of: subPattern,
            with: "_($1)",
            options: .regularExpression
        )
        
        return result
    }
}

// MARK: - LaTeX Display View with better formatting
struct LaTeXDisplayView: View {
    let title: String
    let content: String
    let fontSize: CGFloat
    
    init(title: String, content: String, fontSize: CGFloat = 14) {
        self.title = title
        self.content = content
        self.fontSize = fontSize
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            SimpleLaTeXText(content, fontSize: fontSize)
                .padding(.leading, 4)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Enhanced Text View for better math display
struct MathText: View {
    let text: String
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    
    init(_ text: String, fontSize: CGFloat = 16, fontWeight: Font.Weight = .regular) {
        self.text = text
        self.fontSize = fontSize
        self.fontWeight = fontWeight
    }
    
    var body: some View {
        SimpleLaTeXText(text, fontSize: fontSize)
    }
}
