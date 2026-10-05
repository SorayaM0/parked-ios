import SwiftUI
import SwiftData

@main
struct ParkedApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: ParkingSpot.self)
    }
}
