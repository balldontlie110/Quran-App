//
//  SettingsView.swift
//  Quran
//
//  Created by Ali Earp on 30/06/2024.
//

import SwiftUI
import FirebaseAuth
import PhotosUI
import SDWebImageSwiftUI
import SwiftyCrop

struct Prayer: Identifiable {
    var id: String { prayer }
    
    let prayer: String
    var active: Bool
}

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject private var authenticationModel: AuthenticationModel = AuthenticationModel()
    @EnvironmentObject private var preferencesModel: PreferencesModel
    @EnvironmentObject private var quranModel: QuranModel
    @StateObject private var audioPlayer: AudioPlayer = AudioPlayer()
    
    @Binding var showSettingsView: Bool
    
    @State private var createAccountMode: Bool = false
    @State private var showPassword: Bool = false
    
    @State private var editMode: Bool = false
    
    @State private var imageToResize: UIImage?
    
    @State private var prayers: [Prayer] = [
        Prayer(prayer: "Fajr", active: false),
        Prayer(prayer: "Sunrise", active: false),
        Prayer(prayer: "Zuhr", active: false),
        Prayer(prayer: "Sunset", active: false),
        Prayer(prayer: "Maghrib", active: false)
    ]
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PrayerNotification.prayer, ascending: true)],
        animation: .default
    )
    
    private var prayerNotifications: FetchedResults<PrayerNotification>
    
    @State private var fontSize: Double = 0.0
    
    @State private var translatorId: Int = 0
    @State private var showAllTranslators: Bool = false
    @State private var translatorsSearchText: String = ""
    
    @State private var reciterName: String = ""
    @State private var reciterSubfolder: String = ""
    @State private var showAllReciters: Bool = false
    @State private var recitersSearchText: String = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if authenticationModel.loading {
                    ProgressView()
                } else {
                    ScrollView {
                        VStack {
                            if authenticationModel.user == nil {
                                loginOptions
                            } else {
                                accountOptions
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    doneButton
                }
            }
        }
        .onChange(of: authenticationModel.user) { _, _ in
            authenticationModel.resetFields()
            
            if let username = authenticationModel.user?.displayName {
                authenticationModel.username = username
            }
        }
        .onAppear {
            initialisePrayerNotifications()
            initialisePreferences()
        }
        .onDisappear {
            audioPlayer.resetPlayer()
        }
        .alert(item: $quranModel.errorMessage) { errorMessage in
            Alert(title: Text(errorMessage))
        }
    }
    
    private var doneButton: some View {
        Button {
            self.showSettingsView = false
        } label: {
            Text("Done")
                .bold()
        }
    }
    
    private var accountOptions: some View {
        Group {
            VStack(spacing: 20) {
                updatePhotoPicker
                username
                editButton
                
                Divider()
            }
            
            prayerNotificationsToggles
            preferences
            
            signOutButton
            
            Divider()
            
            tanzilLicense
        }
    }

    private var updatePhotoPicker: some View {
        Group {
            if let user = authenticationModel.user {
                if let photoURL = user.photoURL {
                    PhotosPicker(selection: $authenticationModel.photoItem, matching: .images) {
                        Group {
                            if let photoImage = authenticationModel.photoImage {
                                Image(uiImage: photoImage)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                WebImage(url: photoURL)
                                    .resizable()
                                    .scaledToFill()
                            }
                        }
                        .frame(height: 200)
                        .clipShape(Circle())
                        .overlay { Circle().stroke(lineWidth: 2.5) }
                        .frame(width: 200, height: 200)
                        .foregroundStyle(editMode ? Color.accentColor : Color.primary)
                    }
                    .onChange(of: authenticationModel.photoItem) { _, _ in
                        Task {
                            if let data = try await authenticationModel.photoItem?.loadTransferable(type: Data.self) {
                                imageToResize = UIImage(data: data)
                                authenticationModel.resetFields()
                            }
                        }
                    }
                    .fullScreenCover(item: $imageToResize) { image in
                        let configuration = SwiftyCropConfiguration(maxMagnificationScale: 2.0, cropImageCircular: false, rotateImage: false)
                        
                        SwiftyCropView(imageToCrop: image, maskShape: .square, configuration: configuration) { croppedImage in
                            authenticationModel.photoImage = croppedImage
                            imageToResize = nil
                        }
                    }
                    .disabled(editMode == false)
        
                    if authenticationModel.photoImage != nil {
                        Button {
                            authenticationModel.updatePhoto()
                        } label: {
                            Text("Update Photo")
                                .bold()
                        }.buttonStyle(BorderedButtonStyle())
                    }
                }
            }
        }
    }

    private var username: some View {
        Group {
            TextField("", text: $authenticationModel.username)
                .font(.system(.title, weight: .bold))
                .foregroundStyle(editMode ? Color.accentColor : Color.primary)
                .multilineTextAlignment(.center)
                .disabled(editMode == false)
            
            if authenticationModel.username != authenticationModel.user?.displayName {
                Button {
                    authenticationModel.updateUsername()
                } label: {
                    Text("Update Username")
                        .bold()
                }.buttonStyle(BorderedButtonStyle())
            }
        }
    }
    
    private var editButton: some View {
        Button {
            editMode.toggle()
            authenticationModel.resetFields()
        } label: {
            if editMode {
                Text("Done")
            } else {
                HStack {
                    Text("Edit")
                    
                    Image(systemName: "pencil")
                }
            }
        }
        .bold()
        .buttonStyle(BorderedButtonStyle())
    }

    private var signOutButton: some View {
        Button {
            authenticationModel.signOut()
        } label: {
            Text("Sign Out")
                .bold()
                .foregroundStyle(Color.red)
        }
        .buttonStyle(BorderedButtonStyle())
        .padding(.bottom, 10)
    }
    
    private var loginOptions: some View {
        Group {
            createAccountModePicker
            photoPicker
            
            Spacer()
                .frame(height: 25)
            
            emailField
            passwordField
            usernameField
            
            Spacer()
                .frame(height: 25)
            
            loginButton
            
            Spacer()
                .frame(height: 25)
            
            errorMessage
            
            Divider()
            
            prayerNotificationsToggles
            preferences
            
            Divider()
            
            tanzilLicense
        }
    }

    private var createAccountModePicker: some View {
        Picker("", selection: $createAccountMode) {
            Text("Sign In")
                .tag(false)
            
            Text("Create Account")
                .tag(true)
        }.pickerStyle(.segmented)
    }

    private var photoPicker: some View {
        Group {
            if createAccountMode {
                Spacer()
                    .frame(height: 25)
                
                PhotosPicker(selection: $authenticationModel.photoItem, matching: .images) {
                    Group {
                        if let photoImage = authenticationModel.photoImage {
                            Image(uiImage: photoImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "person")
                                .resizable()
                                .scaledToFill()
                                .padding(50)
                        }
                    }
                    .clipShape(Circle())
                    .overlay { Circle().stroke(lineWidth: 2.5) }
                    .frame(width: 150, height: 150)
                    .foregroundStyle(Color.primary)
                }
                .onChange(of: authenticationModel.photoItem) { _, _ in
                    Task {
                        if let data = try await authenticationModel.photoItem?.loadTransferable(type: Data.self) {
                            imageToResize = UIImage(data: data)
                        }
                    }
                }
                .fullScreenCover(item: $imageToResize) { image in
                    let configuration = SwiftyCropConfiguration(maxMagnificationScale: 2.0, cropImageCircular: false, rotateImage: false)
                    
                    SwiftyCropView(imageToCrop: image, maskShape: .square, configuration: configuration) { croppedImage in
                        authenticationModel.photoImage = croppedImage
                    }
                }
            }
        }
    }

    private var emailField: some View {
        TextField("Email", text: $authenticationModel.email)
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
    }

    private var passwordField: some View {
        HStack {
            if showPassword {
                TextField("Password", text: $authenticationModel.password)
            } else {
                SecureField("Password", text: $authenticationModel.password)
            }
            
            Spacer()
            
            Button {
                self.showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .foregroundStyle(Color.secondary)
            }

        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private var usernameField: some View {
        Group {
            if createAccountMode {
                Spacer()
                    .frame(height: 25)
                
                TextField("Username", text: $authenticationModel.username)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
    }

    private var loginButton: some View {
        Button {
            if createAccountMode {
                authenticationModel.createAccount()
            } else {
                authenticationModel.signIn()
            }
        } label: {
            Text(createAccountMode ? "Create Account" : "Sign In")
                .bold()
        }.buttonStyle(BorderedButtonStyle())
    }

    private var errorMessage: some View {
        Group {
            if authenticationModel.error != "" {
                Text(authenticationModel.error)
                    .foregroundStyle(Color.red)
                    .multilineTextAlignment(.center)
                    .font(.caption)
            }
        }
    }
    
    private var prayerNotificationsToggles: some View {
        VStack(spacing: 10) {
            ForEach($prayers) { $prayer in
                Toggle(isOn: $prayer.active) {
                    Text(prayer.prayer)
                        .bold()
                }
                .onChange(of: prayer.active) { _, _ in
                    updatePrayerNotification(prayer)
                }
            }
        }.padding()
    }
    
    private var preferences: some View {
        VStack(spacing: 20) {
            fontSizeSlider
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            translatorPicker
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            reciterPicker
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }.padding(.bottom, 10)
    }
    
    private var fontSizeSlider: some View {
        VStack(spacing: 5) {
            Text("Font Size: \(Int(fontSize))")
                .font(.system(.headline, weight: .bold))
            
            Slider(value: $fontSize, in: 20...60, step: 1.0)
                .padding(.vertical, 10)
                .onChange(of: fontSize) { _, _ in
                    preferencesModel.updatePreferences(
                        fontSize: fontSize,
                        translatorId: translatorId,
                        reciterName: reciterName,
                        reciterSubfolder: reciterSubfolder
                    )
                }
            
            Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
                .font(.system(size: fontSize, weight: .bold))
                .multilineTextAlignment(.center)
                .lineSpacing(20)
        }
    }
    
    private var translatorPicker: some View {
        LazyVStack(spacing: 5) {
            VStack(spacing: 10) {
                selectedTranslatorRow
                showTranslatorsListButton
            }
            
            if showAllTranslators {
                LazyVStack(spacing: 10) {
                    translatorsSearchBar
                    translatorsList
                }.padding(.bottom, -5)
            }
        }
    }
    
    private var selectedTranslatorRow: some View {
        VStack(spacing: 5) {
            Text("Translation")
                .font(.system(.headline, weight: .bold))
            
            if let translator = quranModel.translators.first(where: { translator in
                translator.id == Int(preferencesModel.preferences?.translationId ?? 0)
            }) {
                TranslatorRow(translator: translator)
                    .padding(.vertical, 5)
            }
        }
    }
    
    private var showTranslatorsListButton: some View {
        Button {
            self.showAllTranslators.toggle()
        } label: {
            Image(systemName: showAllTranslators ? "chevron.up" : "chevron.down")
                .fontWeight(.bold)
        }
    }
    
    private var translatorsList: some View {
        ForEach(filteredTranslators) { translator in
            Button {
                quranModel.checkLocalTranslation(translationId: Int(translatorId)) {
                    self.translatorId = translator.id
                    
                    preferencesModel.updatePreferences(
                        fontSize: fontSize,
                        translatorId: translatorId,
                        reciterName: reciterName,
                        reciterSubfolder: reciterSubfolder
                    )
                }
            } label: {
                TranslatorRow(translator: translator)
                    .fontWeight(translator.id == translatorId ? .black : .regular)
                    .padding(.vertical, 5)
            }
            
            if translator != filteredTranslators.last {
                Divider()
            }
        }
    }
    
    private var translatorsSearchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.secondary)
            
            TextField("Search", text: $translatorsSearchText)
            
            if translatorsSearchText != "" {
                Button {
                    self.translatorsSearchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .padding(5)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.vertical, 10)
    }
    
    private var reciterPicker: some View {
        LazyVStack(spacing: 5) {
            VStack(spacing: 10) {
                selectedReciterRow
                showRecitersListButton
            }
            
            if showAllReciters {
                LazyVStack(spacing: 10) {
                    recitersSearchBar
                    recitersList
                }.padding(.bottom, -5)
            }
        }
    }
    
    private var selectedReciterRow: some View {
        VStack(spacing: 5) {
            Text("Reciter")
                .font(.system(.headline, weight: .bold))
            
            if let reciter = quranModel.reciters.first(where: { reciter in
                reciter.subfolder == preferencesModel.preferences?.reciterSubfolder ?? ""
            }) {
                Text(reciter.name)
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 5)
            }
        }
    }
    
    private var showRecitersListButton: some View {
        Button {
            self.showAllReciters.toggle()
        } label: {
            Image(systemName: showAllReciters ? "chevron.up" : "chevron.down")
                .fontWeight(.bold)
        }
    }
    
    private var recitersList: some View {
        ForEach(filteredReciters) { reciter in
            Button {
                self.reciterName = reciter.name
                self.reciterSubfolder = reciter.subfolder
                
                preferencesModel.updatePreferences(
                    fontSize: fontSize,
                    translatorId: translatorId,
                    reciterName: reciterName,
                    reciterSubfolder: reciterSubfolder
                )
                
                if let audioUrl = URL(string: "https://everyayah.com/data/\(reciterSubfolder)/001001.mp3") {
                    audioPlayer.setupPlayer(with: audioUrl)
                    audioPlayer.playPause()
                }
            } label: {
                Text(reciter.name)
                    .foregroundStyle(Color.primary)
                    .fontWeight(reciter.subfolder == reciterSubfolder ? .black : .regular)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 5)
            }
            
            if reciter != filteredReciters.last {
                Divider()
            }
        }
    }
    
    private var recitersSearchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.secondary)
            
            TextField("Search", text: $recitersSearchText)
            
            if recitersSearchText != "" {
                Button {
                    self.recitersSearchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .padding(5)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.vertical, 10)
    }
    
    private var tanzilLicense: some View {
        HStack {
            if let tanzilURL = URL(string: "https://tanzil.net") {
                Text("Arabic text sourced from:")
                Link("Tanzil", destination: tanzilURL)
            }
        }.padding(.vertical, 10)
    }
    
    private var filteredTranslators: [Translator] {
        if translatorsSearchText == "" {
            return quranModel.translators
        }
        
        return quranModel.translators.filter { translator in
            if translator.name.lowercased().contains(translatorsSearchText.lowercased()) {
                return true
            }
            
            if translator.author_name.lowercased().contains(translatorsSearchText.lowercased()) {
                return true
            }
            
            if translator.language_name.lowercased().contains(translatorsSearchText.lowercased()) {
                return true
            }
            
            return false
        }
    }
    
    private var filteredReciters: [Reciter] {
        if recitersSearchText == "" {
            return quranModel.reciters
        }
        
        return quranModel.reciters.filter { reciter in
            return reciter.name.lowercased().contains(recitersSearchText.lowercased())
        }
    }
    
    private func initialisePrayerNotifications() {
        for prayerNotification in prayerNotifications {
            if let prayerIndex = prayers.firstIndex(where: { prayer in
                prayer.prayer == prayerNotification.prayer
            }) {
                prayers[prayerIndex].active = prayerNotification.active
            }
        }
    }
    
    private func updatePrayerNotification(_ prayer: Prayer) {
        if let prayerNotification = prayerNotifications.first(where: { prayerNotification in
            prayerNotification.prayer == prayer.prayer
        }) {
            prayerNotification.active = prayer.active
        } else {
            let prayerNotification = PrayerNotification(context: viewContext)
            
            prayerNotification.prayer = prayer.prayer
            prayerNotification.active = prayer.active
        }
        
        do {
            try viewContext.save()
            
            NotificationManager.shared.updateNotifications()
        } catch {
            print(error)
        }
    }
    
    private func initialisePreferences() {
        if let preferences = preferencesModel.preferences {
            self.fontSize = preferences.fontSize
            self.translatorId = Int(preferences.translationId)
            self.reciterName = preferences.reciterName ?? "Ghamadi"
            self.reciterSubfolder = preferences.reciterSubfolder ?? "Ghamadi_40kbps"
        }
    }
}

extension UIImage: @retroactive Identifiable {
    public var id: ObjectIdentifier {
        ObjectIdentifier(self)
    }
}

extension String: @retroactive Identifiable {
    public var id: UUID {
        return UUID()
    }
}

struct TranslatorRow: View {
    let translator: Translator
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), alignment: .top),
        GridItem(.flexible(), alignment: .top)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading) {
            Text("Author: ")
                .foregroundStyle(Color.secondary)
                
            Text(translator.author_name)
            
            
            Text("Language: ")
                .foregroundStyle(Color.secondary)
            
            Text(translator.language_name.capitalized)
        }
        .foregroundStyle(Color.primary)
        .multilineTextAlignment(.center)
    }
}

#Preview {
    SettingsView(showSettingsView: .constant(true))
        .environmentObject(PreferencesModel())
        .environmentObject(QuranModel())
}
