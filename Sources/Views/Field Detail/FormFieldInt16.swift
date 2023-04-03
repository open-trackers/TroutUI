//
//  FormFieldInt16.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import CoreData
import SwiftUI

import TrackerUI

struct FormFieldInt16: View {
    @Binding var value: Int16
    var unitsSuffix: String? = nil

    var body: some View {
        FormIntegerPad(value: $value, upperBound: Int16.max) {
            Text("\($0 ?? 0) \(unitsSuffix ?? "")")
                .font(.title2)
        }
    }
}

struct FormFieldInt16_Previews: PreviewProvider {
    struct TestHolder: View {
        @State var foo: Int16 = 2343
        var body: some View {
            NavigationStack {
                Form {
                    FormFieldInt16(value: $foo)
                }
            }
        }
    }

    static var previews: some View {
        TestHolder()
    }
}
