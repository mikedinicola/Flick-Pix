//
//  PhotoCollectionViewCell.swift
//  Flick Pix
//
//  Created by Mike DiNicola on 5/20/18.
//  Copyright © 2018 Mike-DiNicola. All rights reserved.
//

import UIKit
import INSPhotoGallery

class PhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
    func populateWithPhoto(_ photo: INSPhotoViewable) {
        photo.loadThumbnailImageWithCompletionHandler { [weak photo] (image, error) in
            if let image = image {
                if let photo = photo as? INSPhoto {
                    photo.thumbnailImage = image
                }
                self.imageView.image = image
            }
        }
    }
}
