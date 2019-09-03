//
//  AssetCell.swift
//  AnimateDemo
//
//  Created by Ruben Nine on 30/08/2019.
//  Copyright © 2019 Filestack. All rights reserved.
//

import Photos

class AssetCell: UICollectionViewCell {
    @IBOutlet var image: UIImageView!
    @IBOutlet var selectedCheckbox: UIImageView!
    @IBOutlet var dimView: UIView!
    @IBOutlet var additionalInfoLabel: UILabel!
    private lazy var gradientLayer = CAGradientLayer()

    private var asset: PHAsset!

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = image.frame
    }

    func configure(for asset: PHAsset, isSelected: Bool) {
        self.asset = asset
        asset.fetchImage(forSize: image.frame.size) { image in
            DispatchQueue.main.async {
                self.configure(with: image)
                self.set(selected: isSelected)
            }
        }
    }

    func set(selected: Bool) {
        dimView.isHidden = !selected
        selectedCheckbox.isHidden = !selected
    }
}

private extension AssetCell {
    func configure(with image: UIImage?) {
        self.image.image = image
        selectedCheckbox.image = UIImage(named: "icon-selected", in: Bundle(for: type(of: self)), compatibleWith: nil)
    }

    func setupGradientLayer() {
        image.layer.insertSublayer(gradientLayer, at: 0)
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.clear.cgColor, UIColor(white: 0.55, alpha: 0.6).cgColor]
        gradientLayer.locations = [NSNumber(value: 0), NSNumber(value: 0.6), NSNumber(value: 1)]
        gradientLayer.startPoint = CGPoint(x: 1, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        gradientLayer.frame = image.frame
    }
}
