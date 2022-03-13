//
//  AppDelegate.swift
//  KSAudioPlayer
//
//  Created by Kuziboev Siddikjon on 3/10/22.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    weak var audioListVC: AudiosListVC?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // MPNowPlayingInfoCenter
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        // Make status bar white
        UINavigationBar.appearance().barStyle = .black
        
        window = UIWindow()
        let nav = UINavigationController(rootViewController: AudiosListVC(nibName: "AudiosListVC", bundle: nil))
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
        if let navigationController = window?.rootViewController as? UINavigationController {
            audioListVC = navigationController.viewControllers.first as? AudiosListVC
        }
        
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        
        UIApplication.shared.endReceivingRemoteControlEvents()
        
    }
    // MARK: - Remote Controls

    override func remoteControlReceived(with event: UIEvent?) {
        super.remoteControlReceived(with: event)
        
        guard let event = event, event.type == .remoteControl else { return }
        
        switch event.subtype {
        case .remoteControlPlay:
            KSAudioPlayer.shared.play()
        case .remoteControlPause:
            KSAudioPlayer.shared.pause()
        case .remoteControlTogglePlayPause:
            KSAudioPlayer.shared.togglePlaying()
        case .remoteControlNextTrack:
            audioListVC?.didPressNextButton()
        case .remoteControlPreviousTrack:
            audioListVC?.didPressPreviousButton()
        default:
            break
        }
    }
}
