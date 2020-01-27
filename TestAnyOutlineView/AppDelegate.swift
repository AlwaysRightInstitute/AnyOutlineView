//
//  AppDelegate.swift
//  TestAnyOutlineView
//
//  Created by Helge Heß on 27.01.20.
//  Copyright © 2020 ZeeZide GmbH. All rights reserved.
//

import Cocoa
import AnyOutlineView

// Notes:
// - set the outlineview class to `AnyOutlineView` in the NIB (no module!)
// - create an outlet, do NOT wire up delegate/datasource! (TODO, how can
//   we expose `anyDelegate`, `anyaDataSource` to IB?)


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!
  @IBOutlet weak var outlineView: AnyOutlineView!
  
  @IBAction func performModification(_ sender: Any) {
  }
  @IBAction func changeChildItem(_ sender: Any) {
  }
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    outlineView.anyDelegate   = arraySectionDelegate
    outlineView.anyDataSource = arraySectionDataSource
    
    outlineView.expandItem(nil, expandChildren: true)
  }
  
  let arraySectionDataSource = ArraySectionAnyOutlineViewDataSource(source)
  let arraySectionDelegate   = ArraySectionDelegate()
}

import struct DifferenceKit.ArraySection

final class ArraySectionDelegate: AnyOutlineViewDelegate {
  
  enum CellID {
    static let header = NSUserInterfaceItemIdentifier(rawValue: "HeaderCell")
    static let data   = NSUserInterfaceItemIdentifier(rawValue: "DataCell")
  }
  
  func outlineView(_ outlineView: AnyOutlineView,
                   viewFor tableColumn: NSTableColumn?, item: Any) -> NSView?
  {
    let cell : NSTableCellView
    if let section = item as? ArraySection<String, String> {
      cell = outlineView.makeView(withIdentifier: CellID.header, owner: nil)
             as! NSTableCellView
      cell.textField?.stringValue = section.model
    }
    else {
      cell = outlineView.makeView(withIdentifier: CellID.data, owner: nil)
             as! NSTableCellView
      cell.textField?.stringValue = String(describing: item)
    }
    return cell
  }
}
