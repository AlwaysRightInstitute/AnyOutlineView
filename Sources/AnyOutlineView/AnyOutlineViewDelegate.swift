//
//  AnyOutlineViewDelegate.swift
//  TestIt
//
//  Created by Helge Heß on 27.01.20.
//  Copyright © 2020 ZeeZide GmbH. All rights reserved.
//

#if os(macOS)

import Cocoa

public protocol AnyOutlineViewDelegate: AnyObject {
  
  func outlineView(_ outlineView: AnyOutlineView,
                   viewFor tableColumn: NSTableColumn?, item: Any) -> NSView?
  
  // MARK: - Optional

  func outlineView(_ outlineView: AnyOutlineView,
                   didAdd rowView: NSTableRowView, forRow row: Int)
  func outlineView(_ outlineView: AnyOutlineView,
                   didRemove rowView: NSTableRowView, forRow row: Int)

  func outlineView(_ outlineView: AnyOutlineView,
                   shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool

  func selectionShouldChange(in outlineView: AnyOutlineView) -> Bool

  func outlineView(_ outlineView: AnyOutlineView, shouldSelectItem item: Any)
       -> Bool
  func outlineView(_ outlineView: AnyOutlineView,
                   shouldSelect tableColumn: NSTableColumn?) -> Bool

  func outlineView(_ outlineView: AnyOutlineView, isGroupItem item: Any)
       -> Bool
  func outlineView(_ outlineView: AnyOutlineView, shouldExpandItem item: Any)
       -> Bool
  func outlineView(_ outlineView: AnyOutlineView, shouldCollapseItem item: Any)
       -> Bool

  func outlineViewSelectionDidChange (_ notification: Notification)
  func outlineViewColumnDidMove      (_ notification: Notification)
  func outlineViewColumnDidResize    (_ notification: Notification)
  func outlineViewSelectionIsChanging(_ notification: Notification)
  func outlineViewItemWillExpand     (_ notification: Notification)
  func outlineViewItemDidExpand      (_ notification: Notification)
  func outlineViewItemWillCollapse   (_ notification: Notification)
  func outlineViewItemDidCollapse    (_ notification: Notification)
}


// MARK: - Default Implementations of Optional Methods

public extension AnyOutlineViewDelegate {
  
  @inlinable
  func outlineView(_ outlineView: AnyOutlineView,
                   didAdd rowView: NSTableRowView, forRow row: Int) {}
  @inlinable
  func outlineView(_ outlineView: AnyOutlineView,
                   didRemove rowView: NSTableRowView, forRow row: Int) {}
  @inlinable
  func outlineView(_ outlineView: AnyOutlineView,
                   shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool
  {
    return false
  }
  @inlinable
  func selectionShouldChange(in outlineView: AnyOutlineView) -> Bool {
    return true
  }
  
  @inlinable
  func outlineView(_ outlineView: AnyOutlineView, shouldSelectItem item: Any)
       -> Bool
  {
    return true
  }
  @inlinable
  func outlineView(_ outlineView: AnyOutlineView,
                   shouldSelect tableColumn: NSTableColumn?) -> Bool {
    return true
  }

  @inlinable
  func outlineView(_ outlineView: AnyOutlineView, isGroupItem item: Any)
       -> Bool
  {
    return false
  }

  @inlinable
  func outlineView(_ outlineView: AnyOutlineView, shouldExpandItem item: Any)
       -> Bool
  {
    return true
  }
  @inlinable
  func outlineView(_ outlineView: AnyOutlineView, shouldCollapseItem item: Any)
       -> Bool
  {
    return true
  }

  @inlinable func outlineViewSelectionDidChange (_ n: Notification) {}
  @inlinable func outlineViewColumnDidMove      (_ n: Notification) {}
  @inlinable func outlineViewColumnDidResize    (_ n: Notification) {}
  @inlinable func outlineViewSelectionIsChanging(_ n: Notification) {}
  @inlinable func outlineViewItemWillExpand     (_ n: Notification) {}
  @inlinable func outlineViewItemDidExpand      (_ n: Notification) {}
  @inlinable func outlineViewItemWillCollapse   (_ n: Notification) {}
  @inlinable func outlineViewItemDidCollapse    (_ n: Notification) {}
}

#endif // macOS
