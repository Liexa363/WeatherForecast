//
//  WeatherViewModel.swift
//  WeatherForecast
//
//  Created by Liexa MacBook Pro on 22.07.2024.
//

import SwiftUI
import Combine
import CoreLocation

class WeatherViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var weatherData: [Weather] = []
    @Published var city: String = ""
    @Published var cityName: String = ""
    @Published var searchHistory: [String] = []
    @Published var errorMessage: IdentifiableError? = nil
    
    private var cancellables: Set<AnyCancellable> = []
    private let locationManager = CLLocationManager()
    
    var selectionManager: SelectionManager?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    func fetchWeather(for latitude: Double, _ longitude: Double) {
        let startDate = DateFormatter.apiDateFormatter.string(from: Date())
        let endDate = DateFormatter.apiDateFormatter.string(from: Calendar.current.date(byAdding: .day, value: 15, to: Date())!)
        
        guard let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&daily=temperature_2m_max,weathercode&start_date=\(startDate)&end_date=\(endDate)&timezone=auto") else {
            self.errorMessage = IdentifiableError(message: "Failed to create URL. Please try again later.")
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: WeatherResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    self.handleNetworkError(error)
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
                self.handleGeocodingError(error)
                return
            }
            
            if let placemark = placemarks?.first, let location = placemark.location {
                self.cityName = placemark.locality ?? city
                self.fetchWeather(for: location.coordinate.latitude, location.coordinate.longitude)
                self.selectionManager?.selectedTab = 0
            } else {
                self.errorMessage = IdentifiableError(message: "City not found. Please enter a valid city name.")
            }
        }
    }
    
    func addCityToHistory(_ city: String) {
        if !searchHistory.contains(city) {
            searchHistory.append(city)
        }
    }
    
    func requestUserLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
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
            self.errorMessage = IdentifiableError(message: "Location access denied. Please enable location services in your device settings.")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            self.errorMessage = IdentifiableError(message: "Unknown authorization status. Please try again later.")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let placemark = placemarks?.first {
                    self.cityName = placemark.locality ?? "Unknown location"
                    self.fetchWeather(for: location.coordinate.latitude, location.coordinate.longitude)
                } else {
                    self.errorMessage = IdentifiableError(message: "Failed to determine city name. Please try again later.")
                }
            }
            locationManager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.errorMessage = IdentifiableError(message: "Failed to fetch location. Please check your location settings and try again.")
    }
    
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = inputFormatter.date(from: dateString) else { return dateString }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "EE, d MMMM"
        return outputFormatter.string(from: date)
    }
    
    private func handleNetworkError(_ error: Error) {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                self.errorMessage = IdentifiableError(message: "No internet connection. Please check your network settings and try again.")
            case .timedOut:
                self.errorMessage = IdentifiableError(message: "The request timed out. Please try again later.")
            case .cannotFindHost, .cannotConnectToHost:
                self.errorMessage = IdentifiableError(message: "Unable to connect to the server. Please try again later.")
            default:
                self.errorMessage = IdentifiableError(message: "An unknown network error occurred. Please try again later.")
            }
        } else {
            self.errorMessage = IdentifiableError(message: "An unknown error occurred. Please try again later.")
        }
    }
    
    private func handleGeocodingError(_ error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .network:
                self.errorMessage = IdentifiableError(message: "Network error occurred while fetching city information. Please try again later.")
            case .geocodeFoundNoResult:
                self.errorMessage = IdentifiableError(message: "No results found for the specified city. Please check the city name and try again.")
            case .geocodeFoundPartialResult:
                self.errorMessage = IdentifiableError(message: "Partial results found for the specified city. Please provide a more specific city name.")
            default:
                self.errorMessage = IdentifiableError(message: "An unknown error occurred while fetching city information. Please try again later.")
            }
        } else {
            self.errorMessage = IdentifiableError(message: "An unknown error occurred. Please try again later.")
        }
    }
}

extension DateFormatter {
    static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

struct IdentifiableError: Identifiable {
    var id = UUID()
    var message: String
}



