//
//  MadrassahView.swift
//  Quran
//
//  Created by Ali Earp on 04/09/2024.
//

import SwiftUI

struct MadrassahView: View {
    @StateObject private var madrassahModel: MadrassahModel = MadrassahModel()
    
    private let columns = [GridItem](repeating: GridItem(.flexible()), count: 3)
    
    @State private var showAddClassView: Bool = false
    
    var body: some View {
        VStack {
            if let madrassahUser = madrassahModel.madrassahUser {
                VStack {
                    classesList
                    
                    Spacer()
                    
                    if madrassahUser.isTeacher {
                        addClassButton
                    }
                }
                .padding()
                .sheet(isPresented: $showAddClassView) {
                    AddClassView(madrassahModel: madrassahModel, showAddClassView: $showAddClassView)
                }
            } else if madrassahModel.loading {
                ProgressView()
            } else {
                LinkMadrassahAccountView(madrassahModel: madrassahModel)
            }
        }
        .onAppear {
            madrassahModel.reset()
            madrassahModel.listenForUserStateChange()
        }
    }
    
    @ViewBuilder
    private var classesList: some View {
        if let madrassahUser = madrassahModel.madrassahUser {
            LazyVGrid(columns: columns) {
                ForEach(classes) { mClass in
                    NavigationLink {
                        ClassView(resourcesModel: ResourcesModel(mClass: mClass, madrassahUser: madrassahUser), madrassahUser: madrassahUser, mClass: mClass)
                    } label: {
                        VStack {
                            Text("Class \(mClass.year)\(mClass.gender)")
                                .font(.headline)
                                .foregroundStyle(Color.primary)
                            
                            Text(mClass.section)
                                .font(.subheadline)
                                .foregroundStyle(Color.secondary)
                        }
                        .minimumScaleFactor(.leastNonzeroMagnitude)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(2.5)
                    }
                }
            }
        }
    }
    
    private var classes: [Class] {
        if let madrassahUser = madrassahModel.madrassahUser, let madrassahId = madrassahUser.id {
            let madrassahClasses = madrassahModel.classes.sorted {
                let hasTargetId1 = $0.teacherIds.contains(madrassahId)
                let hasTargetId2 = $1.teacherIds.contains(madrassahId)
                
                if hasTargetId1 != hasTargetId2 {
                    return hasTargetId1 && !hasTargetId2
                }
                
                if $0.year != $1.year {
                    return $0.year > $1.year
                }
                
                let genderOrder: [String: Int] = ["B": 0, "G": 1, "M": 2]
                if let genderOrder1 = genderOrder[$0.gender], let genderOrder2 = genderOrder[$1.gender] {
                    return genderOrder1 < genderOrder2
                }
                
                return false
            }
            
            if madrassahUser.isTeacher {
                return madrassahClasses
            }
            
            return madrassahClasses.filter { mClass in
                mClass.studentIds.contains(madrassahId)
            }
        }
        
        return []
    }
    
    private var addClassButton: some View {
        Button {
            self.showAddClassView.toggle()
        } label: {
            Text("Add Class")
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
    MadrassahView()
}
