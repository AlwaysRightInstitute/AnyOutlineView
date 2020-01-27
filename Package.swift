// swift-tools-version:5.0

import PackageDescription

let package = Package(
  name: "AnyOutlineView",
  platforms: [
    .macOS(.v10_12)
  ],
  products: [
    .library(name: "AnyOutlineView", targets: [ "AnyOutlineView" ])
  ],
  dependencies: [],
  targets: [
    .target(name: "AnyOutlineView", dependencies: [])
  ]
)
