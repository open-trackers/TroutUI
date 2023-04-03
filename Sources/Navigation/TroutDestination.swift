//
//  TroutDestination.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import TrackerLib
import TrackerUI
import TroutLib

// obtain the view for the specified route
public struct TroutDestination: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: TroutRouter

    private var route: TroutRoute

    public init(_ route: TroutRoute) {
        self.route = route
    }

    // @AppStorage(storageKeyQuickLogRecents) private var quickLogRecents: QuickLogRecentsDict = .init()

    public var body: some View {
        switch route {
        case .settings:
            // NOTE: that this is only being used for watch settings
            if let appSetting = try? AppSetting.getOrCreate(viewContext) {
                TroutSettings(appSetting: appSetting, onRestoreToDefaults: {})
            } else {
                Text("Settings not available.")
            }
        case .about:
            aboutView
        case let .routineDetail(routineURI):
            if let routine: MRoutine = MRoutine.get(viewContext, forURIRepresentation: routineURI) {
                RoutineDetail(routine: routine)
                    .environmentObject(router)
                    .environment(\.managedObjectContext, viewContext)
            } else {
                Text("Routine not available to display detail.")
            }
        case let .taskList(routineURI):
            if let routine: MRoutine = MRoutine.get(viewContext, forURIRepresentation: routineURI) {
                TaskList(routine: routine)
                    .environmentObject(router)
                    .environment(\.managedObjectContext, viewContext)
            } else {
                Text("Routine not available to display task list.")
            }
        case let .taskGroupList(routineURI):
            if let routine: MRoutine = MRoutine.get(viewContext, forURIRepresentation: routineURI) {
                TaskGroupList(routine: routine)
                    .environmentObject(router)
                    .environment(\.managedObjectContext, viewContext)
            } else {
                Text("Routine not available to display preset list.")
            }
        case let .taskDetail(taskURI):
            if let task: MTask = MTask.get(viewContext, forURIRepresentation: taskURI) {
                MTaskDetail(task: task)
                    .environmentObject(router)
                    .environment(\.managedObjectContext, viewContext)
            } else {
                Text("Task not available to display detail.")
            }
        case let .fieldList(taskURI):
            if let task: MTask = MTask.get(viewContext, forURIRepresentation: taskURI) {
                FieldList(task: task)
                    .environmentObject(router)
                    .environment(\.managedObjectContext, viewContext)
            } else {
                Text("Task not available to display field list.")
            }
        case let .boolFieldDetail(fieldURI):
            if let field: MFieldBool = MFieldBool.get(viewContext, forURIRepresentation: fieldURI) {
                FieldDetBool(field: field)
                    .environmentObject(router)
                    .environment(\.managedObjectContext, viewContext)
            } else {
                Text("Field not available to display detail.")
            }
        case let .int16FieldDetail(fieldURI):
            if let field: MFieldInt16 = MFieldInt16.get(viewContext, forURIRepresentation: fieldURI) {
                FieldDetInt16(field: field)
                    .environmentObject(router)
                    .environment(\.managedObjectContext, viewContext)
            } else {
                Text("Field not available to display detail.")
            }
        default:
            // routes defined by platform-specific projects should have been handled earlier
            EmptyView()
        }
    }

    private var aboutView: some View {
        AboutView(shortAppName: shortAppName,
                  websiteURL: websiteAppURL,
                  privacyURL: websitePrivacyURL,
                  termsURL: websiteTermsURL,
                  tutorialURL: websiteAppTutorialURL,
                  copyright: copyright,
                  plea: websitePlea)
        {
            AppIcon(name: "app_icon")
        }
    }
}
