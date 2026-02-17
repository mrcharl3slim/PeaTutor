//
//  QuestionContainerView.swift
//  PeaTutorApp
//
//  Sub-Sprint 3.4: Integrated with full worksheet feedback sync
//

import SwiftUI

struct QuestionContainerView: View {
    let result: ExtractedWorksheet
    let worksheetId: String
    
    @State private var currentQuestionIndex = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            progressBar
            
            // Question navigation
            TabView(selection: $currentQuestionIndex) {
                ForEach(result.questions.indices, id: \.self) { index in
                    QuestionDetailView(
                        question: result.questions[index],
                        questionNumber: index + 1,
                        worksheetId: worksheetId
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Bottom toolbar
            bottomToolbar
        }
        .navigationTitle("Questions (\(currentQuestionIndex + 1)/\(result.questions.count))")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(
                        width: geometry.size.width * CGFloat(currentQuestionIndex + 1) / CGFloat(result.questions.count),
                        height: 4
                    )
                    .animation(.easeInOut, value: currentQuestionIndex)
            }
        }
        .frame(height: 4)
    }
    
    // MARK: - Bottom Toolbar
    
    private var bottomToolbar: some View {
        VStack(spacing: 12) {
            // Full worksheet feedback button (NEW - with history & sync)
            FullWorksheetFeedbackButton(
                worksheetId: worksheetId,
                questions: result.questions
            )
            .padding(.horizontal)
            
            Divider()
            
            // Navigation controls
            HStack(spacing: 20) {
                // Previous button
                Button(action: { withAnimation { previousQuestion() } }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .font(.subheadline)
                    .foregroundColor(currentQuestionIndex > 0 ? .blue : .gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(currentQuestionIndex > 0 ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    )
                }
                .disabled(currentQuestionIndex == 0)
                
                // Question indicator
                VStack(spacing: 4) {
                    Text("Question")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 6) {
                        ForEach(result.questions.indices, id: \.self) { index in
                            Circle()
                                .fill(index == currentQuestionIndex ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: index == currentQuestionIndex ? 10 : 8, height: index == currentQuestionIndex ? 10 : 8)
                                .animation(.easeInOut, value: currentQuestionIndex)
                        }
                    }
                }
                
                // Next button
                Button(action: { withAnimation { nextQuestion() } }) {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                    .foregroundColor(currentQuestionIndex < result.questions.count - 1 ? .blue : .gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(currentQuestionIndex < result.questions.count - 1 ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    )
                }
                .disabled(currentQuestionIndex == result.questions.count - 1)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: -2)
    }
    
    // MARK: - Navigation Methods
    
    private func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        }
    }
    
    private func nextQuestion() {
        if currentQuestionIndex < result.questions.count - 1 {
            currentQuestionIndex += 1
        }
    }
}

// MARK: - Preview
struct QuestionContainerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            QuestionContainerView(
                result: ExtractedWorksheet(questions: [
                    ExtractedQuestion(
                        id: "Q1",
                        questionText: "Solve for x: 2x + 3 = 7",
                        marks: 2,
                        skillsTested: ["Algebra", "Linear Equations"],
                        subparts: [],
                        hints: "Isolate x by moving constants to the right side",
                        stepByStep: "Step 1: Subtract 3 from both sides\nStep 2: Divide by 2",
                        answer: "x = 2"
                    ),
                    ExtractedQuestion(
                        id: "Q2",
                        questionText: "Find the derivative of f(x) = x²",
                        marks: 3,
                        skillsTested: ["Calculus", "Differentiation"],
                        subparts: [],
                        hints: "Use the power rule",
                        stepByStep: "Apply power rule: d/dx(x^n) = nx^(n-1)",
                        answer: "f'(x) = 2x"
                    )
                ]),
                worksheetId: "ws-123"
            )
        }
    }
}
