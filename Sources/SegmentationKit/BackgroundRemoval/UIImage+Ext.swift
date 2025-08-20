//
//  UIImage+Ext.swift
//  SegmentationKit
//
//  Created by hari krishna on 20/08/2025.
//
import UIKit

extension UIImage {
    func resize(to targetSize: CGSize, scale: CGFloat = 1.0) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
