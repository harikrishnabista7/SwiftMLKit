//
//  U2NetSegmentation.swift
//  SwiftMLKit
//
//  Created by hari krishna on 03/09/2025.
//

import CoreML
import MLKitUtilities
import UIKit

public final class U2NetSegmentation: Segmentation {
    private let model: u2netp

    private let imageProcessing: ImageProcessing

    public init() throws {
        do {
            model = try u2netp(configuration: .init())
        } catch {
            throw SegmentationError.failedToLoadModel
        }
        imageProcessing = ImageProcessing()
    }

    public func segment(image: UIImage) async throws -> UIImage {
        let buffer = try await imageProcessing.createPixelBuffer(from: image, resizingTo: CGSize(width: 320, height: 320))
        let prediction = try model.prediction(in_0: buffer)

        let output = prediction.out_p0

        let ciImage = CIImage(cvPixelBuffer: output)
        guard let cgImage = imageProcessing.createCGImage(from: ciImage) else {
            throw SegmentationError.failedToProcessImage
        }

        return UIImage(cgImage: cgImage)
    }
}
