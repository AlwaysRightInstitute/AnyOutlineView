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

       /*
         let source = [
             ArraySection(model: "Section 1", elements: ["A", "B", "C"]),
             ArraySection(model: "Section 2", elements: ["D", "E", "F"]),
             ArraySection(model: "Section 3", elements: ["G", "H", "I"]),
             ArraySection(model: "Section 4", elements: ["J", "K", "L"])
         ]

         let target = [
             ArraySection(model: "Section 5", elements: ["M", "N", "O"]),
             ArraySection(model: "Section 1", elements: ["A", "C"]),
             ArraySection(model: "Section 4", elements: ["J", "I", "K", "L"]),
             ArraySection(model: "Section 3", elements: ["G", "H", "Z"]),
             ArraySection(model: "Section 6", elements: ["P", "Q", "R"])
         ]
        
         CHANGES: Changeset(
             sectionDeleted: [
                 1 // index 1 - S2
             ],
             elementDeleted: [
                 [element: 1, section: 0] // B in index 0 - S1
             ]
             data: [
                 ArraySection(
                     model: Section 1,
                     elements: ["A", "C"] // does not work!
                 ),
                 ArraySection(
                     model: Section 3,
                     elements: ["G", "H", "I"]
                 ),
                 ArraySection(
                     model: Section 4,
                     elements: ["J", "K", "L"]
                 )
             ],
         )
         CHANGES: Changeset(
             sectionInserted: [
                 0, // S5 into 0
                 4  // S6 to the end (takes into account that S5 is inserted!)
             ],
             sectionMoved: [
                 (source: 2, target: 3/*2*/) // we make that 3, move S3 after S4
             ]
             data: [
                 ArraySection(
                     model: Section 5,
                     elements: ["M", "N", "O"]
                 ),
                 ArraySection(
                     model: Section 1,
                     elements: ["A", "C"]
                 ),
                 ArraySection(
                     model: Section 4,
                     elements: ["J", "K", "L"]
                 ),
                 ArraySection(
                     model: Section 3,
                     elements: ["G", "H", "I"]
                 ),
                 ArraySection(
                     model: Section 6,
                     elements: ["P", "Q", "R"]
                 )
             ],
         )
         CHANGES: Changeset(
             data: [
                 ArraySection(
                     model: Section 5,
                     elements: ["M", "N", "O"]
                 ),
                 ArraySection(
                     model: Section 1,
                     elements: ["A", "C"]
                 ),
                 ArraySection(
                     model: Section 4,
                     elements: ["J", "I", "K", "L"]
                 ),
                 ArraySection(
                     model: Section 3,
                     elements: ["G", "H", "Z"]
                 ),
                 ArraySection(
                     model: Section 6,
                     elements: ["P", "Q", "R"]
                 )
             ],
             elementInserted: [
                 [element: 2, section: 3]
             ],
             elementMoved: [
                 (source: [element: 2, section: 3], target: [element: 1, section: 2])
             ]
         )
  */
         for changeset in [stagedChangeset[0]] {
           print("CHANGES:", changeset)
             if let interrupt = interrupt, interrupt(changeset), let sections = stagedChangeset.last?.data {
                 setData(sections)
                 return reloadData()
             }
           
             beginUpdates()
             defer { endUpdates() }
             
             setData(changeset.data)

             if !changeset.sectionDeleted.isEmpty {
                 removeItems(at: IndexSet(changeset.sectionDeleted),
                             inParent: nil, withAnimation: deleteRowsAnimation)
             }

             if !changeset.sectionInserted.isEmpty {
                 insertItems(at: IndexSet(changeset.sectionInserted),
                             inParent: nil, withAnimation: insertRowsAnimation)
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
