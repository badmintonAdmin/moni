// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "Moni",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .target(
            name: "CIOHID",
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("CoreFoundation")
            ]
        ),
        .executableTarget(
            name: "Moni",
            dependencies: ["CIOHID"],
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement")
            ]
        )
    ]
)
