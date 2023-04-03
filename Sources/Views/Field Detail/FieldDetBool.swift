//
//  FieldDetBool.swift
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

import TrackerUI
import TroutLib

struct FieldDetBool: View {
    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - Parameters

    @ObservedObject var field: MFieldBool

    // MARK: - Locals

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: FieldDetBool.self))

    // MARK: - Views

    var body: some View {
        Form {
            FieldDetName(field: field,
                         tint: fieldColor)
            Section {
                Toggle(isOn: $field.value) {
                    Text("Value")
                }
            }

            Section {
                Toggle(isOn: $field.clearOnRun) {
                    Text("Clear on run?")
                }
            }
        }
        .accentColor(fieldColor)
        .symbolRenderingMode(.hierarchical)
        .onDisappear(perform: onDisappearAction)
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

struct FieldDetBool_Previews: PreviewProvider {
    struct TestHolder: View {
        var field: MFieldBool
        var body: some View {
            FieldDetBool(field: field)
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let routine = MRoutine.create(ctx, userOrder: 0)
        let task = MTask.create(ctx, routine: routine, userOrder: 0)
        task.name = "Beverage"
        let field = MFieldBool.create(ctx, task: task, name: "Stout", userOrder: 0, clearOnRun: true, value: true)
        return TestHolder(field: field)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
            .accentColor(.orange)
    }
}
