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

enum Section: String, CaseIterable {
  
  case dropbox      = "Dropbox"
  case airdrop      = "AirDrop"
  case applications = "Applications"
  case desktop      = "Desktop"
  
  var items : [ String ] {
    switch self {
      case .dropbox: return [ "Public", "Documents", "Other" ]
      case .airdrop: return [ "MacPro2020", "iMac Blueberry" ]
      case .applications:
        return [ "Diagram.app", "FrameMaker.app", "ProjectBuilder.app" ]
      case .desktop: return [ "Kaffee", "Kuchen", "Krümel" ]
    }
  }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!
  @IBOutlet weak var outlineView: AnyOutlineView!
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    outlineView.anyDelegate   = self
    outlineView.anyDataSource = self
    
    outlineView.expandItem(nil, expandChildren: true)
  }
}

extension AppDelegate: AnyOutlineViewDataSource {
  
  func outlineView(_ outlineView: AnyOutlineView,
                   numberOfChildrenOfItem item: Any?) -> Int
  {
    switch item {
      case .none:                  return Section.allCases.count // root
      case let section as Section: return section.items.count
      default:                     return 0
    }
  }
  
  func outlineView(_ outlineView: AnyOutlineView,
                   child index: Int, ofItem item: Any?) -> Any
  {
    switch item {
      case .none:                  return Section.allCases[index]
      case let section as Section: return section.items[index]
      default: fatalError("unexpected item: \(item as Any)")
    }
  }
  
  func outlineView(_ outlineView: AnyOutlineView, isItemExpandable item: Any)
       -> Bool
  {
    return item is Section
  }
}

extension AppDelegate: AnyOutlineViewDelegate {
  
  enum CellID {
    static let header = NSUserInterfaceItemIdentifier(rawValue: "HeaderCell")
    static let data   = NSUserInterfaceItemIdentifier(rawValue: "DataCell")
  }
  
  func outlineView(_ outlineView: AnyOutlineView,
                   viewFor tableColumn: NSTableColumn?, item: Any) -> NSView?
  {
    let cell : NSTableCellView
    if let section = item as? Section {
      cell = outlineView.makeView(withIdentifier: CellID.header, owner: nil)
             as! NSTableCellView
      cell.textField?.stringValue = section.rawValue
    }
    else {
      cell = outlineView.makeView(withIdentifier: CellID.data, owner: nil)
             as! NSTableCellView
      cell.textField?.stringValue = String(describing: item)
    }
    return cell
  }
}
