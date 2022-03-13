//
//  KSAudioPlayer.swift
//  KSAudioPlayer
//
//  Created by Kuziboev Siddikjon on 3/10/22.
//

import Foundation
import AVFoundation


@objc public protocol FRadioPlayerDelegate: AnyObject {
    /**
     Called when player changes state
     
     - parameter player: FRadioPlayer
     - parameter state: FRadioPlayerState
     */
    func radioPlayer(_ player: KSAudioPlayer, playerStateDidChange state: FRadioPlayerState)
    
    /**
     Called when the player changes the playing state
     
     - parameter player: FRadioPlayer
     - parameter state: FRadioPlaybackState
     */
    func radioPlayer(_ player: KSAudioPlayer, playbackStateDidChange state: FRadioPlaybackState)
    
    /**
     Called when player changes the current player item
     
     - parameter player: FRadioPlayer
     - parameter url: Radio URL
     */
    @objc optional func radioPlayer(_ player: KSAudioPlayer, itemDidChange url: URL?)
    
    /**
     Called when player item changes the timed metadata value, it uses (separatedBy: " - ") to get the artist/song name, if you want more control over the raw metadata, consider using `metadataDidChange rawValue` instead
     
     - parameter player: FRadioPlayer
     - parameter artistName: The artist name
     - parameter trackName: The track name
     */
    @objc optional func radioPlayer(_ player: KSAudioPlayer, metadataDidChange artistName: String?, trackName: String?)
    
    /**
     Called when player item changes the timed metadata value
     
     - parameter player: FRadioPlayer
     - parameter rawValue: metadata raw value
     */
    @objc optional func radioPlayer(_ player: KSAudioPlayer, metadataDidChange rawValue: String?)
    
    /**
     Called when the player gets the artwork for the playing song
     
     - parameter player: FRadioPlayer
     - parameter artworkURL: URL for the artwork from iTunes
     */
    @objc optional func radioPlayer(_ player: KSAudioPlayer, artworkDidChange artworkURL: URL?)
    
    
}



@objc public enum FRadioPlaybackState: Int {
    
    /// Player is playing
    case playing
    
    /// Player is paused
    case paused
    
    /// Player is stopped
    case stopped
    
    /// Return a readable description
    public var description: String {
        switch self {
        case .playing: return "Player is playing"
        case .paused: return "Player is paused"
        case .stopped: return "Player is stopped"
        }
    }
}

// MARK: - FRadioPlayerState

/**
 `FRadioPlayerState` is the Player status enum
 */

@objc public enum FRadioPlayerState: Int {
    
    /// URL not set
    case urlNotSet
    
    /// Player is ready to play
    case readyToPlay
    
    /// Player is loading
    case loading
    
    /// The loading has finished
    case loadingFinished
    
    /// Error with playing
    case error
    
    /// Return a readable description
    public var description: String {
        switch self {
        case .urlNotSet: return "URL is not set"
        case .readyToPlay: return "Ready to play"
        case .loading: return "Loading"
        case .loadingFinished: return "Loading finished"
        case .error: return "Error"
        }
    }
}




open class KSAudioPlayer: NSObject {
    
    // MARK: - Properties
    public static let shared = KSAudioPlayer()
    
    open var audioURL: URL? {
        didSet {
            audioURLDidChange(with: audioURL)
        }
    }
    
    var player: AVPlayer?
    
    private var lastPlayerItem: AVPlayerItem?
    
    var station: AudioDM?
    
    fileprivate let seekDuration: Float64 = 10
    
    
    private var playerItem: AVPlayerItem?{
        didSet {
            playerItemDidChange()
        }
    }
    
    open weak var delegate: FRadioPlayerDelegate?
    
    
    /// Check if the player is playing
    open var isPlaying: Bool {
        switch playbackState {
        case .paused , .stopped :
            return false
        case .playing :
            return true
        }
    }
    
    /// Player current state of type `FRadioPlayerState`
    open private(set) var state = FRadioPlayerState.urlNotSet {
        didSet {
            guard oldValue != state else { return }
            delegate?.radioPlayer(self, playerStateDidChange: state)
        }
    }
    
    /// Playing state of type `FRadioPlaybackState`
    open private(set) var playbackState = FRadioPlaybackState.stopped {
        didSet {
            guard oldValue != playbackState else { return }
            delegate?.radioPlayer(self, playbackStateDidChange: playbackState)
        }
    }
    
    
    
    private override init() {
        super.init()
        
        // Enable bluetooth playback
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default, options: [.defaultToSpeaker, .allowBluetooth, .allowAirPlay])
    }
    
    //    // MARK: - Private helpers
    private func audioURLDidChange(with url: URL?) {
        resetPlayer()
        guard let url = url else {state = .urlNotSet; return }
        state = .loading
        setupPlayer(url: url)
    }
    
    private func setupPlayer(url: URL) {
        if player == nil {
            player = AVPlayer()
            //Removes black screen when connecting to appleTV
            player?.allowsExternalPlayback = false
        }
        
        saveAudioToFile(url) { savedUrl, isFileExsist in
            self.playerItem = AVPlayerItem(url: savedUrl!)
            NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "saved_ksaudio"), object: isFileExsist)
            
        }
    }
    
    private func playerItemDidChange() {
        guard lastPlayerItem != playerItem else { return }
        
        if let item = lastPlayerItem {
            pause()
        }
        
        lastPlayerItem = playerItem
        
        if let item = playerItem {
            player?.replaceCurrentItem(with: item)
            play()
        }
        
        delegate?.radioPlayer?(self, itemDidChange: audioURL)
    }
    
    
    open func getCurrentTime()-> CMTime? {
        guard let player = player else { return nil }
        return player.currentTime()
    }
    
    open func getAssetDuration()-> CMTime? {
        guard let player = player else { return nil }
        return player.currentItem?.asset.duration
    }
    //MARK: play pause next back
    func play() {
        guard let player = player else { return }
        if player.currentItem == nil, playerItem != nil {
            player.replaceCurrentItem(with: playerItem)
        }
        
        player.play()
        playbackState = .playing
    }
    
    open func pause() {
        guard let player = player else { return }
        player.pause()
        playbackState = .paused
        
    }
    
    func resetPlayer() {
        stop()
        playerItem = nil
        lastPlayerItem = nil
        player = nil
    }
    
    open func stop() {
        guard let player = player else { return }
        player.replaceCurrentItem(with: nil)
        playbackState = .stopped
        
    }
    
    open func transferForward() {
        if player == nil { return }
        if let duration  = player!.currentItem?.duration {
            let playerCurrentTime = CMTimeGetSeconds(player!.currentTime())
            let newTime = playerCurrentTime + seekDuration
            if newTime < CMTimeGetSeconds(duration)
            {
                let selectedTime: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
                player!.seek(to: selectedTime)
            }
            player?.pause()
            player?.play()
        }
    }
    
    open func transferBack() {
        if player == nil { return }
        let playerCurrenTime = CMTimeGetSeconds(player!.currentTime())
        var newTime = playerCurrenTime - seekDuration
        if newTime < 0 { newTime = 0 }
        player?.pause()
        let selectedTime: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
        player?.seek(to: selectedTime)
        player?.play()
    }
    
    open func togglePlaying() {
        isPlaying ? pause() : play()
    }
    
    // MARK: - KVO
    
    /// :nodoc:
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if let item = object as? AVPlayerItem, let keyPath = keyPath, item == self.playerItem {
            
            switch keyPath {
                
            case "status":
                
                if player?.status == AVPlayer.Status.readyToPlay {
                    self.state = .readyToPlay
                } else if player?.status == AVPlayer.Status.failed {
                    self.state = .error
                }
                
            case "playbackBufferEmpty":
                
                if item.isPlaybackBufferEmpty {
                    self.state = .loading
                }
                
            case "playbackLikelyToKeepUp":
                
                self.state = item.isPlaybackLikelyToKeepUp ? .loadingFinished : .loading
                
            default:
                break
            }
        }
    }
    
    deinit {
        resetPlayer()
        NotificationCenter.default.removeObserver(self)
    }
    
}

//MARK: -File Saved
extension KSAudioPlayer {
    
    func saveAudioToFile(_ audioFile: URL, completion: @escaping (URL?, Bool) -> Void) {
        let documentsURL = try!
        FileManager.default.url(for: .documentDirectory,
                                   in: .userDomainMask,
                                   appropriateFor: nil,
                                   create: false)
        let savedURL = documentsURL.appendingPathComponent(audioFile.lastPathComponent)
        ///For time slider
        if isFileExsist(with: savedURL.path) {
            print("The file already exists at path")
            state = .readyToPlay
            completion(savedURL, true)
            
        } else {
            state = .loading
            //  if the file doesn't exist
            //  just download the data from your url
            DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async(execute: {
                if let myAudioDataFromUrl = try? Data(contentsOf: audioFile){
                    // after downloading your data you need to save it to your destination url
                    if (try? myAudioDataFromUrl.write(to: savedURL, options: [.atomic])) != nil {
                        print("file saved")
                        self.state = .readyToPlay
                        
                        completion(savedURL, false)
                    } else {
                        print("error saving file")
                        completion(nil, false)
                    }
                }
            })
        }
        
        
    }
    
    func isFileExsist(with path: String)-> Bool {
        return FileManager().fileExists(atPath: path)
    }
    
}

