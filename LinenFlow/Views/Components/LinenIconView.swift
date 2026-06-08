import SwiftUI

struct LinenIconView: View {
    let systemName: String
    var weight: Font.Weight = .regular
    
    var body: some View {
        Image(systemName: systemName)
            .fontWeight(weight)
    }
}

extension LinenIconView {
    init(item: String, weight: Font.Weight = .regular) {
        self.init(systemName: LinenIconLibrary.symbolName(forItem: item), weight: weight)
    }
    
    init(tower: String, weight: Font.Weight = .regular) {
        self.init(systemName: LinenIconLibrary.symbolName(forTower: tower), weight: weight)
    }
    
    init(status: CalculationStatus, weight: Font.Weight = .regular) {
        self.init(systemName: LinenIconLibrary.symbolName(forStatus: status), weight: weight)
    }
}
