//
//  SegmentationDemoView.swift
//  SegmentationKitExample
//
//  Created by hari krishna on 30/08/2025.
//

import SwiftUI

struct SegmentationDemoView: View {
    var body: some View {
        List {
            NavigationLink("Background Removal") {
                BackgroundRemovalDemoView()
            }
            NavigationLink("Background Replace") {
                BackgroundReplaceDemoView()
            }
        }
        .navigationTitle(Text("Segmentation Demo"))
    }
}

#Preview {
    NavigationView {
        SegmentationDemoView()
    }
    
}
