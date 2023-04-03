//
//  TaskList.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import os
import SwiftUI

import TrackerUI
import TroutLib

public struct TaskList: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: TroutRouter

    // MARK: - Parameters

    private var routine: MRoutine

    public init(routine: MRoutine) {
        self.routine = routine

        let sort = MTask.byUserOrder()
        let pred = MTask.getPredicate(routine: routine)
        _tasks = FetchRequest<MTask>(entity: MTask.entity(),
                                     sortDescriptors: sort,
                                     predicate: pred)
    }

    // MARK: - Locals

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: TaskList.self))

    @FetchRequest private var tasks: FetchedResults<MTask>

    // MARK: - Views

    public var body: some View {
        List {
            ForEach(tasks, id: \.self) { task in
                Button(action: { detailAction(task: task) }) {
                    Text("\(task.name ?? "unknown")")
                        .foregroundColor(taskColor)
                }
                #if os(watchOS)
                .listItemTint(taskListItemTint)
                #elseif os(iOS)
                .listRowBackground(taskListItemTint)
                #endif
            }
            .onMove(perform: moveAction)
            .onDelete(perform: deleteAction)

            #if os(watchOS)
                AddTaskButton(routine: routine)
                    .accentColor(taskColorDarkBg)
                    .symbolRenderingMode(.hierarchical)

            #endif
        }
        #if os(iOS)
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItem {
                AddTaskButton(routine: routine)
            }
        }
        #endif
    }

    // MARK: - Properties

    private var taskColor: Color {
        colorScheme == .light ? taskColorLiteBg : taskColorDarkBg
    }

    // MARK: - Actions

    private func detailAction(task: MTask) {
        logger.notice("\(#function)")
        Haptics.play()

        router.path.append(TroutRoute.taskDetail(task.uriRepresentation))
    }

    private func deleteAction(offsets: IndexSet) {
        logger.notice("\(#function)")
        offsets.map { tasks[$0] }.forEach(viewContext.delete)
        do {
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }

    private func moveAction(from source: IndexSet, to destination: Int) {
        logger.notice("\(#function)")
        MTask.move(tasks, from: source, to: destination)
        do {
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }
}

struct TaskList_Previews: PreviewProvider {
    struct TestHolder: View {
        var routine: MRoutine
        @State var navData: Data?
        var body: some View {
            TroutNavStack(navData: $navData) {
                TaskList(routine: routine)
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let routine = MRoutine.create(ctx, userOrder: 0)
        routine.name = "Back & Bicep"
        let task = MTask.create(ctx, routine: routine, userOrder: 0)
        task.name = "Lat Pulldown"
        task.routine = routine
        return TestHolder(routine: routine)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
            .accentColor(.orange)
    }
}
