//
//  AudioListTVC.swift
//  KSAudioPlayer
//
//  Created by Kuziboev Siddikjon on 3/10/22.
//

import UIKit

class AudioListTVC: UITableViewCell {

    @IBOutlet weak var lblDesc: UILabel!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    
    static let identifier = String(describing: AudioListTVC.self)
    static func nib()-> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}
