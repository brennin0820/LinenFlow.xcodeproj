import Foundation
import OSLog

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.himmerflow.app"

    static let boot    = Logger(subsystem: subsystem, category: "boot")
    static let seed    = Logger(subsystem: subsystem, category: "seed")
    static let session = Logger(subsystem: subsystem, category: "session")
    static let widget  = Logger(subsystem: subsystem, category: "widget")
    static let logs    = Logger(subsystem: subsystem, category: "logs")
    static let save    = Logger(subsystem: subsystem, category: "save")
    static let activity = Logger(subsystem: subsystem, category: "liveactivity")
}
