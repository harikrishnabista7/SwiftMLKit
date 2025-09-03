//
//  BackgroundReplaceDemoView.swift
//  SegmentationKitExample
//
//  Created by hari krishna on 30/08/2025.
//

import SegmentationKit
import SwiftUI

struct BackgroundReplaceDemoView: View {
    let images = ["a", "b", "c", "d", "e", "f"]
    let backgrounds = ["b1", "b2", "b3", "b4", "b5", "b6"]

    @State private var selectedImage: String?
    @State private var selectedBackground: String?
    @State private var processedImage: UIImage?
    
    @State private var selectedModel: SegmentationModel = .deepLabV3
    @State private var showImagePicker: Bool = false
    @State private var showBackgroundPicker: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // --- Model Picker ---
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

                // --- Original & Background selection ---
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
                        Text("Background")
                        if let selectedBackground {
                            Image(selectedBackground)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .overlay(Text("No background selected"))
                        }
                    }
                    .overlay(alignment: .bottom) {
                        Button {
                            showBackgroundPicker = true
                        } label: {
                            Text("Select Background")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.accentColor)
                                .clipShape(Capsule())
                        }
                        .padding(.bottom)
                    }

                    // --- Processed Output ---
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

                // --- Replace Button ---
                Button {
                    replaceBackground()
                } label: {
                    Text("Replace Background")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background((selectedImage != nil && selectedBackground != nil) ? Color.blue : Color.gray)
                        .clipShape(Capsule())
                }
                .disabled(selectedImage == nil || selectedBackground == nil)

                Spacer()
            }
            // Image Picker for Foreground
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(images: images, selectedImage: $selectedImage, showPicker: $showImagePicker)
            }
            // Image Picker for Background
            .sheet(isPresented: $showBackgroundPicker) {
                ImagePickerView(images: backgrounds, selectedImage: $selectedBackground, showPicker: $showBackgroundPicker)
            }
            .padding()
            .onChange(of: selectedImage) { _ in processedImage = nil }
            .onChange(of: selectedBackground) { _ in processedImage = nil }
        }
    }

    func replaceBackground() {
        guard
            let selectedImage,
            let selectedBackground,
            let fg = UIImage(named: selectedImage),
            let bg = UIImage(named: selectedBackground)
        else { return }

        do {
            let segmentation = try SegmentationKit.makeSegmenter(model: .deepLabV3)
            
            Task {
                processedImage = try await segmentation.replaceBackground(of: fg, withBackground: bg)
            }
        } catch {
            print("Background replacement error: \(error)")
        }
    }
}


#Preview {
    BackgroundReplaceDemoView()
}
