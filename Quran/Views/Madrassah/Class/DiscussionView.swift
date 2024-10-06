//
//  DiscussionView.swift
//  Quran
//
//  Created by Ali Earp on 04/09/2024.
//

import SwiftUI
import SDWebImageSwiftUI
import PhotosUI
import ExyteMediaPicker

struct DiscussionView: View {
    @StateObject var discussionModel: DiscussionModel
    
    @State private var showCameraPicker: Bool = false
    @State private var showPhotoLibraryPicker: Bool = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    
    @State private var userProfile: UserProfile?
    
    @State private var showImageLibrary: String?
    
    @State private var scrollPosition: String? = ""
    
    @State private var messageBarHeight: CGFloat = 0
    
    @Namespace private var namespace
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2.5) {
                        ForEach(messages) { message in
                            MessageView(discussionModel: discussionModel, message: message, nextMessageIsSame: nextMessageIsSame(message: message), userProfile: $userProfile, showImageLibrary: $showImageLibrary, namespace: namespace)
                        }
                    }.padding(10)
                    
                    Color.clear
                        .frame(height: 0)
                        .id("")
                }
                .defaultScrollAnchor(.bottom)
                .scrollPosition(id: $scrollPosition, anchor: .bottom)
                .simultaneousGesture(DragGesture(minimumDistance: 100).onChanged { value in
                    if value.location.y > value.startLocation.y {
                        hideKeyboard()
                    }
                })
                .onTapGesture {
                    hideKeyboard()
                }
            }
            .padding(.bottom, messageBarHeight)
            .navigationDestination(item: $showImageLibrary) { selectedPhotoURL in
                if #available(iOS 18.0, *) {
                    ImageLibrary(photoURLs: photoURLs, initialPhotoURL: selectedPhotoURL)
                        .navigationTransition(.zoom(sourceID: selectedPhotoURL, in: namespace))
                } else {
                    ImageLibrary(photoURLs: photoURLs, initialPhotoURL: selectedPhotoURL)
                }
            }
            
            messageBar
        }
        .sheet(isPresented: $showCameraPicker) {
            ImagePickerView(sourceType: .camera) { image in
                discussionModel.images.append(image)
            }.ignoresSafeArea()
        }
        .photosPicker(isPresented: $showPhotoLibraryPicker, selection: $selectedPhotoItems, maxSelectionCount: nil, selectionBehavior: .continuousAndOrdered, matching: .images, preferredItemEncoding: .automatic)
        .onChange(of: showPhotoLibraryPicker) { _, _ in
            if !showPhotoLibraryPicker {
                discussionModel.images = []
                
                Task {
                    for photoItem in selectedPhotoItems {
                        if let data = try await photoItem.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                            discussionModel.images.append(image)
                        }
                    }
                }
            }
        }
        .sheet(item: $userProfile) { userProfile in
            ProfileDetailView(userProfile: $userProfile)
        }
    }
    
    private var messages: [Message] {
        discussionModel.messages.sorted {
            $0.timestamp.dateValue() < $1.timestamp.dateValue()
        }
    }
    
    private var photoURLs: [String] {
        messages.map { message in
            message.photoURLs
        }.flatMap { $0 }
    }
    
    private func nextMessageIsSame(message: Message) -> (Bool, Bool) {
        if let nextMessage = messages.first(where: { nextMessage in
            nextMessage.timestamp.dateValue() > message.timestamp.dateValue()
        }) {
            if nextMessage.from == message.from {
                let timeInterval = nextMessage.timestamp.dateValue().timeIntervalSince(message.timestamp.dateValue())
                
                return (timeInterval < 60, true)
            }
        }
        
        return (false, false)
    }
    
    private var messageBar: some View {
        HStack(alignment: .bottom) {
            Menu {
                Button {
                    self.showCameraPicker.toggle()
                } label: {
                    Label {
                        Text("Camera")
                    } icon: {
                        Image(systemName: "camera")
                            .font(.title2)
                            .foregroundStyle(Color.secondary)
                            .padding(.bottom, 5)
                    }
                }
                
                Button {
                    self.showPhotoLibraryPicker.toggle()
                } label: {
                    Label {
                        Text("Photo Library")
                    } icon: {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(Color.secondary)
                            .padding(.bottom, 5)
                    }
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.white, Color(.secondarySystemBackground))
                    .padding(.bottom, 2.5)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                if !discussionModel.images.isEmpty {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(discussionModel.images) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .overlay(alignment: .topTrailing) {
                                        Button {
                                            withAnimation(.easeInOut) {
                                                if let index = discussionModel.images.firstIndex(where: { checkImage in
                                                    checkImage == image
                                                }) {
                                                    discussionModel.images.remove(at: index)
                                                    selectedPhotoItems.remove(at: index)
                                                }
                                            }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .symbolRenderingMode(.palette)
                                                .foregroundStyle(Color.primary, Color(.tertiaryLabel))
                                        }.padding(5)
                                    }
                            }
                        }.padding(5)
                    }.scrollIndicators(.hidden)
                    
                    Divider()
                }
                
                HStack(alignment: .bottom) {
                    TextField("Message", text: $discussionModel.message, axis: .vertical)
                        .padding(.horizontal, 10)
                    
                    Spacer()
                    
                    Button {
                        discussionModel.sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.white, Color.blue)
                    }
                }.padding(5)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .background(RoundedRectangle(cornerRadius: 20).stroke(.secondary, lineWidth: 0.5))
        }
        .padding([.horizontal, .bottom])
        .padding(.top, 5)
        .overlay {
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        self.messageBarHeight = geometry.size.height
                    }
                    .onChange(of: geometry.size) { _, _ in
                        self.messageBarHeight = geometry.size.height
                    }
            }
        }
    }
}

struct MessageView: View {
    @StateObject var discussionModel: DiscussionModel
    
    let message: Message
    let nextMessageIsSame: (time: Bool, from: Bool)
    
    @Binding var userProfile: UserProfile?
    
    @Binding var showImageLibrary: String?
    
    let namespace: Namespace.ID
    
    var body: some View {
        HStack {
            let fromUser = message.from == discussionModel.madrassahUser.id
            
            if fromUser {
                Spacer()
            }
            
            HStack(alignment: .top, spacing: 5) {
                let userProfile = discussionModel.userProfiles.first(where: { $0.id == message.from })
                
                if !fromUser && !nextMessageIsSame.time {
                    Button {
                        self.userProfile = userProfile
                    } label: {
                        UserProfilePhoto(photoURL: userProfile?.photoURL)
                    }.padding(.top, 7.5)
                } else if !fromUser {
                    Spacer()
                        .frame(width: 25, height: 25)
                }
                
                VStack(alignment: fromUser ? .trailing : .leading, spacing: 5) {
                    VStack(alignment: fromUser ? .trailing : .leading, spacing: 2.5) {
                        if !message.photoURLs.isEmpty, let photoId = message.photoURLs.first {
                            if #available(iOS 18.0, *) {
                                Images(message: message, photoId: photoId, fromUser: fromUser, showImageLibrary: $showImageLibrary)
                                    .matchedTransitionSource(id: photoId, in: namespace)
                            } else {
                                Images(message: message, photoId: photoId, fromUser: fromUser, showImageLibrary: $showImageLibrary)
                            }
                        }
                        
                        if !message.message.isEmpty {
                            Text(linkifiedText(from: message.message))
                                .multilineTextAlignment(fromUser ? .trailing : .leading)
                                .padding(7.5)
                                .background(fromUser ? Color(.green) : Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(fromUser ? .leading : .trailing, 75)
                        }
                    }
                    
                    if !nextMessageIsSame.time {
                        Group {
                            if !fromUser, let userProfile = userProfile {
                                Text("\(userProfile.username) - \(message.timestamp.string())")
                            } else {
                                Text(message.timestamp.string())
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                        .padding(.horizontal, 7.5)
                    }
                }
            }
            
            if !fromUser {
                Spacer()
            }
        }.padding(.bottom, nextMessageIsSame.from ? 0 : 10)
    }
    
    private func linkifiedText(from text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        if let regex = try? NSRegularExpression(pattern: #"(https?:\/\/[^\s]+)"#, options: []) {
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in matches {
                if let range = Range(match.range, in: text) {
                    let urlString = String(text[range])
                    if let url = URL(string: urlString) {
                        if let attributedRange = attributedString.range(of: urlString) {
                            attributedString[attributedRange].link = url
                            attributedString[attributedRange].foregroundColor = Color(.systemBlue)
                        }
                    }
                }
            }
        }
        
        return attributedString
    }
}

struct Images: View {
    let message: Message
    let photoId: String
    let fromUser: Bool
    
    @Binding var showImageLibrary: String?
    
    var body: some View {
        Button {
            self.showImageLibrary = photoId
        } label: {
            HStack {
                if fromUser {
                    Spacer()
                }
                
                ZStack(alignment: fromUser ? .bottomLeading : .bottomTrailing) {
                    ForEach(Array(message.photoURLs.prefix(4).enumerated()), id: \.offset) { index, photoURL in
                        let rotation = (fromUser ? -3 : 3) * CGFloat(index)
                        
                        WebImage(url: URL(string: photoURL)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 240, height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 15)
                                .frame(width: 240, height: 180)
                                .foregroundStyle(Color(.secondarySystemBackground))
                                .overlay {
                                    if index == 0 {
                                        ProgressView()
                                    }
                                }
                        }
                        .rotationEffect(Angle(degrees: rotation), anchor: fromUser ? .bottomLeading : .bottomTrailing)
                        .zIndex(Double(-index))
                    }
                }
                
                if !fromUser {
                    Spacer()
                }
            }
        }.padding(.top, message.photoURLs.count > 1 ? CGFloat(min(message.photoURLs.count, 4)) * 10 : 0)
    }
}

struct UserProfilePhoto: View {
    let photoURL: URL?
    
    var size: CGFloat = 25
    
    var body: some View {
        WebImage(url: photoURL) { image in
            image
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
        } placeholder: {
            Image(systemName: "person.circle")
                .resizable()
                .scaledToFill()
                .foregroundStyle(Color.gray)
                .fontWeight(.thin)
        }.frame(width: size, height: size)
    }
}

struct ImageLibrary: View {
    let photoURLs: [String]
    let initialPhotoURL: String
    
    @State private var selectedPhotoURL: String?
    @State private var selectedSmallPhotoURL: String?
    
    @State private var showOptions: Bool = true
    
    @State private var success: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                saveButton
            }
            .padding(.horizontal)
            .opacity(showOptions ? 1 : 0)
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(photoURLs, id: \.self) { photoURL in
                            WebImage(url: URL(string: photoURL)) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.horizontal, 5)
                                    .containerRelativeFrame(.horizontal)
                            } placeholder: {
                                
                            }.id(photoURL)
                        }
                    }.scrollTargetLayout()
                }
                .scrollPosition(id: $selectedPhotoURL)
                .scrollTargetBehavior(.paging)
                .scrollIndicators(.hidden)
            }
            
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    Spacer()
                        .frame(width: UIScreen.main.bounds.width / 2 - 16)
                    
                    ForEach(photoURLs, id: \.self) { photoURL in
                        WebImage(url: URL(string: photoURL)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            
                        }
                        .frame(width: 27, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .padding(.horizontal, 2.5)
                        .id(photoURL)
                    }
                    
                    Spacer()
                        .frame(width: UIScreen.main.bounds.width / 2 - 16)
                }.scrollTargetLayout()
            }
            .scrollPosition(id: $selectedSmallPhotoURL, anchor: .center)
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .frame(height: 48)
            .opacity(showOptions ? 1 : 0)
        }
        .onAppear {
            self.selectedPhotoURL = initialPhotoURL
            self.selectedSmallPhotoURL = initialPhotoURL
        }
        .onChange(of: selectedPhotoURL) { _, _ in
            self.selectedSmallPhotoURL = selectedPhotoURL
        }
        .onChange(of: selectedSmallPhotoURL) { _, _ in
            self.selectedPhotoURL = selectedSmallPhotoURL
        }
        .onTapGesture {
            withAnimation {
                self.showOptions.toggle()
            }
        }
        .alert("Image saved to your photo library.", isPresented: $success) {
            
        }
    }
    
    private var saveButton: some View {
        Button {
            if let photoURL = selectedPhotoURL {
                saveImage(photoURL: photoURL)
            }
        } label: {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(.title, weight: .light))
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.accentColor, Material.regular)
        }
    }
    
    private func saveImage(photoURL: String) {
        getUIImage(photoURL: photoURL) { image in
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            
            self.success = true
        }
    }
    
    private func getUIImage(photoURL: String, completion: @escaping (UIImage) -> Void) {
        if let url = URL(string: photoURL) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print(error)
                    return
                }
                
                if let data = data {
                    if let image = UIImage(data: data) {
                        completion(image)
                    }
                }
            }.resume()
        }
    }
}

#Preview {
    DiscussionView(discussionModel: DiscussionModel(mClass: Class(year: 0, gender: "", teacherIds: [], studentIds: []), madrassahUser: Member(user: "", gender: "", year: nil, isTeacher: false, classIds: nil)))
}
