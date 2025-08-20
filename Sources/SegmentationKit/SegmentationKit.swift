// The Swift Programming Language
// https://docs.swift.org/swift-book


public final class SegmentationKit {
    public static func makeBackgroundRemover(model: BackgroundRemovalModel) throws -> Segmentation {
        switch model {
        case .deepLabV3:
            return try DeepLabBackgroundRemover()
        }
    }
}
