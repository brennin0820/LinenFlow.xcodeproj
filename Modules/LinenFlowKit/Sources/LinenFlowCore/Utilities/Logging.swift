import OSLog

public enum HimmerFlowLog {
    public static let subsystem = "com.himmerflow"

    public static let orchestrator = Logger(subsystem: subsystem, category: "orchestrator")
    public static let reconciliation = Logger(subsystem: subsystem, category: "reconciliation")
    public static let notifications = Logger(subsystem: subsystem, category: "notifications")
    public static let location = Logger(subsystem: subsystem, category: "location")
    public static let liveActivity = Logger(subsystem: subsystem, category: "liveActivity")
    public static let persistence = Logger(subsystem: subsystem, category: "persistence")
}
