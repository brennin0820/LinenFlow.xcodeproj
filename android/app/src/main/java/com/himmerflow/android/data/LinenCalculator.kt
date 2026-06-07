package com.himmerflow.android.data

object LinenCalculator {
    fun availableItems(tower: Tower): List<LinenItem> =
        DefaultData.linenItems.filter { item ->
            item.allowedTowerNames.isEmpty() || tower.name in item.allowedTowerNames
        }

    fun calculate(
        tower: Tower,
        entries: List<ReceivingEntry>,
        items: List<LinenItem> = availableItems(tower)
    ): Pair<List<CalculationSummary>, List<FloorDistributionRow>> {
        val itemByName = items.associateBy { it.name }
        val summaries = mutableListOf<CalculationSummary>()
        val rows = mutableListOf<FloorDistributionRow>()

        entries
            .filter { it.receivedPieces > 0 }
            .sortedBy { it.itemName }
            .forEach { entry ->
                val item = itemByName[entry.itemName] ?: return@forEach
                summaries += summaryFor(tower, item, entry.receivedPieces)
                rows += if (tower.deliveryMode == DeliveryMode.Bundles) {
                    bundleDistribution(entry.itemName, entry.receivedPieces / item.bundleSize, tower.floorCount)
                } else {
                    pieceDistribution(entry.itemName, entry.receivedPieces, tower.floorCount)
                }
            }

        return summaries.sortedBy { it.itemName } to rows
    }

    private fun summaryFor(tower: Tower, item: LinenItem, pieces: Int): CalculationSummary {
        val safePieces = pieces.coerceAtLeast(0)
        val fullBundles = if (item.bundleSize > 0) safePieces / item.bundleSize else 0
        val loosePieces = if (item.bundleSize > 0) safePieces % item.bundleSize else 0
        val requiredPieces = if (tower.deliveryMode == DeliveryMode.Bundles) {
            tower.floorCount * item.parCount
        } else {
            safePieces
        }
        val difference = safePieces - requiredPieces
        val status = when {
            difference > 0 -> CalculationStatus.Overage
            difference < 0 -> CalculationStatus.Shortage
            else -> CalculationStatus.Exact
        }

        return CalculationSummary(
            itemName = item.name,
            receivedPieces = safePieces,
            bundleSize = item.bundleSize,
            fullBundles = fullBundles,
            loosePieces = loosePieces,
            requiredPieces = requiredPieces,
            differencePieces = difference,
            status = status,
            basePerFloorPieces = if (tower.floorCount > 0) safePieces / tower.floorCount else 0,
            remainderPieces = if (tower.floorCount > 0) safePieces % tower.floorCount else 0
        )
    }

    private fun pieceDistribution(
        itemName: String,
        pieces: Int,
        floorCount: Int
    ): List<FloorDistributionRow> {
        if (floorCount <= 0) return emptyList()
        val safePieces = pieces.coerceAtLeast(0)
        val base = safePieces / floorCount
        val remainder = safePieces % floorCount
        return (1..floorCount).map { floor ->
            FloorDistributionRow(
                floorNumber = floor,
                itemName = itemName,
                suggestedPieces = base + if (floor <= remainder) 1 else 0
            )
        }
    }

    private fun bundleDistribution(
        itemName: String,
        bundles: Int,
        floorCount: Int
    ): List<FloorDistributionRow> {
        if (floorCount <= 0) return emptyList()
        val safeBundles = bundles.coerceAtLeast(0)
        val base = safeBundles / floorCount
        val remainder = safeBundles % floorCount
        return (1..floorCount).map { floor ->
            val value = base + if (floor <= remainder) 1 else 0
            FloorDistributionRow(
                floorNumber = floor,
                itemName = itemName,
                suggestedPieces = 0,
                suggestedBundles = value
            )
        }
    }

    fun widgetRows(
        tower: Tower,
        selectedItemNames: List<String>,
        distributions: List<FloorDistributionRow>
    ): List<WidgetItemRow> {
        val unitIsBundles = tower.deliveryMode == DeliveryMode.Bundles
        return selectedItemNames.take(3).mapNotNull { itemName ->
            val itemRows = distributions.filter { it.itemName == itemName }
            val first = itemRows.firstOrNull() ?: return@mapNotNull null
            val value = if (unitIsBundles) {
                "${first.suggestedBundles ?: 0} bdl"
            } else {
                "${first.suggestedPieces} pcs"
            }
            WidgetItemRow(
                itemName = itemName,
                label = "Floor ${first.floorNumber}",
                valueText = value
            )
        }
    }
}
