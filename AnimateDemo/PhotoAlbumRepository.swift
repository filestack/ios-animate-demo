//
//  PhotoAlbumRepository.swift
//  AnimateDemo
//
//  Created by Ruben Nine on 30/08/2019.
//  Copyright © 2019 Filestack. All rights reserved.
//

import UIKit
import Photos

struct Album {
    let title: String
    let elements: [PHAsset]
}

class PhotoAlbumRepository {
    private var cachedAlbums: [Album]?

    func getAlbums(completion: @escaping ([Album]) -> Void) {
        if let cachedAlbums = cachedAlbums {
            completion(cachedAlbums)
        } else {
            fetchAndCacheAlbums(completion: completion)
        }
    }

    private func fetchAndCacheAlbums(completion: (([Album]) -> Void)?) {
        DispatchQueue.global(qos: .default).async {
            let collections = PHAssetCollection.allCollections(types: [.smartAlbum, .album])
            let allAlbums = collections.map { Album(title: $0.localizedTitle ?? "", elements: $0.allAssets) }
            let nonEmptyAlbums = allAlbums.filter { !$0.elements.isEmpty }

            self.cachedAlbums = nonEmptyAlbums
            completion?(nonEmptyAlbums)
        }
    }
}
