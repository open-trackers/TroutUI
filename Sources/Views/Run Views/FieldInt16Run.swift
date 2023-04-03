//
//  FieldInt16Run.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import TrackerUI
import TroutLib

struct FieldInt16Run: View {
    @ObservedObject var field: MFieldInt16
    let onTap: () -> Void

    #if os(watchOS)
        private let maxFontSize: CGFloat = 60
    #elseif os(iOS)
        private let maxFontSize: CGFloat = 50
    #endif

    var body: some View {
        VStack {
//            HStack {
            Text(field.wrappedName.uppercased())
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(1)
//                Spacer()
//            }
//            .contentShape(Rectangle())
//            .onTapGesture(perform: onTap)

            if field.controlType == MField.ControlType.stepper.rawValue {
                Stepper(value: $field.value) {
                    stepperTextLabel
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onTap)
                }
            } else {
                FormIntegerPad(value: $field.value,
                               upperBound: field.upperBound)
                { _ in
                    HStack {
                        textLabel
                            .font(.title2)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onTap)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var stepperTextLabel: some View {
        TitleText(textLabel,
                  maxFontSize: maxFontSize)
    }

    private var textLabel: Text {
        if let unitsSuffix = field.unitsSuffix {
            return Text("\(field.value) \(unitsSuffix)")
        } else {
            return Text("\(field.value)")
        }
    }
}

// struct Int16Field_Previews: PreviewProvider {
//    static var previews: some View {
//        SwiftUIView()
//    }
// }
