//
//  AnyOutlineViewStagedReload.swift
//  TestAnyOutlineView
//
//  Created by Helge Heß on 27.01.20.
//  Copyright © 2020 ZeeZide GmbH. All rights reserved.
//

import Cocoa
import DifferenceKit
import AnyOutlineView

public extension AnyOutlineView {
  
  /// Applies multiple animated updates in stages using `StagedChangeset`.
  ///
  /// - Note: There are combination of changes that crash when applied simultaneously in `performBatchUpdates`.
  ///         Assumes that `StagedChangeset` has a minimum staged changesets to avoid it.
  ///         The data of the data-source needs to be updated synchronously before `performBatchUpdates` in every stages.
  ///
  /// - Parameters:
  ///   - stagedChangeset: A staged set of changes.
  ///   - deleteRowsAnimation: An option to animate the row deletion.
  ///   - insertRowsAnimation: An option to animate the row insertion.
  ///   - interrupt: A closure that takes an changeset as its argument and returns `true` if the animated
  ///                updates should be stopped and performed reloadData. Default is nil.
  ///   - setData: A closure that takes the collection as a parameter.
  ///              The collection should be set to data-source of UICollectionView.
  func reload<C, M, E>(
    using stagedChangeset: StagedChangeset<C>,
    deleteRowsAnimation: NSTableView.AnimationOptions = .effectFade,
    insertRowsAnimation: NSTableView.AnimationOptions = .slideDown,
    interrupt: ((Changeset<C>) -> Bool)? = nil,
    setData: (C) -> Void
  )
    where C: Collection, C.Element == ArraySection<M, E>,
    M: Differentiable, E: Differentiable
  {
    if case .none = window, let sections = stagedChangeset.last?.data {
      setData(sections)
      return reloadData()
    }
    guard !stagedChangeset.isEmpty else { return }
        
    for changeset in stagedChangeset {
      #if DEBUG
        print("CHANGES:", changeset)
      #endif
      
      if let interrupt = interrupt, interrupt(changeset), let sections = stagedChangeset.last?.data {
        setData(sections)
        return reloadData()
      }
      
      
      var sectionIndexMap =
            AppKitIndexShifter(count: numberOfChildren(ofItem: nil))
      var elementIndexMaps : [ AppKitIndexShifter ] = {
        var array = [ AppKitIndexShifter ]()
        array.reserveCapacity(sectionIndexMap.count)
        for i in 0..<sectionIndexMap.count {
          let section = child(i, ofItem: nil)
          array[i] =
            AppKitIndexShifter(count: numberOfChildren(ofItem: section))
        }
        return array
      }()
      
      beginUpdates()
      defer { endUpdates() }
            
      setData(changeset.data)
      
      if !changeset.sectionDeleted.isEmpty {
        let set = IndexSet(changeset.sectionDeleted)
        set.reversed().forEach { sectionIndexMap.remove(at: $0) }
        removeItems(at: set, inParent: nil, withAnimation: deleteRowsAnimation)
      }
      
      if !changeset.sectionInserted.isEmpty {
        let set = IndexSet(changeset.sectionInserted)
        set.reversed().forEach { sectionIndexMap.remove(at: $0) }
        insertItems(at: set, inParent: nil, withAnimation: insertRowsAnimation)
      }
      
      if !changeset.sectionUpdated.isEmpty {
        for index in changeset.sectionUpdated {
          let sectionItem = child(index, ofItem: nil)
          reloadItem(sectionItem)
        }
      }
      
      for ( source, target ) in changeset.sectionMoved {
        // we get 2=>2 moves here
        var adjustedTarget = target
        if source == target { // 2=>2 is really 2=>3
          adjustedTarget += 1
        }
        // others are probably still wrong, we may need to adjust the
        // target as if the source was NOT dropped. I think the logic
        // in the differ assumes it is dropped.
        moveItem(at: source,         inParent: nil,
                 to: adjustedTarget, inParent: nil)
      }
      
      func groupBySection(_ pathes: [ ElementPath ]) -> [ Int : IndexSet ]
      {
        guard !pathes.isEmpty else { return [:] }
        
        if pathes.count == 1, let first = pathes.first {
          return [ first.section: [ first.element ] ]
        }
        
        var elementIndicesBySection = [ Int: IndexSet ]()
        for path in pathes {
          elementIndicesBySection[path.section, default: .init()]
            .insert(path.element)
        }
        return elementIndicesBySection
      }
      
      if !changeset.elementDeleted.isEmpty {
        for (section, elements) in groupBySection(changeset.elementDeleted) {
          let sectionItem = child(section, ofItem: nil)
          removeItems(at: elements, inParent: sectionItem, withAnimation: deleteRowsAnimation)
        }
      }
      
      if !changeset.elementInserted.isEmpty {
        for (section, elements) in groupBySection(changeset.elementInserted) {
          let sectionItem = child(section, ofItem: nil)
          insertItems(at: elements, inParent: sectionItem, withAnimation: insertRowsAnimation)
        }
      }
      
      if !changeset.elementUpdated.isEmpty {
        // To group or not to group, that is the question.
        for (section, elements) in groupBySection(changeset.elementUpdated) {
          let sectionItem = child(section, ofItem: nil)
          for index in elements {
            let elementItem = child(index, ofItem: sectionItem)
            reloadItem(elementItem)
          }
        }
      }
      
      for (source, target) in changeset.elementMoved {
        let sourceSectionItem = child(source.section, ofItem: nil)
        let targetSectionItem = child(target.section, ofItem: nil)
        
        var adjustedTarget = target.element
        if source.section == target.section {
          if source == target { // 2=>2 is really 2=>3
            adjustedTarget += 1
          }
          // others are probably still wrong, we may need to adjust the
          // target as if the source was NOT dropped. I think the logic
          // in the differ assumes it is dropped.
        }
        
        moveItem(at: source.element, inParent: sourceSectionItem,
                 to: adjustedTarget, inParent: targetSectionItem)
      }
    }
  }
}

struct AppKitIndexShifter {
  
  // The index into the map is the original index in the source set,
  // the value is the index in the applied set.
  var indexMap : [ Int ]
  
  init(count: Int) {
    indexMap = [ Int ]()
    indexMap.reserveCapacity(count)
    for i in 0..<count { indexMap.append(i) }
  }
  
  var count: Int { indexMap.count }
  
  subscript(sourceIndex index: Int) -> Int {
    return indexMap[index]
  }
  
  mutating func insert(at originalIndex: Int) {
    for i in originalIndex..<indexMap.endIndex {
      indexMap[i] += 1
    }
  }
  mutating func remove(at originalIndex: Int) {
    for i in originalIndex..<indexMap.endIndex {
      indexMap[i] -= 1
    }
  }
  /**
   *
   * [0] a 2=>3 [0] a 0=>2 [0] b
   * [1] b      [1] b      [1] d
   * [2] c      [2] d      [2] a
   * [3] d      [3] c      [3] c
   *
   */
  mutating func move(at originalIndex: Int, to originalToIndex: Int) {
    // TBD: Is this actually correct? :thinking:
    remove(at: originalIndex)
    insert(at: originalToIndex)
  }
}
