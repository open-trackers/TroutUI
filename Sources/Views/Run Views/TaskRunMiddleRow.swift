//
//  TaskRunMiddleRow.swift
//
// Copyright 2022, 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

#if os(watchOS)

//    enum TaskMiddleRowMode: Int {
//        case intensity = 0
//        case settings = 1
//        case volume = 2
//
//        var next: TaskMiddleRowMode {
//            switch self {
//            case .intensity:
//                return .settings
//            case .settings:
//                return .volume
//            case .volume:
//                return .intensity
//            }
//        }
//    }

    struct TaskRunMiddleRow: View {
        // MARK: - Parameters

//        var imageName: String
//        var imageColor: Color
        var onDetail: () -> Void
        let onTap: () -> Void

//        var onTap: () -> Void
//        var content: () -> Content

        // MARK: - Views

        var body: some View {
            HStack {
                HStack {
                    Text("Edit Task")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture(perform: onTap)

                Button(action: onDetail) {
                    Image(systemName: "ellipsis.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.yellow)
                }
                .padding(.vertical)
                .buttonStyle(.borderless)
                .font(.title2)
                // .border(.teal)
            }
        }
    }

//    struct TaskRunMiddleRow_Previews: PreviewProvider {
//        static var previews: some View {
//            TaskRunMiddleRow(imageName: "gearshape", imageColor: .blue, onDetail: {}, onTap: {}) {
//                Text("Settings")
//            }
//        }
//    }

#endif
