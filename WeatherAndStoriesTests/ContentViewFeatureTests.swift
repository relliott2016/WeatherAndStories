//
//  WeatherAndStoriesTests.swift
//  WeatherAndStoriesTests
//
//  Created by Robbie Elliott on 2024-10-10.
//

import Testing
import XCTestDynamicOverlay
import ComposableArchitecture
import CoreLocation
import SwiftUI
@testable import WeatherAndStories

@MainActor
struct ContentViewFeatureTests {
    @Test
    func testLocationAuthorizationDenied() async throws {
        let store = TestStore(initialState: ContentViewFeature.State(
            locationManager: nil,
            weatherViewModel: WeatherViewModel(),
            hasNoCachedData: true  // Explicitly set to true as there's no cached data
        )) {
            ContentViewFeature()
        }

        // Disable exhaustivity to ignore intermediate actions
        store.exhaustivity = .off

        // Simulate location access being denied
        await store.send(.locationChanged(nil))

        // Check final state
        #expect(!store.state.showWeather, "Weather should not be shown when location is denied")
        #expect(store.state.hasNoCachedData, "Should have no cached data")
        #expect(store.state.statusMessage == "", "Status message should be empty")
        #expect(!store.state.isFetchingLocation, "Should not be fetching location")
        #expect(!store.state.isFetchingWeather, "Should not be fetching weather")

        // Allow any remaining effects to complete
        await store.finish()
    }

    @Test
    func testLocationAllowOnce() async throws {
        let store = TestStore(initialState: ContentViewFeature.State(
            weatherViewModel: WeatherViewModel(),
            hasNoCachedData: true
        )) {
            ContentViewFeature()
        }

        // Disable exhaustivity
        store.exhaustivity = .off

        // Simulate app launch
        await store.send(.onAppear)

        // Simulate location change
        let mockLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        await store.send(.locationChanged(mockLocation))

        // Simulate weather fetched
        let mockWeather = CachedWeatherData(cityName: "San Francisco", temperature: 18.0)
        await store.send(.weatherFetched(mockWeather)) {
            $0.showWeather = true
            $0.isFetchingWeather = false
        }

        // Check final state
        #expect(store.state.showWeather)
        #expect(!store.state.isFetchingWeather)

        // Allow any remaining effects to complete
        await store.finish()
    }

    @Test
    func testLocationAllowWhileUsingApp() async throws {
        let store = TestStore(initialState: ContentViewFeature.State(
            weatherViewModel: WeatherViewModel(),
            hasNoCachedData: true
        )) {
            ContentViewFeature()
        }

        // Disable exhaustivity
        store.exhaustivity = .off

        // Simulate app launch
        await store.send(.onAppear)

        // Simulate location change (user grants "Allow While Using App" permission)
        let mockLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        await store.send(.locationChanged(mockLocation))

        // Simulate weather fetched
        let mockWeather = CachedWeatherData(cityName: "San Francisco", temperature: 18.0)
        await store.send(.weatherFetched(mockWeather)) {
            $0.showWeather = true
            $0.isFetchingWeather = false
        }

        // Check final state
        #expect(store.state.showWeather)
        #expect(!store.state.isFetchingWeather)

        // Allow any remaining effects to complete
        await store.finish()
    }

    @Test
    func testOfflineWithCachedData() async throws {
        let cachedWeather = CachedWeatherData(cityName: "Cached City", temperature: 20.0)

        let store = TestStore(initialState: ContentViewFeature.State(
            weatherViewModel: WeatherViewModel(),
            cachedWeather: cachedWeather,
            networkMonitor: NetworkMonitor(),
            isOffline: true,
            hasNoCachedData: false
        )) {
            ContentViewFeature()
        }

        store.exhaustivity = .off

        await store.send(.onAppear)

        await store.send(.loadCachedWeather)

        // Check final state
        #expect(store.state.showWeather, "Weather should be shown when offline with cached data")
        #expect(!store.state.hasNoCachedData, "Should have cached data")
        #expect(store.state.weatherViewModel.weather?.cityName == "Cached City", "Cached city name should be loaded")
        #expect(store.state.weatherViewModel.weather?.temperature == 20.0, "Cached temperature should be loaded")
        #expect(store.state.isOffline, "Should be offline")
        #expect(!store.state.isFetchingLocation, "Should not be fetching location")
        #expect(!store.state.isFetchingWeather, "Should not be fetching weather")

        await store.finish()
    }

    @Test
    func testOfflineWithNoCachedData() async throws {
        let store = TestStore(initialState: ContentViewFeature.State(
            weatherViewModel: WeatherViewModel(),
            cachedWeather: nil,
            networkMonitor: NetworkMonitor(),
            isOffline: true,
            hasNoCachedData: true
        )) {
            ContentViewFeature()
        }

        store.exhaustivity = .off

        await store.send(.onAppear)

        await store.send(.loadCachedWeather)

        // Check final state
        #expect(!store.state.showWeather, "Weather should not be shown when offline with no cached data")
        #expect(store.state.hasNoCachedData, "Should have no cached data")
        #expect(store.state.weatherViewModel.weather == nil, "Weather data should be nil")
        #expect(store.state.isOffline, "Should be offline")
        #expect(!store.state.isFetchingLocation, "Should not be fetching location")
        #expect(!store.state.isFetchingWeather, "Should not be fetching weather")

        await store.finish()
    }

    @Test
    func testMissingAPIKey() async throws {
        let store = TestStore(initialState: ContentViewFeature.State(
            weatherViewModel: WeatherViewModel(),
            hasNoCachedData: true,
            isAPIKeyMissing: true  // Start with isAPIKeyMissing as true
        )) {
            ContentViewFeature()
        }

        // Disable exhaustivity
        store.exhaustivity = .off

        // Simulate app launch
        await store.send(.onAppear)

        // Check the state after onAppear
        #expect(store.state.isAPIKeyMissing, "API key should be missing initially")
        #expect(!store.state.showWeather, "Weather should not be shown when API key is missing")
        #expect(!store.state.isFetchingLocation, "Should not be fetching location initially")
        #expect(!store.state.isFetchingWeather, "Should not be fetching weather initially")
        #expect(store.state.statusMessage == "", "Status message should be empty initially")

        // Simulate location change
        let mockLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        await store.send(.locationChanged(mockLocation)) {
            $0.isAPIKeyMissing = false  // API key status changes after location change
            $0.isFetchingWeather = true
            $0.statusMessage = "Fetching weather data..."
        }

        // Check final state
        #expect(!store.state.isAPIKeyMissing, "API key should not be missing after location change")
        #expect(!store.state.showWeather, "Weather should not be shown yet")
        #expect(!store.state.isFetchingLocation, "Should not be fetching location after location change")
        #expect(store.state.isFetchingWeather, "Should be fetching weather after location change")
        #expect(store.state.statusMessage == "Fetching weather data...", "Status message should indicate fetching weather")

        await store.finish()
    }

    @Test
    func testValidAPIKey() async throws {
        let store = TestStore(initialState: ContentViewFeature.State(
            weatherViewModel: WeatherViewModel(),
            hasNoCachedData: true,
            isAPIKeyMissing: false
        )) {
            ContentViewFeature()
        }

        store.exhaustivity = .off

        await store.send(.onAppear)

        await store.send(.checkAPIKeyStatus)

        // Simulate location change
        let mockLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        await store.send(.locationChanged(mockLocation))

        // Check intermediate state
        #expect(!store.state.isAPIKeyMissing, "API key should be valid")
        #expect(store.state.isFetchingWeather, "Should be fetching weather")

        // Simulate weather fetched
        let mockWeather = CachedWeatherData(cityName: "San Francisco", temperature: 18.0)
        await store.send(.weatherFetched(mockWeather)) {
            $0.showWeather = true
            $0.isFetchingWeather = false
        }

        // Check final state
        #expect(!store.state.isAPIKeyMissing, "API key should be valid")
        #expect(store.state.showWeather, "Weather should be shown when API key is valid")
        #expect(!store.state.isFetchingWeather, "Should not be fetching weather after data is received")

        await store.finish()
    }
}
