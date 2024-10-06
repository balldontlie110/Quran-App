//
//  TestQuestionView.swift
//  Quran
//
//  Created by Ali Earp on 10/09/2024.
//

import SwiftUI

struct TestQuestionView: View {
    let question: TestQuestion
    let lastQuestion: Bool
    
    @Binding var answers: [TestAnswer]
    
    @State private var answer: String = ""
    
    var body: some View {
        VStack {
            Text(question.question)
                .font(.system(.title, weight: .bold))
            
            Spacer()
            
            TextField("Answer", text: $answer, axis: .vertical)
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            Spacer()
            
            nextQuestionButton
        }.padding()
    }
    
    private var nextQuestionButton: some View {
        Button {
            let testAnswer = TestAnswer(questionNumber: question.questionNumber, answer: answer)
            
            self.answers.append(testAnswer)
            
            self.answer = ""
        } label: {
            Text(lastQuestion ? "Submit" : "Next Question")
                .font(.headline)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
        }
    }
}

#Preview {
    TestQuestionView(question: TestQuestion(questionNumber: 0, question: ""), lastQuestion: false, answers: .constant([]))
}
