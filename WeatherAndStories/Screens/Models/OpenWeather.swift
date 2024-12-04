//
//  OpenWeather.swift
//  WeatherAndStories
//
//  Created by Robbie Elliott on 2024-10-10.
//

import Foundation
import SwiftData

struct OpenWeatherResponse: Decodable {
    let name: String
    let main: MainWeather
}

struct MainWeather: Codable {
    let temp: Double
}

@Model
final class CachedWeatherData {
    var cityName: String
    var temperature: Double
    var timeStamp: Date

    init(cityName: String, temperature: Double, timeStamp: Date = Date()) {
        self.cityName = cityName
        self.temperature = temperature
        self.timeStamp = timeStamp
    }
}

extension OpenWeatherResponse {
    func toCachedWeatherData() -> CachedWeatherData {
        CachedWeatherData(cityName: name, temperature: main.temp)
    }
}
