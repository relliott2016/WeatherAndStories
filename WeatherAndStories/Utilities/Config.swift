//
//  Config.swift
//  WeatherAndStories
//
//  Created by Robbie Elliott on 2024-10-17.
//

import Foundation

import Foundation

struct Config {
    static var weatherAPIKey: String {
        guard let apiKey = Bundle.main.infoDictionary?["OPENWEATHERMAP_API_KEY"] as? String else {
            fatalError("OPENWEATHERMAP_API_KEY entry is missing from the Info.plist")
        }

        guard apiKey != "ADD_OPENWEATHERMAP_API_KEY_HERE" else {
            fatalError("You need to replace the OPENWEATHERMAP_API_KEY placeholder with your API key in the Info.plist")
        }

        return apiKey
    }
}
