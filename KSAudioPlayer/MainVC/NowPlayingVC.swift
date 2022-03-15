//
//  NowPlayingVC.swift
//  KSAudioPlayer
//
//  Created by Kuziboev Siddikjon on 3/10/22.
//

import UIKit
import AVKit
import MediaPlayer
protocol NowPlayingViewControllerDelegate: AnyObject {
    func didPressPlayingButton()
    func didPressStopButton()
    func didPressNextButton()
    func didPressPreviousButton()
    func didTransferBack()
    func didTransferForward()
}


class NowPlayingVC: UIViewController {
    
    @IBOutlet weak var audioImg: UIImageView!
    @IBOutlet weak var lblDuration: UILabel!
    @IBOutlet weak var lblCurrentTime: UILabel!
    
    @IBOutlet weak var volumeView: UIView!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var audioName: UILabel!
    @IBOutlet weak var playBtn: UIButton!
    
    var newStation = true
    var currentStation: AudioDM!
    let audioPlayer = KSAudioPlayer.shared
    weak var delegate: NowPlayingViewControllerDelegate?
    var mpVolumeSlider: UISlider?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.tintColor = .white
        sliderNotification()
        title = currentStation.name
        setupVolumeSlider()
        newStation ? stationDidChange() : playerStateDidChange(audioPlayer.state, animate: false)
        setUpPlayer()

    }
    
    func sliderNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(sliderSet(_:)), name: NSNotification.Name.init(rawValue: "saved_ksaudio"), object: nil)
    }
    
    @objc func sliderSet(_ notification: NSNotification) {
        if let isSaved = notification.object as? Bool {
            if isSaved {
                
                setUpPlayer()
            }else {
                DispatchQueue.main.async {
                    self.setUpPlayer()
                }
            }
        }
    }
    
    //MARK: Player state
    func playbackStateDidChange(_ playbackState: FRadioPlaybackState, animate: Bool) {
        
        let message: String?
        switch playbackState {
        case .paused:
            message = "Station Pause..."
        case .playing:
            message = nil
        case .stopped:
            message = "Station Stopped..."
        }

        DispatchQueue.main.async {[self] in
           audioName.text = message
           isPlayingDidChange(self.audioPlayer.isPlaying)
           updateLabels(with: message, animate: false)
           
        }
    }
    
    func playerStateDidChange(_ state: KSAudioPlayerState, animate: Bool) {
        let message: String?

        switch state {
        case .loading:
            message = "Loading Station ..."
        case .urlNotSet:
            message = "Station URL not valide"
        case .readyToPlay, .loadingFinished:
            NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object:  audioPlayer.player?.currentItem)

            playbackStateDidChange(audioPlayer.playbackState, animate: animate)
            return
        case .error:
            message = "Error Playing"
        }
        DispatchQueue.main.async {
            self.updateLabels(with: message, animate: false)
        }

    }
    
    
    //MARK: Update label
    func updateLabels(with statusMessage: String? = nil, animate: Bool = true) {
        
        guard let statusMessage = statusMessage else {
            self.audioName.text = self.audioPlayer.station?.name
            return
        }
        guard self.audioName.text != statusMessage else { return }
        self.audioName.text = self.currentStation.name
    }
    
    func stationDidChange() {
        audioPlayer.audioURL = URL(string: currentStation.url)
        self.title = currentStation.name
        
    }
    
    private func isPlayingDidChange(_ isPlaying: Bool) {
        self.playBtn.isSelected = isPlaying
        }
    
    func load(station: AudioDM?, isNewStation: Bool = true) {
        guard let station = station else { return }
        currentStation = station
        //        currentTrack = track
        newStation = isNewStation
    }
    
    @IBAction func nextBtnPressed(_ sender: Any) {
        delegate?.didPressNextButton()
    }
    
    @IBAction func backBtnPressed(_ sender: Any) {
        delegate?.didPressPreviousButton()
    }
    
    @IBAction func playBtnPressed(_ sender: Any) {
        delegate?.didPressPlayingButton()
    }
    @IBAction func rightPlayBtnPressed(_ sender: Any) {
        delegate?.didTransferForward()
    }
    
    @IBAction func leftPlayBtnPressed(_ sender: Any) {
        delegate?.didTransferBack()
    }
    
    @objc func playerDidFinishPlaying(_ note: NSNotification) {
        delegate?.didPressNextButton()
    }
    
}

//MARK: Time Slider
extension NowPlayingVC {
    
    
    func setUpTimeSlider() {
        
        timeSlider.isContinuous = true
        timeSlider.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        timeSlider.setThumbImage(UIImage(named: "thumb"), for: .normal)
        timeSlider.addTarget(self, action: #selector(playbackSliderValueChanged(_:)), for: .valueChanged)
    }
    
    func setUpPlayer() {
        // Add playback slider
       setUpTimeSlider()
        let duration : CMTime = audioPlayer.getAssetDuration() ?? CMTime()
        let seconds : Float64 = CMTimeGetSeconds(duration)
        lblDuration.text = self.stringFromTimeInterval(interval: seconds)
        
        let duration1 : CMTime = audioPlayer.getCurrentTime() ?? CMTime()
        let seconds1 : Float64 = CMTimeGetSeconds(duration1)
        
        if !seconds1.isNaN {
            lblCurrentTime.text = self.stringFromTimeInterval(interval: seconds1)
        }
        
        if !seconds.isNaN {
            timeSlider.maximumValue = Float(seconds)
        }
        if let t = self.audioPlayer.getCurrentTime() {
            let time : Float64 = CMTimeGetSeconds(t)
            self.timeSlider.value = Float(time);
        }
            
        audioPlayer.player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main) { (CMTime) -> Void in
            if self.audioPlayer.player?.currentItem?.status == .readyToPlay {
                let time : Float64 = CMTimeGetSeconds(self.audioPlayer.getCurrentTime() ?? CMTime)
                self.timeSlider.value = Float ( time );
                
                self.lblCurrentTime.text = self.stringFromTimeInterval(interval: time)
            }
        }
    }
    
    
    @objc func playbackSliderValueChanged(_ playbackSlider: UISlider){
        
        if !(playbackSlider.value.isNaN || playbackSlider.value.isInfinite)  {
            let seconds : Int64 = Int64(playbackSlider.value)
            let targetTime:CMTime = CMTimeMake(value: seconds, timescale: 1)
            
            let player = audioPlayer.player
            
            player!.seek(to: targetTime)
            
            if player!.rate == 0
            {
                player?.play()
            }
        }
        
    }
    
    
    func stringFromTimeInterval(interval: TimeInterval) -> String {
        if !(interval.isNaN || interval.isInfinite)  {
            let interval = Int(interval)
            let seconds = interval % 60
            let minutes = (interval / 60) % 60
            let hours = (interval / 3600)
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }else {
            return ""
        }
        
        
    }
}

//MARK: Volume Slider
extension NowPlayingVC {
    
    func setupVolumeSlider() {
        // Note: This slider implementation uses a MPVolumeView
        // The volume slider only works in devices, not the simulator.
        for subview in MPVolumeView().subviews {
            guard let volumeSlider = subview as? UISlider else { continue }
            mpVolumeSlider = volumeSlider
        }
        
        guard let mpVolumeSlider = mpVolumeSlider else { return }
        
        volumeView.addSubview(mpVolumeSlider)
        
        mpVolumeSlider.translatesAutoresizingMaskIntoConstraints = false
        mpVolumeSlider.leftAnchor.constraint(equalTo: volumeView.leftAnchor).isActive = true
        mpVolumeSlider.rightAnchor.constraint(equalTo: volumeView.rightAnchor).isActive = true
        mpVolumeSlider.centerYAnchor.constraint(equalTo: volumeView.centerYAnchor).isActive = true
        
        mpVolumeSlider.setThumbImage(#imageLiteral(resourceName: "slider-ball"), for: .normal)
    }
}


