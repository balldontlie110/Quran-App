//
//  AssignmentView.swift
//  Quran
//
//  Created by Ali Earp on 08/09/2024.
//

import SwiftUI
import FirebaseCore

struct AssignmentView: View {
    @StateObject var assignmentsModel: AssignmentsModel
    
    @Binding var assignment: Assignment?
    
    @State private var userProfile: UserProfile?
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                if let assignment = assignment, let userProfile = userProfile {
                    HStack(alignment: .top) {
                        Text(assignment.title)
                            .font(.system(.title, weight: .bold))
                        
                        Spacer()
                        
                        UserProfilePhoto(photoURL: userProfile.photoURL, size: 40)
                    }
                    
                    Text(assignment.description)
                        .foregroundStyle(Color.secondary)
                    
                    HStack(alignment: .top) {
                        Text("Set by: \(userProfile.username)")
                        
                        Spacer()
                        
                        Text(assignment.timestamp.string())
                            .foregroundStyle(Color.secondary)
                            .multilineTextAlignment(.trailing)
                    }.bold()
                    
                    Text("\(userProfile.username) would like you to submit this homework \(assignment.onlineSubmission ? "online" : "in class").")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                    
                    Spacer()
                    
                    if let madrassahId = assignmentsModel.madrassahUser.id {
                        if !assignment.submissions.contains(madrassahId) {
                            if assignment.test {
                                takeTestButton
                            }
                        } else {
                            HStack {
                                Spacer()
                                
                                Text("You've already added a submission for this assignment.\nIf you don't believe this to be the case, please contact your teacher.")
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Spacer()
                            }
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .multilineTextAlignment(.leading)
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    doneButton
                }
            }
            .onAppear {
                if let madrassahId = assignment?.uploadedBy {
                    assignmentsModel.fetchUserProfile(madrassahId: madrassahId) { userProfile in
                        self.userProfile = userProfile
                    }
                }
            }
        }
    }
    
    private var doneButton: some View {
        Button {
            self.assignment = nil
        } label: {
            Text("Done")
                .bold()
        }
    }
    
    private var takeTestButton: some View {
        NavigationLink {
            TestView(assignmentsModel: assignmentsModel, assignment: $assignment)
        } label: {
            Text("Take Test")
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
    AssignmentView(assignmentsModel: AssignmentsModel(mClass: Class(year: 0, gender: "", teacherIds: [], studentIds: []), madrassahUser: Member(user: "", gender: "", year: nil, isTeacher: false, classIds: nil)), assignment: .constant(Assignment(id: nil, uploadedBy: "", onlineSubmission: false, test: false, title: "", description: "", submissions: [], timestamp: Timestamp())))
}
