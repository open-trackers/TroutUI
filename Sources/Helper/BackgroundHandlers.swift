//
//  BackgroundHandlers.swift
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
import TroutLib

/// Preserves 'fresh' zRoutines in .main store no older than thresholdSecs. Deletes those 'stale' ones earlier.
public let freshThresholdSecs: TimeInterval = 86400 * 7 // one week

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                            category: "BackgroundHandlers")

public extension Notification.Name {
    static let startMRoutine = Notification.Name("trout-start-routine") // payload of routineURI
}

public func handleStartMRoutineUA(_ context: NSManagedObjectContext, _ userActivity: NSUserActivity) {
    guard let routineURI = userActivity.userInfo?[userActivity_uriRepKey] as? URL,
          let routine = MRoutine.get(context, forURIRepresentation: routineURI) as? MRoutine,
          !routine.isDeleted,
          routine.archiveID != nil
    else {
        // logger.notice("\(#function): could not resolve MRoutine; so unable to start it via shortcut.")
        return
    }

    // logger.notice("\(#function): routine=\(routine.wrappedName)")

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        NotificationCenter.default.post(name: .startMRoutine, object: routineURI)
    }
}

public func handleTaskAction(_ manager: CoreDataStack) async {
    logger.notice("\(#function) START")

    await manager.container.performBackgroundTask { backgroundContext in
        do {
            #if os(watchOS)
                // delete log records older than one year
                guard let mainStore = manager.getMainStore(backgroundContext),
                      let keepSince = Calendar.current.date(byAdding: .year, value: -1, to: Date.now)
                else { throw TrackerError.missingData(msg: "Clean: could not resolve date one year in past") }
                logger.notice("\(#function): keepSince=\(keepSince)")
                try cleanLogRecords(backgroundContext, keepSince: keepSince, inStore: mainStore)
                try backgroundContext.save()
            #endif

            #if os(iOS)
                guard let mainStore = manager.getMainStore(backgroundContext),
                      let archiveStore = manager.getArchiveStore(backgroundContext)
                else {
                    logger.error("\(#function): unable to acquire configuration to transfer log records.")
                    return
                }

                // move log records to archive store
                try transferToArchive(backgroundContext,
                                      mainStore: mainStore,
                                      archiveStore: archiveStore,
                                      thresholdSecs: freshThresholdSecs)
                try backgroundContext.save()
            #endif

            // update the widget(s), if any
            try WidgetEntry.refresh(backgroundContext,
                                    reload: true,
                                    defaultColor: .accentColor)

        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }
    logger.notice("\(#function) END")
}
