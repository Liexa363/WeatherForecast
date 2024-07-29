//
//  ContentView.swift
//  WeatherForecast
//
//  Created by Liexa MacBook Pro on 22.07.2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = WeatherViewModel()
    @StateObject var selectionManager = SelectionManager()
    
    var body: some View {
        TabView(selection: $selectionManager.selectedTab) {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            CitySearchView(viewModel: viewModel)
                .environmentObject(selectionManager)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(1)
        }
        .alert(item: $viewModel.errorMessage) { errorMessage in
            Alert(title: Text("Error"), message: Text(errorMessage.message), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            viewModel.selectionManager = selectionManager
            viewModel.requestUserLocation()
        }
    }
}

#Preview {
    ContentView()
}

