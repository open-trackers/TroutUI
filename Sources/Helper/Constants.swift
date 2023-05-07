//
//  Constants.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI

public let defaultImageName = "wrench.and.screwdriver.fill"

public let routineColor: Color = .accentColor
public let routineColorDarkBg: Color = routineColor.opacity(0.8)
public let routineColorLiteBg: Color = .primary
public let routineListItemTint: Color = routineColor.opacity(0.2)

public let taskColor: Color = .yellow
public let taskColorDarkBg: Color = taskColor.opacity(0.8)
public let taskColorLiteBg: Color = .primary
public let taskListItemTint: Color = taskColor.opacity(0.2)

public let fieldColor: Color = .cyan
public let fieldColorDarkBg: Color = fieldColor.opacity(0.8)
public let fieldColorLiteBg: Color = fieldColor
public let fieldListItemTint: Color = fieldColor.opacity(0.2)

public let taskGroupColor: Color = .mint
public let taskGroupColorDarkBg: Color = taskGroupColor.opacity(0.8)
public let taskGroupColorLiteBg: Color = .primary
public let taskGroupListItemTint: Color = taskGroupColor.opacity(0.2)

public let stopColor: Color = .pink

public let taskDoneColor: Color = .green
public let taskUndoColor: Color = .green
public let taskAdvanceColor: Color = .mint
public let taskNextColor: Color = .blue

public let taskGearColor: Color = .gray
public let taskSetsColor: Color = .teal

public let titleColor: Color = .primary.opacity(0.8)
public let lastColor: Color = .primary.opacity(0.6)
public let disabledColor: Color = .secondary.opacity(0.4)
public let completedColor: Color = .secondary.opacity(0.5)

public let numberWeight: Font.Weight = .light

public let numberFont: Font = .title2

// How frequently to update time strings in RoutineCell
public let routineSinceUpdateSeconds: TimeInterval = 60

// How long to delay before showing edit sheet
public let editDelaySeconds: TimeInterval = 0.1

// How long to delay before showing first incomplete task, when starting routine
public let newFirstIncompleteSeconds: TimeInterval = 0.25

// public let colorSchemeModeKey = "colorScheme"
public let exportFormatKey = "exportFormat"

public let startMRoutineActivityType = "org.openalloc.trout.run-routine"
public let userActivity_uriRepKey = "uriRep"

// storage keys
public let alwaysAdvanceOnLongPressKey = "alwaysAdvanceOnLongPress"
public let logToHistoryKey = "logToHistory"

public let controlTab = URL(string: "uri://control-panel")!

public let websiteDomain = "open-trackers.github.io"
public let copyright = "Copyright 2023 OpenAlloc LLC"

public let websiteURL = URL(string: "https://\(websiteDomain)")!
public let websitePrivacyURL = websiteURL.appending(path: "privacy")
public let websiteTermsURL = websiteURL.appending(path: "terms")

public let websiteAppURL = websiteURL.appending(path: "trt")
public let websiteAppTutorialURL = websiteAppURL.appending(path: "tutorial")

public let websitePlea: String =
    "As an open source project, we depend on our community of users. Please rate and review \(shortAppName) in the App Store!"

#if os(watchOS)
    public let shortAppName = "TRT"
#elseif os(iOS)
    public let shortAppName = "TRT+"
#endif
