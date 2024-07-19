//
//  DuaView.swift
//  Quran
//
//  Created by Ali Earp on 14/06/2024.
//

import SwiftUI

struct DuaView: View {
    @EnvironmentObject private var preferencesModel: PreferencesModel
    
    let dua: Dua
    
    @StateObject private var audioPlayer = AudioPlayer()
    @State private var sliderValue: Double = 0.0
    
    @State private var scrollPosition: Int?
    @State private var previousScrollPosition: Int?
    private let dummyId = 0
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(dua.verses) { verse in
                        VStack(spacing: 0) {
                            VStack(spacing: 10) {
                                Text(verse.arabic)
                                    .font(.system(size: CGFloat(preferencesModel.preferences?.fontSize ?? 40.0), weight: .bold))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(20)
                                
                                Text(verse.translation)
                                    .font(.system(size: 20))
                                    .multilineTextAlignment(.center)
                            }.padding(.vertical)
                            
                            if verse.id != dua.verses.count {
                                Divider()
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
                .scrollTargetLayout()
                
                Spacer()
                    .frame(height: 50)
            }
            .scrollPosition(id: $scrollPosition, anchor: .top)
            .onChange(of: scrollPosition) { oldVal, newVal in
                if let newVal, newVal != dummyId {
                    previousScrollPosition = newVal
                }
            }
            .onChange(of: proxy.size) {
                if let previousScrollPosition {
                    scrollPosition = dummyId
                    Task { @MainActor in
                        scrollPosition = previousScrollPosition
                    }
                }
            }
        }
        .navigationTitle(dua.type)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            audioButton
        }
        .overlay(alignment: .bottom) {
            audioPlayerSlider
        }
        .onAppear {
            if let audioURL = Bundle.main.url(forResource: dua.audio, withExtension: "mp3") {
                audioPlayer.setupPlayer(with: audioURL)
            }
        }
        .onChange(of: audioPlayer.currentTime) { newVal, oldVal in
            updateScrollPosition(oldVal: oldVal, newVal: newVal)
        }
        .onDisappear {
            audioPlayer.resetPlayer()
        }
        .onReceive(audioPlayer.$currentTime) { newValue in
            sliderValue = newValue
        }
    }
    
    private var audioButton: some View {
        Button {
            audioPlayer.playPause()
        } label: {
            Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.primary)
        }
    }
    
    private var audioPlayerSlider: some View {
        HStack {
            Text(formatTime(audioPlayer.currentTime))
            
            Slider(value: $sliderValue, in: 0...audioPlayer.duration, onEditingChanged: sliderEditingChanged)
            
            Text(formatTime(audioPlayer.duration))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 5)
        .padding(.horizontal)
    }
    
    private func sliderEditingChanged(editingStarted: Bool) {
        if !editingStarted {
            audioPlayer.seek(to: sliderValue)
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func updateScrollPosition(oldVal: Double, newVal: Double) {
        if Int(newVal) != Int(oldVal) {
            if let nextVerse = dua.verses.last(where: { verse in
                verse.audio <= Int(audioPlayer.currentTime)
            }) {
                if self.scrollPosition != nextVerse.id {
                    scrollPosition = dummyId
                    Task { @MainActor in
                        withAnimation {
                            self.scrollPosition = nextVerse.id
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let duaModel: DuaModel = DuaModel()
    
    if let dua = duaModel.duas.first {
        DuaView(dua: dua)
            .environmentObject(PreferencesModel())
    }
}
