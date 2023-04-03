//
//  AddRoutineButton.swift
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

public struct AddRoutineButton: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var router: TroutRouter

    // MARK: - Parameters

    public init() {}

    // MARK: - Locals

    // MARK: - Views

    public var body: some View {
        AddElementButton(elementName: "Routine",
                         onCreate: createAction,
                         onAfterSave: afterSaveAction)
    }

    // MARK: - Properties

    private var maxOrder: Int16 {
        do {
            return try MRoutine.maxUserOrder(viewContext) ?? 0
        } catch {
            // logger.error("\(#function): \(error.localizedDescription)")
        }
        return 0
    }

    // MARK: - Actions

    private func createAction() -> MRoutine {
        MRoutine.create(viewContext, userOrder: maxOrder + 1, name: "New Routine")
    }

    private func afterSaveAction(_ nu: MRoutine) {
        router.path.append(TroutRoute.routineDetail(nu.uriRepresentation))
    }
}

// struct AddRoutineButton_Previews: PreviewProvider {
//    static var previews: some View {
//        AddRoutineButton()
//    }
// }
