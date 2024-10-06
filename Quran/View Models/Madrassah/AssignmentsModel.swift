//
//  AssignmentsModel.swift
//  Quran
//
//  Created by Ali Earp on 04/09/2024.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

class AssignmentsModel: ObservableObject {
    let mClass: Class
    let madrassahUser: Member
    
    @Published var assignments: [Assignment] = []
    
    @Published var assignmentsListener: ListenerRegistration?
    
    @Published var loading: Bool = false
    @Published var error: String = ""
    
    init(mClass: Class, madrassahUser: Member) {
        self.mClass = mClass
        self.madrassahUser = madrassahUser
        
        fetchAssignments()
    }
    
    private var assignmentsCollection: CollectionReference? {
        if let classId = mClass.id {
            return Firestore.firestore().collection("madrassah").document("classes").collection("classes").document(classId).collection("assignments")
        }
        
        return nil
    }
    
    private var assignmentsReference: StorageReference? {
        if let classId = mClass.id {
            return Storage.storage().reference().child("madrassah").child("classes").child(classId).child("assignments")
        }
        
        return nil
    }
    
    private func fetchAssignments() {
        if let assignmentsCollection = assignmentsCollection {
            self.assignmentsListener = assignmentsCollection.addSnapshotListener { snapshot, error in
                if let error = error {
                    print(error)
                    return
                }
                
                if let snapshot = snapshot {
                    var assignments: [Assignment] = []
                    
                    for change in snapshot.documentChanges {
                        if change.type == .added {
                            do {
                                let assignment = try change.document.data(as: Assignment.self)
                                
                                assignments.append(assignment)
                            } catch {
                                print(error)
                            }
                        } else if change.type == .modified {
                            do {
                                let assignment = try change.document.data(as: Assignment.self)
                                
                                self.assignments.removeAll(where: { $0.id == assignment.id })
                                
                                self.assignments.append(assignment)
                            } catch {
                                print(error)
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.assignments += assignments
                    }
                }
            }
        }
    }
    
    func fetchTestQuestions(assignmentId: String, completion: @escaping ([TestQuestion]) -> Void) {
        if let assignmentsCollection = assignmentsCollection {
            assignmentsCollection.document(assignmentId).collection("questions").getDocuments { snapshot, error in
                if let error = error {
                    print(error)
                    return
                }
                
                if let snapshot = snapshot {
                    var questions: [TestQuestion] = []
                    
                    for document in snapshot.documents {
                        do {
                            let question = try document.data(as: TestQuestion.self)
                            
                            questions.append(question)
                        } catch {
                            print(error)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        completion(questions)
                    }
                }
            }
        }
    }
    
    func submitAnswers(answers: [TestAnswer], assignmentId: String) {
        if let assignmentsCollection = assignmentsCollection, let madrassahId = madrassahUser.id {
            let submissionDocument = assignmentsCollection.document(assignmentId).collection("submissions").document()
            
            submissionDocument.setData([
                "timestamp": Timestamp(),
                "submittedBy": madrassahId
            ])
            
            for answer in answers {
                do {
                    try submissionDocument.collection("answers").addDocument(from: answer) { error in
                        if let error = error {
                            print(error)
                            return
                        }
                    }
                } catch {
                    print(error)
                }
            }
            
            assignmentsCollection.document(assignmentId).updateData(["submissions": FieldValue.arrayUnion([madrassahId])])
        }
    }
    
    func uploadAssignment(title: String, description: String, onlineSubmission: Bool, test: Bool, questions: [TestQuestion], completion: @escaping (Bool) -> Void) {
        self.loading = true
        
        if !title.isEmpty && !description.isEmpty && isValidTest(), let assignmentsCollection = assignmentsCollection, let madrassahId = madrassahUser.id {
            let assignment = Assignment(uploadedBy: madrassahId, onlineSubmission: onlineSubmission, test: false, title: title, description: description, submissions: [], timestamp: Timestamp())
            
            do {
                try assignmentsCollection.addDocument(from: assignment) { error in
                    if let error = error {
                        print(error)
                        self.error = "There was an error trying to upload the assignment."
                        self.loading = false
                        
                        return
                    }
                    
                    self.error = ""
                    self.loading = false
                    completion(true)
                }
            } catch {
                print(error)
                self.error = "There was an error trying to upload the assignment."
                self.loading = false
            }
        } else {
            if title.isEmpty {
                self.error = "You need a title."
                self.loading = false
            } else if description.isEmpty {
                self.error = "You need a description."
                self.loading = false
            } else if isValidTest() {
                self.error = "You need at least one question for the test."
                self.loading = false
            } else {
                self.error = "There was an error trying to upload the assignment."
                self.loading = false
            }
        }
        
        func isValidTest() -> Bool {
            if test {
                if questions.isEmpty {
                    return false
                }
            }
            
            return true
        }
    }
    
    func fetchUserProfile(madrassahId: String, completion: @escaping (UserProfile) -> Void) {
        Firestore.firestore().collection("madrassah").document("members").collection("members").document(madrassahId).getDocument { snapshot, error in
            if let error = error {
                print(error)
                return
            }
            
            if let snapshot = snapshot {
                if let uid = snapshot.data()?["user"] as? String {
                    Firestore.firestore().collection("users").document(uid).getDocument { userSnapshot, error in
                        if let error = error {
                            print(error)
                            return
                        }
                        
                        if let userSnapshot = userSnapshot {
                            let username = userSnapshot.data()?["username"] as? String ?? ""
                            
                            Storage.storage().reference().child("users").child(uid).downloadURL { url, error in
                                if let error = error {
                                    print(error)
                                    return
                                }
                                
                                if let url = url {
                                    let userProfile = UserProfile(id: madrassahId, username: username, photoURL: url)
                                    
                                    completion(userProfile)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
