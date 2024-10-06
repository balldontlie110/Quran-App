//
//  AssignmentsView.swift
//  Quran
//
//  Created by Ali Earp on 04/09/2024.
//

import SwiftUI

struct AssignmentsView: View {
    @StateObject var assignmentsModel: AssignmentsModel
    
    @State private var assignment: Assignment?
    
    @State private var showNewAssignmentView: Bool = false
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(assignments) { assignment in
                    Button {
                        self.assignment = assignment
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(assignment.title)
                                    .font(.system(.title2, weight: .bold))
                                    .foregroundStyle(Color.primary)
                                
                                Text(assignment.description)
                                    .font(.callout)
                                    .foregroundStyle(Color.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                        }
                        .multilineTextAlignment(.leading)
                        .padding(15)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                
                Spacer()
                    .frame(height: 50)
            }.padding()
        }
        .overlay(alignment: .bottom) {
            newAssignmentButton
        }
        .sheet(isPresented: $showNewAssignmentView) {
            NewAssignmentView(assignmentsModel: assignmentsModel, showNewAssignmentView: $showNewAssignmentView)
        }
        .sheet(item: $assignment) { assignment in
            AssignmentView(assignmentsModel: assignmentsModel, assignment: $assignment)
        }
    }
    
    private var assignments: [Assignment] {
        return assignmentsModel.assignments.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
    }
    
    @ViewBuilder
    private var newAssignmentButton: some View {
        if assignmentsModel.madrassahUser.isTeacher {
            Button {
                self.showNewAssignmentView.toggle()
            } label: {
                Text("New Assignment")
                    .font(.headline)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                    .padding()
            }
        }
    }
}

#Preview {
    AssignmentsView(assignmentsModel: AssignmentsModel(mClass: Class(year: 0, gender: "", teacherIds: [], studentIds: []), madrassahUser: Member(user: "", gender: "", year: nil, isTeacher: false, classIds: nil)))
}
