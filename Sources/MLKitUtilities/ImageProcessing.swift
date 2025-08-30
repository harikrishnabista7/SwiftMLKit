//
//  ImageProcessing.swift
//  SwiftMLKit
//
//  Created by hari krishna on 29/08/2025.
//
import CoreImage.CIFilterBuiltins
import Metal
import UIKit

/// Errors that may occur during image processing.
public enum ImageProcessingError: Error {
    case missingCGImage
    case pixelBufferCreationFailed
}

/// A utility class for image processing operations, GPU-accelerated when Metal is available.
public class ImageProcessing {
    /// Core Image context for GPU or CPU processing.
    /// Uses Metal if a GPU device is available, otherwise falls back to CPU.
    private let context: CIContext

    /// A Core Image filter used to blend the original image with a mask.
    private lazy var maskFilter = CIFilter.blendWithMask()

    /// A Core Image filter used to put image over another image
    private lazy var compositeOverFilter = CIFilter.sourceOverCompositing()

    /// Initializes the ImageProcessing utility.
    /// Uses Metal-backed CIContext if a GPU device is available.
    public init() {
        if let device = MTLCreateSystemDefaultDevice() {
            context = CIContext(mtlDevice: device)
        } else {
            context = CIContext()
        }
    }

    // MARK: - CGImage / CIImage Conversion

    /// Creates a `CGImage` from a `CIImage` using the Metal-backed CIContext.
    func createCGImage(from ciImage: CIImage) -> CGImage? {
        context.createCGImage(ciImage, from: ciImage.extent)
    }

    // MARK: - Pixel Buffer Creation (CPU-backed)

    /// Creates a `CVPixelBuffer` from a `UIImage`, resizing it to the given size.
    /// Uses Core Graphics to draw into the pixel buffer.
    ///
    /// - Parameters:
    ///   - image: Input `UIImage`.
    ///   - size: Target size for the pixel buffer.
    /// - Returns: A resized `CVPixelBuffer`.
    /// - Throws: `BackgroundRemovalError` if creation fails.
    public func createPixelBuffer(from image: UIImage, resizingTo size: CGSize) async throws -> CVPixelBuffer {
        guard let cgImage = image.cgImage else {
            throw ImageProcessingError.missingCGImage
        }

        // Create pixel buffer
        guard let pixelBuffer = makePixelBuffer(width: Int(size.width), height: Int(size.height)) else {
            throw ImageProcessingError.pixelBufferCreationFailed
        }

        // Lock pixel buffer
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw ImageProcessingError.pixelBufferCreationFailed
        }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue
            | CGBitmapInfo.byteOrder32Little.rawValue

        guard let context = CGContext(
            data: pixelData,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw ImageProcessingError.pixelBufferCreationFailed
        }

        let rect = CGRect(origin: .zero, size: size)
        context.draw(cgImage, in: rect)

        return pixelBuffer
    }

    /// Creates a Metal-compatible pixel buffer with BGRA format.
    private func makePixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        let attrs: [String: Any] = [
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
        ]

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                         kCVPixelFormatType_32BGRA, attrs as CFDictionary, &pixelBuffer)
        guard status == kCVReturnSuccess else { return nil }
        return pixelBuffer
    }
}

public extension ImageProcessing {
    /// Applies a mask image to the given image using GPU acceleration if available.
    ///
    /// - Parameters:
    ///   - mask: A `UIImage` representing the mask, where white areas correspond to the subject and black areas to the background.
    ///   - image: The original `UIImage` to which the mask should be applied.
    ///
    /// - Returns: A new `UIImage` with the mask applied. Returns `nil` if the input or mask cannot be converted to `CGImage` or if the Core Image processing fails.
    func applyMask(_ mask: UIImage, to image: UIImage) -> UIImage? {
        guard let inputCgImage = image.cgImage, let maskCgImage = mask.resize(to: image.size).cgImage else { return nil }

        maskFilter.inputImage = CIImage(cgImage: inputCgImage)
        maskFilter.maskImage = CIImage(cgImage: maskCgImage)

        guard let outputCIImage = maskFilter.outputImage, let resultCGImage = createCGImage(from: outputCIImage) else { return nil }

        return UIImage(cgImage: resultCGImage)
    }

//    func composite(_ foreground: UIImage, with background: UIImage) -> UIImage? {
//        guard let foregroundCGImage = foreground.cgImage, let backgroundCGImage = background.cgImage else { return nil }
//
//    }
}
