//
//  RoutineDetTasks.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import TrackerUI
import TroutLib

public struct RoutineDetTasks: View {
    @EnvironmentObject private var router: TroutRouter

    // MARK: - Parameters

    @ObservedObject private var routine: MRoutine

    public init(routine: MRoutine) {
        self.routine = routine
    }

    // MARK: - Locals

    // MARK: - Views

    public var body: some View {
        Section {
            Button(action: taskListAction) {
                HStack {
                    Text("Tasks")
                    Spacer()
                    Text(taskCount > 0 ? String(format: "%d", taskCount) : "none")
                    #if os(watchOS)
                        .foregroundStyle(taskColorDarkBg)
                    #endif
                }
            }
        } footer: {
            Text("The tasks available for this routine.")
        }
    }

    // MARK: - Properties

    private var taskCount: Int {
        routine.tasks?.count ?? 0
    }

    // MARK: - Actions

    private func taskListAction() {
        router.path.append(TroutRoute.taskList(routine.uriRepresentation))
    }
}

struct RoutineDetTasks_Previews: PreviewProvider {
    struct TestHolder: View {
        var routine: MRoutine
        var body: some View {
            Form {
                RoutineDetTasks(routine: routine)
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let routine = MRoutine.create(ctx, userOrder: 0)
        routine.name = "Beverage"
        let task = MTask.create(ctx, routine: routine, userOrder: 0)
        task.routine = routine
        task.name = "Stout"
        return TestHolder(routine: routine)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
            .accentColor(.orange)
    }
}
