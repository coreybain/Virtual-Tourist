//
//  PhotoCell.swift
//  VirtualTourist
//
//  Created by Corey Baines on 31/10/16.
//  Copyright © 2016 Corey Baines. All rights reserved.
//

import Foundation
import UIKit

class PhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var photoView: UIImageView!
    // Outlet for label
    
    @IBOutlet weak var deleteButton: UIButton!
    
    override func prepareForReuse() {
        
        super.prepareForReuse()
        
        if photoView.image == nil {
            activityIndicator.startAnimating()
        }
    }
    
}
