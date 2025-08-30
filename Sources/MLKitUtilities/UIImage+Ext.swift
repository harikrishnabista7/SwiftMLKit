//
//  UIImage+Ext.swift
//  SegmentationKit
//
//  Created by hari krishna on 20/08/2025.
//
import UIKit

public extension UIImage {
    /// Resizes the image to the specified target size.
    ///
    /// - Parameters:
    ///   - targetSize: The desired size for the output image.
    ///   - scale: The scale factor for the output image (default is 1.0).
    /// - Returns: A new `UIImage` resized to the specified size.
    func resize(to targetSize: CGSize, scale: CGFloat = 1.0) -> UIImage {
        if size == targetSize {
            return self
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    /// Applies a mask image to this UIImage using Core Graphics.
    ///
    /// - Parameter mask: A `UIImage` representing the mask, where white areas correspond to the subject and black areas to the background.
    /// - Returns: A new `UIImage` with the mask applied. Returns `nil` if the masking process fails.
    ///
    /// This method uses `UIGraphicsBeginImageContextWithOptions` and blend mode `.destinationIn` to apply the mask.
    func applyingMask(_ mask: UIImage) -> UIImage? {
        return autoreleasepool {
            ImageProcessing().applyMask(mask.resize(to: size), to: self)
        }
    }
}
