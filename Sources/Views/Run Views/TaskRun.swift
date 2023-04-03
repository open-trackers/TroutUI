//
//  TaskRun.swift
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

#if os(iOS)
    struct TaskRunGroupBoxStyle: GroupBoxStyle {
        var rectangle: some Shape {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
        }

        var background: some View {
            rectangle
                .fill(Color(.systemGroupedBackground))
        }

        func makeBody(configuration: Configuration) -> some View {
            VStack(alignment: .center, spacing: 0) {
                configuration.label
                    .font(.title2)
                    .padding(.top, 5)
                configuration.content
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(background)
            .clipShape(rectangle)
        }
    }
#endif

public struct TaskRun: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack

    @AppStorage(logToHistoryKey) var logToHistory: Bool = true

    #if os(iOS)
        @Environment(\.verticalSizeClass) private var verticalSizeClass
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(\.colorScheme) private var colorScheme
    #endif

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: TaskRun.self))

    // MARK: - Parameters

    @ObservedObject private var task: MTask
    private let routineStartedOrResumedAt: Date
    private let onNextIncomplete: (Int16?) -> Void
    private let hasNextIncomplete: () -> Bool
    private let onEdit: (URL) -> Void

    public init(task: MTask,
                routineStartedOrResumedAt: Date,
                onNextIncomplete: @escaping (Int16?) -> Void,
                hasNextIncomplete: @escaping () -> Bool,
                onEdit: @escaping (URL) -> Void)
    {
        self.task = task
        self.routineStartedOrResumedAt = routineStartedOrResumedAt
        self.onNextIncomplete = onNextIncomplete
        self.hasNextIncomplete = hasNextIncomplete
        self.onEdit = onEdit

        let sort = MField.byUserOrder()
        let pred = MField.getPredicate(task: task)
        _fields = FetchRequest<MField>(entity: MField.entity(),
                                       sortDescriptors: sort,
                                       predicate: pred)
    }

    // MARK: - Locals

    @FetchRequest private var fields: FetchedResults<MField>

    #if os(watchOS)
        @SceneStorage("middle-row-index") private var middleRowIndex: Int = 0
    #endif

    #if os(watchOS)
        private let maxFontSize: CGFloat = 60
    #elseif os(iOS)
        private let maxFontSize: CGFloat = 80
    #endif

    // MARK: - Views

    public var body: some View {
        platformContent
    }

    #if os(watchOS)
        private var platformContent: some View {
            GeometryReader { geo in
                VStack {
                    titleText
                        .frame(height: geo.size.height * 3 / 13)

                    middleRow
                        .frame(height: geo.size.height * 5 / 13)

                    navigationRow
                        .frame(height: geo.size.height * 5 / 13)
                }
            }
        }
    #endif

    #if os(iOS)
        private var platformContent: some View {
            GeometryReader { geo in
                VStack {
                    titleText
                        .frame(maxHeight: geo.size.height / 6)

                    let count = fields.count
                    GroupBox {
                        if count > 0 {
                            Form {
                                ForEach(fields) { field in
                                    if let boolField = field as? MFieldBool {
                                        FieldBoolRun(field: boolField) {}
                                    } else if let int16Field = field as? MFieldInt16 {
                                        FieldInt16Run(field: int16Field) {}
                                    }
                                }
                            }
                            .disabled(isDone)
                        } else {
                            Spacer()
                        }
                    } label: {
                        Text("Fields")
                    }
                    .groupBoxStyle(TaskRunGroupBoxStyle())
                    .opacity(count > 0 ? 1.0 : 0.25)

                    navigationRow
                        .padding(.top)
                }
                .padding(.horizontal)
                .padding(.bottom, 40) // allow space for index indicator
            }
        }
    #endif

    private var navigationRow: some View {
        HStack {
            ActionButton(onShortPress: isDone ? undoAction : doneAction,
                         imageSystemName: isDone ? "arrow.uturn.backward" : "checkmark",
                         buttonText: isDone ? "Undo" : "Done",
                         labelFont: labelFont,
                         tint: isDone ? taskUndoColor : taskDoneColor,
                         onLongPress: nil)

            ActionButton(onShortPress: nextAction,
                         imageSystemName: "arrow.forward",
                         buttonText: "Next",
                         labelFont: labelFont,
                         tint: nextColor,
                         onLongPress: nil)
                .disabled(!hasNext)
        }
        .frame(maxHeight: 120)
    }

    private var titleText: some View {
        TitleText(task.wrappedName, maxFontSize: maxFontSize)
            .foregroundColor(titleColor)
    }

    #if os(watchOS)
        @ViewBuilder
        private var middleRow: some View {
            VStack {
                if middleRowIndex < fields.count {
                    let field = fields[middleRowIndex]
                    if let boolField = field as? MFieldBool {
                        FieldBoolRun(field: boolField) {
                            middleRowIndex += 1
                        }
                        .lineLimit(2)
                    } else if let int16Field = field as? MFieldInt16 {
                        FieldInt16Run(field: int16Field) {
                            middleRowIndex += 1
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text("Field type not supported.")
                    }
                } else {
                    TaskRunMiddleRow {
                        onEdit(task.uriRepresentation)
                    } onTap: {
                        middleRowIndex = 0
                    }
                }
            }
            .disabled(isDone)
            .frame(maxHeight: .infinity)
            .padding(.horizontal)
            .font(.title3)
        }
    #endif

    // MARK: - Properties

    // NOTE: mirrored in RoutineControl
    private var labelFont: Font {
        #if os(watchOS)
            .body
        #elseif os(iOS)
            if horizontalSizeClass == .regular, verticalSizeClass == .regular {
                return .largeTitle
            } else {
                return .title2
            }
        #endif
    }

    private var titleColor: Color {
        #if os(watchOS)
            let base = taskColorDarkBg
        #elseif os(iOS)
            let base = colorScheme == .light ? .primary : taskColorDarkBg
        #endif
        return isDone ? completedColor : base
    }

    private var isDone: Bool {
        task.isDone
    }

    private var hasNext: Bool {
        hasNextIncomplete()
    }

    private var nextColor: Color {
        hasNextIncomplete() ? taskNextColor : disabledColor
    }

    // MARK: - Actions

    private func nextIncompleteAction() {
        logger.debug("\(#function) \(task.wrappedName) userOrder=\(task.userOrder) uri=\(task.uriRepresentationSuffix ?? "")")

        // NOTE: no haptic should be done here, as it's secondary to other actions

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onNextIncomplete(task.userOrder)
        }
    }

    private func nextAction() {
        Haptics.play()
        nextIncompleteAction()
    }

    private func undoAction() {
        logger.debug("\(#function)")
        Haptics.play()
        task.lastCompletedAt = nil
    }

    private func doneAction() {
        markDone()
    }

    // MARK: - Helpers

    private func markDone() {
        logger.debug("\(#function)")

        Haptics.play()

        guard let mainStore = manager.getMainStore(viewContext) else { return }

        do {
            try task.markDone(viewContext,
                              mainStore: mainStore,
                              routineStartedOrResumedAt: routineStartedOrResumedAt,
                              logToHistory: logToHistory)
            try viewContext.save()

        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }

        nextIncompleteAction()
    }
}

struct TaskRun_Previews: PreviewProvider {
    struct TestHolder: View {
        var task: MTask
        var body: some View {
            TaskRun(task: task,
                    routineStartedOrResumedAt: Date.now,
                    onNextIncomplete: { _ in },
                    hasNextIncomplete: { true },
                    onEdit: { _ in })
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let routine = MRoutine.create(ctx, userOrder: 0)
        routine.name = "Back & Bicep"
        let t1 = MTask.create(ctx, routine: routine, userOrder: 0)
        t1.name = "Lat Pulldown"
        _ = MFieldBool.create(ctx, task: t1, name: "Foot Massager", userOrder: 0, clearOnRun: true, value: true)
        _ = MFieldInt16.create(ctx, task: t1, name: "Bartending College", userOrder: 1, unitsSuffix: "Pr", controlType: .numPad, value: 11335, upperBound: 30000, stepValue: 5)
        _ = MFieldInt16.create(ctx, task: t1, name: "Beauty College", userOrder: 2, unitsSuffix: "kg", controlType: .stepper, value: 113, upperBound: 300, stepValue: 1)
        _ = MFieldBool.create(ctx, task: t1, name: "fort", userOrder: 2, value: true)
        _ = MFieldInt16.create(ctx, task: t1, name: "barf", userOrder: 3, value: 335, upperBound: 500, stepValue: 5)
        _ = MFieldBool.create(ctx, task: t1, name: "foof", userOrder: 4, value: true)
        _ = MFieldInt16.create(ctx, task: t1, name: "bart", userOrder: 5, value: 335, upperBound: 500, stepValue: 5)
        _ = MFieldBool.create(ctx, task: t1, name: "foot", userOrder: 6, value: true)
        _ = MFieldInt16.create(ctx, task: t1, name: "barg", userOrder: 7, value: 335, upperBound: 500, stepValue: 5)
        try? ctx.save()

        return NavigationStack {
            TestHolder(task: t1)
                .environment(\.managedObjectContext, ctx)
                .environmentObject(manager)
                .accentColor(.orange)
        }
    }
}
