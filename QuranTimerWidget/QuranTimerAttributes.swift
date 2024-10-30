//
//  QuranTimer.swift
//  Quran
//
//  Created by Ali Earp on 10/29/24.
//

import Foundation
import ActivityKit
import AppIntents

struct QuranTimerAttributes: ActivityAttributes {
    
    public typealias TimeTrackingStatus = ContentState
    
    public struct ContentState: Codable, Hashable {
        var duration: Int
    }
    
    var remaining: Int
}

class QuranTimerLiveActivityManager {
    
    @discardableResult
    func startActivity(remaining: Int, duration: Int) -> Activity<QuranTimerAttributes>? {
        var activity: Activity<QuranTimerAttributes>?
        let attributes = QuranTimerAttributes(remaining: remaining)
        
        do {
            let state = QuranTimerAttributes.ContentState(
                duration: duration
            )
            
            let content = ActivityContent(state: state, staleDate: nil)
            
            activity = try Activity<QuranTimerAttributes>.request(attributes: attributes, content: content)
        } catch {
            print(error.localizedDescription)
        }
        
        return activity
    }
    
    func updateActivity(activity: String, duration: Int) {
        Task {
            let contentState = QuranTimerAttributes.ContentState(
                duration: duration
            )
            
            let activity = Activity<QuranTimerAttributes>.activities.first(where: { $0.id == activity })
            
            await activity?.update(using: contentState)
        }
    }
    
    func endActivity() {
        Task {
            for activity in Activity<QuranTimerAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
    }
}

struct EndLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "End Live Activity"
    
    func perform() async throws -> some IntentResult {
        for activity in Activity<QuranTimerAttributes>.activities {
            await activity.end(dismissalPolicy: .immediate)
        }
        
        NotificationCenter.default.post(name: Notification.Name("liveActivityEnded"), object: nil)
        
        return .result()
    }
}
