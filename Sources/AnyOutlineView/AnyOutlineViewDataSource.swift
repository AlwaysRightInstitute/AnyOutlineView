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
  
  /**
   * This needs to be implemented if APIs are being used which take an `item`
   * or `parent` item argument, e.g. `reloadItem` or `removeItems`.
   *
   * The `AnyOutlineView` will then walk its data mirror to find the proper
   * object-item from the Any in its shadow structure. (expensive)
   */
  func outlineView(_ outlineView: AnyOutlineView,
                   is item: Any, identical toItem: Any) -> Bool
}

public extension AnyOutlineViewDataSource {
  
  func outlineView(_ outlineView: AnyOutlineView,
                   is item: inout Any, identical toItem: inout Any) -> Bool
  {
    return ObjectIdentifier(item   as AnyObject)
        == ObjectIdentifier(toItem as AnyObject)
  }
}

#endif // macOS
