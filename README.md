#  AnyOutlineView

An `NSOutlineView` that actually works with `Any`, i.e. w/ structs and enums.

`NSOutlineView` only works w/ `AnyObject`s, because it uses identity to
maintain its internal state. I.e. the API's `Any` parameters are incorrectly
mapped to Swift as `Any`. They actually have to be `AnyObject`s for all but
the most static outline view.

This subclass works around that by maintaining an object tree for the new
`AnyOutlineViewDataSource`.
To make this work, that datasource needs to be able to give the items an
"identity".

This view doesn't come for free, it essentially has to mirror the whole
data provided by the `anyDataSource`. It tries to do lookups lazily though.

## Example

### Model

```swift

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
```

### AnyOutlineViewDataSource

```swift
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
```

### AnyOutlineViewDelegate

```swift
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
```

## Who

Brought to you by
[The Always Right Institute](http://www.alwaysrightinstitute.com)
and
[ZeeZide](http://zeezide.de).
We like
[feedback](https://twitter.com/ar_institute),
GitHub stars,
cool [contract work](http://zeezide.com/en/services/services.html),
presumably any form of praise you can think of.
