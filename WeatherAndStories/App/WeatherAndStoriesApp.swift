//
//  WeatherAndStoriesApp.swift
//  WeatherAndStories
//
//  Created by Robbie Elliott on 2024-10-10.
//

import SwiftUI
import SwiftData
import ComposableArchitecture

@main
struct YourApp: App {
    private var isNotTesting: Bool {
        NSClassFromString("XCTestCase") == nil
    }

    var body: some Scene {
        WindowGroup {
            if isNotTesting {
                ContentView(
                    store: Store(initialState: ContentViewFeature.State(weatherViewModel: WeatherViewModel())) {
                        ContentViewFeature()
                    }
                )
                .modelContainer(for: CachedWeatherData.self)
            }
        }
    }
}
