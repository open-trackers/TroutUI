//
//  RoutineDetName.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import TextFieldPreset

import TrackerUI
import TroutLib

public struct RoutineDetName: View {
    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - Parameters

    @ObservedObject private var routine: MRoutine

    public init(routine: MRoutine) {
        self.routine = routine
    }

    // MARK: - Views

    public var body: some View {
        Section {
            TextFieldPreset($routine.wrappedName,
                            prompt: "Enter routine name",
                            axis: .vertical,
                            presets: routinePresets,
                            pickerLabel: { Text($0.description).foregroundStyle(.tint) },
                            onSelect: selectAction)
            #if os(watchOS)
                .padding(.bottom)
            #endif
            #if os(iOS)
            .font(.title3)
            #endif
            .textInputAutocapitalization(.words)

            // KLUDGE: unable to get textfield to display multiple lines, so conditionally
            //         including full text as a courtesy.
            #if os(watchOS)
                if routine.wrappedName.count > 20 {
                    Text(routine.wrappedName)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            #endif
        } header: {
            Text("Name")
        }
    }

    // MARK: - Actions

    // clear any assigned MTaskGroups, and assign the MTaskGroup(s) to the MRoutine
    private func selectAction(_ routinePreset: RoutinePreset) {
        do {
            routine.taskGroupsArray.forEach {
                routine.removeFromTaskGroups($0)
                viewContext.delete($0)
            }
            var userOrder: Int16 = 0
            routinePreset.taskGroups.forEach {
                _ = MTaskGroup.create(viewContext, routine: routine, userOrder: userOrder, groupRaw: $0.rawValue)
                userOrder += 1
            }
            try viewContext.save()
        } catch {
            // logger.error("\(#function): \(error.localizedDescription)")
        }
    }
}

struct RoutineDetName_Previews: PreviewProvider {
    struct TestHolder: View {
        var routine: MRoutine
        var body: some View {
            Form {
                RoutineDetName(routine: routine)
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let routine = MRoutine.create(ctx, userOrder: 0)
        routine.name = "Beverage and this and that and many other things"
        return TestHolder(routine: routine)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
            .accentColor(.orange)
    }
}
