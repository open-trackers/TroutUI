//
//  FieldDetInt16.swift
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

import TrackerUI
import TroutLib

struct FieldDetInt16: View {
    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - Parameters

    @ObservedObject var field: MFieldInt16

    // MARK: - Locals

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                                category: String(describing: FieldDetInt16.self))

    #if os(watchOS)
        // NOTE: no longer saving the tab in scene storage, because it has been
        // annoying to not start out at the first tab when navigating to detail.
        // @SceneStorage("task-detail-tab") private var selectedTab = 0
        @State private var selectedTab: Tab = .name

        enum Tab: Int, CaseIterable {
            case name = 1
            case range = 2
            case stepValue = 3
            case value = 4
            case defaultValue = 5
            case unitsSuffix = 6
            case controlType = 7
        }
    #endif

    // MARK: - Views

    var body: some View {
        platformView
            .accentColor(fieldColor)
            .symbolRenderingMode(.hierarchical)
            .onDisappear(perform: onDisappearAction)
    }

    #if os(watchOS)
        private var platformView: some View {
            ControlBarTabView(selection: $selectedTab, tint: fieldColor, title: title) {
                Form {
                    FieldDetName(field: field,
                                 tint: fieldColor)
                }
                .tag(Tab.name)

                Form {
                    Section("Upper Bound") {
                        FormFieldInt16(value: $field.upperBound, unitsSuffix: field.unitsSuffix)
                    }
                }
                .tag(Tab.range)

                Form {
                    Section("Step Value") {
                        FormFieldInt16(value: $field.stepValue, unitsSuffix: field.unitsSuffix)
                    }
                }
                .tag(Tab.stepValue)

                Form {
                    Section("Value") {
                        FormFieldInt16(value: $field.value, unitsSuffix: field.unitsSuffix)
                    }
                }
                .tag(Tab.value)

                Form {
                    defaultValue
                }
                .tag(Tab.defaultValue)

                Form {
                    unitsSuffix
                }
                .tag(Tab.unitsSuffix)

                Form {
                    // Section("Control Type") {
                    FieldDetControlType(value: $field.controlType)
                    // .pickerStyle(.wheel)
                    // }
                }
                .tag(Tab.controlType)
            }
        }
    #endif

    #if os(iOS)
        private var platformView: some View {
            Form {
                FieldDetName(field: field,
                             tint: fieldColor)
                Section("Upper Bound") {
                    FormFieldInt16(value: $field.upperBound, unitsSuffix: field.unitsSuffix)
                }
                Section("Step Value") {
                    FormFieldInt16(value: $field.stepValue, unitsSuffix: field.unitsSuffix)
                }
                Section("Value") {
                    FormFieldInt16(value: $field.value, unitsSuffix: field.unitsSuffix)
                }
                defaultValue
                unitsSuffix
                Section("Control Type") {
                    FieldDetControlType(value: $field.controlType)
                        .pickerStyle(.segmented)
                }
            }
        }
    #endif

    private var defaultValue: some View {
        Section("Default Value") {
            Toggle(isOn: $field.clearOnRun) {
                Text("Clear to default on run?")
            }
            FormFieldInt16(value: $field.defaultValue, unitsSuffix: field.unitsSuffix)
                .disabled(field.clearOnRun == false)
        }
    }

    private var unitsSuffix: some View {
        Section("Units Suffix") {
            TextField("Suffix text", text: $field.wrappedUnitsSuffix, prompt: Text("Suffix text"))
        }
    }

    // MARK: - Properties

    private var title: String {
        "Short Integer Field"
    }

    // MARK: - Actions

    private func onDisappearAction() {
        do {
            try viewContext.save()
        } catch {
            logger.error("\(#function): \(error.localizedDescription)")
        }
    }
}

struct FieldDetInt16_Previews: PreviewProvider {
    struct TestHolder: View {
        var field: MFieldInt16
        var body: some View {
            FieldDetInt16(field: field)
        }
    }

    static var previews: some View {
        let manager = CoreDataStack.getPreviewStack()
        let ctx = manager.container.viewContext
        let routine = MRoutine.create(ctx, userOrder: 0)
        let task = MTask.create(ctx, routine: routine, userOrder: 0)
        task.name = "Beverage"
        let field = MFieldInt16.create(ctx, task: task, name: "Stout", userOrder: 0, clearOnRun: true, defaultValue: 105, value: 100, upperBound: 1000, stepValue: 5)
        return TestHolder(field: field)
            .environment(\.managedObjectContext, ctx)
            .environmentObject(manager)
            .accentColor(.orange)
    }
}
