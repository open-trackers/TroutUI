//
//  StatusView.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import Compactor

import TrackerLib
import TrackerUI
import TroutLib

public struct ElapsedSinceView: View {
    // MARK: - Parameters

    private var startedOrResumedAt: Date
    private var labelFont: Font

    public init(startedOrResumedAt: Date,
                labelFont: Font = .body)
    {
        self.startedOrResumedAt = startedOrResumedAt
        self.labelFont = labelFont
    }

    // MARK: - Locals

    private static let tc: TimeCompactor = .init(ifZero: "", style: .short, roundSmallToWhole: false)

    @State private var now = Date()
    private let timer = Timer.publish(every: 1,
                                      tolerance: 0.5,
                                      on: .main,
                                      in: .common).autoconnect()

    // MARK: - Views

    public var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(routineColor.opacity(0.2))

                TitleText(remainingStr)
                    .modify {
                        if #available(iOS 16.1, watchOS 9.1, *) {
                            $0.fontDesign(.monospaced)
                        } else {
                            $0.monospaced()
                        }
                    }
                    .padding(.horizontal)
                    .foregroundStyle(routineColor)
            }

            Text("Elapsed")
                .lineLimit(1)
                .font(labelFont)
        }
        .onReceive(timer) { _ in
            now = Date.now
        }
        .onAppear {
            now = Date.now
        }
//        .onDisappear {
//            timer.upstream.connect().cancel()
//        }
    }

    // MARK: - Properties

    private var remainingStr: String {
        formatElapsed(timeInterval: elapsedTime, timeElapsedFormat: timeElapsedFormat)
            ?? Self.tc.string(from: elapsedTime as NSNumber)
            ?? ""
    }

    private var timeElapsedFormat: TimeElapsedFormat {
        let secondsPerHour: TimeInterval = 3600
        return elapsedTime < secondsPerHour ? .mm_ss : .hh_mm_ss
    }

    private var elapsedTime: TimeInterval {
        now.timeIntervalSince(startedOrResumedAt)
    }
}

struct StatusView_Previews: PreviewProvider {
    static var previews: some View {
        ElapsedSinceView(startedOrResumedAt: Date.now.addingTimeInterval(-3590))
            .frame(height: 80)
    }
}
