//
//  RoutineDetTaskGroups.swift
//
// Copyright 2022, 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import TrackerUI
import TroutLib

public struct RoutineDetTaskGroups: View {
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
            Button(action: taskGroupListAction) {
                HStack {
                    Text("Task Groups")
                    Spacer()
                    Text(taskGroupCount > 0 ? String(format: "%d", taskGroupCount) : "none")
                    #if os(watchOS)
                        .foregroundStyle(taskGroupColorDarkBg)
                    #endif
                }
            }
        } footer: {
            Text("The task group presets available for this routine. (If ‘none’, all will be available.)")
        }
    }

    // MARK: - Properties

    private var taskGroupCount: Int {
        routine.taskGroups?.count ?? 0
    }

    // MARK: - Actions

    private func taskGroupListAction() {
        router.path.append(TroutRoute.taskGroupList(routine.uriRepresentation))
    }
}

struct RoutineDetTaskGroups_Previews: PreviewProvider {
    struct TestHolder: View {
        var routine: MRoutine
        var body: some View {
            Form {
                RoutineDetTaskGroups(routine: routine)
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let routine = MRoutine.create(ctx, userOrder: 0)
        routine.name = "Beverage"
        let serving = MTask.create(ctx, routine: routine, userOrder: 0)
        serving.name = "Stout"
        // serving.calories = 323
        return TestHolder(routine: routine)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
            .accentColor(.orange)
    }
}
