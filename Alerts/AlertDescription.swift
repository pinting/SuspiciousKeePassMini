//
//  AlertDescription.swift
//  KeePassMini
//
//  Created by Frank Hausmann on 14.03.23.
//  Copyright © 2023 Self. All rights reserved.
//

import Foundation
import SwiftEntryKit

// Description of a single preset to be presented
struct PresetDescription {
    let title: String
    let description: String
    let thumb: String
    let attributes: EKAttributes
    
    init(with attributes: EKAttributes, title: String, description: String = "", thumb: String) {
        self.attributes = attributes
        self.title = title
        self.description = description
        self.thumb = thumb
    }
}
