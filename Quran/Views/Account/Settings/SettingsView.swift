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

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var authenticationModel: AuthenticationModel
    @EnvironmentObject private var prayerTimesModel: PrayerTimesModel
    @EnvironmentObject private var quranModel: QuranModel
    @EnvironmentObject private var audioPlayer: AudioPlayer
    
    @Binding var showSettingsView: Bool
    
    @State private var quranModelErrorMessage: String?
    
    @State private var showPassword: Bool = false
    @State private var verificationEmailSent: Bool = false
    @State private var realCode: [String]?
    @State private var confirmSignOut: Bool = false
    
    private enum FocusedField {
        case email, password, username
    }
    
    @FocusState private var focusedField: FocusedField?
    
    @State private var editMode: Bool = false
    
    @State private var imageToResize: UIImage?
    
    @State private var reauthenticationAction: ReauthenticateView.ReauthenticateAction?
    
    @AppStorage("prayerNotifications") private var prayerNotificationsString: String = ""
    
    var prayerNotifications: [String : Bool] {
        get {
            if let data = prayerNotificationsString.data(using: .utf8) {
                return (try? JSONDecoder().decode([String : Bool].self, from: data)) ?? [:]
            }
            
            return [:]
        }
    }
    
    private let renamedPrayers: [String] = ["Fajr", "Sunrise", "Zuhr", "Sunset", "Maghrib"]
    
    @AppStorage("fontSize") private var fontSize: Double = 40.0
    @AppStorage("fontNumber") private var fontNumber: Int = 1
    
    @AppStorage("translatorId") private var translatorId: Int = 131
    @AppStorage("translationLanguage") private var translationLanguage: String = "en"
    
    @AppStorage("reciterName") private var reciterName: String = "Alafasy"
    @AppStorage("reciterSubfolder") private var reciterSubfolder: String = "Alafasy_128kbps"
    
    @State private var showAllTranslators: Bool = false
    @State private var translatorsSearchText: String = ""
    
    private let wbwLanguageCodes: [String : String] = ["bengali" : "bn", "german" : "de", "english" : "en", "persian" : "fa", "hindi" : "hi", "indonesian" : "id", "russian" : "ru", "tamil" : "ta", "turkish" : "tr", "urdu" : "ur"]
    
    @State private var showAllReciters: Bool = false
    @State private var recitersSearchText: String = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if authenticationModel.loading {
                    ProgressView()
                } else {
                    ScrollView {
                        LazyVStack {
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
            .navigationDestination(item: $reauthenticationAction) { _ in
                ReauthenticateView(reauthenticationAction: $reauthenticationAction)
            }
            .sheet(isPresented: $verificationEmailSent) {
                if let realCode = realCode {
                    EmailCodeView(verificationEmailSent: $verificationEmailSent, realCode: realCode)
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
        }
        .onAppear {
            authenticationModel.error = ""
            authenticationModel.loading = false
            
            audioPlayer.colorScheme = colorScheme
        }
        .onChange(of: colorScheme) { _, _ in
            audioPlayer.colorScheme = colorScheme
        }
        .onChange(of: quranModel.errorMessage) {
            if let errorMessage = quranModel.errorMessage {
                self.quranModelErrorMessage = errorMessage
            }
        }
        .onDisappear {
            authenticationModel.error = ""
            authenticationModel.loading = false
            
            audioPlayer.resetPlayer()
        }
        .confirmationDialog("", isPresented: $confirmSignOut) {
            Button(role: .destructive) {
                authenticationModel.signOut()
            } label: {
                Text("Sign Out")
            }
        } message: {
            Text("Are you sure you want to sign out of your account?")
        }
        .alert(item: $quranModelErrorMessage) { errorMessage in
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
                
                errorMessage
                
                email
                
                Divider()
            }
            
            prayerNotificationsToggles
            preferences
            
            signOutButton
            
            Divider()
            
            accountManagementButtons
            
//            Divider()
//            
//            attributions
        }
    }
    
    @ViewBuilder
    private var updatePhotoPicker: some View {
        HStack {
            Spacer()
            
            PhotosPicker(selection: $authenticationModel.photoItem, matching: .images) {
                let photoImage = authenticationModel.photoImage
                let photoURL = authenticationModel.user?.photoURL
                
                Group {
                    if let photoImage = photoImage {
                        Image(uiImage: photoImage)
                            .resizable()
                            .scaledToFill()
                    } else if let photoURL = photoURL {
                        WebImage(url: photoURL)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "person.circle")
                            .resizable()
                            .scaledToFit()
                            .fontWeight(.ultraLight)
                    }
                }
                .frame(height: 200)
                .clipShape(Circle())
                .overlay {
                    if photoImage != nil || photoURL != nil {
                        Circle().stroke(lineWidth: 2.5)
                    }
                }
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
                
                SwiftyCropView(imageToCrop: image, maskShape: .circle, configuration: configuration) { croppedImage in
                    authenticationModel.photoImage = croppedImage
                    authenticationModel.photoItem = nil
                    imageToResize = nil
                }
            }
            .disabled(editMode == false)
            
            Spacer()
        }
        .overlay(alignment: .topTrailing) {
            editButton
        }
        
        if authenticationModel.photoImage != nil {
            Button {
                authenticationModel.updatePhoto()
            } label: {
                Text("Update Photo")
                    .bold()
            }.buttonStyle(BorderedButtonStyle())
        }
    }
    
    private var editButton: some View {
        Button {
            editMode.toggle()
            authenticationModel.resetFields()
        } label: {
            if editMode {
                Text("Done")
                    .bold()
            } else {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .bold()
            }
        }
    }
    
    @ViewBuilder
    private var username: some View {
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
    
    @ViewBuilder
    private var email: some View {
        if let email = authenticationModel.user?.email {
            Text(email)
                .font(.system(.title3, weight: .bold))
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var accountManagementButtons: some View {
        VStack {
            updateEmailButton
            updatePasswordButton
            deleteAccountButton
        }
        .multilineTextAlignment(.leading)
        .padding(.vertical, 10)
    }
    
    private var updateEmailButton: some View {
        Button {
            self.reauthenticationAction = .updateEmail
        } label: {
            HStack {
                Text("Update Email")
                
                Spacer()
            }
            .font(.headline)
            .padding(15)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    private var updatePasswordButton: some View {
        Button {
            self.reauthenticationAction = .updatePassword
        } label: {
            HStack {
                Text("Update Password")
                
                Spacer()
            }
            .font(.headline)
            .padding(15)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    private var deleteAccountButton: some View {
        Button {
            self.reauthenticationAction = .deleteAccount
        } label: {
            HStack {
                Text("Delete Account")
                
                Spacer()
                
                Image(systemName: "trash")
            }
            .font(.headline)
            .foregroundStyle(Color.red)
            .padding(15)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    private var signOutButton: some View {
        Button {
            self.confirmSignOut = true
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
            
//            Divider()
//            
//            attributions
        }
    }

    private var createAccountModePicker: some View {
        Picker("", selection: $authenticationModel.createAccountMode) {
            Text("Sign In")
                .tag(false)
            
            Text("Create Account")
                .tag(true)
        }.pickerStyle(.segmented)
    }

    private var photoPicker: some View {
        Group {
            if authenticationModel.createAccountMode {
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
                        authenticationModel.photoItem = nil
                        imageToResize = nil
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
            .focused($focusedField, equals: .email)
            .onSubmit {
                focusedField = .password
            }
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
        .focused($focusedField, equals: .password)
        .onSubmit {
            focusedField = .username
        }
    }
    
    @ViewBuilder
    private var usernameField: some View {
        if authenticationModel.createAccountMode {
            Spacer()
                .frame(height: 25)
            
            TextField("Username", text: $authenticationModel.username)
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($focusedField, equals: .username)
        }
    }

    private var loginButton: some View {
        Button {
            if authenticationModel.createAccountMode {
                authenticationModel.createAccountEmailVerification { code, success in
                    self.realCode = code
                    self.verificationEmailSent = true
                }
            } else {
                authenticationModel.signIn()
            }
        } label: {
            Text(authenticationModel.createAccountMode ? "Create Account" : "Sign In")
                .bold()
        }.buttonStyle(BorderedButtonStyle())
    }
    
    @ViewBuilder
    private var errorMessage: some View {
        if authenticationModel.error != "" {
            Text(authenticationModel.error)
                .foregroundStyle(Color.red)
                .multilineTextAlignment(.center)
                .font(.caption)
            
            if authenticationModel.createAccountMode {
                Spacer()
                    .frame(height: 25)
            }
        }
    }
    
    private var prayerNotificationsToggles: some View {
        LazyVStack(spacing: 10) {
            ForEach(Array(prayerNotifications.keys.sorted(by: {
                if let index1 = renamedPrayers.firstIndex(of: $0), let index2 = renamedPrayers.firstIndex(of: $1) {
                    return index1 < index2
                }
                
                return true
            })), id: \.self) { prayer in
                Toggle(isOn: binding(for: prayer)) {
                    Text(prayer)
                        .bold()
                }
            }
        }
        .onChange(of: prayerNotificationsString) { _, _ in
            NotificationManager.shared.updatePrayerNotifications()
        }
        .padding()
    }
    
    private func binding(for key: String) -> Binding<Bool> {
        return Binding(
            get: { self.prayerNotifications[key, default: false] },
            set: {
                var currentPrayerNotifications = prayerNotifications
                currentPrayerNotifications[key] = $0
                
                updatePrayerNotifications(with: currentPrayerNotifications)
            }
        )
    }
    
    private func updatePrayerNotifications(with newValue: [String: Bool]) {
        if let data = try? JSONEncoder().encode(newValue), let json = String(data: data, encoding: .utf8) {
            prayerNotificationsString = json
        }
    }
    
    private var translatorLanguage: String {
        if let translator = quranModel.translators.first(where: { translator in
            translator.id == translatorId
        }) {
            if let languageCode = wbwLanguageCodes[translator.language_name] {
                return languageCode
            }
        }
        
        return "en"
    }
    
    private var preferences: some View {
        LazyVStack(spacing: 20) {
            fontPreferences
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
    
    private var fontPreferences: some View {
        VStack(spacing: 20) {
            fontSizeSlider
            fontPicker
        }
    }
    
    private var fontSizeSlider: some View {
        VStack(spacing: 5) {
            Text("Arabic Font Size: \(Int(fontSize))")
                .font(.system(.headline, weight: .bold))
            
            Slider(value: $fontSize, in: 20...60, step: 1.0)
                .padding(.vertical, 10)
            
            let defaultFont = Font.system(size: CGFloat(fontSize), weight: .bold)
            let uthmanicFont = Font.custom("KFGQPCUthmanicScriptHAFS", size: CGFloat(fontSize))
            let notoNastaliqFont = Font.custom("NotoNastaliqUrdu", size: CGFloat(fontSize))
            
            let font = fontNumber == 1 ? defaultFont : fontNumber == 2 ? uthmanicFont : notoNastaliqFont
            
            Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
                .font(font)
                .multilineTextAlignment(.center)
                .lineSpacing(20)
        }
    }
    
    private var fontPicker: some View {
        HStack {
            Text("Arabic Font:")
                .font(.system(.headline, weight: .bold))
            
            Menu {
                Button {
                    fontNumber = 1
                } label: {
                    HStack {
                        Text("Default")
                        
                        Spacer()
                        
                        if fontNumber == 1 {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button {
                    fontNumber = 2
                } label: {
                    HStack {
                        Text("Uthmanic Hafs")
                        
                        Spacer()
                        
                        if fontNumber == 2 {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button {
                    fontNumber = 3
                } label: {
                    HStack {
                        Text("Noto Nastaliq")
                        
                        Spacer()
                        
                        if fontNumber == 3 {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                Text(fontNumber == 1 ? "Default" : fontNumber == 2 ? "Uthmanic Hafs" : "Noto Nastaliq")
            }
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
                translator.id == translatorId
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
                quranModel.checkLocalTranslation(translatorId: Int(translator.id)) {
                    translatorId = translator.id
                    translationLanguage = translatorLanguage
                    
                    quranModel.checkLocalWBWTranslation(wbwTranslationId: translatorLanguage)
                    
                    quranModel.errorMessage = "You may need to relaunch the app in order for the changes to take place."
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
                reciter.subfolder == reciterSubfolder
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
                reciterName = reciter.name
                reciterSubfolder = reciter.subfolder
                
                if let audioUrl = URL(string: "https://everyayah.com/data/\(reciter.subfolder)/001001.mp3") {
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
    
    private var attributions: some View {
        LazyVStack(alignment: .leading, spacing: 7.5) {
            Text("Quran Arabic and recitations from: [Tanzil.net](https://tanzil.net)")
            Text("Quran translations from: [Quran.com](https://quran.com)")
            Text("Du'as and Ziaraah text and audio from: [Duas.org](https://duas.org)")
            Text("Prayer times and Islamic calendar in accordance with: [Najaf.org](https://najaf.org)")
            
            Text("Quran icon by UNKNOWN from [Noun Project](https://thenounproject.com) (CC BY 3.0)")
            Text("Calendar icon by Azzam from [Noun Project](https://thenounproject.com) (CC BY 3.0)")
            Text("Events icon by ARISO from [Noun Project](https://thenounproject.com) (CC BY 3.0)")
            Text("Du'as icon by Fahmi Ginanjar from [Noun Project](https://thenounproject.com) (CC BY 3.0)")
            Text("Ziaraah icon by Alfan Zulkarnain from [Noun Project](https://thenounproject.com) (CC BY 3.0)")
            Text("Amaal icon by Trotoart from [Noun Project](https://thenounproject.com) (CC BY 3.0)")
            Text("Tasbeeh icon by Nur Abdillah from [Noun Project](https://thenounproject.com) (CC BY 3.0)")
            Text("Qibla icon by arista septiana dewi from [Noun Project](https://thenounproject.com) (CC BY 3.0)")
            Text("Questions icon by Seochan from [Noun Project](https://thenounproject.com) (CC BY 3.0)")
            Text("Donations icon by David Khai from [Noun Project](https://thenounproject.com) (CC BY 3.0)")
            Text("Favroites icon by Iconiqu from [Noun Project](https://thenounproject.com) (CC BY 3.0)")
            Text("Socials icon by sureya from [Noun Project](https://thenounproject.com) (CC BY 3.0)")
        }
        .multilineTextAlignment(.leading)
        .padding(.vertical, 10)
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
        .environmentObject(QuranModel())
}
