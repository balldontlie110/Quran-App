//
//  ResourcesView.swift
//  Quran
//
//  Created by Ali Earp on 04/09/2024.
//

import SwiftUI
import Firebase

struct ResourcesView: View {
    @StateObject var resourcesModel: ResourcesModel
    
    @State private var showFileImporter: Bool = false
    
    @State private var resourceURL: URL?
    
    @State private var userProfile: UserProfile?
    
    var body: some View {
        resourcesScrollView
            .overlay(alignment: .bottom) {
                if resourcesModel.madrassahUser.isTeacher && !resourcesModel.editMode {
                    uploadResourcesButton
                }
            }
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.item], allowsMultipleSelection: true) { results in
                resourcesModel.uploadResources(files: results)
            }
            .sheet(item: $resourceURL) { url in
                FilePreview(url: url)
                    .ignoresSafeArea()
            }
            .sheet(item: $userProfile) { userProfile in
                ProfileDetailView(userProfile: $userProfile)
            }
    }
    
    private var resourcesScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(resources) { resource in
                    Button {
                        if resourcesModel.editMode {
                            if resourcesModel.selectedResources.contains(where: { $0.id == resource.id }) {
                                resourcesModel.selectedResources.removeAll(where: { $0.id == resource.id })
                            } else {
                                resourcesModel.selectedResources.append(resource)
                            }
                        } else {
                            if let downloadURL = URL(string: resource.downloadURL) {
                                downloadFile(from: downloadURL, fileName: resource.resourceName)
                            }
                        }
                    } label: {
                        ResourceCard(resourcesModel: resourcesModel, resource: resource, userProfile: $userProfile)
                    }
                }
                
                Spacer()
                    .frame(height: 60)
            }.padding()
        }
    }
    
    private var resources: [Resource] {
        resourcesModel.resources.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() })
    }
    
    private func downloadFile(from url: URL, fileName: String) {
        let task = URLSession.shared.downloadTask(with: url) { (localURL, response, error) in
            guard let localURL = localURL, error == nil else {
                return
            }
            
            do {
                if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let destinationURL = documentsDirectory.appendingPathComponent(fileName)
                    
                    if FileManager.default.fileExists(atPath: destinationURL.path()) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    
                    try FileManager.default.moveItem(at: localURL, to: destinationURL)
                    
                    DispatchQueue.main.async {
                        self.resourceURL = destinationURL
                    }
                }
            } catch {
                print(error)
            }
        }
        
        task.resume()
    }
    
    private var uploadResourcesButton: some View {
        Button {
            self.showFileImporter.toggle()
        } label: {
            Text("Upload File")
                .font(.headline)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
        }
    }
}

struct ResourceCard: View {
    @StateObject var resourcesModel: ResourcesModel
    
    let resource: Resource
    
    @Binding var userProfile: UserProfile?
    
    var body: some View {
        HStack(spacing: 15) {
            if resourcesModel.editMode {
                if resourcesModel.selectedResources.contains(where: { $0.id == resource.id }) {
                    Circle()
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 20, height: 20)
                } else {
                    Circle()
                        .stroke(.secondary, lineWidth: 0.5)
                        .frame(width: 20, height: 20)
                }
            }
            
            HStack(alignment: .top, spacing: 10) {
                Group {
                    let splitResourceName = resource.resourceName.split(separator: ".")
                    if let title = splitResourceName.first, let fileExtension = splitResourceName.last {
                        Text(title)
                            .foregroundStyle(Color.primary)
                        +
                        Text(".\(fileExtension)")
                            .font(.callout)
                            .foregroundStyle(Color.secondary)
                    }
                }
                .multilineTextAlignment(.leading)
                .animation(.bouncy, value: resourcesModel.editMode)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(resource.timestamp.shortDate())
                    
                    Text(resource.timestamp.time())
                }
                .font(.caption)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.trailing)
                
                let userProfile = resourcesModel.userProfiles.first(where: { $0.id == resource.uploadedBy })
                
                Button {
                    self.userProfile = userProfile
                } label: {
                    UserProfilePhoto(photoURL: userProfile?.photoURL)
                }
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

extension Timestamp {
    func shortDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d/M/yy"
        
        return formatter.string(from: self.dateValue())
    }
    
    func time() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        return formatter.string(from: self.dateValue())
    }
}

extension URL: @retroactive Identifiable {
    public var id: UUID {
        return UUID()
    }
}

#Preview {
    ResourcesView(resourcesModel: ResourcesModel(mClass: Class(year: 0, gender: "", teacherIds: [], studentIds: []), madrassahUser: Member(user: "", gender: "", year: nil, isTeacher: false, classIds: nil)))
}
