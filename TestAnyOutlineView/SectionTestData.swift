//
//  SectionTestData.swift
//  TestAnyOutlineView
//
//  Created by Helge Heß on 27.01.20.
//  Copyright © 2020 ZeeZide GmbH. All rights reserved.
//

import DifferenceKit

extension String: Differentiable {}

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
