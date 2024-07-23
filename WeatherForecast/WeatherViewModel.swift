//
//  WeatherViewModel.swift
//  WeatherForecast
//
//  Created by Liexa MacBook Pro on 22.07.2024.
//

import Foundation
import Combine
import CoreLocation

class WeatherViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var weatherData: [Weather] = []
    @Published var city: String = ""
    @Published var cityName: String = ""
    @Published var errorMessage: String? = nil
    private var cancellables: Set<AnyCancellable> = []
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    func fetchWeather(for latitude: Double, _ longitude: Double) {
        let startDate = DateFormatter.apiDateFormatter.string(from: Date())
        let endDate = DateFormatter.apiDateFormatter.string(from: Calendar.current.date(byAdding: .day, value: 15, to: Date())!)

        guard let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&daily=temperature_2m_max,weathercode&start_date=\(startDate)&end_date=\(endDate)&timezone=auto") else {
            self.errorMessage = "Invalid URL"
            return
        }

        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: WeatherResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                case .finished:
                    break
                }
            }, receiveValue: { response in
                self.weatherData = zip(response.daily.time, zip(response.daily.temperature_2m_max, response.daily.weathercode)).map { (date, data) in
                    let (temperature, weatherCode) = data
                    let (description, imageName) = self.weatherDescriptionAndImage(for: weatherCode)
                    return Weather(date: self.formatDate(date), temperature: temperature, description: description, imageName: imageName)
                }
            })
            .store(in: &self.cancellables)
    }

    func fetchWeather(for city: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(city) { placemarks, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }

            if let placemark = placemarks?.first, let location = placemark.location {
                self.cityName = placemark.locality ?? city
                self.fetchWeather(for: location.coordinate.latitude, location.coordinate.longitude)
            }
        }
    }

    func weatherDescriptionAndImage(for weatherCode: Int) -> (String, String) {
        switch weatherCode {
        case 0:
            return ("Clear", "sun.max")
        case 1, 2:
            return ("Partly Cloudy", "cloud.sun")
        case 3:
            return ("Cloudy", "cloud")
        case 45, 48:
            return ("Foggy", "cloud.fog")
        case 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82:
            return ("Rainy", "cloud.rain")
        case 71, 73, 75, 77, 85, 86:
            return ("Snowy", "cloud.snow")
        case 95, 96, 99:
            return ("Stormy", "cloud.bolt.rain")
        default:
            return ("Unknown", "questionmark.circle")
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            self.errorMessage = "Location access denied."
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            self.errorMessage = "Unknown authorization status."
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let placemark = placemarks?.first {
                    self.cityName = placemark.locality ?? ""
                    self.fetchWeather(for: location.coordinate.latitude, location.coordinate.longitude)
                }
            }
            locationManager.stopUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.errorMessage = error.localizedDescription
    }

    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = inputFormatter.date(from: dateString) else { return dateString }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "EE, d MMMM"
        return outputFormatter.string(from: date)
    }
}

extension DateFormatter {
    static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

