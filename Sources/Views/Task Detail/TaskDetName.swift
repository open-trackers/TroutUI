//
//  TaskDetName.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import os
import SwiftUI

import TextFieldPreset

import TrackerUI
import TroutLib

struct TaskDetName: View {
    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - Parameters

    @ObservedObject var task: MTask
    let tint: Color

    // MARK: - Locals

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: TaskDetName.self))

    // MARK: - Views

    var body: some View {
        Section {
            TextFieldPreset($task.wrappedName,
                            prompt: "Enter task name",
                            axis: .vertical,
                            presets: filteredPresets,
                            pickerLabel: { Text($0.description) },
                            onSelect: selectAction)
            #if os(watchOS)
                .padding(.bottom)
            #endif
                .tint(tint)

            // KLUDGE: unable to get textfield to display multiple lines, so conditionally
            //         including full text as a courtesy.
            #if os(watchOS)
                if task.wrappedName.count > 20 {
                    Text(task.wrappedName)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            #endif
        } header: {
            Text("Name")
        }
        #if os(iOS)
        .font(.title3)
        #endif
    }

    // MARK: - Properties

    private var filteredPresets: TaskPresetDict {
        task.routine?.filteredPresets ?? taskPresets
    }

    // MARK: - Actions

    // clear any assigned MFields, and assign the MFields(s) to the MTask
    private func selectAction(_ preset: TaskPreset) {
        do {
            try task.populate(viewContext, from: preset)
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }
}

struct TaskDetName_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let routine = MRoutine.create(ctx, userOrder: 0)
        routine.name = "Beverage"
        @ObservedObject var task = MTask.create(ctx, routine: routine, userOrder: 0)
        task.name = "Lat Pulldown"
        return Form { TaskDetName(task: task, tint: .orange) }
    }
}
