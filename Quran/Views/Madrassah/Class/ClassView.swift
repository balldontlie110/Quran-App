//
//  ClassView.swift
//  Quran
//
//  Created by Ali Earp on 04/09/2024.
//

import SwiftUI

struct ClassView: View {
    @StateObject var resourcesModel: ResourcesModel
    
    let madrassahUser: Member
    let mClass: Class
    
    @State private var view: Int = 0
    
    var body: some View {
        TabView(selection: $view) {
            DiscussionView(discussionModel: DiscussionModel(mClass: mClass, madrassahUser: madrassahUser))
                .tabItem {
                    Label("Discussion", systemImage: "message")
                }
                .tag(0)
            
            AssignmentsView(assignmentsModel: AssignmentsModel(mClass: mClass, madrassahUser: madrassahUser))
                .tabItem {
                    Label("Assignments", systemImage: "graduationcap")
                }
                .tag(1)
            
            ResourcesView(resourcesModel: resourcesModel)
                .tabItem {
                    Label("Resources", systemImage: "folder")
                }
                .tag(2)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                deleteButton
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                selectButton
            }
        }
        .toolbar(.visible, for: .navigationBar)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private var selectButton: some View {
        if view == 2 && resourcesModel.madrassahUser.isTeacher {
            Button {
                withAnimation {
                    resourcesModel.selectedResources = []
                    resourcesModel.editMode.toggle()
                }
            } label: {
                Text(resourcesModel.editMode ? "Cancel" : "Select")
                    .font(.headline)
            }
        }
    }
    
    @ViewBuilder
    private var deleteButton: some View {
        if view == 2 && resourcesModel.editMode {
            Button {
                resourcesModel.deleteResources()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(Color.red)
            }
        }
    }
    
    private var navigationTitle: String {
        return "\(mClass.section) - \(mClass.year)\(mClass.gender)"
    }
}

#Preview {
    ClassView(resourcesModel: ResourcesModel(mClass: Class(year: 0, gender: "", teacherIds: [], studentIds: []), madrassahUser: Member(user: "", gender: "", year: nil, isTeacher: false, classIds: nil)), madrassahUser: Member(user: "", gender: "", year: nil, isTeacher: false, classIds: nil), mClass: Class(year: 0, gender: "", teacherIds: [], studentIds: []))
}
