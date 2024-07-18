//
//  AudioPlayer.swift
//  Quran
//
//  Created by Ali Earp on 15/07/2024.
//

import Foundation
import AVFoundation
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
    
    @Published var finished: Bool = false
    @Published var continuePlaying: Bool = false
    
    func setupPlayer(with url: URL, verse: Verse? = nil) {
        finished = false
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
    
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 10)
        player?.seek(to: cmTime)
    }
    
    @objc private func audioDidFinishPlaying() {
        isPlaying = false
        player?.seek(to: CMTime.zero)
        
        if continuePlaying {
            finished = true
        }
    }
    
    func resetPlayer() {
        player?.pause()
        player?.seek(to: CMTime.zero)
        isPlaying = false
        currentTime = 0.0
        duration = 0.0
        url = nil
        finished = false
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
