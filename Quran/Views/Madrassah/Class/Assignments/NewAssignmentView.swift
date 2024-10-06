//
//  NewAssignmentView.swift
//  Quran
//
//  Created by Ali Earp on 11/09/2024.
//

import SwiftUI

struct NewAssignmentView: View {
    @StateObject var assignmentsModel: AssignmentsModel
    
    @Binding var showNewAssignmentView: Bool
    
    @State private var title: String = ""
    @State private var description: String = ""
    
    @State private var test: Bool = false
    
    @State private var onlineSubmission: Bool = true
    
    @State private var questions: [TestQuestion] = [TestQuestion(questionNumber: 1, question: "")]
    
    init(assignmentsModel: AssignmentsModel, showNewAssignmentView: Binding<Bool>) {
        self._assignmentsModel = StateObject(wrappedValue: assignmentsModel)
        self._showNewAssignmentView = showNewAssignmentView
        
        UITableView.appearance().separatorStyle = .none
    }
    
    var body: some View {
        NavigationStack {
            List {
                TextField("Title", text: $title)
                    .font(.system(.title3, weight: .bold))
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 5, trailing: 20))
                    .listRowSeparator(.hidden)
                
                TextField("Description", text: $description, axis: .vertical)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 10, trailing: 20))
                    .listRowSeparator(.hidden)
                
                Picker("", selection: $onlineSubmission) {
                    Text("Online")
                        .tag(true)
                    
                    Text("In Class")
                        .tag(false)
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 20, leading: 40, bottom: 20, trailing: 40))
                .listRowSeparator(.hidden)
                .onChange(of: onlineSubmission) { _, _ in
                    if !onlineSubmission {
                        self.test = false
                    }
                }
                
                Toggle("Test", isOn: $test)
                    .padding(.vertical, 10)
                    .padding(.horizontal)
                    .font(.headline)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                    .listRowSeparator(.hidden)
                    .onChange(of: test) { _, _ in
                        if test {
                            self.onlineSubmission = true
                        }
                    }
                
                errorMessage
                
                if assignmentsModel.loading {
                    ProgressView()
                        .listRowSeparator(.hidden)
                }
                
                if test {
                    ForEach($questions, id: \.uuid) { $question in
                        TextField("Question \(question.questionNumber)", text: $question.question, axis: .vertical)
                            .padding(10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .background(RoundedRectangle(cornerRadius: 15).stroke(Color.secondary, lineWidth: 1))
                            .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                            .listRowSeparator(.hidden)
                    }
                    .onDelete(perform: deleteQuestion)
                    .onMove(perform: moveQuestion)
                    
                    HStack {
                        Spacer()
                        
                        Button {
                            self.questions.append(TestQuestion(questionNumber: questions.count + 1, question: ""))
                        } label: {
                            Text("+ New Question")
                                .font(.headline)
                                .foregroundStyle(Color.accentColor)
                        }
                        
                        Spacer()
                    }
                    .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
                    .listRowSeparator(.hidden)
                }
                
                Spacer()
                    .frame(height: 50)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .multilineTextAlignment(.leading)
            .overlay(alignment: .bottom) {
                uploadAssignmentButton
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    cancelButton
                }
                
                if test {
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                            .bold()
                    }
                }
            }
        }
        .simultaneousGesture(DragGesture(minimumDistance: 100).onChanged { value in
            if value.location.y > value.startLocation.y {
                hideKeyboard()
            }
        })
    }
    
    private func deleteQuestion(at offsets: IndexSet) {
        questions.remove(atOffsets: offsets)
        
        resetQuestionNumbers()
    }
    
    private func moveQuestion(from source: IndexSet, to destination: Int) {
        questions.move(fromOffsets: source, toOffset: destination)
        
        resetQuestionNumbers()
    }
    
    private func resetQuestionNumbers() {
        for index in questions.indices {
            questions[index].questionNumber = index + 1
        }
    }
    
    private var cancelButton: some View {
        Button {
            self.showNewAssignmentView = false
        } label: {
            Text("Cancel")
                .bold()
        }
    }
    
    private var uploadAssignmentButton: some View {
        Button {
            assignmentsModel.uploadAssignment(title: title, description: description, onlineSubmission: onlineSubmission, test: test, questions: questions) { success in
                if success {
                    self.showNewAssignmentView = false
                }
            }
        } label: {
            Text("Upload Assignment")
                .font(.headline)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .padding()
        }.ignoresSafeArea(.keyboard)
    }
    
    @ViewBuilder
    private var errorMessage: some View {
        if assignmentsModel.error != "" {
            Text(assignmentsModel.error)
                .foregroundStyle(Color.red)
                .multilineTextAlignment(.center)
                .font(.caption)
                .padding(.top, 5)
        }
    }
}

#Preview {
    NewAssignmentView(assignmentsModel: AssignmentsModel(mClass: Class(year: 0, gender: "", teacherIds: [], studentIds: []), madrassahUser: Member(user: "", gender: "", year: nil, isTeacher: false, classIds: nil)), showNewAssignmentView: .constant(true))
}
