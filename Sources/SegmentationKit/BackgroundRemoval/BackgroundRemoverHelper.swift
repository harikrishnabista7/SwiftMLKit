//
//  BackgroundRemoverHelper.swift
//  SegmentationKit
//
//  Created by hari krishna on 20/08/2025.
//

import MetalKit
import MetalPerformanceShaders
import UIKit

// MARK: - Helper Class

/// A utility class that handles Core Image, Core Video, and Metal-related tasks
/// for background removal pipelines.
///
/// Responsibilities:
/// - Creating and managing `CVPixelBuffer`s from `UIImage` or Metal textures
/// - Resizing images using `MPSImageLanczosScale`
/// - Converting between `UIImage`, `CGImage`, `CIImage`, and `MTLTexture`
/// - Providing a Metal-backed `CIContext` for GPU-accelerated rendering
final class BackgroundRemoverHelper {
    // MARK: - Properties

    /// The system default Metal device (GPU).
    let device: MTLDevice

    /// A command queue used to schedule Metal operations.
    let commandQueue: MTLCommandQueue

    /// Core Image context backed by Metal for efficient rendering.
    let context: CIContext

    // MARK: - Initialization

    /// Creates a new helper instance with Metal + Core Image setup.
    ///
    /// - Returns: A fully initialized `BackgroundRemoverHelper`, or `nil` if
    ///   the system does not support Metal.
    init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue() else {
            return nil
        }
        self.device = device
        commandQueue = queue
        context = CIContext(mtlDevice: device)
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
    func createPixelBuffer(from image: UIImage, resizingTo size: CGSize) async throws -> CVPixelBuffer {
        guard let cgImage = image.cgImage else {
            throw BackgroundRemovalError.missingCGImage
        }

        // Create pixel buffer
        guard let pixelBuffer = makePixelBuffer(width: Int(size.width), height: Int(size.height)) else {
            throw BackgroundRemovalError.pixelBufferCreationFailed
        }

        // Lock pixel buffer
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw BackgroundRemovalError.pixelBufferCreationFailed
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
            throw BackgroundRemovalError.pixelBufferCreationFailed
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

    // MARK: - Pixel Buffer Creation (GPU-backed)

    /// Alternative GPU path: converts `UIImage` into a pixel buffer by going through a Metal texture,
    /// resizing with `MPSImageLanczosScale`, and then rendering into a CVPixelBuffer.

    /* func createPixelBuffer(from image: UIImage, resizingImageTo size: CGSize) async throws -> CVPixelBuffer {
         do {
             let sourceTexture = try createTexture(from: image)
             let resizedTexture = try await resize(inputTexture: sourceTexture, toSize: size)

             guard let pixelBuffer = createPixelBuffer(from: resizedTexture) else {
                 throw BackgroundRemovalError.pixelBufferCreationFailed
             }
             return pixelBuffer

         } catch {
             throw error
         }
     } */

    // MARK: - Metal Texture Handling

    private lazy var textureLoader: MTKTextureLoader = .init(device: device)

    /// Creates a Metal texture from a `UIImage`'s CGImage.
    private func createTexture(from image: UIImage) throws -> MTLTexture {
        guard let cgImage = image.cgImage else { throw BackgroundRemovalError.missingCGImage }

        do {
            let texture = try textureLoader.newTexture(
                cgImage: cgImage,
                options: [
                    .textureUsage: MTLTextureUsage.shaderRead.rawValue,
                    .textureStorageMode: MTLStorageMode.shared.rawValue,
                ]
            )
            return texture
        } catch {
            throw BackgroundRemovalError.textureCreationFailedFromCgImage
        }
    }

    /// Resizes a Metal texture using Metal Performance Shaders (Lanczos filter).
    /* private func resize(inputTexture: MTLTexture, toSize size: CGSize) async throws -> MTLTexture {
         guard let commandBuffer = commandQueue.makeCommandBuffer() else { throw BackgroundRemovalError.failedToResizeImage }
         let scaler = MPSImageLanczosScale(device: device)
         let scaleX = size.width / Double(inputTexture.width)
         let scaleY = size.height / Double(inputTexture.height)

         var transform = MPSScaleTransform(scaleX: scaleX, scaleY: scaleY, translateX: 0, translateY: 0)
         withUnsafePointer(to: &transform) { trans in
             scaler.scaleTransform = trans
         }

         let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: Int(size.width), height: Int(size.height), mipmapped: false)
         textureDescriptor.usage = [.shaderRead, .shaderWrite]

         let outputTexture = commandBuffer.device.makeTexture(descriptor: textureDescriptor)
         guard let outputTexture else {
             throw BackgroundRemovalError.failedToResizeImage
         }
         scaler.encode(commandBuffer: commandBuffer, sourceTexture: inputTexture, destinationTexture: outputTexture)

         return await withCheckedContinuation { continuation in
             commandBuffer.addCompletedHandler { _ in
                 continuation.resume(returning: outputTexture)
             }
             commandBuffer.commit()
         }
     } */

    // MARK: - Conversion Between Metal & PixelBuffer

    /// Renders a Metal texture into a CVPixelBuffer using Core Image.
    private func createPixelBuffer(from texture: MTLTexture) -> CVPixelBuffer? {
        guard var ciImage = CIImage(mtlTexture: texture, options: [:]) else { return nil }
        let transform = CGAffineTransform(scaleX: 1, y: -1)
        ciImage = ciImage.transformed(by: transform)

        let extent = ciImage.extent

        // Calculate translation needed to move to origin
        let translationX = -extent.minX
        let translationY = -extent.minY

        // Apply translation transform
        ciImage = ciImage.transformed(by: CGAffineTransform(translationX: translationX, y: translationY))

        guard let pixelBuffer = makePixelBuffer(width: texture.width, height: texture.height) else { return nil }
        context.render(ciImage, to: pixelBuffer)
        return pixelBuffer
    }

    /// Converts a Metal texture back into a UIImage.
    private func createImage(from texture: MTLTexture) -> UIImage? {
        guard var ciImage = CIImage(mtlTexture: texture, options: [:]) else { return nil }
        let transform = CGAffineTransform(scaleX: 1, y: -1)
        ciImage = ciImage.transformed(by: transform)

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Alternative UIImage to PixelBuffer

    /// Converts a `UIImage` directly into a pixel buffer without resizing.
    /// This is simpler but less efficient than the GPU path.
    func convertUIImageToPixelBuffer(_ image: UIImage, size: CGSize) -> CVPixelBuffer? {
        guard let cgImage = image.cgImage else { return nil }

        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue]
        var buffer: CVPixelBuffer?

        let success = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32BGRA, attrs as CFDictionary, &buffer)

        guard success == kCVReturnSuccess, let buffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])

        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        let pixelData = CVPixelBufferGetBaseAddress(buffer)

        guard let context = CGContext(
            data: pixelData,
            width: Int(image.size.width),
            height: Int(image.size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue) else {
            return nil
        }

        context.draw(cgImage, in: .init(origin: .zero, size: image.size))

        return buffer
    }
}
