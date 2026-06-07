//
//  HimmerFlow_WidgetBundle.swift
//  HimmerFlow Widget
//
//  Created by Brent Lennin R Orlanda on 5/21/26.
//

import WidgetKit
import SwiftUI

@main
struct HimmerFlow_WidgetBundle: WidgetBundle {
    var body: some Widget {
        HimmerFlow_Widget()
        HimmerFlow_WidgetLiveActivity()
    }
}
