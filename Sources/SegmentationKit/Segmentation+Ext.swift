//
//  File.swift
//  SwiftMLKit
//
//  Created by hari krishna on 29/08/2025.
//

import UIKit

public extension Segmentation {
    func removeBackground(from image: UIImage) async throws -> UIImage? {
        let mask = try await segment(image: image)
        return image.applyingMask(mask)
    }
    
    func replaceBackground(of image: UIImage, withBackground background: UIImage) async throws -> UIImage {
        return image
    }
}
