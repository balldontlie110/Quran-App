//
//  QuranTimerWidgetLiveActivity.swift
//  QuranTimerWidget
//
//  Created by Ali Earp on 10/29/24.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct QuranTimerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: QuranTimerAttributes.self) { context in
            HStack(spacing: 15) {
                EndTimerButton(frame: 48)
                    .padding(.leading)
                
                RemainingTimeCircle(duration: context.state.duration, remaining: context.attributes.remaining, viewType: .banner)
                
                Spacer()
                
                Text(getTimeString(context.state.duration))
                    .font(.system(size: 48, weight: .light))
                    .lineLimit(1)
                    .minimumScaleFactor(.leastNonzeroMagnitude)
                    .foregroundStyle(Color.streak)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
            }.activityBackgroundTint(Color.black)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        EndTimerButton(frame: 45)
                        
                        RemainingTimeCircle(duration: context.state.duration, remaining: context.attributes.remaining, viewType: .expanded)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(getTimeString(context.state.duration))
                        .font(.system(size: 35, weight: .light))
                        .lineLimit(1)
                        .minimumScaleFactor(.leastNonzeroMagnitude)
                        .foregroundStyle(Color.streak)
                        .padding(.horizontal, 5)
                        .padding(.top, 10)
                }
            } compactLeading: {
                RemainingTimeCircle(duration: context.state.duration, remaining: context.attributes.remaining, viewType: .compact)
            } compactTrailing: {
                Text(getSingleUnitTimeString(context.state.duration))
                    .foregroundStyle(Color.streak)
                    .padding(5)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(Color.streak)
            }.widgetURL(URL(string: "http://www.apple.com"))
        }
    }
    
    private func getTimeString(_ seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = seconds >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        
        if var time = formatter.string(from: TimeInterval(seconds)) {
            time += "s"
            
            return time
        }
        
        return ""
    }
    
    private func getSingleUnitTimeString(_ seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = seconds >= 3600 ? [.hour] : seconds >= 60 ? [.minute] : [.second]
        formatter.unitsStyle = .positional
        
        if var time = formatter.string(from: TimeInterval(seconds)) {
            time += seconds >= 3600 ? "h" : seconds >= 60 ? "m" : "s"
            
            return time
        }
        
        return ""
    }
}

struct EndTimerButton: View {
    let frame: CGFloat
    
    var body: some View {
        Button(intent: EndLiveActivityIntent()) {
            ZStack {
                Circle()
                    .foregroundStyle(Color.buttonBackground)
                
                Image(systemName: "xmark")
                    .resizable()
                    .scaledToFit()
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.white)
                    .padding(15)
            }.frame(width: frame, height: frame)
        }.buttonStyle(PlainButtonStyle())
    }
}

struct RemainingTimeCircle: View {
    let duration: Int
    let remaining: Int
    
    enum ViewType {
        case banner, expanded, compact, minimal
        
        var frame: CGFloat {
            switch self {
            case .banner:
                return 40
            case .expanded:
                return 35
            case .compact:
                return 10
            case .minimal:
                return 10
            }
        }
        
        var circleWidth: CGFloat {
            switch self {
            case .banner:
                return 5
            case .expanded:
                return 5
            case .compact:
                return 2
            case .minimal:
                return 2
            }
        }
    }
    
    let viewType: ViewType
    
    var body: some View {
        let progress = Double(duration) / Double(remaining)
        
        if progress > 0 {
            ZStack {
                Circle()
                    .stroke(lineWidth: viewType.circleWidth)
                    .foregroundStyle(Color.secondary)
                
                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(style: StrokeStyle(lineWidth: viewType.circleWidth, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(Color.streak)
            }
            .frame(width: viewType.frame, height: viewType.frame)
            .padding(5)
        } else {
            if viewType == .compact || viewType == .minimal {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Color.streak)
                    .padding(.leading, viewType == .compact ? 5 : 0)
            } else {
                Image(systemName: "flame.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: viewType.frame, height: viewType.frame)
                    .foregroundStyle(Color.streak)
                    .padding(viewType == .expanded ? 10 : 5)
                    .padding(.leading, viewType == .banner ? -5 : 0)
            }
        }
    }
}

extension String {
    func removingCharacters(of characterSet: CharacterSet) -> String {
        return self.filter({ !characterSet.containsCharacter($0) })
    }
}

extension CharacterSet {
    func containsCharacter(_ character: Character) -> Bool {
        return character.unicodeScalars.allSatisfy(contains(_:))
    }
}

#Preview("Notification", as: .content, using: QuranTimerAttributes(remaining: 0)) {
   QuranTimerWidgetLiveActivity()
} contentStates: {
    QuranTimerAttributes.ContentState(duration: 0)
}

