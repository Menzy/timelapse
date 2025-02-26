//
//  miniTimerLiveActivity.swift
//  miniTimer
//
//  Created by Wan Menzy on 2/25/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct miniTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct miniTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: miniTimerAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension miniTimerAttributes {
    fileprivate static var preview: miniTimerAttributes {
        miniTimerAttributes(name: "World")
    }
}

extension miniTimerAttributes.ContentState {
    fileprivate static var smiley: miniTimerAttributes.ContentState {
        miniTimerAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: miniTimerAttributes.ContentState {
         miniTimerAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: miniTimerAttributes.preview) {
   miniTimerLiveActivity()
} contentStates: {
    miniTimerAttributes.ContentState.smiley
    miniTimerAttributes.ContentState.starEyes
}
