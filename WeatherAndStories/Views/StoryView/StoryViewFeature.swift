//
//  StoryFeature.swift
//  WeatherAndStories
//
//  Created by Robbie Elliott on 2024-10-11.
//

import ComposableArchitecture
import SwiftUI

struct StoryViewFeature: Reducer {
    struct State: Equatable {
        var currentIndex = 0
        var progress: CGFloat = 0
        var offset: CGFloat = 0
        var isPaused = false
        let images: [String]
        let transitionDuration: Double
        var lastUpdateTime: Date?
        var completedSegments: [Bool]

        init(images: [String], transitionDuration: Double) {
            self.images = images
            self.transitionDuration = transitionDuration
            if !images.isEmpty {
                self.completedSegments = Array(repeating: false, count: images.count)
                self.completedSegments[0] = true  // First segment is initially filled
            } else {
                self.completedSegments = []
            }
        }
    }

    enum Action: Equatable {
        case onAppear
        case togglePauseResume
        case dragChanged(CGFloat)
        case dragEnded(CGFloat)
        case timerTicked
        case nextImage
        case setProgress(CGFloat)
        case updateCompletedSegments
        case setTestState(currentIndex: Int, isPaused: Bool, completedSegments: [Bool])
    }

    @Dependency(\.continuousClock) var clock
    private enum TimerID { case timer }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.lastUpdateTime = Date()
                return state.images.isEmpty ? .none : self.timerEffect()

            case .timerTicked:
                guard !state.isPaused && !state.images.isEmpty else { return .none }
                let now = Date()
                if let lastUpdate = state.lastUpdateTime {
                    let delta = now.timeIntervalSince(lastUpdate)
                    state.progress += CGFloat(delta / state.transitionDuration)
                    if state.progress >= 1 {
                        return .send(.nextImage)
                    }
                }
                state.lastUpdateTime = now
                return .send(.updateCompletedSegments)

            case .nextImage:
                guard !state.images.isEmpty else { return .none }
                state.currentIndex = (state.currentIndex + 1) % state.images.count
                state.progress = 0
                state.lastUpdateTime = Date()
                return .send(.updateCompletedSegments)

            case .togglePauseResume:
                state.isPaused.toggle()
                if state.isPaused {
                    return .concatenate(
                        .cancel(id: TimerID.timer),
                        .send(.updateCompletedSegments)
                    )
                } else {
                    state.lastUpdateTime = Date()
                    state.progress = 0
                    return .concatenate(
                        self.timerEffect(),
                        .send(.updateCompletedSegments)
                    )
                }

            case let .dragChanged(translationWidth):
                state.offset = translationWidth
                return .none

            case let .dragEnded(translationWidth):
                guard !state.images.isEmpty else { return .none }
                let threshold: CGFloat = 50
                if translationWidth > threshold {
                    // Swiping right (to previous image)
                    state.currentIndex = (state.currentIndex - 1 + state.images.count) % state.images.count
                } else if translationWidth < -threshold {
                    // Swiping left (to next image)
                    state.currentIndex = (state.currentIndex + 1) % state.images.count
                }
                state.offset = 0
                state.progress = state.isPaused ? 1 : 0
                state.lastUpdateTime = Date()
                return .send(.updateCompletedSegments)

            case let .setProgress(newProgress):
                state.progress = newProgress
                state.lastUpdateTime = Date()
                return .send(.updateCompletedSegments)

            case .updateCompletedSegments:
                guard !state.images.isEmpty else { return .none }
                if state.isPaused {
                    // When paused, fill all segments up to and including the current one
                    for i in 0...state.currentIndex {
                        state.completedSegments[i] = true
                    }
                    for i in (state.currentIndex + 1)..<state.images.count {
                        state.completedSegments[i] = false
                    }
                } else {
                    // When auto-progressing, fill based on current progress
                    for i in 0..<state.currentIndex {
                        state.completedSegments[i] = true
                    }
                    state.completedSegments[state.currentIndex] = state.progress >= 1
                    for i in (state.currentIndex + 1)..<state.images.count {
                        state.completedSegments[i] = false
                    }
                }
                return .none

            case .setTestState(currentIndex: let currentIndex, isPaused: let isPaused, completedSegments: let completedSegments):
                state.currentIndex = currentIndex
                state.isPaused = isPaused
                state.completedSegments = completedSegments
                return .none
            }
        }
    }

    private func timerEffect() -> Effect<Action> {
        .run { send in
            for await _ in self.clock.timer(interval: .milliseconds(16)) {
                await send(.timerTicked)
            }
        }
        .cancellable(id: TimerID.timer)
    }
}
