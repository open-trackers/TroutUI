//
//  AddFieldButton.swift
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

public struct AddFieldButton: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: TroutRouter

    // MARK: - Parameters

    private var task: MTask

    public init(task: MTask) {
        self.task = task
    }

    // MARK: - Locals

    @State private var showAlert = false

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: AddFieldButton.self))

    // MARK: - Views

    public var body: some View {
        Button(action: { showAlert = true }) {
            #if os(watchOS)
                Label("Add Field", systemImage: "plus.circle")
            #elseif os(iOS)
                Text("Add Field")
            #endif
        }
        // NOTE: using an alert, as confirmationDialog may be clipped at top of view on iPad
        // .confirmationDialog(
        .alert("Add Field", isPresented: $showAlert) {
            Button(action: createBoolAction) {
                Text("Boolean (yes/no)")
            }
            Button(action: createInt16Action) {
                Text("Integer (short)")
            }
            Button(role: .cancel) {
                // do nothing (stop is ignored)
            } label: {
                Text("Cancel")
            }
        }
    }

    // MARK: - Properties

    private var maxOrder: Int16 {
        do {
            return try MField.maxUserOrder(viewContext, task: task) ?? 0
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
        return 0
    }

    // MARK: - Actions

    private func createBoolAction() {
        let nu = MFieldBool.create(viewContext, task: task, name: "New Boolean Field", userOrder: maxOrder + 1, clearOnRun: true, value: false)
        do {
            try viewContext.save()
            router.path.append(.boolFieldDetail(nu.uriRepresentation))
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }

    private func createInt16Action() {
        let nu = MFieldInt16.create(viewContext, task: task, name: "New Short Integer Field", userOrder: maxOrder + 1, clearOnRun: false, value: 0, upperBound: Int16.max, stepValue: 1)
        do {
            try viewContext.save()
            router.path.append(.int16FieldDetail(nu.uriRepresentation))
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }
}

struct AddMFieldButton_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let routine = MRoutine.create(ctx, userOrder: 2)
        let task = MTask.create(ctx, routine: routine, userOrder: 0)
        task.name = "Back & Bicep"
        return AddFieldButton(task: task)
    }
}
