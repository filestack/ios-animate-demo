//
//  PhotosPickerController.swift
//  AnimateDemo
//
//  Created by Ruben Nine on 30/08/2019.
//  Copyright © 2019 Filestack. All rights reserved.
//

import Photos
import UIKit

protocol PhotosPickerControllerDelegate: class {
    func photosPickerDismissed(with selection: [PHAsset])
}

class PhotosPickerController: UICollectionViewController {
    let maximumSelectionAllowed: Int = 10

    weak var delegate: PhotosPickerControllerDelegate?

    var elements: [PHAsset]?
    private var selectedAssets: Set<PHAsset> = Set<PHAsset>()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavBar()
    }

    func configure(with album: Album, selection: Set<PHAsset> = Set<PHAsset>()) {
        title = album.title
        elements = album.elements
        selectedAssets = selection
    }

    var rightBarItems: [UIBarButtonItem] {
        guard selectedAssets.count > 0 else { return [] }

        return [selectionCountBarButton, doneBarButton].compactMap { $0 }
    }

    var doneBarButton: UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissWithSelection))
    }

    var selectionCountBarButton: UIBarButtonItem? {
        let title = "(\(selectedAssets.count)/\(maximumSelectionAllowed))"
        return UIBarButtonItem(title: title, style: .done, target: self, action: #selector(dismissWithSelection))
    }

    func updateNavBar() {
        navigationItem.rightBarButtonItems = rightBarItems
    }

    @objc func dismissWithSelection() {
        navigationController?.popToRootViewController(animated: true)

        DispatchQueue.main.async {
            self.delegate?.photosPickerDismissed(with: Array(self.selectedAssets))
        }
    }
}

extension PhotosPickerController {
    func setupView() {
        view.backgroundColor = .white
        collectionView?.contentInsetAdjustmentBehavior = .always
    }
}

extension PhotosPickerController {
    override func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return elements?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AssetCell",
                                                            for: indexPath) as? AssetCell else {
                                                                return UICollectionViewCell()
        }

        let asset = elements![indexPath.row]
        let isSelected = selectedAssets.contains(asset)

        cell.configure(for: asset, isSelected: isSelected)

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = elements![indexPath.row]
        let isSelecting = !selectedAssets.contains(asset)

        if isSelecting, maximumReached {
            return
        }

        let cell = collectionView.cellForItem(at: indexPath) as! AssetCell

        cell.set(selected: isSelecting)

        if isSelecting {
            selectedAssets.insert(asset)
        } else {
            selectedAssets.remove(asset)
        }

        updateNavBar()
    }
}

extension PhotosPickerController: UICollectionViewDelegateFlowLayout {
    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        return cellSize
    }
}

private extension PhotosPickerController {
    var cellSize: CGSize {
        return CGSize(width: cellEdge, height: cellEdge)
    }

    var cellEdge: CGFloat {
        let totalSpacing = cellSpacing * (columnsCount - 1)
        return (totalWidth - totalSpacing) / columnsCount
    }

    var totalWidth: CGFloat {
        return view.safeAreaLayoutGuide.layoutFrame.width
    }

    var columnsCount: CGFloat {
        let isPortrait = UIApplication.shared.statusBarOrientation.isPortrait
        return isPortrait ? 4 : 7
    }

    var cellSpacing: CGFloat {
        return 2
    }

    var maximumReached: Bool {
        return selectedAssets.count >= maximumSelectionAllowed
    }
}
