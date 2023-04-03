//
//  TroutRoute.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

import TrackerUI

public typealias TroutRouter = Router<TroutRoute>

public enum TroutRoute: Hashable, Codable {
    case settings
    case about
    case routineDetail(_ routineUri: URL)
    case taskDetail(_ taskUri: URL)
    case taskList(_ routineUri: URL)
    case taskRunList(_ routineRunUri: URL)
    case taskDefaults
    case taskGroupList(_ routineUri: URL)
    case routineRunRecent
    case routineRunList
    case fieldList(_ taskURI: URL)
    case boolFieldDetail(_ fieldURI: URL)
    case int16FieldDetail(_ fieldURI: URL)

    private func uriSuffix(_ uri: URL) -> String {
        "[\(uri.absoluteString.suffix(12))]"
    }
}
