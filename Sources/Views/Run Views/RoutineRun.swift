//
//  RoutineRun.swift
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

import TrackerLib
import TrackerUI
import TroutLib

public struct RoutineRun: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: TroutRouter

    // MARK: - Parameters

    private var routine: MRoutine
    @Binding private var isNew: Bool
    @Binding private var startedOrResumedAt: Date
    private let onStop: (MRoutine) -> Void

    public init(routine: MRoutine,
                isNew: Binding<Bool>,
                startedOrResumedAt: Binding<Date>,
                onStop: @escaping (MRoutine) -> Void)
    {
        self.routine = routine
        self.onStop = onStop

        _startedOrResumedAt = startedOrResumedAt

        _tasks = FetchRequest<MTask>(entity: MTask.entity(),
                                     sortDescriptors: MTask.byUserOrder(),
                                     predicate: routine.taskPredicate)
        _incomplete = FetchRequest<MTask>(entity: MTask.entity(),
                                          sortDescriptors: MTask.byUserOrder(),
                                          predicate: routine.incompletePredicate)
        _isNew = isNew

        #if os(iOS)
            let uic = UIColor(.accentColor)
            UIPageControl.appearance().currentPageIndicatorTintColor = uic
            UIPageControl.appearance().pageIndicatorTintColor = uic.withAlphaComponent(0.35)
        #endif
    }

    // MARK: - Locals

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: RoutineRun.self))

    @SceneStorage("routine-run-tab") private var selectedTab: URL = controlTab

    @FetchRequest private var tasks: FetchedResults<MTask>
    @FetchRequest private var incomplete: FetchedResults<MTask>

    // MARK: - Views

    public var body: some View {
        TabView(selection: $selectedTab) {
            RoutineControl(routine: routine,
                           onAdd: addAction,
                           onStop: stopAction,
                           onNextIncomplete: nextIncompleteAction,
                           onRemainingCount: { remainingCount },
                           onCompletedCount: { completedCount },
                           startedOrResumedAt: startedOrResumedAt)
                .tag(controlTab)
                .tabItem {
                    Text("Control")
                }

            ForEach(tasks, id: \.self) { task in
                TaskRun(task: task,
                        routineStartedOrResumedAt: startedOrResumedAt,
                        onNextIncomplete: nextIncompleteAction,
                        hasNextIncomplete: hasNextIncomplete,
                        onEdit: editAction)
                    .tag(task.uriRepresentation)
                    .tabItem {
                        Text(task.wrappedName)
                    }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedTab)
        .tabViewStyle(.page(indexDisplayMode: .always))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                toolbarItem
            }
            #if os(iOS)
                ToolbarItem {
                    Button(action: {
                        editAction(selectedTab)
                    }) {
                        Text("Edit")
                    }
                    .disabled(selectedTab == controlTab)
                }
            #endif
        }

        .onAppear {
            // when starting a routine, select the appropriate tab
            guard isNew else { return }
            isNew = false

            logger.debug("onAppear: starting at the first incomplete task, if any")
            nextIncompleteAction(from: nil)
        }

        #if os(iOS)
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        #endif

        // advertise running "Start ‘Back & Bicep’ Routine"
        .userActivity(startMRoutineActivityType,
                      isActive: hasCompletedAtLeastOneMTask,
                      userActivityUpdate)
    }

    private var toolbarItem: some View {
        Button(action: { Haptics.play(); selectedTab = controlTab }) {
            Image(systemName: "control")
                .foregroundColor(isOnControlPanel ? disabledColor : .primary)
        }
        .disabled(isOnControlPanel)
    }

    // MARK: - Properties

    private var maxOrder: Int16 {
        tasks.last?.userOrder ?? 0
    }

    private var isOnControlPanel: Bool {
        selectedTab == controlTab
    }

    private var remainingCount: Int {
        incomplete.count
    }

    private var hasRemaining: Bool {
        remainingCount > 0
    }

    private func hasNextIncomplete() -> Bool {
        remainingCount > 1
    }

    private var completedCount: Int {
        tasks.count - remainingCount
    }

    private var hasCompletedAtLeastOneMTask: Bool {
        completedCount > 0
    }

    // MARK: - Actions/Updates

    private func addAction() {
        logger.debug("\(#function) maxOrder=\(maxOrder)")
        withAnimation {
            Haptics.play()
            let nu = MTask.create(viewContext, routine: routine, userOrder: maxOrder + 1)
            do {
                try viewContext.save()
            } catch {
                logger.error("\(#function): \(error.localizedDescription)")
            }
            let uriRep = nu.objectID.uriRepresentation()
            editAction(uriRep)
        }
    }

    private func editAction(_ taskURI: URL) {
        logger.debug("\(#function) taskURI=\(taskURI)")
        Haptics.play()
        // TODO: is a delay actually needed? Try it without.
        DispatchQueue.main.asyncAfter(deadline: .now() + editDelaySeconds) {
            if selectedTab != taskURI {
                selectedTab = taskURI
            }
            router.path.append(TroutRoute.taskDetail(taskURI))
        }
    }

    private func stopAction() {
        // TODO: also handle pause here!

        logger.debug("\(#function)")
        // Haptics.play(.stoppingAction)
        onStop(routine) // parent view will take down the sheet & save context
    }

    // if next incomplete task exists, switch to its tab
    private func nextIncompleteAction(from userOrder: Int16?) {
        logger.debug("\(#function) userOrder=\(userOrder ?? -1000)")
        if let nextIncomplete = try? routine.getNextIncomplete(viewContext, from: userOrder) {
            // Haptics.play()
            let nextTab = nextIncomplete.uriRepresentation()
            // logger.debug("\(#function) Selecting TAB, from \(selectedTab.suffix ?? "") to \(nextTab.suffix ?? "")")
            selectedTab = nextTab
        } else {
            Haptics.play(.completedAction)
            // logger.debug("\(#function) from \(selectedTab.suffix ?? "") to CONTROL")
            selectedTab = controlTab
        }
    }

    private func userActivityUpdate(_ userActivity: NSUserActivity) {
        logger.debug("\(#function)")
        userActivity.title = "Start ‘\(routine.wrappedName)’ Routine"
        userActivity.userInfo = [
            userActivity_uriRepKey: routine.uriRepresentation,
        ]
        userActivity.isEligibleForPrediction = true
        userActivity.isEligibleForSearch = true
    }
}

struct MRoutineRun_Previews: PreviewProvider {
    struct TestHolder: View {
        var routine: MRoutine
        @State var startedAt: Date = .now.addingTimeInterval(-1000)
        var body: some View {
            NavigationStack {
                RoutineRun(routine: routine,
                           isNew: .constant(true),
                           startedOrResumedAt: $startedAt,
                           onStop: { _ in })
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let routine = MRoutine.create(ctx, userOrder: 0)
        routine.name = "Back & Bicep"
        let e1 = MTask.create(ctx, routine: routine, userOrder: 0)
        e1.name = "Lat Pulldown"
//        e1.primarySetting = 4
//        e1.secondarySetting = 6
        // e1.units = Units.kilograms.rawValue
//        e1.intensityStep = 7.1
        let e2 = MTask.create(ctx, routine: routine, userOrder: 1)
        e2.name = "Arm Curl"
        return
            TestHolder(routine: routine)
                .environment(\.managedObjectContext, ctx)
    }
}
