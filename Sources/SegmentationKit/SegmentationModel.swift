//
//  SegmentationModel.swift
//  SwiftMLKit
//
//  Created by hari krishna on 29/08/2025.
//


public enum SegmentationModel: Identifiable {
    case deepLabV3
    case u2Net
    
    public var id: Self { self }
}
