import Foundation
import OSLog

public enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.himmerflow.app"

    public static let boot    = Logger(subsystem: subsystem, category: "boot")
    public static let seed    = Logger(subsystem: subsystem, category: "seed")
    public static let session = Logger(subsystem: subsystem, category: "session")
    public static let widget  = Logger(subsystem: subsystem, category: "widget")
    public static let logs    = Logger(subsystem: subsystem, category: "logs")
    public static let save    = Logger(subsystem: subsystem, category: "save")
    public static let activity = Logger(subsystem: subsystem, category: "liveactivity")
}
