//
//  AddTaskButton.swift
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

import TextFieldPreset

import TrackerUI
import TroutLib

public struct AddTaskButton: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: TroutRouter

    // MARK: - Parameters

    private var routine: MRoutine

    public init(routine: MRoutine) {
        self.routine = routine
    }

    // MARK: - Locals

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: AddTaskButton.self))

    #if os(iOS)
        @State private var showBulkAdd = false
        @State private var selected = Set<TaskPreset>()
    #endif

    // MARK: - Views

    public var body: some View {
        AddElementButton(elementName: "Task",
                         onLongPress: longPressAction,
                         onCreate: createAction,
                         onAfterSave: afterSaveAction)
        #if os(iOS)
            .sheet(isPresented: $showBulkAdd) {
                NavigationStack {
                    BulkPresetsPicker(selected: $selected,
                                      presets: filteredPresets,
                                      label: { Text($0.description) })
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel", action: cancelBulkAddAction)
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Add Tasks", action: bulkAddAction)
                                    .disabled(selected.count == 0)
                            }
                        }
                }
            }
        #endif
    }

    // MARK: - Properties

    private var filteredPresets: TaskPresetDict {
        routine.filteredPresets ?? taskPresets
    }

    private var maxOrder: Int16 {
        do {
            return try MTask.maxUserOrder(viewContext, routine: routine) ?? 0
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
        return 0
    }

    // MARK: - Actions

    #if os(iOS)
        private func cancelBulkAddAction() {
            showBulkAdd = false
        }
    #endif

    #if os(iOS)
        private func bulkAddAction() {
            do {
                // produce an ordered array of presets from the unordered set
                let presets = filteredPresets.flatMap(\.value).filter { selected.contains($0) }
                selected.removeAll()

                try MTask.bulkCreate(viewContext, routine: routine, presets: presets)
                try viewContext.save()
            } catch {
                logger.error("\(#function): \(error.localizedDescription)")
            }
            showBulkAdd = false
        }
    #endif

    private func longPressAction() {
        #if os(watchOS)
            Haptics.play(.warning)
        #elseif os(iOS)
            showBulkAdd = true
        #endif
    }

    private func createAction() -> MTask {
        MTask.create(viewContext,
                     routine: routine,
                     userOrder: maxOrder + 1)
    }

    private func afterSaveAction(_ nu: MTask) {
        router.path.append(TroutRoute.taskDetail(nu.uriRepresentation))
    }
}

struct AddTaskButton_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let routine = MRoutine.create(ctx, userOrder: 0)
        routine.name = "Back & Bicep"
        return AddTaskButton(routine: routine)
    }
}
