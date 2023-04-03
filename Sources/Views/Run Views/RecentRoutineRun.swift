//
//  RecentRoutineRun.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData
import SwiftUI

import TrackerLib
import TrackerUI
import TroutLib

public struct RecentRoutineRun<Content: View>: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var manager: CoreDataStack
    @EnvironmentObject private var router: TroutRouter

    // MARK: - Parameters

    private let mainStore: NSPersistentStore
    private let content: (ZRoutineRun) -> Content

    public init(mainStore: NSPersistentStore,
                content: @escaping (ZRoutineRun) -> Content)
    {
        self.mainStore = mainStore
        self.content = content

        let predicate = ZRoutineRun.getPredicate(userRemoved: false)
        let sortDescriptors = ZRoutineRun.byStartedAt(ascending: false)
        let request = makeRequest(ZRoutineRun.self,
                                  predicate: predicate,
                                  sortDescriptors: sortDescriptors,
                                  inStore: mainStore)
        request.fetchLimit = 1
        _routineRuns = FetchRequest<ZRoutineRun>(fetchRequest: request)
    }

    // MARK: - Locals

    @FetchRequest private var routineRuns: FetchedResults<ZRoutineRun>

    // MARK: - Views

    public var body: some View {
        if let routineRun = routineRuns.first {
            content(routineRun)
        } else {
            Text("No recent activity.") // shouldn't appear; included here defensively
        }
    }
}

struct RecentRoutineRun_Previews: PreviewProvider {
    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let mainStore = manager.getMainStore(ctx)!

        let routineArchiveID = UUID()
        let startedAt1 = Date.now.addingTimeInterval(-20000)
        let duration1 = 500.0
        let zR = ZRoutine.create(ctx, routineArchiveID: routineArchiveID, routineName: "blah", toStore: mainStore)
        let zRR = ZRoutineRun.create(ctx, zRoutine: zR, startedAt: startedAt1, elapsedSecs: duration1, toStore: mainStore)
        let taskArchiveID1 = UUID()
        let taskArchiveID2 = UUID()
        let taskArchiveID3 = UUID()
        let completedAt1 = startedAt1.addingTimeInterval(116)
        let completedAt2 = completedAt1.addingTimeInterval(173)
        let completedAt3 = completedAt1.addingTimeInterval(210)
        let zE1 = ZTask.create(ctx, zRoutine: zR, taskArchiveID: taskArchiveID1, taskName: "Lat Pulldown", toStore: mainStore)
        let zE2 = ZTask.create(ctx, zRoutine: zR, taskArchiveID: taskArchiveID2, taskName: "Rear Delt", toStore: mainStore)
        let zE3 = ZTask.create(ctx, zRoutine: zR, taskArchiveID: taskArchiveID3, taskName: "Arm Curl", toStore: mainStore)
        _ = ZTaskRun.create(ctx, zRoutineRun: zRR, zTask: zE1, completedAt: completedAt1, toStore: mainStore)
        let er2 = ZTaskRun.create(ctx, zRoutineRun: zRR, zTask: zE2, completedAt: completedAt2, toStore: mainStore)
        _ = ZTaskRun.create(ctx, zRoutineRun: zRR, zTask: zE3, completedAt: completedAt3, toStore: mainStore)
        er2.userRemoved = true
        try! ctx.save()

        return NavigationStack {
            RecentRoutineRun(mainStore: mainStore) { _ in Text("Content") }
                .environment(\.managedObjectContext, ctx)
        }
    }
}
