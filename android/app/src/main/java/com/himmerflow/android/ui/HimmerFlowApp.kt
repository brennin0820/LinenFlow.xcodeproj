package com.himmerflow.android.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.himmerflow.android.data.CalculationStatus

private val Night = Color(0xFF08131F)
private val CardColor = Color(0xFF101F2D)
private val Accent = Color(0xFF00A6C8)

private enum class AppTab(val title: String, val marker: String) {
    Linen("Linen", "L"),
    Shift("Shift", "S"),
    Logs("Logs", "H"),
    Settings("Settings", "G")
}

@Composable
fun HimmerFlowApp(viewModel: HimmerFlowViewModel = viewModel()) {
    val state by viewModel.uiState.collectAsState()
    var selectedTab by remember { mutableStateOf(AppTab.Linen) }

    MaterialTheme(
        colorScheme = darkColorScheme(
            primary = Accent,
            surface = CardColor,
            background = Night,
            onSurface = Color.White,
            onBackground = Color.White
        )
    ) {
        Surface(color = Night, modifier = Modifier.fillMaxSize()) {
            Column(modifier = Modifier.fillMaxSize()) {
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .verticalScroll(rememberScrollState())
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    when (selectedTab) {
                        AppTab.Linen -> LinenScreen(state, viewModel)
                        AppTab.Shift -> ShiftScreen()
                        AppTab.Logs -> LogsScreen()
                        AppTab.Settings -> SettingsScreen()
                    }
                    Spacer(Modifier.height(24.dp))
                }

                NavigationBar(containerColor = CardColor, contentColor = Color.White) {
                    AppTab.entries.forEach { tab ->
                        NavigationBarItem(
                            selected = selectedTab == tab,
                            onClick = { selectedTab = tab },
                            icon = {
                                Text(
                                    tab.marker,
                                    color = if (selectedTab == tab) Accent else Color.White.copy(alpha = 0.56f),
                                    fontWeight = FontWeight.Black
                                )
                            },
                            label = { Text(tab.title) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun LinenScreen(state: HimmerFlowUiState, viewModel: HimmerFlowViewModel) {
    Text("HimmerFlow", color = Color.White, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
    TowerCard(state, viewModel)
    ReceivingCard(state, viewModel)
    ResultsCard(state)
    WidgetItemsCard(state, viewModel)
}

@Composable
private fun ShiftScreen() {
    Text("Shift", color = Color.White, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
    PremiumCard {
        Text("Smart Shift Alarm", color = Color.White, fontWeight = FontWeight.Bold)
        Text(
            "Android parity target: weekly schedule, commute plan, leaving checklist, Waze route settings, and notifications.",
            color = Color.White.copy(alpha = 0.62f),
            style = MaterialTheme.typography.bodySmall
        )
    }
}

@Composable
private fun LogsScreen() {
    Text("Logs", color = Color.White, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
    PremiumCard {
        Text("Daily Logs", color = Color.White, fontWeight = FontWeight.Bold)
        Text(
            "Android parity target: save daily logs, list previous logs, inspect log details, and reload a log into receiving.",
            color = Color.White.copy(alpha = 0.62f),
            style = MaterialTheme.typography.bodySmall
        )
    }
}

@Composable
private fun SettingsScreen() {
    Text("Settings", color = Color.White, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
    PremiumCard {
        Text("Settings", color = Color.White, fontWeight = FontWeight.Bold)
        Text(
            "Android parity target: tower calibration, shift settings, widget settings, and app preferences.",
            color = Color.White.copy(alpha = 0.62f),
            style = MaterialTheme.typography.bodySmall
        )
    }
}

@Composable
private fun TowerCard(state: HimmerFlowUiState, viewModel: HimmerFlowViewModel) {
    var expanded by remember { mutableStateOf(false) }
    PremiumCard {
        Text("Tower", color = Color.White, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(8.dp))
        Button(onClick = { expanded = true }) {
            Text("${state.selectedTower.name} - ${state.selectedTower.floorCount} floors")
        }
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            state.towers.forEach { tower ->
                DropdownMenuItem(
                    text = { Text("${tower.name} (${tower.deliveryMode.name})") },
                    onClick = {
                        expanded = false
                        viewModel.selectTower(tower)
                    }
                )
            }
        }
    }
}

@Composable
private fun ReceivingCard(state: HimmerFlowUiState, viewModel: HimmerFlowViewModel) {
    PremiumCard {
        Text("Receiving", color = Color.White, fontWeight = FontWeight.Bold)
        Text("Enter received pieces for this tower.", color = Color.White.copy(alpha = 0.62f), style = MaterialTheme.typography.bodySmall)
        Spacer(Modifier.height(10.dp))
        state.availableItems.forEach { item ->
            OutlinedTextField(
                value = state.receivedPieces[item.name].orEmpty(),
                onValueChange = { viewModel.updatePieces(item.name, it) },
                label = { Text(item.name) },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

@Composable
private fun ResultsCard(state: HimmerFlowUiState) {
    PremiumCard {
        Text("Results", color = Color.White, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(8.dp))
        if (state.summaries.isEmpty()) {
            Text("Enter received pieces to calculate results.", color = Color.White.copy(alpha = 0.62f))
        } else {
            state.summaries.forEach { summary ->
                Row(
                    modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(Modifier.weight(1f)) {
                        Text(summary.itemName, color = Color.White, fontWeight = FontWeight.SemiBold)
                        Text(
                            "${summary.receivedPieces} pcs - ${summary.fullBundles} bundles, ${summary.loosePieces} loose",
                            color = Color.White.copy(alpha = 0.58f),
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                    Text(summary.status.label, color = summary.status.color, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun WidgetItemsCard(state: HimmerFlowUiState, viewModel: HimmerFlowViewModel) {
    val selected = state.pinnedWidgetItemNames.filter { pinned -> state.summaries.any { it.itemName == pinned } }
    val atLimit = selected.size >= 3

    PremiumCard {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text("Widget Items", color = Color.White, fontWeight = FontWeight.Bold)
                Text("Choose up to 3 items to show on your widget.", color = Color.White.copy(alpha = 0.62f), style = MaterialTheme.typography.bodySmall)
            }
            Text("${selected.size} / 3 selected", color = Accent, fontWeight = FontWeight.Bold)
        }
        Spacer(Modifier.height(10.dp))
        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            state.summaries.forEach { summary ->
                val isSelected = summary.itemName in selected
                AssistChip(
                    onClick = { viewModel.toggleWidgetItem(summary.itemName) },
                    enabled = isSelected || !atLimit,
                    label = { Text(if (isSelected) "✓ ${summary.itemName}" else summary.itemName) }
                )
            }
        }
        Spacer(Modifier.height(10.dp))
        Text(state.unitLabel, color = Color.White.copy(alpha = 0.62f), style = MaterialTheme.typography.bodySmall)
        state.widgetRows.forEach { row ->
            Row(Modifier.fillMaxWidth().padding(top = 4.dp)) {
                Text(row.itemName, color = Color.White, modifier = Modifier.weight(1f))
                Text(row.valueText, color = Color.White, fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
private fun PremiumCard(content: @Composable ColumnScope.() -> Unit) {
    Card(
        colors = CardDefaults.cardColors(containerColor = CardColor),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(Modifier.padding(14.dp), content = content)
    }
}

private val CalculationStatus.label: String
    get() = when (this) {
        CalculationStatus.Exact -> "Exact"
        CalculationStatus.Shortage -> "Short"
        CalculationStatus.Overage -> "Over"
    }

private val CalculationStatus.color: Color
    get() = when (this) {
        CalculationStatus.Exact -> Color(0xFF4ADE80)
        CalculationStatus.Shortage -> Color(0xFFF97316)
        CalculationStatus.Overage -> Color(0xFF22D3EE)
    }
