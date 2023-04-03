//
//  TaskGroupPicker.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Collections
import os
import SwiftUI

import TroutLib

public struct TaskGroupPicker: View {
    public typealias OnSelect = (TaskGroup) -> Void

    // MARK: - Parameters

    private let taskGroups: [TaskGroup]
    @Binding private var showPresets: Bool
    private let onSelect: OnSelect

    public init(taskGroups: [TaskGroup],
                showPresets: Binding<Bool>,
                onSelect: @escaping OnSelect)
    {
        self.taskGroups = taskGroups
        _showPresets = showPresets
        self.onSelect = onSelect
    }

    // MARK: - Views

    public var body: some View {
        List {
            ForEach(taskGroups.sorted(by: <), id: \.self) { taskGroup in
                Button {
                    onSelect(taskGroup)
                    showPresets = false
                } label: {
                    Text(taskGroup.description)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { showPresets = false }
            }
        }
    }
}

struct TaskGroupPicker_Previews: PreviewProvider {
    struct TestHolder: View {
        let taskGroups: [TaskGroup] = [
            .coldWeatherTravel,
            .diveTravel,
        ]

        @State var showPresets = false
        var body: some View {
            NavigationStack {
                TaskGroupPicker(taskGroups: taskGroups, showPresets: $showPresets) {
                    print("\(#function): Selected \($0.description)")
                }
            }
        }
    }

    static var previews: some View {
        TestHolder()
    }
}
