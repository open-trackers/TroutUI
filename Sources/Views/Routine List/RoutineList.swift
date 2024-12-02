//
//  RoutineList.swift
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

extension MRoutine: @retroactive Named {}

/// Common view shared by watchOS and iOS.
public struct MRoutineList: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack
    @EnvironmentObject private var router: TroutRouter

    #if os(iOS)
        @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif

    // MARK: - Parameters

    public init() {}

    // MARK: - Locals

    private let startMRoutinePublisher = NotificationCenter.default.publisher(for: .startMRoutine)

    private let title = "Task Routines"

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: MRoutineList.self))

    // NOTE: not stored, to allow resume/restore of started routine
    @State private var isNew = false

    @SceneStorage("routine-run-nav") private var routineRunNavData: Data?
    @SceneStorage("run-selected-routine") private var selectedRoutine: URL? = nil
    @SceneStorage("run-started-or-resumed-at") private var startedOrResumedAt: Date = .distantFuture

    // MARK: - Views

    public var body: some View {
        CellList(cell: routineCell,
                 addButton: { AddRoutineButton() })
        {
            #if os(watchOS)
                Group {
                    AddRoutineButton()
                    settingsButton
                    aboutButton
                }
                // .accentColor(.orange) // NOTE: make the images really orange
                .symbolRenderingMode(.hierarchical)
            #elseif os(iOS)
                EmptyView()
            #endif
        }
        #if os(watchOS)
        // .navigationBarTitleDisplayMode(.large)
        .navigationTitle {
            HStack {
                Text(title)
                    .foregroundStyle(routineColor)
                Spacer() // NOTE: top-level title should be leading-justified
            }
        }
        #elseif os(iOS)
        .navigationTitle(title)
        #endif
        .fullScreenCover(item: $selectedRoutine) { url in
            TroutNavStack(navData: $routineRunNavData) {
                VStack {
                    if let routine: MRoutine = MRoutine.get(viewContext, forURIRepresentation: url) {
                        RoutineRun(routine: routine,
                                   isNew: $isNew,
                                   startedOrResumedAt: $startedOrResumedAt,
                                   onStop: stopAction)
                    } else {
                        Text("Routine not found.")
                    }
                }
            }
        }
        .onReceive(startMRoutinePublisher) { payload in
            logger.debug("onReceive: \(startMRoutinePublisher.name.rawValue)")
            guard let routineURI = payload.object as? URL else { return }

            // NOTE: not preserving any existing task completions; starting anew
            startOrResumeAction(routineURI)
        }
    }

    private func routineCell(routine: MRoutine, now: Binding<Date>) -> some View {
        RoutineCell(routine: routine,
                    now: now,
                    onDetail: {
                        detailAction($0)
                    },
                    onShortPress: {
                        startOrResumeAction($0)
                    })
    }

    #if os(watchOS)
        private var settingsButton: some View {
            Button(action: settingsAction) {
                Label("Settings", systemImage: "gear.circle")
            }
        }

        private var aboutButton: some View {
            Button(action: aboutAction) {
                Label("About \(shortAppName)", systemImage: "info.circle")
            }
        }
    #endif

    #if os(iOS)
        private var rowBackground: some View {
            EntityBackground(.accentColor)
        }
    #endif

    // MARK: - Properties

    private var firstMRoutine: MRoutine? {
        guard let firstMRoutine = (try? MRoutine.getFirst(viewContext))
        else { return nil }
        return firstMRoutine
    }

    // MARK: - Actions

    private func detailAction(_ uri: URL) {
        logger.notice("\(#function)")
        Haptics.play()

        router.path.append(TroutRoute.routineDetail(uri))
    }

    private func startOrResumeAction(_ originalURI: URL) {
        clearRun()

        do {
            // NOTE: if cloning, the URI will change
            let routineToRun = try MRoutine.getToRun(viewContext, originalURI)

            logger.notice("\(#function): Start Routine \(routineToRun.wrappedName)")

            // NOTE: storing startedAt locally (not in routine.lastStartedAt)
            // to ignore mistaken starts.
            startedOrResumedAt = try routineToRun.startOrResumeRun(viewContext)

            // save new clone, task completion clears, etc.
            try viewContext.save()

            Haptics.play(.startingAction)

            isNew = true // forces start at first incomplete task
            selectedRoutine = routineToRun.uriRepresentation // displays sheet

        } catch {
            logger.error("\(#function): Start failure \(error.localizedDescription)")
            return
        }
    }

    private func stopAction(_ routine: MRoutine) {
        logger.notice("\(#function): Stop Routine \(routine.wrappedName)")

        Haptics.play(.stoppingAction)

        clearRun()
    }

    #if os(watchOS)
        private func settingsAction() {
            logger.notice("\(#function)")
            Haptics.play()

            router.path.append(TroutRoute.settings)
        }

        private func aboutAction() {
            logger.notice("\(#function)")
            Haptics.play()

            router.path.append(TroutRoute.about)
        }
    #endif

    // MARK: - Helpers

    // clear existing running routine, if any
    private func clearRun() {
        selectedRoutine = nil
        startedOrResumedAt = .distantFuture
        router.path.removeAll()
    }
}

struct MRoutineList_Previews: PreviewProvider {
    struct TestHolder: View {
        var body: some View {
            NavigationStack {
                MRoutineList()
            }
        }
    }

    static var previews: some View {
        // let container = try! PersistenceManager.getTestContainer()
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        // let ctx = container.viewContext
        let routine = MRoutine.create(ctx, userOrder: 0)
        routine.name = "Back & Bicep"
        let task = MTask.create(ctx, routine: routine, userOrder: 0)
        task.name = "Lat Pulldown"
        return TestHolder()
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
        // .accentColor(.green)
    }
}
