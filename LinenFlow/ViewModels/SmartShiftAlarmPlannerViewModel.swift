import Foundation
import SwiftUI
import UserNotifications

@Observable
final class SmartShiftAlarmPlannerViewModel {
    // MARK: - Persisted State
    var schedule: [WorkScheduleDay] = []
    var commutePlan: CommutePlan = CommutePlan()
    var alarmPlan: ShiftAlarmPlan = ShiftAlarmPlan()
    var checklistState: LeavingChecklistState = LeavingChecklistState()
    var scheduleTranscriptNotes: String = ""

    // MARK: - UI State
    var notificationAuthStatus: UNAuthorizationStatus = .notDetermined
    var showChecklistSheet: Bool = false
    var isAlarmsScheduled: Bool = false
    var showAddressEditSheet: Bool = false

    // MARK: - Persistence Keys
    private static let scheduleKey = "shiftPlanner.schedule"
    private static let commutePlanKey = "shiftPlanner.commutePlan"
    private static let alarmPlanKey = "shiftPlanner.alarmPlan"
    private static let checklistStateKey = "shiftPlanner.checklistState"
    private static let transcriptKey = "shiftPlanner.transcriptNotes"

    // MARK: - Computed

    var todayPlan: WorkdayPlan? {
        guard let scheduleDay = todayScheduleDay, scheduleDay.isWorkday else { return nil }
        return WorkdayPlannerService.buildWorkdayPlan(
            weekday: scheduleDay.weekday,
            shiftStartDate: .now,
            scheduleDay: scheduleDay,
            commutePlan: commutePlan
        )
    }

    var nextWorkdayPlan: WorkdayPlan? {
        guard let (nextDay, nextDate) = WorkdayPlannerService.nextWorkShift(schedule: schedule) else { return nil }
        return WorkdayPlannerService.buildWorkdayPlan(
            weekday: nextDay.weekday,
            shiftStartDate: nextDate,
            scheduleDay: nextDay,
            commutePlan: commutePlan
        )
    }

    var heroDisplayPlan: WorkdayPlan? {
        todayPlan ?? nextWorkdayPlan
    }

    var isTodayWorkday: Bool {
        WorkdayPlannerService.isWorkday(schedule)
    }

    var todayScheduleDay: WorkScheduleDay? {
        let weekday = Calendar.current.component(.weekday, from: .now)
        return schedule.first { $0.weekday == weekday }
    }

    var activeChecklistItems: [LeavingChecklistItem] {
        LeavingChecklistService.activeItems(from: checklistState.items)
    }

    var scheduleWarnings: [String] {
        WorkdayPlannerService.validateSchedule(schedule)
    }

    var isWorkAddressSet: Bool {
        !commutePlan.workAddress.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var displayHomeLabel: String { "Home" }

    // MARK: - Init

    init() {
        loadFromDefaults()
        if schedule.isEmpty {
            schedule = WorkdayPlannerService.buildDefaultSchedule()
        }
        if checklistState.items.isEmpty {
            checklistState.items = LeavingChecklistService.buildDefaultItems()
        }
        if commutePlan.workAddress.isEmpty {
            commutePlan.workAddress = "2005 Kalia Rd, Honolulu, HI"
        }
        if commutePlan.homeAddress.isEmpty {
            commutePlan.homeAddress = "98360 Koauka Loop, Aiea, HI"
        }
        if commutePlan.wazeSearchQuery.isEmpty {
            commutePlan.wazeSearchQuery = commutePlan.workAddress
        }
        resetChecklistIfNeeded()
        Task { await refreshNotificationStatus() }
    }

    // MARK: - Persistence

    func save() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(schedule) {
            UserDefaults.standard.set(data, forKey: Self.scheduleKey)
        }
        if let data = try? encoder.encode(commutePlan) {
            UserDefaults.standard.set(data, forKey: Self.commutePlanKey)
        }
        if let data = try? encoder.encode(alarmPlan) {
            UserDefaults.standard.set(data, forKey: Self.alarmPlanKey)
        }
        if let data = try? encoder.encode(checklistState) {
            UserDefaults.standard.set(data, forKey: Self.checklistStateKey)
        }
        UserDefaults.standard.set(scheduleTranscriptNotes, forKey: Self.transcriptKey)
    }

    private func loadFromDefaults() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: Self.scheduleKey),
           let decoded = try? decoder.decode([WorkScheduleDay].self, from: data) {
            schedule = decoded
        }
        if let data = UserDefaults.standard.data(forKey: Self.commutePlanKey),
           let decoded = try? decoder.decode(CommutePlan.self, from: data) {
            commutePlan = decoded
        }
        if let data = UserDefaults.standard.data(forKey: Self.alarmPlanKey),
           let decoded = try? decoder.decode(ShiftAlarmPlan.self, from: data) {
            alarmPlan = decoded
        }
        if let data = UserDefaults.standard.data(forKey: Self.checklistStateKey),
           let decoded = try? decoder.decode(LeavingChecklistState.self, from: data) {
            checklistState = decoded
        }
        scheduleTranscriptNotes = UserDefaults.standard.string(forKey: Self.transcriptKey) ?? ""
    }

    // MARK: - Schedule

    func updateScheduleDay(_ day: WorkScheduleDay) {
        if let idx = schedule.firstIndex(where: { $0.weekday == day.weekday }) {
            schedule[idx] = day
            save()
        }
    }

    // MARK: - Checklist

    func markChecked(_ item: LeavingChecklistItem) {
        if !checklistState.todayCheckedItemIDs.contains(item.id) {
            checklistState.todayCheckedItemIDs.append(item.id)
            save()
        }
    }

    func markUnchecked(_ item: LeavingChecklistItem) {
        checklistState.todayCheckedItemIDs.removeAll { $0 == item.id }
        save()
    }

    func toggleChecked(_ item: LeavingChecklistItem) {
        if checklistState.todayCheckedItemIDs.contains(item.id) {
            markUnchecked(item)
        } else {
            markChecked(item)
        }
    }

    func isChecked(_ item: LeavingChecklistItem) -> Bool {
        checklistState.todayCheckedItemIDs.contains(item.id)
    }

    func resetChecklistIfNeeded() {
        if LeavingChecklistService.shouldResetCheckedItems(lastResetDate: checklistState.lastResetDate) {
            checklistState.todayCheckedItemIDs = []
            checklistState.lastResetDate = .now
            save()
        }
    }

    func resetChecklist() {
        checklistState.todayCheckedItemIDs = []
        checklistState.lastResetDate = .now
        save()
    }

    var checklistProgress: (checked: Int, total: Int) {
        let active = activeChecklistItems
        let checked = active.filter { checklistState.todayCheckedItemIDs.contains($0.id) }.count
        return (checked, active.count)
    }

    func addChecklistItem(title: String) {
        let maxOrder = checklistState.items.map(\.sortOrder).max() ?? -1
        let item = LeavingChecklistItem(title: title, isEnabled: true, sortOrder: maxOrder + 1)
        checklistState.items.append(item)
        save()
    }

    func deleteChecklistItems(at offsets: IndexSet) {
        checklistState.items.remove(atOffsets: offsets)
        save()
    }

    func toggleChecklistItemEnabled(_ item: LeavingChecklistItem) {
        if let idx = checklistState.items.firstIndex(where: { $0.id == item.id }) {
            checklistState.items[idx].isEnabled.toggle()
            save()
        }
    }

    // MARK: - Notifications

    func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            notificationAuthStatus = settings.authorizationStatus
        }
    }

    func requestNotificationPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            await MainActor.run {
                notificationAuthStatus = granted ? .authorized : .denied
            }
        } catch { }
    }

    func scheduleAlarms() async {
        await requestNotificationPermission()
        guard let plan = heroDisplayPlan else { return }
        let identifiers = await ShiftAlarmNotificationService.scheduleAlarmNotifications(
            workdayPlan: plan,
            alarmPlan: alarmPlan,
            commutePlan: commutePlan,
            checklistItems: checklistState.items
        )
        alarmPlan.scheduledNotificationIdentifiers = identifiers
        isAlarmsScheduled = !identifiers.isEmpty
        save()
    }

    func cancelAlarms() async {
        await ShiftAlarmNotificationService.cancelAlarmNotifications(
            identifiers: alarmPlan.scheduledNotificationIdentifiers
        )
        alarmPlan.scheduledNotificationIdentifiers = []
        isAlarmsScheduled = false
        save()
    }

    // MARK: - Waze

    @MainActor
    func openWaze() {
        let mode: WazeRouteService.DestinationMode
        switch commutePlan.wazeDestinationMode {
        case .favWork:
            mode = .favWork
        case .favHome:
            mode = .favHome
        case .searchAddress:
            let query = commutePlan.wazeSearchQuery.isEmpty ? commutePlan.workAddress : commutePlan.wazeSearchQuery
            mode = .searchAddress(query)
        case .coordinates:
            mode = .coordinates(lat: commutePlan.wazeLatitude, lon: commutePlan.wazeLongitude)
        }
        WazeRouteService.openWaze(mode: mode)
    }

    // MARK: - Target Arrival Date Helper

    func targetArrivalDate(for referenceDate: Date = .now) -> Date {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        comps.hour = commutePlan.targetArrivalHour
        comps.minute = commutePlan.targetArrivalMinute
        comps.second = 0
        return calendar.date(from: comps) ?? referenceDate
    }
}
