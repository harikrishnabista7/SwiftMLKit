//
//  DeepLabSegmentation.swift
//  SwiftMLKit
//
//  Created by hari krishna on 29/08/2025.
//

import CoreML
import UIKit
import MLKitUtilities

/// A DeepLabV3 segmentation class that only outputs masks.
///
/// This class runs semantic segmentation on an input image or pixel buffer
/// and returns a mask image or buffer without performing background compositing.
public final class DeepLabSegmentation: Segmentation {
    // MARK: - Properties

    /// Core ML model for DeepLabV3 segmentation.
    private let model: DeepLabV3

    /// Helper utility for pixel buffer conversions.
    private let imageProcessing: ImageProcessing

    // MARK: - Initialization

    public init() throws {
        do {
            model = try DeepLabV3(configuration: MLModelConfiguration())
        } catch {
            throw SegmentationError.failedToLoadModel
        }
        imageProcessing = .init()
    }

    // MARK: - Segmentation

    /// Segments an input UIImage and returns a mask image.
    public func segment(image: UIImage) async throws -> UIImage {
        let buffer = try await imageProcessing.createPixelBuffer(from: image, resizingTo: CGSize(width: 513, height: 513))
        let prediction = try model.prediction(image: buffer)

        guard let maskCGImage = prediction.semanticPredictions.toGrayscaleCGImageAuto(isNormalized: false) else {
            throw SegmentationError.failedToProcessImage
        }
        return UIImage(cgImage: maskCGImage)
    }

    /// Segments a CVPixelBuffer and returns a mask buffer.
//    public func segment(pixelBuffer: CVPixelBuffer) async throws -> CVPixelBuffer {
//        let prediction = try model.prediction(image: pixelBuffer)
//        guard let maskCGImage = prediction.semanticPredictions.toGrayscaleCGImageAuto(isNormalized: false) else {
//            throw SegmentationError.failedToProcessImage
//        }
//        return try helper.createPixelBuffer(from: maskCGImage)
//    }
}
