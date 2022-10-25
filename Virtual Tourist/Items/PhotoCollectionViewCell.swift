//
//  PhotoCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Vishnu V on 22/10/22.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    // Photo
    @IBOutlet weak var imageView: UIImageView!
    
    // checkmark image. Used to indicate ready for deletion
    @IBOutlet weak var checkmarkImageView: UIImageView!
    
    // downloading photo in progress
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
}
