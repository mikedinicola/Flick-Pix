//
//  ViewController.swift
//  Flick Pix
//
//  Created by Mike DiNicola on 5/20/18.
//  Copyright © 2018 Mike-DiNicola. All rights reserved.
//

import UIKit
import INSPhotoGallery

class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var searchController = UISearchController(searchResultsController: nil)
    
    var photos: [INSPhotoViewable]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        queryFlickr()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        searchController.searchResultsUpdater = self
        
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            // TODO: Not working pre-iOS 11 (on sim at least)
            // navigationItem.titleView = searchController.searchBar
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = true
        }
    }
    
    func queryFlickr(_ string: String = "") {
        
        photos = []
        
        let flickrURL = "https://api.flickr.com/services/feeds/photos_public.gne" +
            "?tags=\(string)" +
            "&;tagmode=any" +
            "&format=json" +
        "&nojsoncallback=1"
        
        let session = URLSession.shared
        if let url = URL(string: flickrURL) {
            session.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print(error)
                    return
                }
                
                guard let data = data,
                    let resultDictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as! Dictionary<String, Any>,
                    let items = resultDictionary["items"] as? [Dictionary<String, Any>]else {return}
                
                for item in items {
                    
                    guard let mediaDictionary = item["media"] as? Dictionary<String, Any>,
                        let linkString = mediaDictionary["m"] as? String else {continue}
                    
                    let photo = INSPhoto(imageURL: URL(string: linkString), thumbnailImageURL: URL(string: linkString))
                    
                    if let titleString = item["title"] as? String {
                        photo.attributedTitle = NSAttributedString(string: titleString, attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
                    }
                    
                    self.photos.append(photo)
                }
                
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                }.resume()
        }
    }
}

extension ViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let resultString = searchController.searchBar.text else {return}
        if resultString == "" {return}
        
        queryFlickr(resultString)
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        cell.populateWithPhoto(photos[(indexPath as IndexPath).row])
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell
        let currentPhoto = photos[(indexPath as IndexPath).row]
        let galleryPreview = INSPhotosViewController(photos: photos, initialPhoto: currentPhoto, referenceView: cell)
        
        galleryPreview.referenceViewForPhotoWhenDismissingHandler = { [weak self] photo in
            if let index = self?.photos.index(where: {$0 === photo}) {
                let indexPath = IndexPath(item: index, section: 0)
                return collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell
            }
            return nil
        }
        present(galleryPreview, animated: true, completion: nil)
    }
}
