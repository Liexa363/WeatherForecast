//
//  SelectionManager.swift
//  WeatherForecast
//
//  Created by Liexa MacBook Pro on 29.07.2024.
//

import Combine
import SwiftUI

class SelectionManager: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var selectedCity: String = ""
}

