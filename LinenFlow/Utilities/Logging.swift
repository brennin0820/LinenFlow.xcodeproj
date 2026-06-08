import OSLog

enum HimmerFlowLog {
    static let subsystem = "com.himmerflow"

    static let orchestrator = Logger(subsystem: subsystem, category: "orchestrator")
    static let reconciliation = Logger(subsystem: subsystem, category: "reconciliation")
    static let notifications = Logger(subsystem: subsystem, category: "notifications")
    static let location = Logger(subsystem: subsystem, category: "location")
    static let liveActivity = Logger(subsystem: subsystem, category: "liveActivity")
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
}
