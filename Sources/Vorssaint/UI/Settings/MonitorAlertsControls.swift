// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI
import UserNotifications

struct MonitorAlertsControls: View {
    @ObservedObject private var l10n = L10n.shared
    let compact: Bool
    @State private var notificationsDenied = false
    @AppStorage(DefaultsKey.monitorAlertCPU) private var alertCPU = false
    @AppStorage(DefaultsKey.monitorAlertCPUTemperature) private var alertCPUTemperature = false
    @AppStorage(DefaultsKey.monitorAlertMemory) private var alertMemory = false
    @AppStorage(DefaultsKey.monitorAlertDisk) private var alertDisk = false
    @AppStorage(DefaultsKey.monitorAlertBattery) private var alertBattery = false
    @AppStorage(DefaultsKey.monitorAlertCPUThreshold) private var alertCPUThreshold = 90
    @AppStorage(DefaultsKey.monitorAlertCPUTemperatureThreshold) private var alertCPUTemperatureThreshold = 90
    @AppStorage(DefaultsKey.monitorAlertDiskFreePercent) private var alertDiskFreePercent = 10
    @AppStorage(DefaultsKey.monitorAlertBatteryPercent) private var alertBatteryPercent = 15
    @AppStorage(DefaultsKey.monitorAlertCooldownMinutes) private var alertCooldown = 15

    private var text: MonitorAlertFeatureStrings {
        FeatureStrings.monitorAlerts(l10n.language)
    }

    var body: some View {
        alertControlsContent
            .toggleStyle(.checkbox)
            .controlSize(compact ? .small : .regular)
            .font(compact ? .system(size: 10.5) : .body)
            .onAppear {
                sanitizeAlertValues()
                refreshNotificationStatus()
            }
            .onChange(of: alertCPU) { _ in syncAlerts() }
            .onChange(of: alertCPUTemperature) { _ in syncAlerts() }
            .onChange(of: alertMemory) { _ in syncAlerts() }
            .onChange(of: alertDisk) { _ in syncAlerts() }
            .onChange(of: alertBattery) { _ in syncAlerts() }
            .onChange(of: alertCPUThreshold) { _ in sanitizeAlertValues() }
            .onChange(of: alertCPUTemperatureThreshold) { _ in sanitizeAlertValues() }
            .onChange(of: alertDiskFreePercent) { _ in sanitizeAlertValues() }
            .onChange(of: alertBatteryPercent) { _ in sanitizeAlertValues() }
            .onChange(of: alertCooldown) { _ in sanitizeAlertValues() }
    }

    private var alertControlsContent: some View {
        VStack(alignment: .leading, spacing: compact ? 7 : 8) {
            cpuAlertControls
            cpuTemperatureAlertControls
            Toggle(text.memory, isOn: $alertMemory)
            diskAlertControls
            batteryAlertControls
            cooldownPicker
            Text(text.caption)
                .font(compact ? .system(size: 9.5) : .caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if notificationsDenied, anyAlertEnabled {
                Text(text.notificationsDenied)
                    .font(compact ? .system(size: 9.5) : .caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var cpuAlertControls: some View {
        Toggle(text.cpu, isOn: $alertCPU)
        if alertCPU {
            Stepper("\(text.cpuThreshold) \(alertCPUThreshold)%",
                    value: $alertCPUThreshold,
                    in: 50...100,
                    step: 5)
        }
    }

    @ViewBuilder
    private var cpuTemperatureAlertControls: some View {
        Toggle(text.cpuTemperature, isOn: $alertCPUTemperature)
        if alertCPUTemperature {
            Stepper("\(text.cpuTemperatureThreshold) \(alertCPUTemperatureThreshold) °C",
                    value: $alertCPUTemperatureThreshold,
                    in: 70...105,
                    step: 5)
        }
    }

    @ViewBuilder
    private var diskAlertControls: some View {
        Toggle(text.disk, isOn: $alertDisk)
        if alertDisk {
            Stepper("\(text.diskThreshold) \(alertDiskFreePercent)%",
                    value: $alertDiskFreePercent,
                    in: 5...30,
                    step: 5)
        }
    }

    @ViewBuilder
    private var batteryAlertControls: some View {
        Toggle(text.battery, isOn: $alertBattery)
        if alertBattery {
            Stepper("\(text.batteryThreshold) \(alertBatteryPercent)%",
                    value: $alertBatteryPercent,
                    in: 5...50,
                    step: 5)
        }
    }

    private var cooldownPicker: some View {
        Picker(text.cooldown, selection: $alertCooldown) {
            Text(text.cooldown2).tag(2)
            Text(text.cooldown5).tag(5)
            Text(text.cooldown15).tag(15)
            Text(text.cooldown30).tag(30)
            Text(text.cooldown60).tag(60)
        }
        .pickerStyle(.menu)
    }

    private func syncAlerts() {
        MonitorAlertService.shared.syncWithPreferences()
        refreshNotificationStatus()
    }

    private var anyAlertEnabled: Bool {
        alertCPU || alertCPUTemperature || alertMemory || alertDisk || alertBattery
    }

    /// Checked slightly delayed so a just-fired authorization prompt has a
    /// chance to be answered before the warning appears.
    private func refreshNotificationStatus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    notificationsDenied = settings.authorizationStatus == .denied
                }
            }
        }
    }

    private func sanitizeAlertValues() {
        alertCPUThreshold = Defaults.sanitizedPercent(alertCPUThreshold, fallback: 90, range: 50...100)
        alertCPUTemperatureThreshold = Defaults.sanitizedPercent(alertCPUTemperatureThreshold, fallback: 90, range: 70...105)
        alertDiskFreePercent = Defaults.sanitizedPercent(alertDiskFreePercent, fallback: 10, range: 5...30)
        alertBatteryPercent = Defaults.sanitizedPercent(alertBatteryPercent, fallback: 15, range: 5...50)
        alertCooldown = Defaults.sanitizedMonitorAlertCooldown(alertCooldown)
    }
}
