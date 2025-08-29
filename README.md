# SwiftMLKit

**SwiftMLKit** is a modular Swift package that brings **on-device machine learning capabilities** to iOS applications. It is designed as an umbrella framework, where each module focuses on a specific ML task, all powered by Core ML for privacy-focused, high-performance inference.

Currently implemented: **SegmentationKit** (DeepLabV3, U²-Net coming soon).

Future modules: **PoseKit**, **DetectionKit**.

---

## Features

- **🛡️ Privacy-First**: All processing happens on-device  
- **📱 Modular Architecture**: Use only the modules you need  
- **⚡ High Performance**: Optimized Core ML models for real-time inference  
- **🔄 Async/Await Support**: Smooth integration with Swift concurrency  
- **🎯 Multiple Use Cases**: Background removal, subject extraction, pose estimation, object detection (future)

---

## Modules Overview

| Module             | Description                                 | Status            |
|-------------------|---------------------------------------------|-----------------|
| **SegmentationKit** | Image segmentation & background removal     | Stable           |
| **PoseKit**         | Human pose estimation                        | Coming Soon      |
| **DetectionKit**    | Object detection                             | Coming Soon      |

---

## SegmentationKit

On-device background removal and image segmentation with pixel-accurate masks.

**Models Implemented:**
- **DeepLabV3**: High-accuracy semantic segmentation  
- **U²-Net**: Lightweight alternative for faster inference *(Coming Soon)*

**Use Cases:** Background removal, subject extraction, image editing

---

### Quick Start

```swift
import SwiftUI
import SegmentationKit

struct ContentView: View {
    @State private var processedImage: UIImage?
    
    let inputImage = UIImage(named: "example.jpg")!
    
    var body: some View {
        VStack {
            if let processedImage {
                Image(uiImage: processedImage)
                    .resizable()
                    .scaledToFit()
            }
            
            Button("Remove Background") {
                Task {
                    do {
                        let segmenter = try SegmentationKit.makeBackgroundRemover(model: .deepLabV3)
                        let result = try await segmenter.segment(image: inputImage)
                        processedImage = result
                    } catch {
                        print("Segmentation failed:", error)
                    }
                }
            }
        }
    }
}
```

---

## Performance Considerations

- **Model Loading**: Initialize models once and reuse for better performance  
- **Image Preprocessing**: Handled automatically for correct input sizes  
- **Memory Management**: Run processing on background queues  
- **Device Compatibility**: Neural Engine on newer devices improves speed

---

## Installation

SwiftMLKit can be installed via **Swift Package Manager**:

```swift
https://github.com/harikrishnabista7/SwiftMLKit
```

1. In Xcode: **File > Add Package Dependency…**  
2. Enter the repository URL above  
3. Select the modules you need (e.g., `SegmentationKit`)  
4. Choose the version and add to your project

---

## Demo Applications

- **SegmentationKitExample**: Demonstrates background removal

Future demos will include **PoseKit** and **DetectionKit** once implemented.

---

## Roadmap

- Add U²-Net to SegmentationKit  
- Implement PoseKit for human pose estimation  
- Implement DetectionKit for object detection  
- Real-time video support for segmentation and detection  
- Add more Core ML models for other ML tasks

---

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md).  
- Add new models  
- Improve existing functionality  
- Report issues  
- Submit feature requests

---

## Requirements

- iOS 15.0+  
- Xcode 13.0+

---

## License

SwiftMLKit is available under the MIT license. See [LICENSE](LICENSE).

---

## Acknowledgments

- Core ML models adapted from research papers and open-source implementations  
- Thanks to the open-source ML community for model architectures and training techniques

---

**Built with ❤️ for the iOS developer community**


