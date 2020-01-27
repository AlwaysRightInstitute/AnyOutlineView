//
//  ArraySectionAnyOutlineViewDataSource.swift
//  TestAnyOutlineView
//
//  Created by Helge Heß on 27.01.20.
//  Copyright © 2020 ZeeZide GmbH. All rights reserved.
//

import Cocoa
import DifferenceKit
import AnyOutlineView

final class ArraySectionAnyOutlineViewDataSource
              <Model: Differentiable, Element: Differentiable>
            : AnyOutlineViewDataSource
{
  
  typealias Section = ArraySection<Model, Element>
  
  var sections : [ Section ]
  
  init(_ sections: [ Section ]) { self.sections = sections }
  
  func outlineView(_ ov: AnyOutlineView, numberOfChildrenOfItem item: Any?)
       -> Int
  {
    return (item as? Section)?.elements.count ?? sections.count
  }
  func outlineView(_ ov: AnyOutlineView, child index: Int, ofItem item: Any?)
       -> Any
  {
    return (item as? Section)?.elements[index] ?? sections[index]
  }
  
  func outlineView(_ outlineView: AnyOutlineView,
                   isItemExpandable item: Any) -> Bool
  {
    return item is Section
  }

  func outlineView(_ outlineView: AnyOutlineView,
                   is item: Any, identical toItem: Any) -> Bool
  {
    if let item = item as? Section, let toItem = toItem as? Section {
      return item.differenceIdentifier == toItem.differenceIdentifier
    }
    else if let item = item as? Model, let toItem = toItem as? Model {
      return item.differenceIdentifier == toItem.differenceIdentifier
    }
    else {
      return false
    }
  }
  
}
