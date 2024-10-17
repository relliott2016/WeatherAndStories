//
//  NetworkMonitor.swift
//  WeatherAndStories
//
//  Created by Robbie Elliott on 2024-10-11.
//

import Network
import SwiftUI

@Observable
class NetworkMonitor {
    var isConnected = false
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
