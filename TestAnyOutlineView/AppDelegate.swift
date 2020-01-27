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

enum Section {
  
  case dropbox     (items: [ String ])
  case airdrop     (items: [ String ])
  case applications(items: [ String ])
  case desktop     (items: [ String ])
  
  var label : String {
    switch self {
      case .dropbox:      return "Dropbox"
      case .airdrop:      return "AirDrop"
      case .applications: return "Applications"
      case .desktop:      return "Desktop"
    }
  }
  
  var items : [ String ] {
    set {
      switch self {
        case .dropbox:      self = .dropbox     (items: newValue)
        case .airdrop:      self = .airdrop     (items: newValue)
        case .applications: self = .applications(items: newValue)
        case .desktop:      self = .desktop     (items: newValue)
      }
    }
    get {
      switch self {
        case .dropbox(let items), .airdrop(let items), .applications(let items),
             .desktop(let items): return items
      }
    }
  }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!
  @IBOutlet weak var outlineView: AnyOutlineView!
  
  var data : [ Section ] = [
    .dropbox(items: [ "Public", "Documents", "Other" ]),
    .airdrop(items: [ "MacPro2020", "iMac Blueberry" ]),
    .applications(items: [
      "Diagram.app", "FrameMaker.app", "ProjectBuilder.app"
    ]),
    .desktop(items: [ "Kaffee", "Kuchen", "Krümel" ])
  ]
  
  @IBAction func performModification(_ sender: Any) {
    var items = data[2].items
    let front = items.remove(at: 0) // move 0 to 1 (1 goes to 0)
    items.insert(front, at: 1)
    data[2].items = items
    outlineView.moveItem(at: 0, inParent: data[2], to: 1, inParent: data[2])
  }
  @IBAction func changeChildItem(_ sender: Any) {
    var items = data[2].items
    items[1] += " ★"
    data[2].items = items
    #if false
      // this doesn't work, because String identity
      outlineView.reloadItem(items[1])
    #else
      // so we need to reload the parent for this to work
      outlineView.reloadItem(data[2], reloadChildren: true)
    #endif
  }
  
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
      case .none:                  return data.count // root
      case let section as Section: return section.items.count
      default:                     return 0
    }
  }
  
  func outlineView(_ outlineView: AnyOutlineView,
                   child index: Int, ofItem item: Any?) -> Any
  {
    switch item {
      case .none:                  return data[index]
      case let section as Section: return section.items[index]
      default: fatalError("unexpected item: \(item as Any) \(type(of: item))")
    }
  }
  
  func outlineView(_ outlineView: AnyOutlineView, isItemExpandable item: Any)
       -> Bool
  {
    return item is Section
  }

  func outlineView(_ outlineView: AnyOutlineView,
                   is item: Any, identical toItem: Any) -> Bool
  {
    if let item = item as? Section, let toItem = toItem as? Section {
      switch ( item, toItem ) {
        case ( .dropbox, .dropbox ), ( .airdrop, .airdrop ),
             ( .applications, .applications ), ( .desktop, .desktop ):
          return true
        default:
          return false
      }
    }
    else if let item = item as? String, let toItem = toItem as? String {
      return item == toItem
    }
    else {
      return false
    }
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
      cell.textField?.stringValue = section.label
    }
    else {
      cell = outlineView.makeView(withIdentifier: CellID.data, owner: nil)
             as! NSTableCellView
      cell.textField?.stringValue = String(describing: item)
    }
    return cell
  }
}
