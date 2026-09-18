// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI
import UniformTypeIdentifiers

/// The "Monitor" settings page: pick what shows next to the menu bar icon, how
/// often it refreshes, which blocks appear in the panel, and which metrics draw
/// a history graph. Everything is opt-in or reversible, so users keep only what
/// they find useful.
struct MonitorSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var monitor = SystemMonitor.shared

    @AppStorage(DefaultsKey.menuBarCombineTemperatures) private var combineTemperatures = true
    @AppStorage(DefaultsKey.menuBarSeparateMetrics) private var separateMetrics = false
    @AppStorage(DefaultsKey.menuBarMetricSpacing) private var metricSpacing = "standard"
    @AppStorage(DefaultsKey.menuBarHideIconWithMetrics) private var hideIconWithMetrics = false
    @AppStorage(DefaultsKey.monitorInterval) private var interval = 2
    @AppStorage(DefaultsKey.temperatureUnit) private var temperatureUnit = TemperatureUnit.celsius.rawValue
    @AppStorage(DefaultsKey.monitorShowFanControlBeta) private var showFanControlBeta = false

    @AppStorage(DefaultsKey.monitorGraphCPU) private var graphCPU = true
    @AppStorage(DefaultsKey.monitorGraphGPU) private var graphGPU = true
    @AppStorage(DefaultsKey.monitorGraphMemory) private var graphMemory = true
    @AppStorage(DefaultsKey.monitorGraphNetwork) private var graphNetwork = true
    @AppStorage(DefaultsKey.monitorGraphDisk) private var graphDisk = true
    @AppStorage(DefaultsKey.monitorGraphPower) private var graphPower = true
    @AppStorage(DefaultsKey.monitorGraphBattery) private var graphBattery = true

    @AppStorage(DefaultsKey.menuBarPeripheralBatteryDevice1) private var peripheralDevice1 = ""
    @AppStorage(DefaultsKey.menuBarPeripheralBatteryDevice2) private var peripheralDevice2 = ""

    var body: some View {
        Form {
            Section(l10n.s.monitorMenuBarSection) {
                MenuBarMetricsPreview()
                    .padding(.vertical, 4)
                Toggle(l10n.s.monitorCombineTemperatures, isOn: $combineTemperatures)
                Text(l10n.s.monitorCombineTemperaturesCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker(l10n.s.menuBarSpacingLabel, selection: $metricSpacing) {
                    Text(l10n.s.menuBarSpacingStandard).tag("standard")
                    Text(l10n.s.menuBarSpacingCompact).tag("compact")
                }
                .pickerStyle(.segmented)
                Toggle(l10n.s.menuBarHideIconToggle, isOn: $hideIconWithMetrics)
                Text(l10n.s.menuBarHideIconCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle(l10n.s.monitorSeparateMenuBarMetrics, isOn: $separateMetrics)
                Text(l10n.s.monitorSeparateMenuBarMetricsCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                MenuBarMetricOrderEditor()
                Text(l10n.s.monitorMenuBarCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section {
                Picker(l10n.s.monitorIntervalLabel, selection: $interval) {
                    Text(l10n.s.monitorInterval1).tag(1)
                    Text(l10n.s.monitorInterval2).tag(2)
                    Text(l10n.s.monitorInterval5).tag(5)
                }
                Picker(l10n.s.temperatures, selection: $temperatureUnit) {
                    Text("°C").tag(TemperatureUnit.celsius.rawValue)
                    Text("°F").tag(TemperatureUnit.fahrenheit.rawValue)
                }
                .pickerStyle(.segmented)
            }
            monitorAlertsSection
            Section(l10n.s.monitorPanelSection) {
                MonitorPanelConfig()
                Text(l10n.s.monitorPanelConfigHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            peripheralBatteryDevicesSection
            Section(l10n.s.fanControlBetaSection) {
                Toggle(l10n.s.fanControlBetaShow, isOn: $showFanControlBeta)
                Text(l10n.s.fanControlBetaCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section(l10n.s.monitorOrderSection) {
                PanelOrderEditor()
                Text(l10n.s.monitorOrderHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section(l10n.s.monitorGraphsSection) {
                Toggle(l10n.s.monitorShowCPU, isOn: $graphCPU)
                Toggle(l10n.s.monitorShowGPU, isOn: $graphGPU)
                Toggle(l10n.s.monitorShowMemory, isOn: $graphMemory)
                Toggle(l10n.s.monitorShowNetwork, isOn: $graphNetwork)
                Toggle(l10n.s.diskSection, isOn: $graphDisk)
                Toggle(l10n.s.monitorShowPowerLabel, isOn: $graphPower)
                Toggle(l10n.s.batteryLabel, isOn: $graphBattery)
                Text(l10n.s.monitorGraphsCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .groupedFormStyle()
        .onAppear {
            SystemMonitor.shared.panelDidAppear()
            interval = Defaults.sanitizedMonitorInterval(interval)
            if TemperatureUnit(rawValue: temperatureUnit) == nil {
                temperatureUnit = TemperatureUnit.celsius.rawValue
            }
        }
        .onDisappear {
            SystemMonitor.shared.panelDidDisappear()
        }
    }

    private var monitorAlertsSection: some View {
        let text = FeatureStrings.monitorAlerts(l10n.language)
        return Section(text.section) {
            MonitorAlertsControls(compact: false)
        }
    }

    private var peripheralBatteryDevices: [PeripheralBatteryDevice] {
        PeripheralBatterySupport.sorted(monitor.snapshot.peripheralBatteries)
    }

    @ViewBuilder
    private var peripheralBatteryDevicesSection: some View {
        Section(l10n.s.monitorShowPeripheralBattery) {
            if peripheralBatteryDevices.isEmpty {
                Text(l10n.s.peripheralBatteryNoDevices)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Picker("状态栏设备 1", selection: $peripheralDevice1) {
                    Text("不显示").tag("")
                    ForEach(peripheralBatteryDevices) { device in
                        Text("\(device.name) (\(device.percent)%)").tag(device.id)
                    }
                }
                Picker("状态栏设备 2", selection: $peripheralDevice2) {
                    Text("不显示").tag("")
                    ForEach(peripheralBatteryDevices) { device in
                        Text("\(device.name) (\(device.percent)%)").tag(device.id)
                    }
                }
                .onChange(of: peripheralDevice1) { _ in dedupePeripheralDeviceSelection() }
                .onChange(of: peripheralDevice2) { _ in dedupePeripheralDeviceSelection() }
                Text("可最多显示 2 个蓝牙/外设电量到状态栏（图标 + 百分比）。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func dedupePeripheralDeviceSelection() {
        if !peripheralDevice1.isEmpty, peripheralDevice1 == peripheralDevice2 {
            peripheralDevice2 = ""
        }
    }
}

/// Drag-to-reorder and show/hide list for the menu bar metrics. The order stays
/// independent from which metrics are visible, so toggles do not reshuffle it.
private struct MenuBarMetricOrderEditor: View {
    @ObservedObject private var l10n = L10n.shared
    @AppStorage(DefaultsKey.menuBarMetricOrder) private var metricOrder = ""
    @State private var order: [MenuBarMetric] = MenuBarMetric.order(in: .standard)
    @State private var dragging: MenuBarMetric?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(order) { metric in
                metricOrderRow(metric)
            }
        }
        .padding(.vertical, 2)
        .onAppear { order = MenuBarMetric.order(in: .standard) }
        .onChange(of: metricOrder) { _ in order = MenuBarMetric.order(in: .standard) }
    }

    @ViewBuilder
    private func metricOrderRow(_ metric: MenuBarMetric) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 12))
                        .tertiaryForegroundStyle()
                    Image(systemName: metric.symbolName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 18)
                    Text(metric.title(l10n.s))
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .opacity(dragging == metric ? 0.45 : 1)
                .onDrag {
                    dragging = metric
                    return NSItemProvider(object: metric.rawValue as NSString)
                }
                .onDrop(of: [UTType.text],
                        delegate: MenuBarMetricOrderDropDelegate(target: metric,
                                                                 order: $order,
                                                                 dragging: $dragging))

                MenuBarMetricVisibilityToggle(metric: metric)
            }
            .frame(height: 32)

            if metric == .memory {
                MemoryMenuBarOrderOption()
            }

            if metric == .diskUsage {
                DiskUsageMenuBarOrderOption()
            }

            if metric == .network {
                NetworkMenuBarOrderOption()
            }

            if metric != order.last {
                Divider()
            }
        }
    }
}

// Contributed in PR #179: the memory pressure-dot option lives under the
// Memory row, matching the Network row's inline option.
/// Inline per-metric option row: caption on the left, a switch on the right,
/// indented under its metric. The switch is a hand-rolled capsule Button on
/// purpose: a native Toggle inside the reorderable metric list never receives
/// the click (the row's drag handling swallows it), while a plain Button does.
private struct MetricRowOptionToggle: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Button {
                isOn.toggle()
            } label: {
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? Color.accentColor : Color.secondary.opacity(0.28))
                        .frame(width: 28, height: 16)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                        .padding(2)
                }
                .frame(width: 30, height: 20)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(label)
            .accessibilityLabel(label)
            .accessibilityValue(isOn ? "1" : "0")
        }
        .padding(.leading, 58)
        .padding(.trailing, 4)
        .padding(.bottom, 7)
    }
}

private struct MemoryMenuBarOrderOption: View {
    @ObservedObject private var l10n = L10n.shared
    @AppStorage(DefaultsKey.menuBarMemory) private var menuBarMemory = false
    @AppStorage(DefaultsKey.menuBarMemoryStyle) private var memoryStyle = "percent"

    var body: some View {
        if menuBarMemory {
            MetricRowOptionToggle(label: l10n.s.monitorMemoryPressureDot,
                                  isOn: Binding(
                                      get: { Defaults.sanitizedMenuBarMemoryStyle(memoryStyle) != "percent" },
                                      set: { memoryStyle = $0 ? "both" : "percent" }))
                .onAppear {
                    memoryStyle = Defaults.sanitizedMenuBarMemoryStyle(memoryStyle)
                }
        }
    }
}

private struct DiskUsageMenuBarOrderOption: View {
    @ObservedObject private var l10n = L10n.shared
    @AppStorage(DefaultsKey.menuBarDiskUsage) private var menuBarDiskUsage = false
    @AppStorage(DefaultsKey.menuBarDiskUsageStyle) private var diskUsageStyle = "percent"

    var body: some View {
        if menuBarDiskUsage {
            MetricRowOptionToggle(label: l10n.s.monitorDiskUsageShowFree,
                                  isOn: Binding(
                                      get: { Defaults.sanitizedMenuBarDiskUsageStyle(diskUsageStyle) == "free" },
                                      set: { diskUsageStyle = $0 ? "free" : "percent" }))
                .onAppear {
                    diskUsageStyle = Defaults.sanitizedMenuBarDiskUsageStyle(diskUsageStyle)
                }
        }
    }
}

private struct NetworkMenuBarOrderOption: View {
    @ObservedObject private var l10n = L10n.shared
    @AppStorage(DefaultsKey.menuBarNetwork) private var menuBarNetwork = false
    @AppStorage(DefaultsKey.menuBarNetworkUploadFirst) private var uploadFirst = false

    var body: some View {
        if menuBarNetwork {
            MetricRowOptionToggle(label: l10n.s.monitorNetworkUploadFirst, isOn: $uploadFirst)
        }
    }
}

private struct MenuBarMetricVisibilityToggle: View {
    @ObservedObject private var l10n = L10n.shared
    let metric: MenuBarMetric
    @AppStorage private var shown: Bool

    init(metric: MenuBarMetric) {
        self.metric = metric
        _shown = AppStorage(wrappedValue: false, metric.defaultsKey)
    }

    var body: some View {
        Button {
            shown.toggle()
        } label: {
            Image(systemName: shown ? "eye.fill" : "eye.slash.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(shown ? Color.accentColor : Color.secondary)
                .frame(width: 30, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(shown ? l10n.s.panelHideItem : l10n.s.panelShowItem)
        .accessibilityLabel(shown ? l10n.s.panelHideItem : l10n.s.panelShowItem)
        .accessibilityValue(metric.title(l10n.s))
    }
}

private struct MenuBarMetricOrderDropDelegate: DropDelegate {
    let target: MenuBarMetric
    @Binding var order: [MenuBarMetric]
    @Binding var dragging: MenuBarMetric?

    func dropEntered(info: DropInfo) {
        guard let dragging,
              dragging != target,
              let from = order.firstIndex(of: dragging),
              let to = order.firstIndex(of: target) else { return }

        withAnimation(.easeInOut(duration: 0.12)) {
            order.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
        MenuBarMetric.setOrder(order)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        MenuBarMetric.setOrder(order)
        return true
    }
}

/// Drag-to-reorder and show/hide list for the panel's major sections. Writes the
/// order to `PanelLayout` and each section's visibility to its own key, both of
/// which the live panel observes. A bounded, non-scrolling list so it sits inside
/// the grouped Form without its own scroll area.
private struct PanelOrderEditor: View {
    @ObservedObject private var l10n = L10n.shared
    @AppStorage(DefaultsKey.monitorShowFanControlBeta) private var showFanControlBeta = false
    @State private var order: [PanelSectionID] = PanelLayout.order
    @State private var dragging: PanelSectionID?
    /// Bumped whenever a section is shown/hidden so the dimmed titles and the
    /// "can't hide the last one" guard recompute.
    @State private var visibilityChanges = 0

    var body: some View {
        VStack(spacing: 0) {
            ForEach(editableOrder) { id in
                panelOrderRow(id)
            }
        }
        .padding(.vertical, 2)
        .onAppear { order = PanelLayout.order }
        .onChange(of: showFanControlBeta) { _ in order = PanelLayout.order }
    }

    @ViewBuilder
    private func panelOrderRow(_ id: PanelSectionID) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 12))
                        .tertiaryForegroundStyle()
                    Text(id.title(l10n.s))
                        .foregroundStyle(isShown(id) ? .primary : .secondary)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .opacity(dragging == id ? 0.45 : 1)
                .onDrag {
                    dragging = id
                    return NSItemProvider(object: id.rawValue as NSString)
                }
                .onDrop(of: [UTType.text],
                        delegate: PanelOrderDropDelegate(target: id,
                                                         order: $order,
                                                         dragging: $dragging))

                if id != .fanControl {
                    SectionVisibilityEye(id: id,
                                         canHide: visibleCount > 1,
                                         onChange: { visibilityChanges += 1 })
                }
            }
            .frame(height: 32)

            if id != editableOrder.last {
                Divider()
            }
        }
    }

    private var editableOrder: [PanelSectionID] {
        order.filter { $0 != .fanControl || showFanControlBeta }
    }

    private func isShown(_ id: PanelSectionID) -> Bool {
        _ = visibilityChanges
        return PanelLayout.isShown(id)
    }

    /// How many sections are currently visible in the panel, so the last one
    /// can't be hidden (which would leave an empty panel).
    private var visibleCount: Int {
        _ = visibilityChanges
        return editableOrder.reduce(0) { $0 + (PanelLayout.isShown($1) ? 1 : 0) }
    }
}

/// An eye button that shows/hides one panel section, backed by that section's
/// own visibility key so the live panel updates immediately.
private struct SectionVisibilityEye: View {
    @ObservedObject private var l10n = L10n.shared
    let id: PanelSectionID
    let canHide: Bool
    let onChange: () -> Void
    @AppStorage private var shown: Bool

    init(id: PanelSectionID, canHide: Bool, onChange: @escaping () -> Void) {
        self.id = id
        self.canHide = canHide
        self.onChange = onChange
        _shown = AppStorage(wrappedValue: id.shownByDefault, id.visibilityKey)
    }

    var body: some View {
        Button {
            shown.toggle()
            onChange()
        } label: {
            Image(systemName: shown ? "eye.fill" : "eye.slash.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(shown ? Color.accentColor : Color.secondary)
                .frame(width: 30, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // Keep at least one section visible.
        .disabled(shown && !canHide)
        .help(shown ? l10n.s.panelHideItem : l10n.s.panelShowItem)
    }
}

private struct PanelOrderDropDelegate: DropDelegate {
    let target: PanelSectionID
    @Binding var order: [PanelSectionID]
    @Binding var dragging: PanelSectionID?

    func dropEntered(info: DropInfo) {
        guard let dragging,
              dragging != target,
              let from = order.firstIndex(of: dragging),
              let to = order.firstIndex(of: target) else { return }

        withAnimation(.easeInOut(duration: 0.12)) {
            order.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
        PanelLayout.setOrder(order)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        PanelLayout.setOrder(order)
        return true
    }
}
