//
//  TroutSettings.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData
import os
import SwiftUI

import TrackerLib
import TrackerUI

import TroutLib

public struct TroutSettings<Content>: View
    where Content: View
{
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack
    @EnvironmentObject private var router: TroutRouter

    // MARK: - Parameters

    @ObservedObject private var appSetting: AppSetting
    private let onRestoreToDefaults: () -> Void
    private var content: () -> Content

    public init(appSetting: AppSetting,
                onRestoreToDefaults: @escaping () -> Void = {},
                @ViewBuilder content: @escaping () -> Content = { EmptyView() })
    {
        self.appSetting = appSetting
        self.onRestoreToDefaults = onRestoreToDefaults
        self.content = content
    }

    // MARK: - Locals

    @AppStorage(logToHistoryKey) var logToHistory: Bool = true

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: TroutSettings<Content>.self))

    // MARK: - Views

    public var body: some View {
        BaseSettingsForm(onRestoreToDefaults: resetToDefaultsAction) {
            Section {
                Toggle("Log activity", isOn: $logToHistory)
                    .tint(.accentColor)
            } header: {
                Text("\(Image(systemName: "fossil.shell.fill")) History")
            } footer: {
                #if os(watchOS)
                    Text("Recent history will be stored locally for up to 1 year. Periodically run iPhone/iPad app for long-term storage and review.")
                #elseif os(iOS)
                    Text("History can be reviewed from the home screen.")
                #endif
            }

            PresetsUnitsModePicker(unitsMode: $appSetting.presetUnitsModeEnum)

            // additional platform-specific settings content, if any
            content()
        }
    }

    private var taskColor: Color {
        colorScheme == .light ? taskColorLiteBg : taskColorDarkBg
    }

    private func taskDefaultsAction() {
        router.path.append(TroutRoute.taskDefaults)
    }

    private func resetToDefaultsAction() {
//        alwaysAdvanceOnLongPress = false
        logToHistory = true

        do {
            appSetting.presetUnitsModeEnum = .all
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }

        onRestoreToDefaults() // continue up the chain
    }
}

struct TroutSettings_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let appSet = AppSetting(context: manager.container.viewContext)
        // appSet.startOfDayEnum = StartOfDay.defaultValue
        return NavigationStack { TroutSettings(appSetting: appSet,
                                               onRestoreToDefaults: {}) { EmptyView() }
                .environment(\.managedObjectContext, manager.container.viewContext)
                .environmentObject(manager)
                .accentColor(.orange)
        }
    }
}
