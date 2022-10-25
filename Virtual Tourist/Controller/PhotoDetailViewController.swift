//
//  PhotoDetailViewController.swift
//  Virtual Tourist
//
//  Created by Vishnu V on 22/10/22.
//


import UIKit

class PhotoDetailViewController: UIViewController {

    
    var photo:Photo!
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let imageData = photo.imageData, let title = photo.title {
            imageView.image = UIImage(data: imageData)
            self.title = title
        }
    }
}
