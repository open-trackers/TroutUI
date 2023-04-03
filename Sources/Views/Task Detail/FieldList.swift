//
//  FieldList.swift
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

public struct FieldList: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: TroutRouter

    // MARK: - Parameters

    private var task: MTask

    public init(task: MTask) {
        self.task = task

        let sort = MField.byUserOrder()
        let pred = MField.getPredicate(task: task)
        _fields = FetchRequest<MField>(entity: MField.entity(),
                                       sortDescriptors: sort,
                                       predicate: pred)
    }

    // MARK: - Locals

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: FieldList.self))

    @FetchRequest private var fields: FetchedResults<MField>

    // MARK: - Views

    public var body: some View {
        List {
            ForEach(fields, id: \.self) { field in
                Button(action: { detailAction(field: field) }) {
                    Text("\(field.name ?? "unknown")")
                        .foregroundColor(fieldColor)
                }
                #if os(watchOS)
                .listItemTint(fieldListItemTint)
                #elseif os(iOS)
                .listRowBackground(fieldListItemTint)
                #endif
            }
            .onMove(perform: moveAction)
            .onDelete(perform: deleteAction)

            #if os(watchOS)
                AddFieldButton(task: task)
                    .accentColor(fieldColorDarkBg)
                    .symbolRenderingMode(.hierarchical)

            #endif
        }
        #if os(iOS)
        .navigationTitle("Fields")
        .toolbar {
            ToolbarItem {
                AddFieldButton(task: task)
            }
        }
        #endif
    }

    // MARK: - Properties

    private var fieldColor: Color {
        colorScheme == .light ? fieldColorLiteBg : fieldColorDarkBg
    }

    // MARK: - Actions

    private func detailAction(field: MField) {
        logger.notice("\(#function)")
        Haptics.play()

        let route: TroutRoute? = {
            guard let fieldType = MField.FieldType(rawValue: field.fieldType) else { return nil }
            switch fieldType {
            case .bool:
                return TroutRoute.boolFieldDetail(field.uriRepresentation)
            case .int16:
                return TroutRoute.int16FieldDetail(field.uriRepresentation)
            }
        }()

        guard let route else { return }
        router.path.append(route)
    }

    private func deleteAction(offsets: IndexSet) {
        logger.notice("\(#function)")
        offsets.map { fields[$0] }.forEach(viewContext.delete)
        do {
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }

    private func moveAction(from source: IndexSet, to destination: Int) {
        logger.notice("\(#function)")
        MField.move(fields, from: source, to: destination)
        do {
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }
}

struct FieldList_Previews: PreviewProvider {
    struct TestHolder: View {
        var task: MTask
        @State var navData: Data?
        var body: some View {
            TroutNavStack(navData: $navData) {
                FieldList(task: task)
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let routine = MRoutine.create(ctx, userOrder: 2)
        let task = MTask.create(ctx, routine: routine, userOrder: 0)
        task.name = "Back & Bicep"
//        let task = MField.create(ctx, task: task, userOrder: 0)
//        task.name = "Lat Pulldown"
//        task.task = task
        return TestHolder(task: task)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
            .accentColor(.orange)
    }
}
