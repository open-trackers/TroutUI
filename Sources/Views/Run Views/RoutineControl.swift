//
//  RoutineControl.swift
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

public struct RoutineControl: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: TroutRouter

    #if os(iOS)
        @Environment(\.verticalSizeClass) private var verticalSizeClass
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    // MARK: - Parameters

    private let routine: MRoutine
    private let onAdd: () -> Void
    private let onStop: () -> Void
    private let onNextIncomplete: (Int16?) -> Void
    private let onRemainingCount: () -> Int
    private let onCompletedCount: () -> Int
    private let startedOrResumedAt: Date

    public init(routine: MRoutine,
                onAdd: @escaping () -> Void,
                onStop: @escaping () -> Void,
                onNextIncomplete: @escaping (Int16?) -> Void,
                onRemainingCount: @escaping () -> Int,
                onCompletedCount: @escaping () -> Int,
                startedOrResumedAt: Date)
    {
        self.routine = routine
        self.onAdd = onAdd
        self.onStop = onStop
        self.onNextIncomplete = onNextIncomplete
        self.onRemainingCount = onRemainingCount
        self.onCompletedCount = onCompletedCount
        self.startedOrResumedAt = startedOrResumedAt
    }

    // MARK: - Locals

    #if os(watchOS)
        let verticalSpacing: CGFloat = 12
        let minTitleHeight: CGFloat = 20
        let horzButtonSpacing: CGFloat = 15
        let maxFontSize: CGFloat = 35
    #elseif os(iOS)
        let verticalSpacing: CGFloat = 30
        let minTitleHeight: CGFloat = 60
        let maxButtonHeight: CGFloat = 150
        let horzButtonSpacing: CGFloat = 30
        let maxFontSize: CGFloat = 40
    #endif

    @State private var showStopAlert = false

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: RoutineControl.self))

    // MARK: - Views

    public var body: some View {
        platformView
            // NOTE: using an alert, as confirmationDialog may be clipped at top of view on iPad
            // .confirmationDialog(
            .alert("\(onRemainingCount()) task(s) remain",
                   isPresented: $showStopAlert)
        {
            Button(action: {
                closeRoutine(pause: false)
            }) {
                Text("Stop and close")
                // Label("Stop (close)", systemImage: "stop.fill")
            }
            Button(action: {
                closeRoutine(pause: true)
            }) {
                Text("Pause for later")
                // Label("Pause for later", systemImage: "pause.fill")
            }
            Button(role: .cancel) {
                // do nothing (stop is ignored)
            } label: {
                Text("Cancel")
            }
        }
    }

    #if os(watchOS)
        private let slices: CGFloat = 9
        private var platformView: some View {
            GeometryReader { geo in
                VStack(spacing: verticalSpacing) {
                    TitleText(routine.wrappedName, maxFontSize: maxFontSize)
                        .foregroundColor(titleColor)
                        .frame(minHeight: minTitleHeight)
                        .frame(height: geo.size.height * 1 / slices)

                    middle
                        .frame(height: geo.size.height * 4 / slices)

                    bottom
                        .frame(height: geo.size.height * 4 / slices)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    #endif

    #if os(iOS)
        private var platformView: some View {
            VStack(spacing: verticalSpacing) {
                TitleText(routine.wrappedName, maxFontSize: maxFontSize)
                    .foregroundColor(titleColor)
                    .frame(minHeight: minTitleHeight)
                Group {
                    middle

                    bottom
                }
                .frame(maxHeight: maxButtonHeight)
                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .top)
            // NOTE: padding needed on iPhone 8, 12, and possibly others (visible in light mode)
            .padding(.horizontal)
        }
    #endif

    private var middle: some View {
        HStack(alignment: .bottom, spacing: horzButtonSpacing) {
            ActionButton(onShortPress: stopAction,
                         imageSystemName: "xmark",
                         buttonText: "Stop",
                         labelFont: labelFont,
                         tint: stopColor,
                         onLongPress: nil)

            // NOTE: presently shows only the time since the most recent start/resume.
            //
            // Does NOT yet show the total elapsed time based on MRoutine.lastDuration
            // (where there may have been one or more pauses.)
            ElapsedView(startedAt: startedOrResumedAt,
                        labelFont: labelFont,
                        tint: routineColor)
        }
    }

    private var bottom: some View {
        HStack(alignment: .bottom, spacing: horzButtonSpacing) {
            ActionButton(onShortPress: onAdd,
                         imageSystemName: "plus", // plus.circle.fill
                         buttonText: "Add",
                         labelFont: labelFont,
                         tint: taskColorDarkBg,
                         onLongPress: nil)
            ActionButton(onShortPress: { onNextIncomplete(nil) },
                         imageSystemName: "arrow.forward",
                         buttonText: "Next",
                         labelFont: labelFont,
                         tint: onNextIncompleteColor,
                         onLongPress: nil)
                .disabled(!hasRemaining)
        }
    }

    // MARK: - Properties

    // NOTE: mirrored in MTaskRun
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

    private var onNextIncompleteColor: Color {
        hasRemaining ? taskNextColor : disabledColor
    }

    private var hasRemaining: Bool {
        onRemainingCount() > 0
    }

    private var hasCompleted: Bool {
        onCompletedCount() > 0
    }

    private func stopAction() {
        logger.notice("\(#function): Stop Routine \(routine.wrappedName)")

        if hasRemaining, hasCompleted {
            showStopAlert = true
        } else {
            closeRoutine(pause: false)
        }
    }

    private func closeRoutine(pause: Bool) {
        do {
            try routine.stopRun(startedOrResumedAt: startedOrResumedAt, pause: pause)
            try viewContext.save()
            onStop()
        } catch {
            logger.error("\(#function): Close routine failure \(error.localizedDescription)")
            return
        }
    }
}

struct RoutineControl_Previews: PreviewProvider {
    struct TestHolder: View {
        var routine: MRoutine
        @State var selectedTab: URL? = .init(string: "blah")!
        var startedAt = Date.now.addingTimeInterval(-1200)
        var body: some View {
            RoutineControl(routine: routine,
                           onAdd: {},
                           onStop: {},
                           onNextIncomplete: { _ in },
                           onRemainingCount: { 3 },
                           onCompletedCount: { 1 },
                           startedOrResumedAt: startedAt)
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let routine = MRoutine.create(ctx, userOrder: 0)
        routine.name = "Chest"
        let e1 = MTask.create(ctx, routine: routine, userOrder: 0)
        e1.name = "Lat Pulldown"
        // try? ctx.save()
        return NavigationStack {
            TestHolder(routine: routine)
                .accentColor(.orange)
        }
    }
}
