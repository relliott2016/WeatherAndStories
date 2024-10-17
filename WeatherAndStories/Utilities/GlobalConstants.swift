//
//  GlobalConstants.swift
//  WeatherAndStories
//
//  Created by Robbie Elliott on 2024-10-17.
//

import Foundation

struct GlobalConstants {
    struct URLs {
        static let weatherBase = URL(string: "https://api.openweathermap.org/data/2.5/weather")!
    }

    struct APIKeys {
        static let openWeatherMapPlaceholder = "ADD_OPENWEATHERMAP_API_KEY_HERE"
    }
}
