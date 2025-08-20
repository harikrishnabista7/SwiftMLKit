//
//  DeepLabBackgroundRemover.swift
//  SegmentationKit
//
//  Created by hari krishna on 20/08/2025.
//

import CoreImage.CIFilterBuiltins
import CoreML
import UIKit

/// A background remover powered by DeepLabV3 segmentation model.
///
/// This class takes a `UIImage`, runs semantic segmentation with DeepLabV3 to
/// generate a mask, and then composites the original image with that mask to
/// remove the background.
public final class DeepLabBackgroundRemover: Segmentation {
    // MARK: - Properties

    /// A helper utility to handle pixel buffer creation and Core Graphics conversions.
    private let helper: BackgroundRemoverHelper

    /// The Core ML model used for semantic segmentation (DeepLabV3).
    private let model: DeepLabV3

    /// A Core Image filter used to blend the original image with the predicted mask.
    /// Initialized lazily to reuse the same instance for performance.
    private lazy var maskFilter = CIFilter.blendWithMask()

    // MARK: - Initialization

    /// Creates a new instance of `DeepLabBackgroundRemover`.
    ///
    /// - Throws: `BackgroundRemovalError.failedToInitializeHelper` if the helper cannot be created.
    ///           Errors from Core ML model initialization if loading fails.
    public init() throws {
        guard let helper = BackgroundRemoverHelper() else {
            throw BackgroundRemovalError.failedToInitializeHelper
        }
        self.helper = helper

        // Preload and cache the DeepLabV3 model
        let config = MLModelConfiguration()
        model = try DeepLabV3(configuration: config)
    }

    public func segment(image: UIImage) async throws -> UIImage {
        return try await removeBackground(from: image)
    }

    // MARK: - Public API

    /// Removes the background from the given image asynchronously using DeepLabV3.
    ///
    /// - Parameter image: The source `UIImage` whose background should be removed.
    /// - Returns: A new `UIImage` with background removed.
    /// - Throws:
    ///   - `BackgroundRemovalError.failedToProcessImage` if mask generation or compositing fails.
    ///   - `BackgroundRemovalError.failedToLoadModel` if the Core ML model fails.
    ///   - Propagates errors from pixel buffer creation.
    public func removeBackground(from image: UIImage) async throws -> UIImage {
        do {
            // 1. Convert UIImage to a CVPixelBuffer sized for DeepLabV3 (513x513).
            let buffer = try await helper.createPixelBuffer(
                from: image,
                resizingTo: CGSize(width: 513, height: 513)
            )

            // 2. Run DeepLabV3 segmentation on the pixel buffer.
            let prediction = try model.prediction(image: buffer)

            // 3. Convert semantic predictions into a grayscale CGImage mask.
            guard let maskCGImage = prediction.semanticPredictions
                .toGrayscaleCGImageAuto(isNormalized: false) else {
                throw BackgroundRemovalError.failedToProcessImage
            }

            // 4. Create CIImages from the original input and the mask.
            let inputImage = CIImage(cvPixelBuffer: buffer)
            let maskImage = CIImage(cgImage: maskCGImage)

            // 5. Apply the mask filter (blend original with mask).
            guard let outputImage = applyMask(to: inputImage, withMask: maskImage),
                  let result = helper.createCGImage(from: outputImage) else {
                throw BackgroundRemovalError.failedToProcessImage
            }

            // 6. Convert final CGImage back into UIImage and return.
            return UIImage(cgImage: result).resize(to: image.size)

        } catch let error as BackgroundRemovalError {
            // Forward known background removal errors.
            print(error)
            throw error
        } catch {
            // Wrap any other error as model load failure.
            throw BackgroundRemovalError.failedToLoadModel
        }
    }

    // MARK: - Private Helpers

    /// Applies the Core Image `blendWithMask` filter.
    ///
    /// - Parameters:
    ///   - inputImage: The original input `CIImage`.
    ///   - maskImage: The mask `CIImage` where white = foreground, black = background.
    /// - Returns: A masked `CIImage`, or `nil` if filter application fails.
    private func applyMask(to inputImage: CIImage, withMask maskImage: CIImage) -> CIImage? {
        maskFilter.inputImage = inputImage
        maskFilter.maskImage = maskImage
        return maskFilter.outputImage
    }
}

extension MLMultiArray {
    /// Print array information for debugging
    func printInfo() {
        print("MLMultiArray Info:")
        print("  Shape: \(shape)")
        print("  Count: \(count)")
        print("  Data Type: \(dataType)")
        print("  Strides: \(strides)")

        // Print first few values
        let maxPrint = min(10, count)
        print("  First \(maxPrint) values:", terminator: " ")
        for i in 0 ..< maxPrint {
            print(self[i].floatValue, terminator: " ")
        }
        print()
    }
}
