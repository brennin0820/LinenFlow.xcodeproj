import SwiftUI
import SwiftData
import LinenFlowCore
import LinenFlowEngine

public struct SettingsView: View {
    @AppStorage("isCustomProperty") private var isCustomProperty = false
    @Environment(\.modelContext) private var modelContext
    @Environment(ShiftSettings.self) private var shiftSettings
    @Environment(FlowViewModel.self) private var flowVM
    @Environment(AppThemeSettings.self) private var themeSettings
    @Query(sort: \Tower.name) private var towers: [Tower]
    @Query(sort: \LinenItem.name) private var items: [LinenItem]
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var expandedTowers: Set<String> = []
    @State private var expandedTowerEditorID: UUID?
    @State private var expandedItemEditorID: UUID?
    @State private var isShiftTimingExpanded = false
    @State private var showBlankPropertyConfirm = false
    @State private var showHHVDefaultsConfirm = false
    @State private var showImportAlert = false
    @State private var importCode = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showQRDisplay = false
    @State private var showQRScanner = false
    @State private var generatedQRCode: UIImage?
    @State private var showAddTowerSheet = false

    public var body: some View {
        AppBackground {
            ScrollView {
                VStack(spacing: 18) {
                    settingsOverviewSection
                    if !isCustomProperty {
                        PropertyMapView(towers: towers)
                    }
                    appearanceSection
                    propertyProfileSection

                    SectionHeader(title: "Property", subtitle: "Control active towers, floor ranges, and delivery defaults.")
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(towerSections) { section in
                            VStack(alignment: .leading, spacing: 8) {
                                SettingsTowerGroupHeader(group: section.group, count: section.towers.count)
                                ForEach(section.towers) { tower in
                                    TowerSettingsCard(
                                        tower: tower,
                                        isExpanded: expandedTowerEditorID == tower.id,
                                        onToggle: {
                                            withAnimation(.snappy(duration: 0.18)) {
                                                expandedTowerEditorID = expandedTowerEditorID == tower.id ? nil : tower.id
                                                expandedItemEditorID = nil
                                                isShiftTimingExpanded = false
                                            }
                                        }
                                    ) { save() }
                                }
                            }
                        }

                        Button {
                            showAddTowerSheet = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3.weight(.bold))
                                Text("Add Tower")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(.cyan)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.cyan.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.cyan.opacity(0.35), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add a new tower")
                    }

                    SectionHeader(title: "Linen Catalog", subtitle: "Set par counts, bundle sizes, and availability.")
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(itemSections) { section in
                            VStack(alignment: .leading, spacing: 8) {
                                SettingsItemGroupHeader(group: section.group, count: section.items.count)
                                ForEach(section.items) { item in
                                    LinenItemSettingsCard(
                                        item: item,
                                        isExpanded: expandedItemEditorID == item.id,
                                        onToggle: {
                                            withAnimation(.snappy(duration: 0.18)) {
                                                expandedItemEditorID = expandedItemEditorID == item.id ? nil : item.id
                                                expandedTowerEditorID = nil
                                                isShiftTimingExpanded = false
                                            }
                                        }
                                    ) { save() }
                                }
                            }
                        }
                    }

                    SectionHeader(title: "Operations", subtitle: "Shift timing, reminders, and delivery guidance.")
                    PremiumCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                withAnimation(.snappy(duration: 0.18)) {
                                    isShiftTimingExpanded.toggle()
                                    expandedTowerEditorID = nil
                                    expandedItemEditorID = nil
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "clock.fill")
                                        .foregroundStyle(.cyan)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Work session timing")
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                        Text(shiftTimingSummary)
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.62))
                                    }
                                    Spacer()
                                    Image(systemName: isShiftTimingExpanded ? "chevron.up" : "chevron.down")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white.opacity(0.42))
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint(isShiftTimingExpanded ? "Double tap to collapse time pickers." : "Double tap to edit shift timing.")

                            if isShiftTimingExpanded {
                                Divider().background(Color.white.opacity(0.1))
                                timePicker(label: "Target down time", hour: Binding(
                                    get: { shiftSettings.targetHour },
                                    set: { shiftSettings.targetHour = $0 }
                                ), minute: Binding(
                                    get: { shiftSettings.targetMinute },
                                    set: { shiftSettings.targetMinute = $0 }
                                ))
                                Divider().background(Color.white.opacity(0.1))
                                timePicker(label: "Shift start", hour: Binding(
                                    get: { shiftSettings.shiftStartHour },
                                    set: { shiftSettings.shiftStartHour = $0 }
                                ), minute: Binding(
                                    get: { shiftSettings.shiftStartMinute },
                                    set: { shiftSettings.shiftStartMinute = $0 }
                                ))
                                Divider().background(Color.white.opacity(0.1))
                                timePicker(label: "Shift end", hour: Binding(
                                    get: { shiftSettings.shiftEndHour },
                                    set: { shiftSettings.shiftEndHour = $0 }
                                ), minute: Binding(
                                    get: { shiftSettings.shiftEndMinute },
                                    set: { shiftSettings.shiftEndMinute = $0 }
                                ))
                            }
                        }
                    }
                    
                    PremiumCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SettingsSubsectionTitle(
                                systemImage: "bell.badge.fill",
                                title: "Smart Reminders",
                                subtitle: "Daily local notifications to log par counts.",
                                tint: .blue
                            )

                            if !notificationManager.isAuthorized {
                                Button("Enable Notifications") {
                                    Task {
                                        await notificationManager.requestAuthorization()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                            } else {
                                Toggle("Enable daily reminder", isOn: $notificationManager.isReminderEnabled)
                                    .tint(.blue)
                                    .foregroundStyle(.white.opacity(0.86))
                                
                                if notificationManager.isReminderEnabled {
                                    Divider().background(Color.white.opacity(0.1))
                                    timePicker(label: "Reminder time", hour: $notificationManager.reminderHour, minute: $notificationManager.reminderMinute)
                                }
                            }
                        }
                    }

                    rulesSection

                    SectionHeader(title: "Delivery Rules", subtitle: "Floor sequences per tower. Read-only.")
                    ForEach(towers.filter(\.isActive).sorted { $0.name < $1.name }) { tower in
                        TowerDeliveryRuleCard(
                            tower: tower,
                            isExpanded: expandedTowers.contains(tower.name)
                        ) {
                            withAnimation(.snappy(duration: 0.18)) {
                                if expandedTowers.contains(tower.name) {
                                    expandedTowers.remove(tower.name)
                                } else {
                                    expandedTowers.insert(tower.name)
                                }
                            }
                        }
                    }

                    SectionHeader(title: "Guidance", subtitle: "Short on-screen hints that appear at the right moment.")
                    smartTipsSection

                    SectionHeader(title: "Data")
                    dataSection

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog(
            "Start Fresh (Blank Property)?",
            isPresented: $showBlankPropertyConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Everything and Start Fresh", role: .destructive) {
                flowVM.eraseAllDataAndReset(isCustomProperty: true)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all daily logs, towers, and linen settings so you can configure a new property from scratch.")
        }
        .confirmationDialog(
            "Load Hilton Hawaiian Village Defaults?",
            isPresented: $showHHVDefaultsConfirm,
            titleVisibility: .visible
        ) {
            Button("Replace Data with HHV Defaults", role: .destructive) {
                flowVM.eraseAllDataAndReset(isCustomProperty: false)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all daily logs, custom towers, and linen settings to restore the HHV configuration.")
        }
        .alert("Import Configuration", isPresented: $showImportAlert) {
            TextField("Paste configuration code", text: $importCode)
            Button("Cancel", role: .cancel) { importCode = "" }
            Button("Import", role: .destructive) {
                do {
                    try PropertySharingService.importConfiguration(from: importCode, context: modelContext)
                    importCode = ""
                    flowVM.resetFlow()
                } catch let error as PropertySharingError {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                } catch {
                    errorMessage = "An unknown error occurred."
                    showErrorAlert = true
                }
            }
        } message: {
            Text("This will permanently overwrite your current towers and items with the imported data.")
        }
        .alert("Import Failed", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showQRDisplay) {
            NavigationStack {
                VStack {
                    if let img = generatedQRCode {
                        Image(uiImage: img)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250, height: 250)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    } else {
                        Text("Could not generate QR Code")
                            .foregroundStyle(.red)
                    }
                    Text("Have your coworker scan this from their Settings tab.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 16)
                }
                .navigationTitle("Property QR Code")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showQRDisplay = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showQRScanner) {
            NavigationStack {
                QRScannerView(onScanned: { code in
                    showQRScanner = false
                    do {
                        try PropertySharingService.importConfiguration(from: code, context: modelContext)
                        flowVM.resetFlow()
                    } catch let error as PropertySharingError {
                        errorMessage = error.localizedDescription
                        showErrorAlert = true
                    } catch {
                        errorMessage = "An unknown error occurred."
                        showErrorAlert = true
                    }
                }, onError: { error in
                    showQRScanner = false
                    errorMessage = error
                    showErrorAlert = true
                })
                .navigationTitle("Scan Property QR")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { showQRScanner = false }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddTowerSheet) {
            AddTowerSheet(
                existingNames: Set(towers.map { $0.name }),
                onCreate: { draft in
                    if let tower = flowVM.addTower(
                        name: draft.name,
                        startFloor: draft.startFloor,
                        topFloor: draft.topFloor,
                        skip13thFloor: draft.skip13thFloor,
                        deliveryMode: draft.deliveryMode
                    ) {
                        showAddTowerSheet = false
                        expandedTowerEditorID = tower.id
                    }
                },
                onCancel: { showAddTowerSheet = false }
            )
        }
    }

    private func save() {
        try? modelContext.save()
    }

    private var settingsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isCustomProperty ? "building.2.crop.circle.fill" : "building.2.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.cyan)
                    .frame(width: 42, height: 42)
                    .background(Color.cyan.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(isCustomProperty ? "Custom Property" : "Hilton Hawaiian Village")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text("Settings apply to new calculations and active delivery plans. Saved logs keep their original snapshot.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 8) {
                SettingsSummaryPill(value: "\(towers.filter(\.isActive).count)", label: "Active towers", tint: .green)
                SettingsSummaryPill(value: "\(items.count)", label: "Items", tint: .cyan)
                SettingsSummaryPill(value: timeText(hour: shiftSettings.targetHour, minute: shiftSettings.targetMinute), label: "Target", tint: .orange)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.cyan.opacity(0.14), Color.white.opacity(0.065), Color.indigo.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Appearance",
                subtitle: "Choose a look tuned for shift work or visual polish."
            )

            PremiumCard {
                VStack(alignment: .leading, spacing: 14) {
                    SettingsSubsectionTitle(
                        systemImage: themeSettings.mode.systemImage,
                        title: "Theme",
                        subtitle: themeSettings.mode.subtitle,
                        tint: themeSettings.isPractical ? .blue : .cyan
                    )

                    Picker("Theme", selection: Bindable(themeSettings).mode) {
                        ForEach(AppThemeMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("App theme")
                }
            }
        }
    }

    private var smartTipsSection: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 12) {
                SettingsSubsectionTitle(
                    systemImage: "lightbulb.max.fill",
                    title: "Smart Tips",
                    subtitle: "Control contextual help across the app.",
                    tint: .cyan
                )

                Toggle(isOn: Binding(
                    get: { flowVM.smartTipsEnabled },
                    set: { flowVM.setSmartTipsEnabled($0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Smart Tips")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Show contextual hints throughout the app.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .tint(.cyan)

                Toggle(isOn: Binding(
                    get: { flowVM.autoOpenTipsEnabled },
                    set: { flowVM.setAutoOpenTipsEnabled($0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto-open tips")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Open tips automatically the first time a screen needs them.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .tint(.cyan)
                .disabled(!flowVM.smartTipsEnabled)

                Toggle(isOn: Binding(
                    get: { flowVM.showTipButtons },
                    set: { flowVM.setShowTipButtons($0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show tip buttons")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Display the question-mark buttons that open tips on demand.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .tint(.cyan)
                .disabled(!flowVM.smartTipsEnabled)

                Divider().overlay(Color.white.opacity(0.08))

                Button {
                    flowVM.resetDismissedSmartTips()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.uturn.backward.circle")
                            .font(.caption.weight(.bold))
                        Text("Reset dismissed tips")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.cyan)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.cyan.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var propertyProfileSection: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Profile & Sharing", subtitle: "Reset, restore, export, or import a property setup.")
            
            PremiumCard {
                VStack(alignment: .leading, spacing: 16) {
                    Button {
                        showBlankPropertyConfirm = true
                    } label: {
                        SettingsActionRow(
                            systemImage: "trash.fill",
                            title: "Start Fresh",
                            subtitle: "Delete current property data and configure a blank hotel.",
                            tint: .red
                        )
                    }
                    .buttonStyle(.plain)

                    Divider().background(Color.white.opacity(0.1))

                    Button {
                        showHHVDefaultsConfirm = true
                    } label: {
                        SettingsActionRow(
                            systemImage: "building.2.fill",
                            title: "Restore HHV Defaults",
                            subtitle: "Replace current setup with the original towers and items.",
                            tint: .cyan
                        )
                    }
                    .buttonStyle(.plain)

                    Divider().background(Color.white.opacity(0.1))

                    if let code = try? PropertySharingService.exportConfiguration(towers: towers, items: items) {
                        ShareLink(item: code) {
                            SettingsActionRow(
                                systemImage: "square.and.arrow.up",
                                title: "Share as Text",
                                subtitle: "Send a property configuration code to a coworker.",
                                tint: .green
                            )
                        }
                        .buttonStyle(.plain)

                        Divider().background(Color.white.opacity(0.1))
                        
                        Button {
                            generatedQRCode = PropertySharingService.generateQRCode(from: code)
                            showQRDisplay = true
                        } label: {
                            SettingsActionRow(
                                systemImage: "qrcode",
                                title: "Show QR Code",
                                subtitle: "Let another device scan this property setup.",
                                tint: .green
                            )
                        }
                        .buttonStyle(.plain)
                        
                        Divider().background(Color.white.opacity(0.1))
                    }

                    Button {
                        showImportAlert = true
                    } label: {
                        SettingsActionRow(
                            systemImage: "square.and.arrow.down",
                            title: "Import from Text",
                            subtitle: "Paste a code and replace the current setup.",
                            tint: .orange
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    Button {
                        showQRScanner = true
                    } label: {
                        SettingsActionRow(
                            systemImage: "qrcode.viewfinder",
                            title: "Scan QR Code",
                            subtitle: "Import a coworker's property setup from their phone.",
                            tint: .orange
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var rulesSection: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 12) {
                SettingsSubsectionTitle(
                    systemImage: "checklist.checked",
                    title: "Special Rules",
                    subtitle: "Business rules used while calculating linen plans.",
                    tint: .orange
                )
                SettingsInfoRow(
                    systemImage: "building.columns.fill",
                    title: "Tower-limited items",
                    subtitle: "Double Sheet and Double Cover are only available for Diamond and Alii.",
                    tint: .blue
                )
                Divider().background(Color.white.opacity(0.1))
                SettingsInfoRow(
                    systemImage: "shippingbox.fill",
                    title: "Saved log snapshots",
                    subtitle: "Bundle size changes affect future flows only. Saved logs keep the values used when they were saved.",
                    tint: .orange
                )
            }
        }
    }

    private var dataSection: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 12) {
                SettingsSubsectionTitle(
                    systemImage: "externaldrive.fill",
                    title: "Data Safety",
                    subtitle: "How settings changes affect existing records.",
                    tint: .green
                )
                SettingsInfoRow(
                    systemImage: "lock.doc.fill",
                    title: "Saved logs are immutable",
                    subtitle: "Changing settings here does not rewrite previous daily logs.",
                    tint: .green
                )
            }
        }
    }

    private var towerSections: [TowerDisplayGroupSection] {
        TowerDisplayGroup.allCases.compactMap { group in
            let grouped = towers.filter { $0.displayGroup == group }.sorted { $0.name < $1.name }
            return grouped.isEmpty ? nil : TowerDisplayGroupSection(group: group, towers: grouped)
        }
    }

    private var itemSections: [LinenItemDisplayGroupSection] {
        LinenItemDisplayGroup.allCases.compactMap { group in
            let grouped = items.filter { $0.displayGroup == group }.sorted { $0.name < $1.name }
            return grouped.isEmpty ? nil : LinenItemDisplayGroupSection(group: group, items: grouped)
        }
    }

    private func timePicker(label: String, hour: Binding<Int>, minute: Binding<Int>) -> some View {
        let binding = Binding<Date>(
            get: {
                Calendar.current.date(bySettingHour: hour.wrappedValue, minute: minute.wrappedValue, second: 0, of: Date()) ?? Date()
            },
            set: { newDate in
                let cal = Calendar.current
                hour.wrappedValue = cal.component(.hour, from: newDate)
                minute.wrappedValue = cal.component(.minute, from: newDate)
            }
        )
        return HStack {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.78))
            Spacer()
            DatePicker("", selection: binding, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .colorScheme(.dark)
        }
    }

    private var shiftTimingSummary: String {
        "Target down: \(timeText(hour: shiftSettings.targetHour, minute: shiftSettings.targetMinute)) · Start: \(timeText(hour: shiftSettings.shiftStartHour, minute: shiftSettings.shiftStartMinute)) · End: \(timeText(hour: shiftSettings.shiftEndHour, minute: shiftSettings.shiftEndMinute))"
    }

    private func timeText(hour: Int, minute: Int = 0) -> String {
        let date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}

// MARK: - Tower card

private struct SettingsTowerGroupHeader: View {
    public let group: TowerDisplayGroup
    public let count: Int

    public var body: some View {
        SettingsDisplayGroupHeader(
            title: group.displayName,
            subtitle: group.subtitle,
            count: count,
            systemImage: group.systemImage,
            tint: group == .pieceDistribution ? .green : .blue
        )
    }
}

private struct SettingsItemGroupHeader: View {
    public let group: LinenItemDisplayGroup
    public let count: Int

    public var body: some View {
        SettingsDisplayGroupHeader(
            title: group.displayName,
            subtitle: group.subtitle,
            count: count,
            systemImage: group.systemImage,
            tint: tint
        )
    }

    private var tint: Color {
        switch group {
        case .bath: return .cyan
        case .bedding: return .indigo
        case .specialty: return .orange
        }
    }
}

private struct SettingsDisplayGroupHeader: View {
    public let title: String
    public let subtitle: String
    public let count: Int
    public let systemImage: String
    public let tint: Color

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 22, height: 22)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white.opacity(0.86))
                Text(subtitle)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.48))
            }
            Spacer()
            Text("\(count)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

private struct SettingsSummaryPill: View {
    public let value: String
    public let label: String
    public let tint: Color

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.heavy).monospacedDigit())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.70)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct SettingsSubsectionTitle: View {
    public let systemImage: String
    public let title: String
    public let subtitle: String
    public let tint: Color

    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct SettingsActionRow: View {
    public let systemImage: String
    public let title: String
    public let subtitle: String
    public let tint: Color

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.32))
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct SettingsInfoRow: View {
    public let systemImage: String
    public let title: String
    public let subtitle: String
    public let tint: Color

    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct TowerSettingsCard: View {
    @Environment(FlowViewModel.self) private var flowVM
    @Bindable public var tower: Tower
    public let isExpanded: Bool
    public let onToggle: () -> Void
    public var onCommit: () -> Void

    @State private var editStartFloor: Int = 1
    @State private var editTopFloor: Int = 1
    @State private var editSkip13thFloor: Bool = false
    @State private var showResetConfirm = false
    @State private var showDeleteConfirm = false

    private var isUserCreated: Bool {
        !DefaultData.towers.contains(where: { $0.name == tower.name })
    }

    private var liveCalculatedCount: Int {
        TowerFloorRange.deliveryFloorCount(
            startFloor: editStartFloor,
            topFloor: editTopFloor,
            skip13thFloor: editSkip13thFloor
        )
    }

    private var liveIsValid: Bool {
        TowerFloorRange.isValid(
            startFloor: editStartFloor,
            topFloor: editTopFloor,
            skip13thFloor: editSkip13thFloor
        )
    }

    private var liveFormulaText: String {
        TowerFloorRange.formulaText(
            startFloor: editStartFloor,
            topFloor: editTopFloor,
            skip13thFloor: editSkip13thFloor
        )
    }

    private var liveFloorList: [Int] {
        TowerFloorRange.deliveryFloors(
            startFloor: editStartFloor,
            topFloor: editTopFloor,
            skip13thFloor: editSkip13thFloor
        )
    }

    private var legacyFloors: [Int] {
        DeliveryFloorSequenceService.deliveryFloors(
            towerName: tower.name,
            floorCount: tower.floorCount
        )
    }

    private var collapsedSummary: String {
        if tower.hasCustomFloorRange {
            return TowerFloorRange.summary(
                startFloor: tower.startFloor,
                topFloor: tower.topFloor,
                skip13thFloor: tower.skip13thFloor
            )
        }
        return "Legacy custom sequence · \(tower.floorCount) delivery floors"
    }

    private var hasActiveFlowEntries: Bool {
        flowVM.selectedTower?.id == tower.id && !flowVM.receivingEntries.isEmpty
    }

    private var thirteenIsInsideEditedRange: Bool {
        editStartFloor <= 13 && 13 <= editTopFloor
    }

    private var modeText: String {
        tower.deliveryMode == .bundles ? "Bundle delivery" : "Piece distribution"
    }

    private var fullDescription: String {
        "\(collapsedSummary) · \(modeText)"
    }

    private var accentColor: Color? {
        tower.identityColorHex.flatMap { Color(hex: $0) }
    }

    private var collapsedHeader: some View {
        let isActive = tower.isActive
        let activeText = isActive ? "Active" : "Inactive"
        let activeColor: Color = isActive ? .green : .white
        let activeForegroundColor: Color = isActive ? .green : .white.opacity(0.62)
        let chevronName = isExpanded ? "chevron.up" : "chevron.down"

        return Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(tower.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Text(activeText)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(activeColor.opacity(0.14), in: Capsule())
                        .foregroundStyle(activeForegroundColor)
                    Image(systemName: chevronName)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.42))
                }
                Text(fullDescription)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(isExpanded ? "Double tap to collapse tower settings." : "Double tap to edit tower settings.")
    }

    private var floorRangeHeader: some View {
        HStack(spacing: 8) {
            Text("Floor range")
                .font(.caption.weight(.heavy))
                .foregroundStyle(.white.opacity(0.7))
                .textCase(.uppercase)
            Spacer()
            Button {
                flowVM.presentSmartTip(.towerFloorCountFormula, force: true)
            } label: {
                Image(systemName: "questionmark.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.cyan.opacity(0.85))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("How floor count works")
        }
    }

    private var startFloorRow: some View {
        HStack(spacing: 12) {
            Text("Start floor")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Stepper(value: $editStartFloor, in: TowerFloorRange.minimumStartFloor...TowerFloorRange.maximumTopFloor) {
                Text("\(editStartFloor)")
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.white)
            }
            .tint(.blue)
            .fixedSize()
        }
    }

    private var topFloorRow: some View {
        HStack(spacing: 12) {
            Text("Top floor")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Stepper(value: $editTopFloor, in: TowerFloorRange.minimumStartFloor...TowerFloorRange.maximumTopFloor) {
                Text("\(editTopFloor)")
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.white)
            }
            .tint(.blue)
            .fixedSize()
        }
    }

    private var skip13Section: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle("Skip 13th floor", isOn: $editSkip13thFloor)
                .tint(.blue)
                .foregroundStyle(.white.opacity(0.78))
            Text(skip13HelperText)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var activeFlowNotice: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.cyan.opacity(0.85))
            Text("Changing floors recalculates today's active delivery plan. Saved logs stay unchanged.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var resetButton: some View {
        Button {
            showResetConfirm = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.uturn.backward.circle")
                    .font(.caption.weight(.bold))
                Text("Reset to default floor settings")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Reset tower floor settings to default.")
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "trash.fill")
                    .font(.caption.weight(.bold))
                Text("Delete this tower")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.red.opacity(0.85))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.red.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Delete this user-created tower.")
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    @ViewBuilder
    private var expandedContent: some View {
        Divider().overlay(Color.white.opacity(0.08))
        Toggle("Active tower", isOn: $tower.isActive)
            .tint(.blue)
            .foregroundStyle(.white.opacity(0.78))

        floorRangeHeader

        if !tower.hasCustomFloorRange {
            legacyHelperBanner
        }

        startFloorRow
        topFloorRow
        skip13Section

        calculatedHero

        Text(liveFormulaText)
            .font(.caption.weight(.semibold).monospacedDigit())
            .foregroundStyle(liveIsValid ? .white.opacity(0.72) : .orange)
            .fixedSize(horizontal: false, vertical: true)

        deliveryFloorPreview
        validationOrInfoMessage

        if hasActiveFlowEntries {
            activeFlowNotice
        }

        Text("Delivery mode: \(modeText)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.62))

        resetButton
        if isUserCreated {
            deleteButton
        }
    }

    public var body: some View {
        PremiumCard(accentColor: accentColor) {
            VStack(alignment: .leading, spacing: 10) {
                collapsedHeader
                if isExpanded {
                    expandedContent
                }
            }
        }
        .animation(.snappy(duration: 0.18), value: isExpanded)
        .onChange(of: tower.isActive) { _, newValue in
            flowVM.setTowerActive(tower, isActive: newValue)
            onCommit()
        }
        .onAppear { syncFromTower() }
        .onChange(of: isExpanded) { _, expanded in
            if expanded {
                syncFromTower()
                flowVM.autoPresentSmartTip(.towerFloorCountFormula)
            } else {
                commitIfChanged()
            }
        }
        .onChange(of: editStartFloor) { _, _ in commitIfChanged() }
        .onChange(of: editTopFloor) { _, _ in commitIfChanged() }
        .onChange(of: editSkip13thFloor) { _, _ in commitIfChanged() }
        .confirmationDialog(
            "Reset \(tower.name) floor settings to defaults?",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                flowVM.resetTowerFloorRangeToDefaults(tower)
                syncFromTower()
                onCommit()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Restores the seeded range for this tower. Saved logs are not changed.")
        }
        .confirmationDialog(
            "Delete \(tower.name)?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                flowVM.deleteTower(tower)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Removes this tower from the picker and active flow. Saved Daily Logs are not affected.")
        }
    }

    // MARK: - Subviews

    private var legacyHelperBanner: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.orange.opacity(0.9))
            Text("This tower currently uses a custom legacy sequence. Editing start/top floors will switch it to a simple range.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var calculatedHero: some View {
        HStack(spacing: 8) {
            Image(systemName: "function")
                .font(.caption.weight(.bold))
                .foregroundStyle(liveIsValid ? .cyan : .orange)
            Text("Calculated delivery floors")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text("\(liveCalculatedCount)")
                .font(.title3.weight(.heavy).monospacedDigit())
                .foregroundStyle(liveIsValid ? .white : .orange)
        }
        .padding(10)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var deliveryFloorPreview: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(tower.hasCustomFloorRange ? "Delivery floors" : "Legacy delivery floors")
                .font(.caption2.weight(.heavy))
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)

            if !tower.hasCustomFloorRange {
                Text(TowerFloorRange.compactFloorList(legacyFloors))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            } else if liveIsValid {
                Text(TowerFloorRange.compactFloorList(liveFloorList))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
                if editSkip13thFloor, thirteenIsInsideEditedRange {
                    Text("Skipped: 13")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }
            } else {
                Text("—")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private var validationOrInfoMessage: some View {
        if !liveIsValid {
            if editTopFloor < editStartFloor {
                warningText("Top floor must be the same as or higher than the starting floor.")
            } else {
                warningText("This range has no delivery floors after skipped floors are removed.")
            }
        } else if editSkip13thFloor, !thirteenIsInsideEditedRange {
            infoText("Floor 13 is outside this range, so Skip 13 does not change the count.")
        }
    }

    private func warningText(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.orange.opacity(0.95))
            .fixedSize(horizontal: false, vertical: true)
    }

    private func infoText(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.5))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var skip13HelperText: String {
        if editSkip13thFloor, !thirteenIsInsideEditedRange {
            return "Floor 13 is outside this range, so this does not change the count."
        }
        return "Removes floor 13 only when it is inside this tower's range."
    }

    // MARK: - State helpers

    private func syncFromTower() {
        if tower.hasCustomFloorRange {
            editStartFloor = tower.startFloor
            editTopFloor = tower.topFloor
        } else {
            editStartFloor = max(1, tower.startFloor > 0 ? tower.startFloor : 1)
            editTopFloor = max(editStartFloor, tower.topFloor > 0 ? tower.topFloor : max(tower.floorCount, editStartFloor))
        }
        editSkip13thFloor = tower.skip13thFloor
    }

    private func commitIfChanged() {
        guard liveIsValid else { return }
        if tower.startFloor == editStartFloor,
           tower.topFloor == editTopFloor,
           tower.skip13thFloor == editSkip13thFloor {
            return
        }
        flowVM.updateTowerFloorRange(
            tower,
            startFloor: editStartFloor,
            topFloor: editTopFloor,
            skip13thFloor: editSkip13thFloor
        )
        onCommit()
    }
}

// MARK: - Linen item card

private struct LinenItemSettingsCard: View {
    @Bindable public var item: LinenItem
    public let isExpanded: Bool
    public let onToggle: () -> Void
    public var onCommit: () -> Void

    public var body: some View {
        PremiumCard(accentColor: LinenIconLibrary.color(forItem: item.name)) {
            VStack(alignment: .leading, spacing: 10) {
                Button(action: onToggle) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            LinenItemIcon(itemName: item.name, size: 40, boxed: true)
                            Text(item.name)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                            Spacer()
                            Text(item.countMethod.displayName)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.white.opacity(0.08), in: Capsule())
                                .foregroundStyle(.white.opacity(0.75))
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.42))
                        }

                        HStack(spacing: 14) {
                            LabeledFact(label: "Par / floor", value: "\(item.parCount)")
                            LabeledFact(label: "Bundle size", value: "\(item.bundleSize)")
                            if item.countMethod == .fixedBin, let perBin = item.piecesPerBin {
                                LabeledFact(label: "Pieces / bin", value: "\(perBin)")
                            }
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint(isExpanded ? "Double tap to collapse item settings." : "Double tap to edit item settings.")

                if isExpanded {
                    Divider().overlay(Color.white.opacity(0.08))
                    Toggle("Available for future flows", isOn: $item.isActive)
                        .tint(.blue)
                        .foregroundStyle(.white.opacity(0.78))
                    HStack(spacing: 12) {
                        Text("Par / floor")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                        Stepper(value: $item.parCount, in: 1...30) {
                            Text("\(item.parCount)")
                                .font(.title3.weight(.semibold).monospacedDigit())
                                .foregroundStyle(.white)
                        }
                        .tint(.blue)
                    }
                    HStack(spacing: 12) {
                        Text("Bundle size")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                        Stepper(value: $item.bundleSize, in: 1...500) {
                            Text("\(item.bundleSize) pcs")
                                .font(.title3.weight(.semibold).monospacedDigit())
                                .foregroundStyle(.white)
                        }
                        .tint(.blue)
                    }
                    if item.countMethod == .fixedBin, let perBin = item.piecesPerBin {
                        Label("Fixed-bin rule: \(perBin) pcs/bin", systemImage: "lock.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.58))
                    }
                    Text("Changes apply to future flows. Saved logs keep their original snapshot.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.48))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.snappy(duration: 0.18), value: isExpanded)
        .onChange(of: item.parCount) { _, _ in onCommit() }
        .onChange(of: item.bundleSize) { _, _ in onCommit() }
        .onChange(of: item.isActive) { _, _ in onCommit() }
    }
}

// MARK: - Tower delivery rule card

private struct TowerDeliveryRuleCard: View {
    public let tower: Tower
    public let isExpanded: Bool
    public let onToggle: () -> Void

    private var isConfirmed: Bool {
        TowerOperationalPolicy.hasProtectedDeliveryFloorCount(tower)
    }

    private var floorCount: Int {
        TowerOperationalPolicy.confirmedDeliveryFloorCount(for: tower) ?? tower.floorCount
    }

    private var floors: [Int] {
        FloorNumberingService.deliveryFloors(towerName: tower.name, floorCount: floorCount)
    }

    private var floorRangeDescription: String {
        guard let first = floors.first, let last = floors.last else { return "—" }
        let skipped = (first...last).filter { !floors.contains($0) }
        var desc = "\(first)–\(last)"
        if !skipped.isEmpty {
            desc += " (skip \(skipped.map(String.init).joined(separator: ", ")))"
        }
        return desc
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 8)

    public var body: some View {
        let accentColor = tower.identityColorHex.flatMap { Color(hex: $0) }
        return PremiumCard(accentColor: accentColor) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(tower.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(isConfirmed ? "Confirmed" : "Default")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(
                            (isConfirmed ? Color.green : Color.white.opacity(0.3)).opacity(0.18),
                            in: Capsule()
                        )
                        .foregroundStyle(isConfirmed ? .green : .white.opacity(0.6))
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.42))
                }
                HStack(spacing: 6) {
                    Image(systemName: "building.2")
                        .font(.caption2)
                        .foregroundStyle(.cyan)
                    Text("\(floorCount) stops · \(floorRangeDescription)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.65))
                }
                if !isConfirmed {
                    Text("Uses current tower floor setting.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                }
                if TowerOperationalPolicy.isTimeshareTower(tower.name) {
                    HStack(spacing: 6) {
                        Image(systemName: "house.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        Text("Timeshare — no par system")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.58))
                    }
                }

                if isExpanded {
                    Divider().overlay(Color.white.opacity(0.08))
                    Text("Floor sequence")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(floors, id: \.self) { floor in
                            Text("\(floor)")
                                .font(.caption2.weight(.semibold).monospacedDigit())
                                .foregroundStyle(.white.opacity(0.85))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
    }
}

private struct LabeledFact: View {
    public let label: String
    public let value: String

    public var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Add Tower Sheet

public struct NewTowerDraft {
    public let name: String
    public let startFloor: Int
    public let topFloor: Int
    public let skip13thFloor: Bool
    public let deliveryMode: TowerDeliveryMode
}

private struct AddTowerSheet: View {
    public let existingNames: Set<String>
    public let onCreate: (NewTowerDraft) -> Void
    public let onCancel: () -> Void

    @State private var name: String = ""
    @State private var startFloor: Int = 1
    @State private var topFloor: Int = 15
    @State private var skip13thFloor: Bool = false
    @State private var deliveryMode: TowerDeliveryMode = .bundles

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var nameIsDuplicate: Bool {
        let candidate = trimmedName.lowercased()
        return !candidate.isEmpty && existingNames.contains(where: { $0.lowercased() == candidate })
    }

    private var isValid: Bool {
        !trimmedName.isEmpty
            && !nameIsDuplicate
            && TowerFloorRange.isValid(startFloor: startFloor, topFloor: topFloor, skip13thFloor: skip13thFloor)
    }

    private var calculatedCount: Int {
        TowerFloorRange.deliveryFloorCount(startFloor: startFloor, topFloor: topFloor, skip13thFloor: skip13thFloor)
    }

    private var formulaText: String {
        TowerFloorRange.formulaText(startFloor: startFloor, topFloor: topFloor, skip13thFloor: skip13thFloor)
    }

    private var floorList: [Int] {
        TowerFloorRange.deliveryFloors(startFloor: startFloor, topFloor: topFloor, skip13thFloor: skip13thFloor)
    }

    public var body: some View {
        NavigationStack {
            AppBackground {
                ScrollView {
                    VStack(spacing: 16) {
                        nameCard
                        floorRangeCard
                        deliveryModeCard
                        previewCard
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Add Tower")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: createTower)
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var nameCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tower name")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white.opacity(0.7))
                    .textCase(.uppercase)
                TextField("", text: $name, prompt: Text("e.g. Coral").foregroundStyle(.white.opacity(0.35)))
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                if nameIsDuplicate {
                    Text("A tower named \"\(trimmedName)\" already exists.")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var floorRangeCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Floor range")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white.opacity(0.7))
                    .textCase(.uppercase)

                HStack(spacing: 12) {
                    Text("Start floor")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    Stepper(value: $startFloor, in: TowerFloorRange.minimumStartFloor...TowerFloorRange.maximumTopFloor) {
                        Text("\(startFloor)")
                            .font(.title3.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.white)
                    }
                    .tint(.blue)
                    .fixedSize()
                }

                HStack(spacing: 12) {
                    Text("Top floor")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    Stepper(value: $topFloor, in: TowerFloorRange.minimumStartFloor...TowerFloorRange.maximumTopFloor) {
                        Text("\(topFloor)")
                            .font(.title3.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.white)
                    }
                    .tint(.blue)
                    .fixedSize()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Skip 13th floor", isOn: $skip13thFloor)
                        .tint(.blue)
                        .foregroundStyle(.white.opacity(0.78))
                    Text("Removes floor 13 only when it is inside this tower's range.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var deliveryModeCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Delivery mode")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white.opacity(0.7))
                    .textCase(.uppercase)
                Picker("Delivery mode", selection: $deliveryMode) {
                    Text("Bundle delivery").tag(TowerDeliveryMode.bundles)
                    Text("Piece distribution").tag(TowerDeliveryMode.pieces)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var previewCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "function")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(calculatedCount > 0 ? .cyan : .orange)
                    Text("Calculated delivery floors")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text("\(calculatedCount)")
                        .font(.title3.weight(.heavy).monospacedDigit())
                        .foregroundStyle(calculatedCount > 0 ? .white : .orange)
                }

                Text(formulaText)
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(calculatedCount > 0 ? .white.opacity(0.72) : .orange)
                    .fixedSize(horizontal: false, vertical: true)

                if calculatedCount > 0 {
                    Text(TowerFloorRange.compactFloorList(floorList))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func createTower() {
        guard isValid else { return }
        onCreate(NewTowerDraft(
            name: trimmedName,
            startFloor: startFloor,
            topFloor: topFloor,
            skip13thFloor: skip13thFloor,
            deliveryMode: deliveryMode
        ))
    }
}
