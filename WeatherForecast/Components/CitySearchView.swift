//
//  CitySearchView.swift
//  WeatherForecast
//
//  Created by Liexa MacBook Pro on 29.07.2024.
//

import SwiftUI

struct CitySearchView: View {
    @ObservedObject var viewModel: WeatherViewModel
    @EnvironmentObject var selectionManager: SelectionManager
    
    var body: some View {
        VStack {
            TextField("Enter city", text: $viewModel.city, onCommit: {
                viewModel.fetchWeather(for: viewModel.city)
                viewModel.addCityToHistory(viewModel.city)
                selectionManager.selectedTab = 0
            })
            .onSubmit {
                viewModel.city = ""
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
            
            if !viewModel.searchHistory.isEmpty {
                List {
                    Section(header: Text("HISTORY")) {
                        ForEach(viewModel.searchHistory, id: \.self) { city in
                            Text(city)
                                .onTapGesture {
                                    viewModel.fetchWeather(for: city)
                                    selectionManager.selectedTab = 0
                                }
                        }
                    }
                }
            } else {
                
                Spacer()
                
            }
        }
    }
}
