//
//  WeatherViewModel.swift
//  WeatherAndStories
//
//  Created by Robbie Elliott on 2024-10-10.
//

import SwiftUI
import CoreLocation

@Observable
class WeatherViewModel {
    var weather: CachedWeatherData?

    func fetchWeather(for location: CLLocation) async {
        print("location is: \(location.coordinate.latitude), \(location.coordinate.longitude)")

        var components = URLComponents(url: GlobalConstants.URLs.weatherBase, resolvingAgainstBaseURL: true)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(location.coordinate.latitude)),
            URLQueryItem(name: "lon", value: String(location.coordinate.longitude)),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "appid", value: Config.weatherAPIKey)
        ]

        guard let url = components?.url else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let weatherResponse = try JSONDecoder().decode(OpenWeatherResponse.self, from: data)
            weather = CachedWeatherData(cityName: weatherResponse.name, temperature: weatherResponse.main.temp)
        } catch {
            print("Error fetching weather: \(error)")
        }
    }

    func loadCachedWeather(_ cachedWeather: CachedWeatherData?) {
        weather = cachedWeather
    }
}
