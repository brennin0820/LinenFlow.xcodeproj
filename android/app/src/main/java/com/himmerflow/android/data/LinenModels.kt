package com.himmerflow.android.data

enum class DeliveryMode {
    Pieces,
    Bundles
}

enum class CountMethod {
    FixedBin,
    ManualPieces
}

enum class CalculationStatus {
    Exact,
    Shortage,
    Overage
}

data class Tower(
    val name: String,
    val floorCount: Int,
    val colorHex: String,
    val deliveryMode: DeliveryMode,
    val allowsDoubleItems: Boolean
)

data class LinenItem(
    val name: String,
    val parCount: Int,
    val bundleSize: Int,
    val countMethod: CountMethod,
    val piecesPerBin: Int? = null,
    val allowedTowerNames: Set<String> = emptySet()
)

data class ReceivingEntry(
    val itemName: String,
    val receivedPieces: Int
)

data class CalculationSummary(
    val itemName: String,
    val receivedPieces: Int,
    val bundleSize: Int,
    val fullBundles: Int,
    val loosePieces: Int,
    val requiredPieces: Int,
    val differencePieces: Int,
    val status: CalculationStatus,
    val basePerFloorPieces: Int,
    val remainderPieces: Int
)

data class FloorDistributionRow(
    val floorNumber: Int,
    val itemName: String,
    val suggestedPieces: Int,
    val suggestedBundles: Int? = null
)

data class WidgetItemRow(
    val itemName: String,
    val label: String,
    val valueText: String
)
