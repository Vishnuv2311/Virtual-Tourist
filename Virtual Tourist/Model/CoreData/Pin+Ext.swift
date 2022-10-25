//
//  Pin+Ext.swift
//  Virtual Tourist
//
//  Created by Vishnu V on 22/10/22.
//

import Foundation
import CoreData

extension Pin {
    
    func downloadedPhotoImageCount() -> Int {
        guard let photos = self.photos as? Set<Photo> else {
            return 0
        }
        
        var count = 0
        for photo in photos {
            if let _ = photo.imageData {
                count += 1
            }
        }
        return count
    }
}
