//
//  TaskDetFields.swift
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

public struct TaskDetFields: View {
    @EnvironmentObject private var router: TroutRouter

    // MARK: - Parameters

    @ObservedObject private var task: MTask

    public init(task: MTask) {
        self.task = task
    }

    // MARK: - Locals

    // MARK: - Views

    public var body: some View {
        Section {
            Button(action: fieldListAction) {
                HStack {
                    Text("Fields")
                    Spacer()
                    Text(fieldCount > 0 ? String(format: "%d", fieldCount) : "none")
                    #if os(watchOS)
                        // .foregroundStyle(fieldColorDarkBg)
                    #endif
                }
            }
        } footer: {
            Text("The fields available for this task.")
        }
    }

    // MARK: - Properties

    private var fieldCount: Int {
        task.fields?.count ?? 0
    }

    // MARK: - Actions

    private func fieldListAction() {
        router.path.append(TroutRoute.fieldList(task.uriRepresentation))
    }
}

struct TaskDetFields_Previews: PreviewProvider {
    struct TestHolder: View {
        var task: MTask
        var body: some View {
            Form {
                TaskDetFields(task: task)
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let routine = MRoutine.create(ctx, userOrder: 0)
        let task = MTask.create(ctx, routine: routine, userOrder: 0)
        task.name = "Beverage"
        _ = MFieldBool.create(ctx, task: task, name: "Stout", userOrder: 0, clearOnRun: true, value: true)
        return TestHolder(task: task)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
            .accentColor(.orange)
    }
}
