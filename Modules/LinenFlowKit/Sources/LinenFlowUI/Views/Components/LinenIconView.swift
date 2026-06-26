import SwiftUI
import LinenFlowCore
import LinenFlowEngine

public struct LinenIconView: View {
    public let systemName: String
    public var weight: Font.Weight = .regular
    
    public var body: some View {
        Image(systemName: systemName)
            .fontWeight(weight)
    }
}

public extension LinenIconView {
    public init(item: String, weight: Font.Weight = .regular) {
        self.init(systemName: LinenIconLibrary.symbolName(forItem: item), weight: weight)
    }
    
    public init(tower: String, weight: Font.Weight = .regular) {
        self.init(systemName: LinenIconLibrary.symbolName(forTower: tower), weight: weight)
    }
    
    public init(status: CalculationStatus, weight: Font.Weight = .regular) {
        self.init(systemName: LinenIconLibrary.symbolName(forStatus: status), weight: weight)
    }
}
