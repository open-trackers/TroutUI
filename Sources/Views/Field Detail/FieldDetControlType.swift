//
//  FieldDetControlType.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData
import SwiftUI

struct FieldDetControlType: View {
    @Binding var value: Int16

    var body: some View {
        Picker("Control Type", selection: $value) {
            Text("Number Pad").tag(0)
            Text("Stepper").tag(1)
        }
        // .pickerStyle(.inline)
    }
}

struct FieldDetControlType_Previews: PreviewProvider {
    struct TestHolder: View {
        @State var foo: Int16 = 1
        var body: some View {
            NavigationStack {
                Form {
                    FieldDetControlType(value: $foo)
                }
            }
        }
    }

    static var previews: some View {
        TestHolder()
    }
}
