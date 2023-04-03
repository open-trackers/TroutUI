//
//  TroutStepper.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

import TrackerUI

#if os(iOS)
    public struct TroutStepper<T, Label>: View
        where T: Numeric & _FormatSpecifiable & Strideable, Label: View
    {
        // MARK: - Parameters

        @Binding private var value: T
        private var range: ClosedRange<T>
        private var step: T
        private var content: () -> Label

        public init(value: Binding<T>,
                    in range: ClosedRange<T>,
                    step: T,
                    @ViewBuilder label: @escaping () -> Label)
        {
            _value = value
            self.range = range
            self.step = step
            content = label
        }

        // MARK: - Locals

        private let heightFactor: CGFloat = 0.66

        // MARK: - Views

        public var body: some View {
            HStack(alignment: .center) {
                GeometryReader { geo in
                    let maxHeight = geo.size.height * heightFactor
                    HStack(alignment: .center) {
                        button("minus.circle.fill",
                               maxHeight: maxHeight,
                               action: decreaseAction)

                        Spacer()

                        content()

                        Spacer()

                        button("plus.circle.fill",
                               maxHeight: maxHeight,
                               action: increaseAction)
                    }
                    .frame(width: geo.size.width,
                           height: geo.size.height,
                           alignment: .center)
                }
            }
        }

        // NOTE: using onTapGesture rather than action to allow use in Form.
        private func button(_ systemName: String,
                            maxHeight: CGFloat,
                            action: @escaping () -> Void) -> some View
        {
            Button(action: action) {
                Image(systemName: systemName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: maxHeight)
            }
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.tint)
        }

        // MARK: - Actions

        private func decreaseAction() {
            Haptics.play()
            value = max(range.lowerBound, value - step)
        }

        private func increaseAction() {
            Haptics.play()
            value = min(value + step, range.upperBound)
        }
    }

    struct TroutStepper_Previews: PreviewProvider {
        struct TestHolder: View {
            @State private var value: Float = 95.0
            var body: some View {
                TroutStepper(value: $value, in: 0 ... 200, step: 5.0) {
                    Text("\(value, specifier: "%0.1f lbs")")
                        .font(.system(size: 100))
                        .minimumScaleFactor(0.01)
                        .lineLimit(1)
                }
                .frame(width: 300, height: 100)
                .border(.teal)
            }
        }

        static var previews: some View {
            Form {
                TestHolder()
            }
        }
    }
#endif
