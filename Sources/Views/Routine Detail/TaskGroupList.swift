//
//  TaskGroupList.swift
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

public struct TaskGroupList: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: TroutRouter

    // MARK: - Parameters

    private var routine: MRoutine

    public init(routine: MRoutine) {
        self.routine = routine

        let sort = MTaskGroup.byUserOrder()
        let pred = MTaskGroup.getPredicate(routine: routine)
        _routinePresets = FetchRequest<MTaskGroup>(entity: MTaskGroup.entity(),
                                                   sortDescriptors: sort,
                                                   predicate: pred)
    }

    // MARK: - Locals

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: TaskGroupList.self))

    @FetchRequest private var routinePresets: FetchedResults<MTaskGroup>

    @State private var taskGroupSelection: TaskGroup?
    @State private var showPicker = false

    // MARK: - Views

    public var body: some View {
        List {
            ForEach(routinePresets, id: \.self) { preset in
                if case let groupRaw = preset.groupRaw,
                   let taskGroup = TaskGroup(rawValue: groupRaw)
                {
                    Text("\(taskGroup.description)")
                    #if os(watchOS)
                        .listItemTint(taskGroupListItemTint)
                    #elseif os(iOS)
                        .listRowBackground(taskGroupListItemTint)
                    #endif
                }
            }
            .onMove(perform: moveAction)
            .onDelete(perform: deleteAction)

            #if os(watchOS)
                addPresetButton {
                    Label("Add Task Group", systemImage: "plus.circle")
                        .symbolRenderingMode(.hierarchical)
                }
                .accentColor(taskGroupColorDarkBg)
                .symbolRenderingMode(.hierarchical)
            #endif
        }
        #if os(watchOS)
        .navigationTitle {
            Text(title)
                .foregroundStyle(taskGroupColorDarkBg)
        }
        #elseif os(iOS)
        .navigationTitle(title)
        .toolbar {
            ToolbarItem {
                addPresetButton {
                    Text("Add Task Group")
                }
            }
        }
        #endif
        .sheet(isPresented: $showPicker) {
            NavigationStack {
                TaskGroupPicker(taskGroups: unselectedCases,
                                showPresets: $showPicker,
                                onSelect: addPresetAction)
            }
            .interactiveDismissDisabled() // NOTE: needed to prevent home button from dismissing sheet
        }
    }

    private func addPresetButton(content: () -> some View) -> some View {
        Button(action: { showPicker = true }) {
            content()
        }
        .disabled(unselectedCases.count == 0)
    }

    // MARK: - Properties

    private var title: String {
        "Task Groups"
    }

    private var unselectedCases: [TaskGroup] {
        let selectedCases = routinePresets.reduce(into: []) { $0.append($1.groupRaw) }
        return TaskGroup.allCases.filter { !selectedCases.contains($0.rawValue) }
    }

    private var maxOrder: Int16 {
        routinePresets.last?.userOrder ?? 0
    }

    // MARK: - Actions

    private func addPresetAction(preset: TaskGroup) {
        do {
            _ = MTaskGroup.create(viewContext, routine: routine, userOrder: maxOrder + 1, groupRaw: preset.rawValue)
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }

    private func deleteAction(offsets: IndexSet) {
        offsets.map { routinePresets[$0] }.forEach(viewContext.delete)
        do {
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }

    private func moveAction(from source: IndexSet, to destination: Int) {
        MTaskGroup.move(routinePresets, from: source, to: destination)
        do {
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }
}

struct TaskGroupList_Previews: PreviewProvider {
    struct TestHolder: View {
        var routine: MRoutine
        @State var navData: Data?
        var body: some View {
            TroutNavStack(navData: $navData) {
                TaskGroupList(routine: routine)
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let routine = MRoutine.create(ctx, userOrder: 0)
        routine.name = "Beverage"
        _ = MTaskGroup.create(ctx, routine: routine, userOrder: 0, groupRaw: TaskGroup.coldWeatherTravel.rawValue)
        _ = MTaskGroup.create(ctx, routine: routine, userOrder: 1, groupRaw: TaskGroup.warmWeatherTravel.rawValue)
        return TestHolder(routine: routine)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
            .accentColor(.orange)
    }
}
