//
//  HomeView.swift
//  WeatherForecast
//
//  Created by Liexa MacBook Pro on 29.07.2024.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: WeatherViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                if !viewModel.cityName.isEmpty {
                    Text(viewModel.cityName)
                        .font(.largeTitle)
                        .padding()
                }
                
                List(viewModel.weatherData) { weather in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(weather.date)
                                .font(.headline)
                            Text("\(String(weather.temperature))°C")
                            Text(weather.description)
                        }
                        Spacer()
                        Image(systemName: weather.imageName)
                            .resizable()
                            .frame(width: 50, height: 50)
                    }
                }
            }
        }
    }
}
