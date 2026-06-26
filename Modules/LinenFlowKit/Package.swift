// swift-tools-version: 6.1
import PackageDescription

// LinenFlowKit — the modular core of the LinenFlow ("HimmerFlow") app.
//
// The app is sliced into four cohesive units with a strict one-way
// dependency graph:
//
//     App (HimmerFlow target)  ->  LinenFlowUI  ->  LinenFlowEngine  ->  LinenFlowCore
//
//   • LinenFlowCore   — Models, Utilities, SeedData, LiveActivity attributes,
//                       Protocols. No dependency on the other slices.
//   • LinenFlowEngine — Services + Orchestration (business logic). Depends on Core.
//   • LinenFlowUI     — Views + ViewModels (presentation). Depends on Engine + Core.
//   • App             — the thin executable target in LinenFlow.xcodeproj.
//
// The app target sets SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor; the same
// default isolation is applied here so the moved code keeps its semantics.
let mainActorIsolation: [SwiftSetting] = [
    .defaultIsolation(MainActor.self)
]

let package = Package(
    name: "LinenFlowKit",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(name: "LinenFlowCore", targets: ["LinenFlowCore"]),
        .library(name: "LinenFlowEngine", targets: ["LinenFlowEngine"]),
        .library(name: "LinenFlowUI", targets: ["LinenFlowUI"]),
    ],
    targets: [
        .target(
            name: "LinenFlowCore",
            path: "Sources/LinenFlowCore",
            // ShiftActivityWidget is a WidgetKit view that is intentionally
            // excluded from the app build today; keep it out of the module too.
            exclude: [
                "LiveActivity/ShiftActivityWidget.swift",
            ],
            swiftSettings: mainActorIsolation
        ),
        .target(
            name: "LinenFlowEngine",
            dependencies: ["LinenFlowCore"],
            path: "Sources/LinenFlowEngine",
            swiftSettings: mainActorIsolation
        ),
        .target(
            name: "LinenFlowUI",
            dependencies: ["LinenFlowEngine", "LinenFlowCore"],
            path: "Sources/LinenFlowUI",
            // Legacy flow screens are intentionally excluded from the app build
            // today; preserve that by keeping them out of compilation.
            exclude: [
                "Views/Flow/Legacy/FloorDistributionView.swift",
                "Views/Flow/Legacy/FlowStep.swift",
                "Views/Flow/Legacy/RebalanceShortFloorsView.swift",
                "Views/Flow/Legacy/ReceivingView.swift",
                "Views/Flow/Legacy/ResultsView.swift",
                "Views/Flow/Legacy/ReviewReceivedView.swift",
            ],
            swiftSettings: mainActorIsolation
        ),
    ]
)
