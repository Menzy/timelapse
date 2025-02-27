//
//  miniTimerBundle.swift
//  miniTimer
//
//  Created by Wan Menzy on 2/25/25.
//

import WidgetKit
import SwiftUI

@main
struct miniTimerBundle: WidgetBundle {
    var body: some Widget {
        miniTimer()
        miniTimerControl()
        miniTimerLiveActivity()
    }
}
