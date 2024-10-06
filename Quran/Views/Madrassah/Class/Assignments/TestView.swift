//
//  TestView.swift
//  Quran
//
//  Created by Ali Earp on 10/09/2024.
//

import SwiftUI
import FirebaseCore

struct TestView: View {
    @StateObject var assignmentsModel: AssignmentsModel
    
    @Binding var assignment: Assignment?
    
    @State private var questions: [TestQuestion] = []
    @State private var currentQuestion: Int = 1
    
    @State private var answers: [TestAnswer] = []
    
    var body: some View {
        VStack {
            HStack {
                if currentQuestion <= questions.count {
                    Text(String(currentQuestion))
                    
                    ProgressView(value: Double(currentQuestion - 1), total: Double(questions.count))
                }
                
                Text(String(questions.count))
            }.font(.system(.headline, weight: .bold))
            
            if let question = questions.first(where: { $0.questionNumber == currentQuestion }) {
                TestQuestionView(question: question, lastQuestion: currentQuestion == questions.count, answers: $answers)
            } else {
                Spacer()
                
                Text("Your answers have been submitted. When your teacher has marked them, you will be able to view your score here.")
                    .font(.system(.title3, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
        }
        .padding()
        .onChange(of: answers) { _, _ in
            self.currentQuestion += 1
            
            if currentQuestion > questions.count, let assingmentId = assignment?.id {
                assignmentsModel.submitAnswers(answers: answers, assignmentId: assingmentId)
                
                self.assignment = nil
            }
        }
        .onAppear {
            if let assingmentId = assignment?.id {
                assignmentsModel.fetchTestQuestions(assignmentId: assingmentId) { questions in
                    self.questions = questions.sorted { $0.questionNumber < $1.questionNumber }
                }
            }
        }
    }
}

#Preview {
    TestView(assignmentsModel: AssignmentsModel(mClass: Class(year: 0, gender: "", teacherIds: [], studentIds: []), madrassahUser: Member(user: "", gender: "", year: nil, isTeacher: false, classIds: nil)), assignment: .constant(Assignment(id: nil, uploadedBy: "", onlineSubmission: false, test: false, title: "", description: "", submissions: [], timestamp: Timestamp())))
}
