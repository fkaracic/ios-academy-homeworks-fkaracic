//
//  TitleTableViewCell.swift
//  TVShows
//
//  Created by Infinum Student Academy on 24/07/2018.
//  Copyright © 2018 Filip Karacic. All rights reserved.
//

import UIKit
import Kingfisher

class TitleTableViewCell: UITableViewCell {

    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var showTitleLabel: UILabel!
    
    func configureWith(show: Show){
        showTitleLabel.text = show.title
        
        let url = URL(string: "https://api.infinum.academy" + show.imageUrl)
        coverImageView.kf.setImage(with: url)
    }
}
