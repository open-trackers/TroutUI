//
//  FieldBoolRun.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import TroutLib

struct FieldBoolRun: View {
    @ObservedObject var field: MFieldBool
    let onTap: () -> Void

    var body: some View {
        Toggle(isOn: $field.value) {
            HStack {
                Text("\(field.wrappedName)")
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
        }
    }
}

// struct BoolField_Previews: PreviewProvider {
//    static var previews: some View {
//        SwiftUIView()
//    }
// }
