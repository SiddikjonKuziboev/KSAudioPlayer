//
//  AudioDM.swift
//  KSAudioPlayer
//
//  Created by Kuziboev Siddikjon on 3/10/22.
//

import Foundation

struct AudioDM {
    var name: String
    var img: String
    var url: String
    
}

extension AudioDM: Equatable {
    
    static func == (lhs: AudioDM, rhs: AudioDM) -> Bool {
        return (lhs.name == rhs.name) && (lhs.img == rhs.img) && (lhs.url == rhs.url) 
    }
}

struct Track {
    var title: String
    var artist: String
    var artworkLoaded = false
    
    init(title: String, artist: String) {
        self.title = title
        self.artist = artist
    }
}
