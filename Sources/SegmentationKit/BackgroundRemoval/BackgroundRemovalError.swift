//
//  BackgroundRemovalError.swift
//  SegmentationKit
//
//  Created by hari krishna on 20/08/2025.
//

import Foundation

// MARK: - Error Types

/// Errors that may occur during background removal and image processing.
enum BackgroundRemovalError: Error {
    case failedToLoadModel
    case failedToProcessImage
    case failedToResizeImage
    case missingCGImage
    case textureCreationFailedFromCgImage
    case pixelBufferCreationFailed
    case ciImageCreationFailed
    case failedToInitializeHelper
    case insufficientMemory
}
