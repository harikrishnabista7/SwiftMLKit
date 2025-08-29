//
//  ImagePickerView.swift
//  SegmentationKitExample
//
//  Created by hari krishna on 20/08/2025.
//

import SwiftUI

// MARK: - Image Picker

struct ImagePickerView: View {
    let images: [String]

    @Binding var selectedImage: String?
    @Binding var showPicker: Bool

    var body: some View {
        let rows = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        NavigationView {
            ScrollView {
                LazyVGrid(columns: rows, spacing: 10) {
                    ForEach(images, id: \.self) { value in
                        Button {
                            selectedImage = value
                        } label: {
                            Image(value)
                                .resizable()
                                .aspectRatio(1, contentMode: .fill)
                                .frame(height: 100)
                                .clipped()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedImage == value ? Color.accentColor : .clear, lineWidth: 3)
                                )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Select Image")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showPicker = false }
                }
            }
        }
    }
}
