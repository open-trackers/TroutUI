//
//  Provider.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI
import WidgetKit

import TroutLib

public struct Provider: TimelineProvider {
    public init() {}

    public func placeholder(in _: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), timeInterval: 2000, pairs: [
            WidgetEntry.Pair(.red, 0.34),
            WidgetEntry.Pair(.green, 0.33),
            WidgetEntry.Pair(.blue, 0.33),
        ])
    }

    public func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }

    public func getTimeline(in _: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        guard let entry = UserDefaults.appGroup.get() else { return }
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}
