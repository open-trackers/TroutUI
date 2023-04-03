//
//  RoutineDetTemplate.swift
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

struct RoutineDetTemplate: View {
    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - Parameters

    @ObservedObject var routine: MRoutine

    // MARK: - Views

    public var body: some View {
        Section {
            Toggle(isOn: $routine.isTemplate) {
                Label("Template", systemImage: "t.square")
            }
            .onChange(of: routine.isTemplate, perform: changeAction)
            .disabled(routine.pausedAt != nil)
        } footer: {
            Text("A routine template will be cloned to a non-template prior to being run. Use if you're running multiple instances of a routine concurrently.")
        }
    }

    // MARK: - Actions

    private func changeAction(_: Bool) {
        // NOTE: clear the state, as the routine is changing roles
        try? routine.clearState(viewContext)
    }
}

struct RoutineDetTemplate_Previews: PreviewProvider {
    struct TestHolder: View {
        var routine: MRoutine
        var body: some View {
            Form {
                RoutineDetTemplate(routine: routine)
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let routine = MRoutine.create(ctx, userOrder: 0)
        routine.name = "Beverage"
        return TestHolder(routine: routine)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
            .accentColor(.orange)
    }
}
