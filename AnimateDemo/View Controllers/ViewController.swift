//
//  ViewController.swift
//  AnimateDemo
//
//  Created by Ruben Nine on 30/08/2019.
//  Copyright © 2019 Filestack. All rights reserved.
//

import FilestackSDK
import Photos
import SVProgressHUD
import SwiftGifOrigin
import UIKit

private struct Images {
    // Placeholder image URL
    static let placeholderImageURL = Bundle.main.url(forResource: "placeholder", withExtension: "png")!
}

private let processSize = CGSize(width: 300, height: 300)

class ViewController: UIViewController {
    private var documentsDirectoryURL: URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    private let imageView: UIImageView = {
        // Setup transformed image view
        let imageView = UIImageView(image: UIImage(contentsOfFile: Images.placeholderImageURL.path))

        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        return imageView
    }()

    // View Overrides

    override func viewDidLoad() {
        // Add stack view to view hierarchy
        view.addSubview(imageView)
        updateNavBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        // Setup image view constraints
        let views = ["imageView" : imageView]
        let margin: CGFloat = 22

        let h = NSLayoutConstraint.constraints(withVisualFormat: "H:|-left-[imageView]-right-|",
                                               metrics: ["left": view.safeAreaInsets.left + margin,
                                                         "right": view.safeAreaInsets.right + margin],
                                               views: views)

        let w = NSLayoutConstraint.constraints(withVisualFormat: "V:|-top-[imageView]-bottom-|",
                                               metrics: ["top": view.safeAreaInsets.top + margin,
                                                         "bottom": view.safeAreaInsets.bottom + margin],
                                               views: views)

        // Remove existing view constraints
        view.removeConstraints(view.constraints)
        // Add new view constraints
        view.addConstraints(h)
        view.addConstraints(w)

        super.viewDidAppear(animated)
    }

    // Actions

    @IBAction func pickAndTransformImage(_ sender: AnyObject) {
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .authorized:
                let albumRepository = PhotoAlbumRepository()

                albumRepository.getAlbums { (albums) in
                    let selectedAlbums = albums.filter({ (album) -> Bool in
                        return album.title == "Camera Roll"
                    })

                    guard let cameraRoll = selectedAlbums.first else { return }

                    DispatchQueue.main.async {
                        let vc = self.viewController(with: "PhotosPickerController")

                        guard let picker = vc as? PhotosPickerController else {
                            fatalError("PhotosPickerController type is corrupted")
                        }

                        picker.delegate = self
                        picker.configure(with: cameraRoll)

                        self.navigationController!.pushViewController(picker, animated: true)
                    }
                }
            default:
                break
            }
        }
    }

    // Private Functions

    private func viewController(with name: String) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: type(of: self)))
        return storyboard.instantiateViewController(withIdentifier: name)
    }

    private func updateNavBar() {
        let button = UIBarButtonItem(title: "Select images", style: .done, target: self, action: #selector(pickAndTransformImage))
        navigationItem.leftBarButtonItem = button
    }
}

extension ViewController: PhotosPickerControllerDelegate {
    func photosPickerDismissed(with selection: [PHAsset]) {
        guard let fsClient = fsClient else { return }

        SVProgressHUD.show(withStatus: "Processing")
        let processor = Processor(fsClient: fsClient)

        processor.process(assets: selection, maxSize: processSize) { (outputURL) in
            SVProgressHUD.dismiss()

            guard let outputURL = outputURL else {
                SVProgressHUD.showError(withStatus: "Unable to complete process.")
                return
            }

            // Update image view's image with our animated image.
            if let animatedImage = UIImage.gif(url: outputURL.absoluteString) {
                self.imageView.image = animatedImage
            }

            // Try to save GIF in photos library, and upon completion, delete temporary file at `outputURL`.
            PHPhotoLibrary.requestAuthorization { (status) in
                switch status {
                case .authorized:
                    PHPhotoLibrary.shared().performChanges({
                        let request = PHAssetCreationRequest.forAsset()
                        request.addResource(with: .photo, fileURL: outputURL, options: nil)
                    }) { (success, error) in
                        // Delete file at temporary location.
                        try? FileManager.default.removeItem(at: outputURL)

                        DispatchQueue.main.async {
                            if let error = error {
                                SVProgressHUD.showError(withStatus: error.localizedDescription)
                            } else {
                                SVProgressHUD.showSuccess(withStatus: "GIF animation added to photos album.")
                            }
                        }
                    }
                default:
                    break
                }
            }
        }
    }
}
