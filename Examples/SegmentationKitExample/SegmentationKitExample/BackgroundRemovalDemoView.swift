//
//  BackgroundRemovalDemo.swift
//  SegmentationKitExample
//
//  Created by hari krishna on 20/08/2025.
//

import SegmentationKit
import SwiftUI

//enum BackgroundModel: String, CaseIterable, Identifiable {
//    case deepLab = "DeepLabV3"
//    case u2net = "U2Net"
//
//    var id: String { rawValue }
//}
extension SegmentationModel {
    static var cases: [SegmentationModel] {
        [.deepLabV3, .u2Net]
    }
    var rawValue: String {
        switch self {
        case .deepLabV3: return "DeepLabV3"
        case .u2Net: return "U2Net"
        }
    }

}

struct BackgroundRemovalDemoView: View {
    let images = ["a", "b", "c", "d", "e", "f"]

    @State private var selectedImage: String?
    @State private var processedImage: UIImage?
    @State private var selectedModel: SegmentationModel = .deepLabV3
    @State private var showImagePicker: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Menu {
                    ForEach(SegmentationModel.cases) { model in
                        Button {
                            selectedModel = model
                        } label: {
                            HStack {
                                Text(model.rawValue)
                                if selectedModel == model {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text("Model:")
                        Text(selectedModel.rawValue).bold()
                        Spacer()
                        Image(systemName: "chevron.down")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                // Images side by side
                VStack(spacing: 20) {
                    VStack {
                        Text("Original")
                        if let selectedImage {
                            Image(selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 16))

                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .overlay(Text("No image selected"))
                        }
                    }
                    .overlay(alignment: .bottom) {
                        Button {
                            showImagePicker = true
                        } label: {
                            Text("Select Image")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.accentColor)
                                .clipShape(Capsule())
                        }
                        .padding(.bottom)
                    }

                    VStack {
                        Text("Processed")
                        if let processedImage {
                            Image(uiImage: processedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .overlay(Text("No result yet"))
                        }
                    }
                }
                .padding(.horizontal)

                Button {
                    processImage()
                } label: {
                    Text("Process Image")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(selectedImage != nil ? Color.blue : Color.gray)
                        .clipShape(Capsule())
                }
                .disabled(selectedImage == nil)

                Spacer()
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(images: images, selectedImage: $selectedImage, showPicker: $showImagePicker)
            }
            .padding()
            .onChange(of: selectedImage, perform: { newValue in
                if newValue != nil {
                    processedImage = nil
                }
            })
        }
    }

    func processImage() {
        guard let selectedImage, let inputImage = UIImage(named: selectedImage) else { return }
        do {
            let segmentation = try SegmentationKit.makeSegmenter(model: selectedModel)
            Task {
                processedImage = try await segmentation.removeBackground(from: inputImage)
            }
        } catch {
            print(error)
        }
    }
}

#Preview {
    BackgroundRemovalDemoView()
}
