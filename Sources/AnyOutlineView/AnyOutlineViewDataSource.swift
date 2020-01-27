//
//  AnyOutlineViewDataSource.swift
//  TestIt
//
//  Created by Helge Heß on 26.01.20.
//  Copyright © 2020 ZeeZide GmbH. All rights reserved.
//

#if os(macOS)

import Cocoa

public protocol AnyOutlineViewDataSource: AnyObject {
  
  func outlineView(_ outlineView: AnyOutlineView,
                   numberOfChildrenOfItem item: Any?)
       -> Int
  func outlineView(_ outlineView: AnyOutlineView,
                   child index: Int, ofItem item: Any?)
       -> Any  
  func outlineView(_ outlineView: AnyOutlineView,
                   isItemExpandable item: Any) -> Bool
}

#endif // macOS
