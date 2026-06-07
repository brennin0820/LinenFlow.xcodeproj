package com.himmerflow.android.data

object DefaultData {

    val towers: List<Tower> = listOf(
        Tower(name = "Lagoon", floorCount = 21, colorHex = "#00A6C8", deliveryMode = DeliveryMode.Pieces, allowsDoubleItems = false),
        Tower(name = "GI", floorCount = 34, colorHex = "#C89B3C", deliveryMode = DeliveryMode.Pieces, allowsDoubleItems = false),
        Tower(name = "GW", floorCount = 32, colorHex = "#2F6F8F", deliveryMode = DeliveryMode.Pieces, allowsDoubleItems = false),
        Tower(name = "Diamond", floorCount = 15, colorHex = "#7C878E", deliveryMode = DeliveryMode.Bundles, allowsDoubleItems = true),
        Tower(name = "Alii", floorCount = 14, colorHex = "#7B3F98", deliveryMode = DeliveryMode.Bundles, allowsDoubleItems = true),
        Tower(name = "Tapa", floorCount = 33, colorHex = "#B66A35", deliveryMode = DeliveryMode.Bundles, allowsDoubleItems = false),
        Tower(name = "Rainbow", floorCount = 31, colorHex = "#F05A7E", deliveryMode = DeliveryMode.Bundles, allowsDoubleItems = false)
    )

    val linenItems: List<LinenItem> = listOf(
        LinenItem("Bath Towel", parCount = 14, bundleSize = 5, countMethod = CountMethod.FixedBin, piecesPerBin = 245),
        LinenItem("Bath Mat", parCount = 3, bundleSize = 10, countMethod = CountMethod.ManualPieces),
        LinenItem("Hand Towel", parCount = 4, bundleSize = 20, countMethod = CountMethod.ManualPieces),
        LinenItem("Washcloth", parCount = 2, bundleSize = 50, countMethod = CountMethod.ManualPieces),
        LinenItem("Pillow Case", parCount = 3, bundleSize = 50, countMethod = CountMethod.ManualPieces),
        LinenItem("King Sheet", parCount = 3, bundleSize = 5, countMethod = CountMethod.ManualPieces, allowedTowerNames = setOf("Alii", "Diamond", "Tapa", "Rainbow")),
        LinenItem("King Cover", parCount = 3, bundleSize = 5, countMethod = CountMethod.ManualPieces, allowedTowerNames = setOf("Alii", "Diamond", "Tapa", "Rainbow")),
        LinenItem("Queen Sheet", parCount = 4, bundleSize = 5, countMethod = CountMethod.ManualPieces, allowedTowerNames = setOf("Tapa", "Rainbow")),
        LinenItem("Queen Cover", parCount = 4, bundleSize = 5, countMethod = CountMethod.ManualPieces, allowedTowerNames = setOf("Tapa", "Rainbow")),
        LinenItem("Double Sheet", parCount = 4, bundleSize = 5, countMethod = CountMethod.ManualPieces, allowedTowerNames = setOf("Alii", "Diamond")),
        LinenItem("Double Cover", parCount = 4, bundleSize = 5, countMethod = CountMethod.ManualPieces, allowedTowerNames = setOf("Alii", "Diamond")),
        LinenItem("Twin Sheet", parCount = 4, bundleSize = 5, countMethod = CountMethod.ManualPieces),
        LinenItem("Twin Cover", parCount = 4, bundleSize = 5, countMethod = CountMethod.ManualPieces)
    )
}
