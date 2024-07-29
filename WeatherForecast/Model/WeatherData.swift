//
//  WeatherData.swift
//  WeatherForecast
//
//  Created by Liexa MacBook Pro on 22.07.2024.
//

import Foundation

struct Weather: Identifiable {
    let id = UUID()
    let date: String
    let temperature: Double
    let description: String
    let imageName: String
}

struct WeatherResponse: Codable {
    let daily: DailyWeather
}

struct DailyWeather: Codable {
    let time: [String]
    let temperature_2m_max: [Double]
    let weathercode: [Int]
}

