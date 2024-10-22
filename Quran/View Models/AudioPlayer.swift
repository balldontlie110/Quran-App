//
//  AudioPlayer.swift
//  Quran
//
//  Created by Ali Earp on 15/07/2024.
//

import SwiftUI
import AVFoundation
import MediaPlayer
import Combine

class AudioPlayer: ObservableObject {
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isPlaying = false
    @Published var currentTime: Double = 0.0
    @Published var duration: Double = 0.0
    
    @Published var url: URL?
    @Published var verse: Verse?
    @Published var showAudioPlayerSlider: Bool = true
    
    @Published var surahNumber: String?
    @Published var surahName: String?
    @Published var nextVerse: ((Verse) -> Verse?)?
    @Published var previousVerse: ((Verse) -> Verse?)?
    @Published var reciterSubfolder: String?
    
    private var pauseTarget: Any?
    private var playTarget: Any?
    private var nextVerseTarget: Any?
    private var previousVerseTarget: Any?
    
    @Published var colorScheme: ColorScheme?
    
    func setupPlayer(with url: URL, verse: Verse? = nil) {
        showAudioPlayerSlider = true
        
        if isPlaying {
            playPause()
        }
        
        self.url = url
        self.verse = verse
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        playerItem?.publisher(for: \.duration)
            .compactMap { $0.seconds.isFinite ? $0.seconds : nil }
            .assign(to: \.duration, on: self)
            .store(in: &cancellables)
        
        timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 10), queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
        
        setMediaPlayerControls()
        setNowPlayingInfo()
        
        NotificationCenter.default.addObserver(self, selector: #selector(audioDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    func playPause() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
            
            isPlaying = false
        } else {
            player.play()
            
            isPlaying = true
        }
    }
    
    private func setMediaPlayerControls() {
        pauseTarget = MPRemoteCommandCenter.shared().pauseCommand.addTarget { event in
            self.playPause()
            
            return .success
        }
        
        playTarget = MPRemoteCommandCenter.shared().playCommand.addTarget { event in
            self.playPause()
            
            return .success
        }
        
        nextVerseTarget = MPRemoteCommandCenter.shared().nextTrackCommand.addTarget { event in
            self.skipToVerse(forwards: true)
            
            return .success
        }
        
        previousVerseTarget = MPRemoteCommandCenter.shared().previousTrackCommand.addTarget { event in
            self.skipToVerse(forwards: false)
            
            return .success
        }
    }
    
    private func removeMediaCommandTargets() {
        MPRemoteCommandCenter.shared().pauseCommand.removeTarget(pauseTarget)
        MPRemoteCommandCenter.shared().playCommand.removeTarget(playTarget)
        MPRemoteCommandCenter.shared().nextTrackCommand.removeTarget(nextVerseTarget)
        MPRemoteCommandCenter.shared().previousTrackCommand.removeTarget(previousVerseTarget)
    }
    
    private func setNowPlayingInfo() {
        if let surahNumber = surahNumber, let surahName = surahName, let verse = verse {
            let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
            var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
            
            let title = surahName
            let details = "\(surahNumber):\(verse.id)"
            
            if let image = UIImage(named: "hyderi-\(colorScheme == .dark ? "dark" : "light")") {
                let artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: {  (_) -> UIImage in
                    return image
                })
                
                nowPlayingInfo[MPMediaItemPropertyTitle] = title
                nowPlayingInfo[MPMediaItemPropertyArtist] = details
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                
                nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
            }
        }
    }
    
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 10)
        player?.seek(to: cmTime)
    }
    
    @objc private func audioDidFinishPlaying() {
        isPlaying = false
        player?.seek(to: CMTime.zero)
        
        if UserDefaultsController.shared.bool(forKey: "continuePlaying") {
            guard let verse = self.verse,
                  let nextVerse = nextVerse?(verse),
                  let reciterSubfolder = reciterSubfolder,
                  let audioUrl = URL(string: "https://everyayah.com/data/\(reciterSubfolder)/\(nextVerse.audio).mp3")
            else { return }
            
            self.setupPlayer(with: audioUrl, verse: nextVerse)
            self.playPause()
        }
        
        removeMediaCommandTargets()
    }
    
    private func skipToVerse(forwards: Bool) {
        guard let verse = self.verse,
              let newVerse = forwards ? nextVerse?(verse) : previousVerse?(verse),
              let reciterSubfolder = reciterSubfolder,
              let audioUrl = URL(string: "https://everyayah.com/data/\(reciterSubfolder)/\(newVerse.audio).mp3")
        else { return }
        
        self.setupPlayer(with: audioUrl, verse: newVerse)
        self.playPause()
        
        removeMediaCommandTargets()
    }
    
    func resetPlayer() {
        player?.pause()
        player?.seek(to: CMTime.zero)
        isPlaying = false
        currentTime = 0.0
        duration = 0.0
        url = nil
        player = nil
        playerItem = nil
    }
    
    deinit {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        
        NotificationCenter.default.removeObserver(self)
    }
}
