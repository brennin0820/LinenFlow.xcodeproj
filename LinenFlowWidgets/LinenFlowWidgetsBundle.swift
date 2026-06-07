import WidgetKit
import SwiftUI

@main
struct HimmerFlowWidgetsBundle: WidgetBundle {
    var body: some Widget {
        ShiftStatusWidget()
        LockScreenWidget()
        DeliveryLiveActivityWidget()
    }
}
