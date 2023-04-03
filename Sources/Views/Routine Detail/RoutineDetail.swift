//
//  RoutineDetail.swift
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

public struct RoutineDetail: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: TroutRouter

    // MARK: - Parameters

    @ObservedObject private var routine: MRoutine

    public init(routine: MRoutine) {
        self.routine = routine

        _color = State(initialValue: routine.getColor() ?? .clear)
    }

    // MARK: - Locals

    // Using .clear as a local non-optional proxy for nil, because picker won't
    // work with optional.
    // When saved, the color .clear assigned is nil.
    @State private var color: Color

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: RoutineDetail.self))

    #if os(watchOS)
        // NOTE: no longer saving the tab in scene storage, because it has been
        // annoying to not start out at the first tab when navigating to detail.
        // @SceneStorage("routine-detail-tab") private var selectedTab: Int = 0
        @State private var selectedTab: Tab = .name

        enum Tab: Int, CaseIterable {
            case name = 1
            case colorImage = 2
            case taskGroups = 3
            case template = 4
            case tasks = 5
        }
    #endif

    // MARK: - Views

    public var body: some View {
        platformView
            .symbolRenderingMode(.hierarchical)
            .onDisappear(perform: onDisappearAction)
    }

    #if os(watchOS)
        private var platformView: some View {
            ControlBarTabView(selection: $selectedTab, tint: routineColor, title: title) {
                Form {
                    RoutineDetName(routine: routine)
                }
                .tag(Tab.name)
                Form {
                    FormColorPicker(color: $color)
                    RoutineDetImage(routine: routine, forceFocus: true)
                }
                .tag(Tab.colorImage)

                Form {
                    RoutineDetTaskGroups(routine: routine)
                }
                .tag(Tab.taskGroups)

                Form {
                    RoutineDetTemplate(routine: routine)
                }
                .tag(Tab.template)

                FakeSection(title: "Tasks") {
                    TaskList(routine: routine)
                }
                .tag(Tab.tasks)
            }
        }
    #endif

    #if os(iOS)
        private var platformView: some View {
            Form {
                RoutineDetName(routine: routine)
                FormColorPicker(color: $color)
                RoutineDetImage(routine: routine, forceFocus: false)
                RoutineDetTasks(routine: routine)
                RoutineDetTaskGroups(routine: routine)
                RoutineDetTemplate(routine: routine)
            }
            .navigationTitle(title)
        }
    #endif

    // MARK: - Properties

    private var title: String {
        "Routine"
    }

    #if os(iOS)
        private var taskCount: Int {
            routine.tasks?.count ?? 0
        }
    #endif

    // MARK: - Actions

    private func onDisappearAction() {
        do {
            routine.setColor(color != .clear ? color : nil)
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }
}

struct RoutineDetail_Previews: PreviewProvider {
    struct TestHolder: View {
        var routine: MRoutine
        var body: some View {
            NavigationStack {
                RoutineDetail(routine: routine)
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
        return TestHolder(routine: routine)
            .environment(\.managedObjectContext, ctx)
            .accentColor(.orange)
    }
}
