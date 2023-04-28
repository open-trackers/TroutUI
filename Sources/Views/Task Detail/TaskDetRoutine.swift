//
//  TaskDetRoutine.swift
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

struct TaskDetRoutine: View {
    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - Parameters

    @ObservedObject private var routine: MRoutine
    private var onSelect: (UUID?) -> Void

    init(routine: MRoutine,
         onSelect: @escaping (UUID?) -> Void)
    {
        self.routine = routine
        self.onSelect = onSelect
        let sort = MRoutine.byName()
        _routines = FetchRequest<MRoutine>(entity: MRoutine.entity(),
                                           sortDescriptors: sort)
        _selected = State(initialValue: routine.archiveID)
    }

    // MARK: - Locals

    @FetchRequest private var routines: FetchedResults<MRoutine>

    @State private var selected: UUID?

//    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
//                                category: String(describing: ExDetMRoutine.self))

    // MARK: - Views

    var body: some View {
        platformView
            .onChange(of: selected) { nuArchiveID in
                onSelect(nuArchiveID)
            }
    }

    #if os(watchOS)
        private var platformView: some View {
            Picker("Routine", selection: $selected) {
                ForEach(routines) { element in
                    Text(element.wrappedName)
                        .tag(element.archiveID)
                }
            }
        }
    #endif

    #if os(iOS)
        private var platformView: some View {
            Section("Routine") {
                Picker("", selection: $selected) {
                    ForEach(routines) { element in
                        HStack {
                            Text(element.wrappedName)
                            Spacer()
                        }
                        .tag(element.archiveID)
                    }
                }
                .pickerStyle(.navigationLink)
            }
        }
    #endif
}

struct TaskDetRoutine_Previews: PreviewProvider {
    struct TestHolder: View {
        @ObservedObject var routine: MRoutine
        var body: some View {
            TaskDetRoutine(routine: routine, onSelect: { _ in })
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let routine1 = MRoutine.create(ctx, userOrder: 0)
        routine1.name = "Beverage"
        let routine2 = MRoutine.create(ctx, userOrder: 1)
        routine2.name = "Meat"
        try? ctx.save()
        return Form { TestHolder(routine: routine2) }
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
            .accentColor(.orange)
    }
}
