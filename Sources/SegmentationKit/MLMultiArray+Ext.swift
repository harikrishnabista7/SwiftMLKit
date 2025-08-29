//
//  MLMultiArray+Ext.swift
//  SegmentationKit
//
//  Created by hari krishna on 20/08/2025.
//

import CoreGraphics
import CoreML

extension MLMultiArray {
    /// Creates a grayscale UIImage from MLMultiArray with automatic dimension detection
    /// Supports common Core ML output formats: [1, height, width] or [height, width]
    /// - Parameter isNormalized: Whether values are normalized (0.0-1.0) or raw pixels (0-255)
    /// - Returns: Grayscale UIImage or nil if creation fails
    func toGrayscaleCGImageAuto(isNormalized: Bool = true) -> CGImage? {
        let shape = self.shape.map { $0.intValue }
        let width: Int
        let height: Int

        // Handle different array shapes
        switch shape.count {
        case 2:
            // [height, width]
            height = shape[0]
            width = shape[1]
        case 3:
            // [1, height, width] or [channels, height, width]
            if shape[0] == 1 {
                height = shape[1]
                width = shape[2]
            } else {
                print("Error: Unsupported shape for grayscale conversion: \(shape)")
                return nil
            }
        case 4:
            // [batch, channels, height, width] - assume batch=1, channels=1
            if shape[0] == 1 && shape[1] == 1 {
                height = shape[2]
                width = shape[3]
            } else {
                print("Error: Unsupported shape for grayscale conversion: \(shape)")
                return nil
            }
        default:
            print("Error: Unsupported number of dimensions: \(shape.count)")
            return nil
        }

        return toGrayscaleCGImage(width: width, height: height, isNormalized: isNormalized)
    }

    /// Creates a grayscale UIImage from MLMultiArray
    /// Assumes the array contains normalized values (0.0 to 1.0) or pixel values (0 to 255)
    /// - Parameters:
    ///   - width: Image width
    ///   - height: Image height
    ///   - isNormalized: Whether values are normalized (0.0-1.0) or raw pixels (0-255)
    /// - Returns: Grayscale UIImage or nil if creation fails
    func toGrayscaleCGImage(width: Int, height: Int, isNormalized: Bool = true) -> CGImage? {
        // Validate array dimensions
        guard count >= width * height else {
            print("Error: MLMultiArray size (\(count)) is smaller than required (\(width * height))")
            return nil
        }

        // Create a bitmap context for grayscale
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGImageAlphaInfo.none.rawValue

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            print("Error: Failed to create CGContext")
            return nil
        }

        // Get pointer to the pixel data
        guard let pixelData = context.data?.bindMemory(to: UInt8.self, capacity: width * height) else {
            print("Error: Failed to get pixel data pointer")
            return nil
        }

        // Convert MLMultiArray data to pixel values
        for i in 0 ..< (width * height) {
            let value = self[i].floatValue

            // Convert to 0-255 range based on input type
            let pixelValue: UInt8
            if isNormalized {
                // Clamp normalized values to 0.0-1.0 range
                let clampedValue = max(0.0, min(1.0, value))
                pixelValue = UInt8(clampedValue * 255.0)
            } else {
                // Clamp raw pixel values to 0-255 range
                var clampedValue = max(0.0, min(255.0, value))
                if clampedValue > 0 {
                    clampedValue = 255
                }

                pixelValue = UInt8(clampedValue)
            }

            pixelData[i] = pixelValue
        }

        return context.makeImage()
    }

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
