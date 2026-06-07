import Foundation

struct DeliveryPaceEngine: Sendable {
    func makeSession(
        tower: Tower?,
        summaries: [CalculationSummary],
        deliveryRows: [FloorDistributionRow],
        completedFloors: Set<Int>,
        now: Date,
        shiftStartTime: Date,
        targetDownTime: Date,
        expectedShiftEndTime: Date,
        deliveryStartedAt: Date?,
        activeTrip: ElevatorTrip? = nil
    ) -> ShiftSession {
        let floorsFromRows = Array(Set(deliveryRows.map(\.floorNumber))).sorted()
        let floors = floorsFromRows.isEmpty ? FloorNumberingService.deliveryFloors(for: tower) : floorsFromRows
        let remainingFloors = floors.filter { !completedFloors.contains($0) }
        let completedCount = floors.filter { completedFloors.contains($0) }.count
        let startTime = deliveryStartedAt
        let elapsedMinutes = startTime.map { max(0, now.timeIntervalSince($0) / 60) } ?? 0
        let allowedMinutes = max(0, targetDownTime.timeIntervalSince(now) / 60)
        let allowedMinutesPerFloor = remainingFloors.isEmpty ? 0 : allowedMinutes / Double(remainingFloors.count)
        let averageFloorMinutes = completedCount > 0 ? elapsedMinutes / Double(completedCount) : max(allowedMinutesPerFloor, defaultMinutesPerFloor(for: floors.count))
        let estimatedMinutesRemaining = Int(ceil(Double(remainingFloors.count) * averageFloorMinutes))
        let estimatedCompletionTime = Calendar.current.date(byAdding: .minute, value: estimatedMinutesRemaining, to: now)
        let minutesToTarget = Int(targetDownTime.timeIntervalSince(now) / 60)
        let delta = estimatedMinutesRemaining - max(minutesToTarget, 0)
        let paceStatus: PaceStatus

        if floors.isEmpty || startTime == nil {
            paceStatus = .notStarted
        } else if remainingFloors.isEmpty {
            paceStatus = .ahead
        } else if delta > 5 {
            paceStatus = .behind
        } else if delta < -10 {
            paceStatus = .ahead
        } else {
            paceStatus = .onPace
        }

        return ShiftSession(
            towerName: tower?.name,
            floorCount: tower?.floorCount ?? floors.count,
            shiftStartTime: shiftStartTime,
            targetDownTime: targetDownTime,
            expectedShiftEndTime: expectedShiftEndTime,
            deliveryStartedAt: deliveryStartedAt,
            completedFloors: completedFloors,
            remainingFloors: remainingFloors,
            totalFloors: floors.count,
            estimatedFinishTime: estimatedCompletionTime,
            estimatedMinutesRemaining: max(0, estimatedMinutesRemaining),
            isBehindPace: paceStatus == .behind,
            activeItemFocus: recommendedItemFocus(from: summaries),
            activeTrip: activeTrip,
            remainingBundles: remainingBundleCount(from: summaries),
            averageFloorCompletionMinutes: averageFloorMinutes,
            paceStatus: paceStatus,
            recommendedNextAction: recommendedNextAction(paceStatus: paceStatus, activeItemFocus: recommendedItemFocus(from: summaries))
        )
    }

    func alertText(for session: ShiftSession, now: Date) -> String {
        switch session.paceStatus {
        case .notStarted:
            return "Start delivery to track live pace."
        case .ahead:
            return "You are ahead of pace."
        case .onPace:
            if let activeItemFocus = session.activeItemFocus {
                return "Recommended to begin \(activeItemFocus) now."
            }
            return "You are on pace."
        case .behind:
            guard let estimatedCompletionTime = session.estimatedCompletionTime else {
                return "You are behind target."
            }
            let minutesBehind = max(1, Int(ceil(estimatedCompletionTime.timeIntervalSince(session.targetDownTime) / 60)))
            return "You are \(minutesBehind) minutes behind target."
        }
    }

    private func recommendedNextAction(paceStatus: PaceStatus, activeItemFocus: String?) -> String {
        switch paceStatus {
        case .notStarted:
            return "Start delivery when ready."
        case .behind:
            return "Pick up pace and finish remaining floors first."
        case .ahead:
            return "Continue floor completion and verify any skipped rooms."
        case .onPace:
            if let activeItemFocus {
                return "Recommended to begin \(activeItemFocus) now."
            }
            return "Keep completing floors from the checklist."
        }
    }

    private func defaultMinutesPerFloor(for floorCount: Int) -> Double {
        if floorCount >= 30 { return 2.2 }
        if floorCount >= 20 { return 2.5 }
        return 3.0
    }

    private func remainingBundleCount(from summaries: [CalculationSummary]) -> Int {
        summaries.reduce(0) { total, summary in
            total + max(summary.deliverableBundles, summary.fullBundles)
        }
    }

    private func recommendedItemFocus(from summaries: [CalculationSummary]) -> String? {
        summaries
            .filter { $0.fullBundles > 0 || $0.receivedPieces > 0 }
            .sorted { lhs, rhs in
                if lhs.fullBundles == rhs.fullBundles {
                    return itemPriority(lhs.itemName) < itemPriority(rhs.itemName)
                }
                return lhs.fullBundles < rhs.fullBundles
            }
            .first?
            .itemName
    }

    private func itemPriority(_ itemName: String) -> Int {
        let name = itemName.lowercased()
        if name.contains("washcloth") { return 0 }
        if name.contains("bath mat") { return 1 }
        if name.contains("hand towel") { return 2 }
        if name.contains("pillow") { return 3 }
        return 10
    }
}
