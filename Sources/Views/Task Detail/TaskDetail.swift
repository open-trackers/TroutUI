//
//  MTaskDetail.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import os
import SwiftUI

import TrackerUI
import TroutLib

public struct MTaskDetail: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: TroutRouter

    // MARK: - Parameters

    @ObservedObject private var task: MTask

    public init(task: MTask) {
        self.task = task
    }

    // MARK: - Locals

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: MTaskDetail.self))

    #if os(watchOS)
        // NOTE: no longer saving the tab in scene storage, because it has been
        // annoying to not start out at the first tab when navigating to detail.
        // @SceneStorage("task-detail-tab") private var selectedTab = 0
        @State private var selectedTab: Tab = .name

        enum Tab: Int, CaseIterable {
            case name = 1
            case fields = 2
//            case primary = 2
//            case secondary = 3
//            case sets = 4
//            case reps = 5
//            case intensity = 6
//            case intensityStep = 7
//            case intensityUnit = 8
//            case intensityInvert = 9
        }
    #endif

    // MARK: - Views

    public var body: some View {
        platformView
            .accentColor(taskColor)
            .symbolRenderingMode(.hierarchical)
            .onDisappear(perform: onDisappearAction)
    }

    #if os(watchOS)

        private var platformView: some View {
            ControlBarTabView(selection: $selectedTab, tint: taskColor, title: title) {
                Form {
                    TaskDetName(task: task,
                                tint: taskColor)
                }
                .tag(Tab.name)

                FakeSection(title: "Fields") {
                    FieldList(task: task)
                }
                .tag(Tab.fields)
            }
        }

    #endif

    #if os(iOS)
        private var platformView: some View {
            Form {
                TaskDetName(task: task,
                            tint: taskColor)

                TaskDetFields(task: task)
            }
            .navigationTitle(title)
        }
    #endif

    // MARK: - Properties

    private var taskColor: Color {
        colorScheme == .light ? taskColorLiteBg : taskColorDarkBg
    }

    private var title: String {
        "Task"
    }

    // MARK: - Actions

    private func onDisappearAction() {
        do {
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }
}

struct MTaskDetail_Previews: PreviewProvider {
    struct TestHolder: View {
        var task: MTask
        var body: some View {
            NavigationStack {
                MTaskDetail(task: task)
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let routine = MRoutine.create(ctx, userOrder: 0)
        routine.name = "Back & Bicep"
        let task = MTask.create(ctx, routine: routine, userOrder: 0)
        task.name = "Lat Pulldown"
        task.routine = routine
        return TestHolder(task: task)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
            .accentColor(.orange)
    }
}
