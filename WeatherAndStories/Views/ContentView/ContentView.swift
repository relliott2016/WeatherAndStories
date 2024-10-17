//
//  ContentView.swift
//  WeatherAndStories
//
//  Created by Robbie Elliott on 2024-10-10.
//

import SwiftUI
import SwiftData
import CoreLocation
import ComposableArchitecture

struct ContentView: View {
    let store: StoreOf<ContentViewFeature>
    @Query private var cachedWeather: [CachedWeatherData]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationStack {
                VStack(spacing: 20) {
                    Text("Current Weather")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top)
                    weatherContentView(viewStore: viewStore)
                    storyNavigationLink(viewStore: viewStore)
                    transitionSlider(viewStore: viewStore)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Kompanion")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                viewStore.send(.onAppear)
                viewStore.send(.loadStoryImages)
                viewStore.send(.setModelContext(modelContext))
                viewStore.send(.setCachedWeather(cachedWeather.first))
                viewStore.send(.setOfflineStatus(!viewStore.networkMonitor.isConnected))
                viewStore.send(.setHasNoCachedData(cachedWeather.isEmpty))
            }
            .onChange(of: viewStore.networkMonitor.isConnected) { oldValue, newValue in
                viewStore.send(.networkStatusChanged(newValue))
            }
            .onChange(of: viewStore.locationManager?.lastLocation) { oldValue, newValue in
                viewStore.send(.locationChanged(newValue))
            }
            .onChange(of: cachedWeather) { oldValue, newValue in
                viewStore.send(.setCachedWeather(newValue.first))
            }
        }
    }

    private func weatherContentView(viewStore: ViewStore<ContentViewFeature.State, ContentViewFeature.Action>) -> some View {
        weatherView(viewStore: viewStore)
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.blue.opacity(0.6), lineWidth: 2)
                    .background(Color.blue.opacity(0.1))
            )
            .cornerRadius(15)
            .padding(.horizontal)
    }

    private func weatherView(viewStore: ViewStore<ContentViewFeature.State, ContentViewFeature.Action>) -> some View {
        ZStack {
            if viewStore.isOffline && viewStore.hasNoCachedData {
                Text("Offline: No cached data available")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding()
            } else if let locationManager = viewStore.locationManager {
                weatherContentBasedOnAuthStatus(locationManager.authorizationStatus, viewStore: viewStore)
            } else {
                Text("Initializing location services...")
            }
        }
    }

    @ViewBuilder
    private func weatherContentBasedOnAuthStatus(_ status: CLAuthorizationStatus, viewStore: ViewStore<ContentViewFeature.State, ContentViewFeature.Action>) -> some View {
        switch status {
        case .denied, .restricted:
            Text("Location access denied. Enable it in iOS Settings Location Services and restart the app.")
                .multilineTextAlignment(.center)
                .padding()
        case .notDetermined:
            Text("Waiting for location permission...")
        case .authorizedWhenInUse, .authorizedAlways:
            weatherDataView(viewStore: viewStore)
        @unknown default:
            Text("Unknown authorization status")
        }
    }

    private func weatherDataView(viewStore: ViewStore<ContentViewFeature.State, ContentViewFeature.Action>) -> some View {
        VStack {
            if viewStore.showWeather, let weather = viewStore.weatherViewModel.weather {
                displayWeather(cityName: weather.cityName, temperature: weather.temperature)
            } else if viewStore.isOffline, let cachedWeather = viewStore.cachedWeather {
                displayWeather(cityName: cachedWeather.cityName, temperature: cachedWeather.temperature)
            }

            if viewStore.isFetchingLocation || viewStore.isFetchingWeather {
                VStack {
                    ProgressView()
                    Text(viewStore.statusMessage)
                }
            }

            if viewStore.isOffline && !viewStore.hasNoCachedData {
                Text("Offline: Showing cached data")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 5)
            }
        }
    }

    private func displayWeather(cityName: String, temperature: Double) -> some View {
        VStack {
            Text(cityName)
                .font(.title2)
            Text("\(Int(temperature))°C")
                .font(.system(size: 70, weight: .bold))
        }
    }

    private func storyNavigationLink(viewStore: ViewStore<ContentViewFeature.State, ContentViewFeature.Action>) -> some View {
        NavigationLink {
            StoryView(
                store: Store(initialState: StoryViewFeature.State(images: viewStore.storyImages, transitionDuration: viewStore.transitionDuration)) {
                    StoryViewFeature()
                }
            )
        } label: {
            Text("Open Story View")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding(.bottom, -10)
    }

    private func transitionSlider(viewStore: ViewStore<ContentViewFeature.State, ContentViewFeature.Action>) -> some View {
        VStack(spacing: 10) {
            Text("Story Transition Time")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)

            Text("\(viewStore.transitionDuration, specifier: "%.1f") sec")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .center)

            Slider(value: viewStore.binding(
                get: \.transitionDuration,
                send: ContentViewFeature.Action.updateTransitionDuration
            ), in: 1...10, step: 0.5)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

#Preview {
    ContentView(
        store: Store(initialState: ContentViewFeature.State(weatherViewModel: WeatherViewModel())) {
            ContentViewFeature()
        }
    )
    .modelContainer(for: CachedWeatherData.self)
}
