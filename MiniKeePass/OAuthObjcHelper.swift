//
//  OAuthObjcHelper.swift
//  IOSKeePass
//
//  Created by Frank Hausmann on 31.01.22.
//  Copyright © 2022 Self. All rights reserved.
//

import Foundation
import OAuthSwift


@objc public class OAuthObjcHelper: NSObject{
    
   
    @objc public init(url: URL) {
        
        OAuthSwift.handle(url: url)
    }
    

}
