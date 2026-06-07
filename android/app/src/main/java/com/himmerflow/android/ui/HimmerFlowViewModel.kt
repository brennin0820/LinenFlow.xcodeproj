package com.himmerflow.android.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import com.himmerflow.android.data.DefaultData
import com.himmerflow.android.data.DeliveryMode
import com.himmerflow.android.data.LinenCalculator
import com.himmerflow.android.data.ReceivingEntry
import com.himmerflow.android.data.Tower
import com.himmerflow.android.data.WidgetItemRow
import com.himmerflow.android.data.WidgetStateStore
import com.himmerflow.android.widget.HimmerFlowWidgetProvider
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update

data class HimmerFlowUiState(
    val towers: List<Tower> = DefaultData.towers,
    val selectedTower: Tower = DefaultData.towers.first(),
    val receivedPieces: Map<String, String> = emptyMap(),
    val pinnedWidgetItemNames: List<String> = emptyList()
) {
    val availableItems = LinenCalculator.availableItems(selectedTower)
    val entries = receivedPieces.mapNotNull { (name, rawValue) ->
        val pieces = rawValue.toIntOrNull()?.coerceAtLeast(0) ?: return@mapNotNull null
        ReceivingEntry(name, pieces)
    }
    val results = LinenCalculator.calculate(selectedTower, entries)
    val summaries = results.first
    val distributions = results.second
    val widgetItemNames: List<String> =
        pinnedWidgetItemNames.filter { pinned -> summaries.any { it.itemName == pinned } }
            .ifEmpty { summaries.take(3).map { it.itemName } }
            .take(3)
    val widgetRows: List<WidgetItemRow> =
        LinenCalculator.widgetRows(selectedTower, widgetItemNames, distributions)
    val unitLabel: String = if (selectedTower.deliveryMode == DeliveryMode.Bundles) "Bundles per floor" else "Pieces per floor"
}

class HimmerFlowViewModel(
    private val app: Application
) : AndroidViewModel(app) {
    private val _uiState = MutableStateFlow(HimmerFlowUiState())
    val uiState: StateFlow<HimmerFlowUiState> = _uiState

    init {
        syncWidget()
    }

    fun selectTower(tower: Tower) {
        _uiState.update {
            it.copy(
                selectedTower = tower,
                receivedPieces = emptyMap(),
                pinnedWidgetItemNames = emptyList()
            )
        }
        syncWidget()
    }

    fun updatePieces(itemName: String, value: String) {
        val cleanValue = value.filter { it.isDigit() }.take(5)
        _uiState.update { state ->
            state.copy(receivedPieces = state.receivedPieces + (itemName to cleanValue))
        }
        syncWidget()
    }

    fun toggleWidgetItem(itemName: String) {
        _uiState.update { state ->
            val calculatedNames = state.summaries.map { it.itemName }.toSet()
            val current = state.pinnedWidgetItemNames.filter { it in calculatedNames }
            val next = when {
                itemName in current -> current - itemName
                current.size < 3 && itemName in calculatedNames -> current + itemName
                else -> current
            }
            state.copy(pinnedWidgetItemNames = next)
        }
        syncWidget()
    }

    private fun syncWidget() {
        val state = _uiState.value
        WidgetStateStore.save(app, state.selectedTower, state.widgetRows)
        HimmerFlowWidgetProvider.updateAll(app)
    }
}
