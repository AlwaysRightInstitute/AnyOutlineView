//
//  AnyOutlineView.swift
//  TestIt
//
//  Created by Helge Heß on 26.01.20.
//  Copyright © 2020 ZeeZide GmbH. All rights reserved.
//

#if os(macOS)

import Cocoa

/**
 * Any NSOutlineView which actually works w/ `Any` values, i.e. value types.
 *
 * The view itself is its own _NSOutlineViewDataSource_. Use the `anyDataSource`
 * to provide the actual data.
 *
 * ## NSOutlineView
 *
 * `NSOutlineView` only works w/ `AnyObject`s, because it uses identity to
 * maintain its internal state. I.e. the API's `Any` parameters are incorrectly
 * mapped to Swift as `Any`. They actually have to be `AnyObject`s for all but
 * the most static outline view.
 *
 * This subclass works around that by maintaining an object tree for the new
 * `AnyOutlineViewDataSource`.
 * To make this work, that datasource needs to be able to give the items an
 * "identity".
 *
 * This view doesn't come for free, it essentially has to mirror the whole
 * data provided by the `anyDataSource`. It tries to do lookups lazily though.
 */
@objc(AnyOutlineView)
open class AnyOutlineView: NSOutlineView {
  
  open weak var anyDataSource : AnyOutlineViewDataSource? {
    didSet {
      if oldValue !== anyDataSource { reloadData() }
    }
  }
  open weak var anyDelegate : AnyOutlineViewDelegate?
  
  override open var dataSource: NSOutlineViewDataSource? {
    set {
      assert(newValue === self,
             "attempt to set the `AnyOutlineView` datasource to something else")
    }
    get { return self }
  }
  override open var delegate: NSOutlineViewDelegate? {
    set {
      assert(newValue === self,
             "attempt to set the `AnyOutlineView` delegate to something else")
      super.delegate = newValue
    }
    get { // override is not enough for delegate
      return super.delegate
    }
  }
  
  
  // MARK: - Init
  
  public override init(frame: NSRect) {
    super.init(frame: frame)
    setup()
  }
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
  private func setup() {
    self.delegate   = self
    self.dataSource = self
  }
  
  
  // MARK: - Item Tree
  
  public final class Item: CustomStringConvertible {
    
    public enum Value {
      case fault
      case item(Item)
    }
    
    public unowned let parent: Item?
    public var value    : Any
    public var children : [ Value ]?
    
    public init(_ value: Any, parent: Item?) {
      self.value  = value
      self.parent = parent
    }
    
    private func ensureCapacity(_ count: Int) {
      if children == nil { children = [ Value ]() }
      children!.reserveCapacity(count)
      while children!.count < count { children!.append(.fault) }
    }
    func registerCount(_ count: Int) {
      ensureCapacity(count)
    }
    
    func index(of item: Item) -> Int? { // TBD we could store the index I guess
      guard let children = children else { return nil }
      return children.firstIndex(where: { itemValue in
        switch itemValue {
          case .fault: return false
          case .item(let arrayItem): return arrayItem === item
        }
      })
    }
    
    public var description: String { return String(describing: value) }
  }
  public var root = Item(2007, parent: nil)
  
  private func updateItem(_ item: Any?, updateChildren: Bool) {
    guard let dataSource = anyDataSource else {
      assertionFailure("missing datasource for reload operation")
      return
    }
    
    let typedItem = item as? Item
    guard let ownItem = (item == nil ? root : typedItem) else {
      assertionFailure("could not locate own item: \(item as Any)")
      return
    }
    
    // If it is not the root, patch the value
    if let typedItem = typedItem, let parent = typedItem.parent {
      if let typedItemIndex = parent.index(of: typedItem) {
        typedItem.value =
          dataSource.outlineView(self, child: typedItemIndex,
                                 ofItem: parent === root ? nil : parent.value)
      }
      else {
        assertionFailure("could not locate item in parent")
      }
    }
    
    // Passing `nil` as the `item` will reload everything under the root.
    // Tested: reloadItem() w/o reloadChildren does NOT query the count or
    //         reload the children at all.
    // Only reloadChildren: true requiries the count (and then the children)
    if typedItem == nil || updateChildren {
      ownItem.children = nil // reset our whole map
      ensureCountInItem(ownItem)
    }
  }
  
  
  // MARK: - Modifying OutlineView API
  
  override open func reloadData() {
    defer { super.reloadData() }
    root = Item(2007, parent: nil)
    // TODO: do we really want this? Is the OutlineView still going to cache?
  }
  
  open func reloadObjectItem(_ item: Any?, reloadChildren: Bool) {
    // Tested: `reloadItem` doesn't recursive on _itself_ w/ `reloadChildren`.
    // We need to patch the whole hierarchy upfront.
    defer {
      super.reloadItem(item, reloadChildren: reloadChildren)
    }
    updateItem(item, updateChildren: reloadChildren)
  }
      
  open func insertObjectItems(at indexes: IndexSet, inParent parent: Any?,
                              withAnimation animationOptions:
                                NSTableView.AnimationOptions = [])
  {
    defer {
      super.insertItems(at: indexes, inParent: parent,
                        withAnimation: animationOptions)
    }
    
    let ownParent = (parent as? Item) ?? root
    ensureCountInItem(ownParent)
    
    for index in indexes.reversed() {
      ownParent.children?.insert(.fault, at: index)
    }
  }
  
  open func removeObjectItems(at indexes: IndexSet,inParent parent: Any?,
                              withAnimation animationOptions:
                                NSTableView.AnimationOptions = [])
  {
    defer {
      super.removeItems(at: indexes, inParent: parent,
                        withAnimation: animationOptions)
    }
    
    let ownParent = (parent as? Item) ?? root
    ensureCountInItem(ownParent)
    
    for index in indexes.reversed() {
      ownParent.children?.remove(at: index)
    }
  }
  
  open func moveObjectItem(at fromIndex : Int, inParent oldParent : Any?,
                           to toIndex   : Int, inParent newParent : Any?)
  {
    defer {
      super.moveItem(at: fromIndex, inParent: oldParent,
                     to: toIndex,   inParent: newParent)
    }
    assert(oldParent == nil || oldParent is Item)
    assert(newParent == nil || newParent is Item)
    
    let ownOldParent = (oldParent as? Item) ?? root
    let ownNewParent = (newParent as? Item) ?? root
    
    ensureCountInItem(ownOldParent)
    ensureCountInItem(ownNewParent)
    
    let oldValue = ownOldParent.children?.remove(at: fromIndex) ?? .fault
    ownNewParent.children?.insert(oldValue, at: toIndex)
  }
  
  
  // MARK: - Back Mapping API

  override open func reloadItem(_ item: Any?, reloadChildren: Bool) {
    guard let plainItem = item, !(plainItem is Item) else {
      return reloadObjectItem(item, reloadChildren: reloadChildren)
    }
    
    guard let objectItem = lookupItem(for: plainItem) else { return }
    reloadObjectItem(objectItem, reloadChildren: reloadChildren)
  }

  override open func insertItems(at indexes: IndexSet, inParent parent: Any?,
                                 withAnimation animationOptions:
                                   NSTableView.AnimationOptions = [])
  {
    guard let plainParent = parent, !(plainParent is Item) else {
      return insertObjectItems(at: indexes, inParent: parent,
                               withAnimation: animationOptions)
    }
    
    guard let objectParent = lookupItem(for: plainParent) else { return }
    return insertObjectItems(at: indexes, inParent: objectParent,
                             withAnimation: animationOptions)
  }
  
  override open func removeItems(at indexes: IndexSet,inParent parent: Any?,
                                 withAnimation animationOptions:
                                   NSTableView.AnimationOptions = [])
  {
    guard let plainParent = parent, !(plainParent is Item) else {
      return removeObjectItems(at: indexes, inParent: parent,
                               withAnimation: animationOptions)
    }
    
    guard let objectParent = lookupItem(for: plainParent) else { return }
    return removeObjectItems(at: indexes, inParent: objectParent,
                             withAnimation: animationOptions)
  }
  
  override open func moveItem(at fromIndex : Int, inParent oldParent : Any?,
                              to toIndex   : Int, inParent newParent : Any?)
  {
    if oldParent == nil && newParent == nil {
      moveObjectItem(at: fromIndex, inParent: nil, to: toIndex, inParent: nil)
    }
    else if oldParent is Item || newParent is Item {
      moveObjectItem(at: fromIndex, inParent: oldParent,
                     to: toIndex,   inParent: newParent)
    }
    else {
      let oldObjectParent : Item?
      if let oldParent = oldParent {
        guard let result = lookupItem(for: oldParent) else { return }
        oldObjectParent = result
      }
      else { oldObjectParent = nil }
      
      let newObjectParent : Item?
      if let newParent = newParent {
        guard let result = lookupItem(for: newParent) else { return }
        newObjectParent = result
      }
      else { newObjectParent = nil }
      
      moveObjectItem(at: fromIndex, inParent: oldObjectParent,
                     to: toIndex,   inParent: newObjectParent)
    }
  }

  
  // MARK: - Retrieval

  private func lookupItem(for value: Any) -> Item? {
    guard let item = _lookupItem(for: value, in: root) else {
      print("failed to locate item in outline view: \(value)")
      assertionFailure("failed to locate value in outline view: \(value)")
      return nil
    }
    return item
  }
  private func _lookupItem(for value: Any, in parent: Item) -> Item? {
    // We could make it ID based, but that would probably mean AnyHashable or
    // generics. For this we want to keep it "Any".
    guard let dataSource = anyDataSource else { return nil }
    guard let children = parent.children else { return nil }
    
    for fault in children {
      guard case .item(let item) = fault else { continue }
      if dataSource.outlineView(self, is: value, identical: item.value) {
        return item
      }
    }
    for fault in children {
      guard case .item(let item) = fault else { continue }
      if let child = _lookupItem(for: value, in: item) { return child }
    }
    return nil
  }
  

  @discardableResult
  fileprivate func ensureCountInItem(_ item: Item) -> Int {
    if let count = item.children?.count { return count } // have it already
    
    let count = anyDataSource?
                  .outlineView(self, numberOfChildrenOfItem:
                                       (item === root ? nil : item.value))
             ?? 0
    
    item.registerCount(count)
    return count
  }
  
  internal func assertOwnItem(_ item: Any?, in outlineView: NSOutlineView,
                              file: StaticString = #file, line: UInt = #line)
  {
    assert(item == nil || item is Item,
           "unexpected item in AnyOutlineView \(item as Any)",
           file: file, line: line)
    assert(outlineView === self,
           "Call to AnyOutlineView datasource from different view",
           file: file, line: line)
  }

}

extension AnyOutlineView: NSOutlineViewDataSource {
  
  public func outlineView(_ outlineView: NSOutlineView,
                          numberOfChildrenOfItem item: Any?)
              -> Int
  {
    assertOwnItem(item, in: outlineView)
    let typedItem = item as? Item
    let ownItem   = typedItem ?? root
    return ensureCountInItem(ownItem)
  }

  public func outlineView(_ outlineView: NSOutlineView,
                          child index: Int, ofItem item: Any?)
              -> Any
  {
    assertOwnItem(item, in: outlineView)
    let typedItem = item as? Item
    let ownItem   = typedItem ?? root
    _ = ensureCountInItem(ownItem)
    
    if case .item(let childItem) = ownItem.children![index] {
      return childItem
    }
    
    guard let dataSource = anyDataSource else {
      assertionFailure("missing datasource for child lookup")
      return "42"
    }
    
    let childValue = dataSource.outlineView(self, child: index,
                                            ofItem: typedItem?.value)
    let childItem = Item(childValue, parent: ownItem)
    ownItem.children![index] = .item(childItem)
    
    return childItem
  }

  public func outlineView(_ outlineView: NSOutlineView,
                          isItemExpandable item: Any) -> Bool
  {
    assertOwnItem(item, in: outlineView)
    guard let typedItem = item as? Item else {
      return false
    }
    return anyDataSource?.outlineView(self, isItemExpandable: typedItem.value)
        ?? false
  }
}

extension AnyOutlineView: NSOutlineViewDelegate {
  // Note: no Cell-based OutlineView methods

  @inline(__always)
  private func unwrap(_ item: Any) -> Any {
    return ((item as? Item)?.value) ?? item
  }
  
  public func outlineView(_ outlineView: NSOutlineView,
                          viewFor tableColumn: NSTableColumn?, item: Any)
              -> NSView?
  {
    assertOwnItem(item, in: outlineView)
    return anyDelegate?.outlineView(self, viewFor: tableColumn,
                                    item: unwrap(item))
  }
  
  public func outlineView(_ outlineView: NSOutlineView,
                          didAdd rowView: NSTableRowView, forRow row: Int)
  {
    anyDelegate?.outlineView(self, didAdd: rowView, forRow: row)
  }
  public func outlineView(_ outlineView: NSOutlineView,
                          didRemove rowView: NSTableRowView, forRow row: Int)
  {
    anyDelegate?.outlineView(self, didRemove: rowView, forRow: row)
  }
  
  public func outlineView(_ outlineView: NSOutlineView,
                          shouldEdit tableColumn: NSTableColumn?, item: Any)
              -> Bool
  {
    assertOwnItem(item, in: outlineView)
    return anyDelegate?.outlineView(self, shouldEdit: tableColumn,
                                    item: unwrap(item))
        ?? false
  }

  public func selectionShouldChange(in outlineView: NSOutlineView) -> Bool {
    return anyDelegate?.selectionShouldChange(in: self) ?? true
  }

  
  public func outlineView(_ outlineView: NSOutlineView,
                          shouldSelectItem item: Any) -> Bool
  {
    return anyDelegate?.outlineView(self, shouldSelectItem: unwrap(item))
        ?? false
  }
  // TBD: proposedSelectionIndexes

  public func outlineView(_ outlineView: NSOutlineView,
                          shouldSelect tableColumn: NSTableColumn?) -> Bool
  {
    return anyDelegate?.outlineView(self, shouldSelect: tableColumn) ?? true
  }

  public func outlineView(_ outlineView: NSOutlineView,
                          isGroupItem item: Any) -> Bool
  {
    return anyDelegate?.outlineView(self, isGroupItem: unwrap(item)) ?? false
  }
  public func outlineView(_ outlineView: NSOutlineView,
                          shouldExpandItem item: Any) -> Bool
  {
    return anyDelegate?.outlineView(self, shouldExpandItem: unwrap(item))
        ?? true
  }
  public func outlineView(_ outlineView: NSOutlineView,
                          shouldCollapseItem item: Any) -> Bool
  {
    return anyDelegate?.outlineView(self, shouldCollapseItem: unwrap(item))
        ?? true
  }

  // TODO:
  #if false // TODO:
  func outlineView(_ outlineView: NSOutlineView,
                   mouseDownInHeaderOf tableColumn: NSTableColumn) {}
  func outlineView(_ outlineView: NSOutlineView,
                   didClick tableColumn: NSTableColumn) {}
  func outlineView(_ outlineView: NSOutlineView,
                   didDrag tableColumn: NSTableColumn) {}
  
  func outlineView(_ outlineView: NSOutlineView,
                   shouldShowCellExpansionFor tableColumn: NSTableColumn?,
                   item: Any) -> Bool

  func outlineView(_ outlineView: NSOutlineView,
                   typeSelectStringFor tableColumn: NSTableColumn?,
                   item: Any) -> String? { return "TODO" }
  func outlineView(_ outlineView: NSOutlineView,
                   nextTypeSelectMatchFromItem startItem: Any,
                   toItem endItem: Any,
                   for searchString: String) -> Any? { return nil }
  func outlineView(_ outlineView: NSOutlineView,
                   shouldTypeSelectFor event: NSEvent,
                   withCurrentSearch searchString: String?) -> Bool
  func outlineView(_ outlineView: NSOutlineView,
                   sizeToFitWidthOfColumn column: Int) -> CGFloat { return 0 }
  func outlineView(_ outlineView: NSOutlineView,
                   shouldReorderColumn columnIndex: Int,
                   toColumn newColumnIndex: Int) -> Bool { return true }
  #endif

  // TBD:
  // func outlineView(_ outlineView: NSOutlineView,
  //                  heightOfRowByItem item: Any) -> CGFloat

  
  public func outlineViewSelectionDidChange(_ notification: Notification) {
    anyDelegate?.outlineViewSelectionDidChange(notification)
  }
  public func outlineViewColumnDidMove(_ notification: Notification) {
    anyDelegate?.outlineViewColumnDidMove(notification)
  }
  public func outlineViewColumnDidResize(_ notification: Notification) {
    anyDelegate?.outlineViewColumnDidResize(notification)
  }
  public func outlineViewSelectionIsChanging(_ notification: Notification) {
    anyDelegate?.outlineViewSelectionIsChanging(notification)
  }
  public func outlineViewItemWillExpand(_ notification: Notification) {
    anyDelegate?.outlineViewItemWillExpand(notification)
  }
  public func outlineViewItemDidExpand(_ notification: Notification) {
    anyDelegate?.outlineViewItemDidExpand(notification)
  }
  public func outlineViewItemWillCollapse(_ notification: Notification) {
    anyDelegate?.outlineViewItemWillCollapse(notification)
  }
  public func outlineViewItemDidCollapse(_ notification: Notification) {
    anyDelegate?.outlineViewItemDidCollapse(notification)
  }
}

#endif // macOS
