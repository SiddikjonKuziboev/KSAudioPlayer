//
//  AudiosListVC.swift
//  KSAudioPlayer
//
//  Created by Kuziboev Siddikjon on 3/10/22.
//

import UIKit
import AVFoundation
import MediaPlayer

class AudiosListVC: UIViewController {
    
    @IBOutlet weak var nowPlayingBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var animationImage: UIImageView!
    
    var stations = [AudioDM](){
        didSet {
            guard stations != oldValue else { return }
        }
    }
        
    var nowPlayingVC: NowPlayingVC?
    let audioPlayer = KSAudioPlayer.shared
    var previousStation: AudioDM?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpTableView()
        audioPlayer.delegate = self
        createNowPlayingAnimation()
        setupRemoteCommandCenter()
        
        stations = [
            AudioDM(name: "ozodbek_nazarbekov_-_gozal_hayot", img: "", url: "https://uzhits.net/music/dl2/2020/04/16/ozodbek_nazarbekov_-_gozal_hayot_(uzhits.net).mp3"),
            AudioDM(name: "sardor-mamadaliyev-doston-ergashev", img: "", url: "https://uzhits.net/uploads/files/2022-02/sardor-mamadaliyev-doston-ergashev-qizlarga-tushunmayman_(uzhits.net).mp3"),
            AudioDM(name: "Ozodbek_Nazarbekov", img: "", url: "https://uzhits.net/music/dl2/2017/03/21/Ozodbek_Nazarbekov_-_Gul_(uzhits.net).mp3"),
            AudioDM(name: "/shahzoda-manzura", img: "", url: "https://uzhits.net/musiccc/dl2/2020/2020-10/shahzoda-manzura-shunchaki-izlamading-remix_(uzhits.net).mp3"),
            AudioDM(name: "munisa-rizayeva", img: "", url: "https://uzhits.net/uploads/files/2021-12/munisa-rizayeva-yetmadimi_(uzhits.net).mp3"),
            AudioDM(name: "munisa-rizayeva-boldi-yurak", img: "", url: "https://uzhits.net/musiccc/dl2/2020/2020-11/munisa-rizayeva-boldi-yurak_(uzhits.net).mp3"),
            AudioDM(name: "janob-rasul", img: "", url: "https://uzhits.net/uploads/files/2022-01/janob-rasul-gejalar_(uzhits.net).mp3"),
            AudioDM(name: "shohruhxon_-_begona", img: "", url: "https://uzhits.net/music/dl2/2020/03/31/shohruhxon_-_begona_(uzhits.net).mp3"),
            AudioDM(name: "shohruhxon_-_gulim", img: "", url: "https://uzhits.net/music/dl2/2020/01/24/shohruhxon_-_gulim_(uzhits.net).mp3"),
            
            
        ]
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "Siddikjon's Player"
    }
    
    // MARK: - Private helpers    
    private func stationsDidUpdate() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            guard let currentStation = self.audioPlayer.station else { return }
            
            // Reset everything if the new stations list doesn't have the current station
            if self.stations.firstIndex(of: currentStation) == nil { self.resetCurrentStation() }
        }
    }
    
    func createNowPlayingAnimation() {
        animationImage.animationImages = AnimationFrames.createFrames()
        animationImage.animationDuration = 0.7
    }
    
    // Reset all properties to default
    private func resetCurrentStation() {
        audioPlayer.resetPlayer()
        animationImage.stopAnimating()
        nowPlayingBtn.setTitle("Choose a station above to begin", for: .normal)
        nowPlayingBtn.isEnabled = false
    }
    
    func startNowPlayingAnimation(_ animate: Bool) {
        animate ? animationImage.startAnimating() : animationImage.stopAnimating()
    }
    
    // Update the now playing button title
    private func updateNowPlayingButton(station: AudioDM?) {
        guard let station = station else { resetCurrentStation(); return }
        
        let playingTitle = station.name
        nowPlayingBtn.setTitle(playingTitle, for: .normal)
        nowPlayingBtn.isEnabled = true
    }
    
    
    // MARK: - Remote Command Center Controls
    ///Lock screen
    func setupRemoteCommandCenter() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Add handler for Play Command
        commandCenter.playCommand.addTarget { event in
            return .success
        }
        
        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { event in
            return .success
        }
        
        // Add handler for Next Command
        commandCenter.nextTrackCommand.addTarget { event in
            return .success
        }
        
        // Add handler for Previous Command
        commandCenter.previousTrackCommand.addTarget { event in
            return .success
        }
    }
    
    // MARK: - MPNowPlayingInfoCenter (Lock screen)
    func updateLockScreen() {
        
        // Define Now Playing Info
        var nowPlayingInfo = [String : Any]()
        
        if let image = UIImage(named: "albumArt") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { size -> UIImage in
                return image
            })
        }
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = audioPlayer.station?.name
        if let t = audioPlayer.getCurrentTime() {
            let time = CMTimeGetSeconds(t)
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = CMTimeGetSeconds(audioPlayer.getAssetDuration() ?? CMTime())
            
        }
        
        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    @IBAction func nowPlayingBtnPressed(_ sender: Any) {
        didSelectRow(index: nil)
    }
    
}

//MARK: TableView
extension AudiosListVC: UITableViewDataSource {
    
    func setUpTableView() {
        tableView.register(AudioListTVC.nib(), forCellReuseIdentifier: AudioListTVC.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.reloadData()
        tableView.contentInset = UIEdgeInsets(top: 15, left: 0, bottom: 0, right: 0)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        stations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: AudioListTVC.identifier, for: indexPath)as! AudioListTVC
        cell.selectionStyle = .none
        
        cell.lblName.text = stations[indexPath.row].name
        
        // alternate background color
        cell.backgroundColor = (indexPath.row % 2 == 0) ? UIColor.clear : UIColor.black.withAlphaComponent(0.2)
        
        return cell
        
    }
}

//MARK: DidSelect
extension AudiosListVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectRow(index: indexPath)
    }
    
    func didSelectRow(index: IndexPath?) {
        title = ""
        let newStation: Bool
        
        if let indexPath = index {
            // User clicked on row, load/reset station
            audioPlayer.station =  stations[indexPath.row]
            newStation = audioPlayer.station != previousStation
            previousStation = audioPlayer.station
        } else {
            // User clicked on Now Playing button
            newStation = false
        }
        
        let vc = NowPlayingVC(nibName: "NowPlayingVC", bundle: nil)
        vc.load(station: audioPlayer.station, isNewStation: newStation)
        nowPlayingVC = NowPlayingVC()
        vc.delegate = self
        nowPlayingVC = vc
        vc.load(station: audioPlayer.station, isNewStation: newStation)
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

//MARK: NowPlayingVC delegates
extension AudiosListVC: NowPlayingViewControllerDelegate {
    
    func didTransferBack() {
        audioPlayer.transferBack()
    }
    
    func didTransferForward() {
        audioPlayer.transferForward()
    }
    
    
    private func getIndex(of station: AudioDM?) -> Int? {
        guard let station = station, let index = stations.firstIndex(of: station) else { return nil }
        return index
    }
    
    func didPressPlayingButton() {
        audioPlayer.togglePlaying()
    }
    
    func didPressStopButton() {
        audioPlayer.stop()
    }
    
    func didPressNextButton() {
        guard let index = getIndex(of: audioPlayer.station) else { return }
        audioPlayer.station = (index + 1 == stations.count) ? stations[0] : stations[index + 1]
        handleRemoteStationChange()
    }
    
    func didPressPreviousButton() {
        guard let index = getIndex(of: audioPlayer.station) else { return }
        audioPlayer.station = (index == 0) ? stations.last : stations[index - 1]
        handleRemoteStationChange()
    }
    
    func handleRemoteStationChange() {
        
        if let nowPlayingVC = nowPlayingVC {
            // If nowPlayingVC is presented
            nowPlayingVC.load(station: audioPlayer.station, isNewStation: false)
            nowPlayingVC.stationDidChange()
        } else if let station = audioPlayer.station {
            // If nowPlayingVC is not presented (change from remote controls)
            audioPlayer.audioURL = URL(string: station.url)
        }
    }
}

//MARK: KSAudioPlayerDelegate
extension AudiosListVC: KSAudioPlayerDelegate {
    
    func radioPlayer(_ player: KSAudioPlayer, playerStateDidChange state: KSAudioPlayerState) {
        nowPlayingVC?.playerStateDidChange(state, animate: true)
    }
    
    func radioPlayer(_ player: KSAudioPlayer, playbackStateDidChange state: FRadioPlaybackState) {
        DispatchQueue.main.async {
            self.nowPlayingVC?.playbackStateDidChange(state, animate: true)
            self.updateNowPlayingButton(station: self.audioPlayer.station)
            self.startNowPlayingAnimation(self.audioPlayer.isPlaying)
            self.updateLockScreen()
        }
        
    }
}
