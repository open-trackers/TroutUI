//
//  SinceText.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Combine
import SwiftUI

import Compactor

import TroutLib

public struct SinceText: View {
    // MARK: - Parameters

    private let prefix: String?
    private let startedAt: Date?
    private let duration: TimeInterval?
    @Binding private var now: Date
    private let compactorStyle: TimeCompactor.Style

    public init(prefix: String? = nil,
                startedAt: Date?,
                duration: TimeInterval?,
                now: Binding<Date>,
                compactorStyle: TimeCompactor.Style)
    {
        self.prefix = prefix
        self.startedAt = startedAt
        self.duration = duration
        _now = now
        self.compactorStyle = compactorStyle

        tcDur = .init(ifZero: "", style: compactorStyle, roundSmallToWhole: false)
        tcSince = .init(ifZero: nil, style: compactorStyle, roundSmallToWhole: true)
    }

    // MARK: - Locals

    private var tcDur: TimeCompactor
    private var tcSince: TimeCompactor

    // MARK: - Views

    public var body: some View {
        Text(lastStr ?? "")
    }

    // MARK: - Properties

    private var lastStr: String? {
        guard let _sinceStr = sinceStr else { return nil }
        let _prefix: String = {
            guard let prefix, prefix.count > 0 else { return "" }
            return "\(prefix) "
        }()
        if let _durationStr = durationStr {
            return "\(_prefix)\(_sinceStr) ago, for \(_durationStr)"
        } else {
            return "\(_prefix)\(_sinceStr) ago"
        }
    }

    private var sinceStr: String? {
        guard let sinceInterval else { return nil }
        return tcSince.string(from: sinceInterval as NSNumber)
    }

    // time interval since the last workout ended, formatted compactly
    private var sinceInterval: TimeInterval? {
        guard let startedAt else { return nil }

        // NOTE: now (driven by timer) may be lagging startedAt,
        // so clamping at 0.
        let baseSince = max(0, now.timeIntervalSince(startedAt))

        guard let duration,
              duration > 0
        else { return baseSince }

        return max(0, baseSince - duration)
    }

    private var durationStr: String? {
        guard let duration,
              duration > 0 else { return nil }
        return tcDur.string(from: duration as NSNumber)
    }
}

struct SinceText_Previews: PreviewProvider {
    struct TestHolder: View {
        var startedAt = Date.now.addingTimeInterval(-2 * 86400)
        var duration = 1000.0
        @State var now: Date = .now
        var body: some View {
            VStack(alignment: .leading) {
                SinceText(startedAt: startedAt, duration: duration, now: $now, compactorStyle: .short)
                SinceText(startedAt: startedAt, duration: nil, now: $now, compactorStyle: .short)
                SinceText(prefix: "blah", startedAt: startedAt, duration: 0, now: $now, compactorStyle: .short)
                SinceText(prefix: "", startedAt: startedAt, duration: duration, now: $now, compactorStyle: .medium)
                SinceText(startedAt: startedAt, duration: duration, now: $now, compactorStyle: .full)
            }
            .border(.gray)
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        return NavigationStack {
            TestHolder()
                .environment(\.managedObjectContext, ctx)
        }
        .environment(\.managedObjectContext, ctx)
    }
}
