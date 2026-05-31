import SwiftUI

@main
struct MoniApp: App {
    @State private var model = MetricsModel()

    var body: some Scene {
        MenuBarExtra("Moni", systemImage: "cpu") {
            StatsPanel(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}
