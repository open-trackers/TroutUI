//
//  FieldDetName.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Collections
import SwiftUI

import TextFieldPreset

import TrackerUI
import TroutLib

struct FieldDetName: View {
    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - Parameters

    @ObservedObject private var field: MField
    private let tint: Color

    init(field: MField, tint: Color) {
        self.field = field
        self.tint = tint
    }

    // MARK: - Views

    var body: some View {
        Section {
            Group {
                if field is MFieldInt16 {
                    TextFieldPreset($field.wrappedName,
                                    prompt: "Enter field name",
                                    axis: .vertical,
                                    presets: filteredFieldPresetsInt16,
                                    pickerLabel: { Text($0.description) },
                                    onSelect: selectAction)
                } else if field is MFieldBool {
                    TextFieldPreset($field.wrappedName,
                                    prompt: "Enter field name",
                                    axis: .vertical,
                                    presets: fieldPresetsBool,
                                    pickerLabel: { Text($0.description) },
                                    onSelect: selectAction)
                }
            }
            #if os(watchOS)
            .padding(.bottom)
            #endif
            .tint(tint)

            // KLUDGE: unable to get textfield to display multiple lines, so conditionally
            //         including full text as a courtesy.
            #if os(watchOS)
                if field.wrappedName.count > 20 {
                    Text(field.wrappedName)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            #endif
        } header: {
            Text("Name")
        }
        #if os(iOS)
        .font(.title3)
        #endif
    }

    // MARK: - Properties

    private var filteredFieldPresetsInt16: FieldPresetInt16Dict {
        switch unitsMode {
        case .all:
            return fieldPresetsInt16
        case .metricOnly:
            return fieldPresetsInt16.filter { !FieldGroupInt16.usGroups.contains($0.key) }
        case .usOnly:
            return fieldPresetsInt16.filter { !FieldGroupInt16.metricGroups.contains($0.key) }
        }
    }

    private var unitsMode: PresetsUnitsMode {
        guard let mode = try? AppSetting.getOrCreate(viewContext).presetUnitsMode
        else { return .all }
        return PresetsUnitsMode(rawValue: Int(mode)) ?? .all
    }

    // MARK: - Actions

    private func selectAction(_ fieldPreset: FieldPreset<AnyHashable>) {
        try? field.update(viewContext, from: fieldPreset)
    }
}

struct FieldDetName_Previews: PreviewProvider {
    struct TestHolder: View {
        @ObservedObject var field: MField
        var body: some View {
            NavigationStack {
                Form { FieldDetName(field: field, tint: .orange) }
            }
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let routine = MRoutine.create(ctx, userOrder: 0, name: "beverage")
        let task = MTask.create(ctx, routine: routine, userOrder: 0, name: "coffee")
        // let field = MFieldBool.create(ctx, task: task, name: "Socks", userOrder: 0, clearOnRun: true, value: true)
        let field = MFieldInt16.create(ctx, task: task, name: "Socks", userOrder: 0, value: 233)
        return TestHolder(field: field)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
            .accentColor(.blue)
    }
}
