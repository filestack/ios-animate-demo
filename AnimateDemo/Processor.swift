//
//  Processor.swift
//  AnimateDemo
//
//  Created by Ruben Nine on 30/08/2019.
//  Copyright © 2019 Filestack. All rights reserved.
//

import FilestackSDK
import Photos.PHAsset

final class Processor {
    private let fsClient: FilestackSDK.Client
    private let storageOptions = StorageOptions(location: .s3, access: .private)
    private let serialQueue = DispatchQueue(label: "com.filestack.AnimateDemo.serial-queue")
    private let dispatchGroup = DispatchGroup()
    private let temporaryDirectoryURL = FileManager.default.temporaryDirectory

    // MARK: - Lifecycle

    init(fsClient: FilestackSDK.Client) {
        self.fsClient = fsClient
    }

    // MARK: - Public Functions

    func process(assets: [PHAsset], maxSize: CGSize, completion: @escaping (_ outputURL: URL?) -> Void) {
        serialQueue.async {
            // Save photo library assets at `maxSize` resolution into temporary URL locations.
            let urls = self.extract(assets: assets, maxSize: maxSize)
            // Upload files and obtain Filestack handles.
            let fileLinks = self.upload(urls: urls)
            // Remove temporary URLs.
            self.deleteURLs(urls: urls)
            // Setup animate transform with array of Filestack handles.
            let animateTransformable = self.fsClient.transformable(handles: (fileLinks.map { $0.handle }))
            animateTransformable.add(transform: AnimateTransform().delay(1000))

            // Download animated GIF and call completion block.
            let session = URLSession.shared
            let task = session.downloadTask(with: animateTransformable.url) { (url, response, error) in
                // Delete uploaded file links.
                for fileLink in fileLinks {
                    fileLink.delete(completionHandler: { _ in })
                }

                let outputURL: URL = self.temporaryDirectoryURL
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("gif")

                if let url = url, (try? FileManager.default.copyItem(at: url, to: outputURL)) != nil {
                    DispatchQueue.main.async {
                        completion(outputURL)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }

            task.resume()
        }
    }

    // MARK: - Private Functions

    // Upload URLs to Filestack and return file links.
    private func upload(urls: [URL]) -> [FileLink] {
        var fileLinks = [FileLink]()

        dispatchGroup.enter()

        fsClient.multiFileUpload(from: urls, storeOptions: storageOptions) { (responses) in
            let handles = responses.compactMap { $0.json?["handle"] as? String }
            fileLinks = handles.map { self.fsClient.fileLink(for: $0) }
            self.dispatchGroup.leave()
        }

        dispatchGroup.wait()

        return fileLinks
    }

    // Save photo library assets at `maxSize` resolution into temporary URL locations.
    private func extract(assets: [PHAsset], maxSize: CGSize) -> [URL] {
        var urls = [URL]()

        for asset in assets {
            let imageManager = PHCachingImageManager()
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            options.deliveryMode = .highQualityFormat

            imageManager.requestImage(for: asset, targetSize: maxSize, contentMode: .aspectFit, options: options) { image, _ in
                guard let data = image?.jpegData(compressionQuality: 0.85) else { return }

                let url = self.temporaryDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")

                if (try? data.write(to: url)) != nil {
                    urls.append(url)
                }
            }
        }

        return urls
    }

    // Delete temporary URLs.
    private func deleteURLs(urls: [URL]) {
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
