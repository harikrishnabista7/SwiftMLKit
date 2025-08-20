//
//  Segmentation.swift
//  SegmentationKit
//
//  Created by hari krishna on 20/08/2025.
//

import UIKit

public protocol Segmentation {
    func segment(image: UIImage) async throws -> UIImage
}
