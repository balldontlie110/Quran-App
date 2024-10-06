//
//  AddClassView.swift
//  Quran
//
//  Created by Ali Earp on 04/09/2024.
//

import SwiftUI

struct AddClassView: View {
    @StateObject var madrassahModel: MadrassahModel
    
    @Binding var showAddClassView: Bool
    
    @State private var year: Int?
    @State private var gender: String = "B"
    
    @State private var teacherIds: [String] = []
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack(spacing: 0) {
                    yearPicker
                    
                    Divider()
                    
                    genderPicker
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                errorMessage
                
                Spacer()
                
                if madrassahModel.loading {
                    ProgressView()
                }
                
                teachersPicker
                
                Spacer()
                
                addClassButton
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    cancelButton
                }
            }
            .navigationTitle("Madrassah")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            madrassahModel.error = ""
            madrassahModel.loading = false
            
            madrassahModel.getTeachers()
        }
        .onDisappear {
            madrassahModel.error = ""
            madrassahModel.loading = false
        }
    }
    
    private var cancelButton: some View {
        Button {
            self.showAddClassView = false
        } label: {
            Text("Cancel")
                .bold()
        }
    }
    
    private var yearPicker: some View {
        Menu {
            ForEach(1..<13) { year in
                Button {
                    self.year = year
                } label: {
                    HStack {
                        Text(String(year))
                        
                        Spacer()
                        
                        if year == self.year {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text("Year")
                    .font(.headline)
                    .foregroundStyle(Color.primary, Color.primary)
                
                Spacer()
                
                Text(year == nil ? "" : String(year ?? 0))
                    .foregroundStyle(Color.primary, Color.primary)
                    .multilineTextAlignment(.center)
                    .frame(minWidth: 35, minHeight: 35)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }.padding()
        }
    }
    
    private var genderPicker: some View {
        HStack {
            Text("Gender")
                .font(.headline)
                .foregroundStyle(Color.primary)
                .padding(.trailing)
            
            Spacer()
            
            Picker("", selection: $gender) {
                Text("Boys")
                    .tag("B")
                
                Text("Girls")
                    .tag("G")
                
                Text("Mixed")
                    .tag("")
            }.pickerStyle(.segmented)
        }.padding()
    }
    
    @ViewBuilder
    private var teachersPicker: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Teachers")
                    .font(.system(.title, weight: .bold))
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }.padding(.top)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(madrassahModel.teacherProfiles) { teacher in
                        Button {
                            if teacherIds.contains(where: { $0 == teacher.id }) {
                                self.teacherIds.removeAll(where: { $0 == teacher.id })
                            } else {
                                self.teacherIds.append(teacher.id)
                            }
                        } label: {
                            HStack(spacing: 15) {
                                UserProfilePhoto(photoURL: teacher.photoURL, size: 30)
                                
                                Text(teacher.username)
                                    .font(.system(.headline, weight: .semibold))
                                    .foregroundStyle(Color.primary)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                                
                                if teacherIds.contains(where: { $0 == teacher.id }) {
                                    Circle()
                                        .foregroundStyle(Color.accentColor)
                                        .frame(width: 20, height: 20)
                                } else {
                                    Circle()
                                        .stroke(.secondary, lineWidth: 1)
                                        .frame(width: 20, height: 20)
                                }
                            }.padding(10)
                        }
                        
                        if madrassahModel.teacherProfiles.last?.id != teacher.id {
                            Divider()
                        }
                    }
                }.padding(10)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.bottom)
        }
    }
    
    private var addClassButton: some View {
        Button {
            madrassahModel.addClass(year: year, gender: gender, teacherIds: teacherIds) { success in
                if success {
                    self.showAddClassView = false
                }
            }
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
    
    @ViewBuilder
    private var errorMessage: some View {
        if madrassahModel.error != "" {
            Text(madrassahModel.error)
                .foregroundStyle(Color.red)
                .multilineTextAlignment(.center)
                .font(.caption)
                .padding(.top, 5)
        }
    }
}

#Preview {
    AddClassView(madrassahModel: MadrassahModel(), showAddClassView: .constant(true))
}
