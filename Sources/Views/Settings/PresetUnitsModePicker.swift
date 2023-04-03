//
//  PresetsUnitsModePicker.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import TroutLib

public struct PresetsUnitsModePicker: View {
    // MARK: - Parameters

    @Binding private var unitsMode: PresetsUnitsMode

    public init(unitsMode: Binding<PresetsUnitsMode>) {
        _unitsMode = unitsMode
    }

    // MARK: - Locals

    // MARK: - Views

    public var body: some View {
        Section {
            Picker("Preset Units", selection: $unitsMode) {
                ForEach(PresetsUnitsMode.allCases, id: \.self) {
                    Text($0.description)
                        .font(.title2)
                        .tag($0)
                }
            }
            #if os(iOS)
            .pickerStyle(.menu)
            #endif
        } footer: {
            Text("Whether US, metric, or both systems will be available when creating fields.")
        }
    }
}

struct PresetUnitsModePicker_Previews: PreviewProvider {
    struct TestHolder: View {
        @State var unitsMode: PresetsUnitsMode = .metricOnly
        var body: some View {
            Form {
                PresetsUnitsModePicker(unitsMode: $unitsMode)
            }
        }
    }

    static var previews: some View {
        NavigationStack {
            TestHolder()
                .accentColor(.orange)
        }
    }
}
