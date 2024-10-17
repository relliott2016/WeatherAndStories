//
//  ContentViewFeature.swift
//  WeatherAndStories
//
//  Created by Robbie Elliott on 2024-10-12.
//

import SwiftUI
import SwiftData
import CoreLocation
import ComposableArchitecture

struct ContentViewFeature: Reducer {
    struct State: Equatable {
        var locationManager: LocationManager?
        var weatherViewModel: WeatherViewModel
        var hasAttemptedWeatherFetch: Bool = false
        var transitionDuration: Double = 3.0
        var cachedWeather: CachedWeatherData?
        var networkMonitor: NetworkMonitor = NetworkMonitor()
        var isFetchingLocation: Bool = false
        var isFetchingWeather: Bool = false
        var showWeather: Bool = false
        var statusMessage: String = ""
        var storyImages: [String] = []
        var modelContext: ModelContext?
        var isOffline: Bool = false
        var hasNoCachedData: Bool = true
        var isAPIKeyMissing: Bool = false

        static func == (lhs: State, rhs: State) -> Bool {
            lhs.hasAttemptedWeatherFetch == rhs.hasAttemptedWeatherFetch &&
            lhs.transitionDuration == rhs.transitionDuration &&
            lhs.isFetchingLocation == rhs.isFetchingLocation &&
            lhs.isFetchingWeather == rhs.isFetchingWeather &&
            lhs.showWeather == rhs.showWeather &&
            lhs.statusMessage == rhs.statusMessage &&
            lhs.storyImages == rhs.storyImages &&
            lhs.isOffline == rhs.isOffline &&
            lhs.hasNoCachedData == rhs.hasNoCachedData &&
            lhs.isAPIKeyMissing == rhs.isAPIKeyMissing
        }
    }

    enum Action: Equatable {
        case onAppear
        case initializeLocationManager
        case setModelContext(ModelContext)
        case setCachedWeather(CachedWeatherData?)
        case networkStatusChanged(Bool)
        case locationChanged(CLLocation?)
        case updateTransitionDuration(Double)
        case loadStoryImages
        case setStatusMessage(String)
        case setShowWeather(Bool)
        case setFetchingLocation(Bool)
        case setFetchingWeather(Bool)
        case loadWeatherData
        case loadCachedWeather
        case fetchAndCacheWeather(CLLocation)
        case weatherFetched(CachedWeatherData?)
        case setOfflineStatus(Bool)
        case setHasNoCachedData(Bool)
        case checkAPIKeyStatus
        case setAPIKeyStatus(Bool)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .concatenate(
                    .send(.initializeLocationManager),
                    .send(.checkAPIKeyStatus)
                )

            case .initializeLocationManager:
                if state.locationManager == nil {
                    state.locationManager = LocationManager.shared
                }
                return .send(.loadWeatherData)

            case let .setModelContext(context):
                state.modelContext = context
                return .none

            case let .setCachedWeather(cachedWeather):
                state.cachedWeather = cachedWeather
                state.hasNoCachedData = cachedWeather == nil
                if let weather = cachedWeather {
                    print("Cached weather data available for city \(weather.cityName)")
                    if state.isOffline {
                        return .send(.loadCachedWeather)
                    }
                } else {
                    print("No cached weather data available")
                }
                return .none

            case let .networkStatusChanged(isConnected):
                state.isOffline = !isConnected
                if isConnected {
                    state.hasAttemptedWeatherFetch = false
                    return .send(.loadWeatherData)
                } else {
                    return .send(.loadCachedWeather)
                }

            case .loadCachedWeather:
                if let cachedWeather = state.cachedWeather {
                    state.weatherViewModel.loadCachedWeather(cachedWeather)
                    print("Cached Weather data city \(cachedWeather.cityName), and temperature \(cachedWeather.temperature) loaded")
                    state.showWeather = true
                    state.hasNoCachedData = false
                } else {
                    print("No cached weather data available to load")
                    state.hasNoCachedData = true
                    state.showWeather = false
                }
                state.isFetchingLocation = false
                state.isFetchingWeather = false
                state.statusMessage = ""
                return .none

            case let .setOfflineStatus(isOffline):
                state.isOffline = isOffline
                if isOffline {
                    return .send(.loadCachedWeather)
                }
                return .none

            case let .setHasNoCachedData(hasNoCachedData):
                state.hasNoCachedData = hasNoCachedData
                return .none

            case let .locationChanged(newLocation):
                if let location = newLocation, state.networkMonitor.isConnected {
                    state.isFetchingLocation = false
                    state.isFetchingWeather = true
                    state.statusMessage = "Fetching weather data..."
                    return .send(.fetchAndCacheWeather(location))
                }
                return .none

            case let .updateTransitionDuration(duration):
                state.transitionDuration = duration
                return .none

            case .loadStoryImages:
                state.storyImages = [
                    "person.crop.circle",
                    "person.crop.circle.fill",
                    "person.crop.square",
                    "person.crop.square.fill",
                    "person.crop.rectangle"
                ]
                return .none

            case let .setStatusMessage(message):
                state.statusMessage = message
                return .none

            case let .setShowWeather(show):
                state.showWeather = show
                return .none

            case let .setFetchingLocation(fetching):
                state.isFetchingLocation = fetching
                return .none

            case let .setFetchingWeather(fetching):
                state.isFetchingWeather = fetching
                return .none

            case .loadWeatherData:
                if state.isAPIKeyMissing {
                    return .none
                }
                if state.networkMonitor.isConnected {
                    if !state.hasAttemptedWeatherFetch {
                        state.hasAttemptedWeatherFetch = true
                        state.isFetchingLocation = true
                        state.showWeather = false
                        state.statusMessage = "Fetching location..."
                        state.locationManager?.refreshLocation(isConnected: true)
                    }
                } else {
                    return .send(.loadCachedWeather)
                }
                return .none

            case let .fetchAndCacheWeather(location):
                return .run { [weatherViewModel = state.weatherViewModel] send in
                    await send(.setFetchingWeather(true))
                    await send(.setShowWeather(false))
                    await send(.setStatusMessage("Fetching weather data..."))
                    print("Fetching weather data for location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                    let weatherData = await fetchWeather(for: location, using: weatherViewModel)
                    await send(.weatherFetched(weatherData))
                }

            case let .weatherFetched(weatherData):
                state.isFetchingWeather = false
                state.statusMessage = ""
                if let weatherData = weatherData {
                    state.weatherViewModel.weather = weatherData
                    state.showWeather = true

                    if let modelContext = state.modelContext {
                        // Remove existing cached weather data
                        if let existingCachedWeather = state.cachedWeather {
                            modelContext.delete(existingCachedWeather)
                        }
                        // Insert new weather data
                        modelContext.insert(weatherData)
                        do {
                            try modelContext.save()
                            print("Weather data city \(weatherData.cityName), and temperature \(weatherData.temperature) fetched and cached successfully")
                            // Update the cached weather in the state
                            state.cachedWeather = weatherData
                        } catch {
                            print("Failed to save weather data: \(error)")
                        }
                    } else {
                        print("ModelContext is not set, unable to cache weather data")
                    }
                } else {
                    print("Failed to fetch weather data")
                }
                return .none

            case .checkAPIKeyStatus:
                let isAPIKeyMissing = Config.weatherAPIKey == nil
                return .send(.setAPIKeyStatus(isAPIKeyMissing))

            case let .setAPIKeyStatus(isMissing):
                state.isAPIKeyMissing = isMissing
                return .none
            }
        }
    }

    private func fetchWeather(for location: CLLocation, using viewModel: WeatherViewModel) async -> CachedWeatherData? {
        await viewModel.fetchWeather(for: location)
        return viewModel.weather
    }
}
