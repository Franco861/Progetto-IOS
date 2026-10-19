//
//  ContentView.swift
//  AppGeop
//
//  Created by s18 on 15/10/26.
//

import SwiftUI
import MapKit

// MARK: - 1. MODELLO DATI (REST Countries)
struct Country: Codable, Identifiable, Hashable {
    var id: String { cca3 }
    let cca3: String
    let name: CountryName
    let capital: [String]?
    let region: String
    let population: Int
    let latlng: [Double]?
    let flags: CountryFlags

    struct CountryName: Codable, Hashable {
        let common: String
        let official: String
    }

    struct CountryFlags: Codable, Hashable {
        let png: String
    }

    // Convertitore comodo da latlng [Double] a CLLocationCoordinate2D per MapKit
    var coordinate: CLLocationCoordinate2D? {
        guard let latlng = latlng, latlng.count >= 2 else { return nil }
        return CLLocationCoordinate2D(latitude: latlng[0], longitude: latlng[1])
    }
}

// MARK: - 2. VIEWMODEL CONDIVISO (API & Logica Filtri)
@MainActor
class CountryViewModel: ObservableObject {
    @Published var countries: [Country] = []
    @Published var searchText: String = ""
    @Published var selectedRegion: String = "Tutti"
    @Published var isLoading: Bool = false
    @Published var selectedCountry: Country? = nil

    let regions = ["Tutti", "Africa", "Americas", "Asia", "Europe", "Oceania"]

    // Proprietà calcolata per applicare ricerca e filtri in tempo reale
    var filteredCountries: [Country] {
        countries.filter { country in
            let matchesSearch = searchText.isEmpty || country.name.common.localizedCaseInsensitiveContains(searchText)
            let matchesRegion = (selectedRegion == "Tutti") || (country.region == selectedRegion)
            return matchesSearch && matchesRegion
        }
    }

    func fetchCountries() async {
        guard countries.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "https://restcountries.com/v3.1/all") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([Country].self, from: data)
            self.countries = decoded.sorted { $0.name.common < $1.name.common }
        } catch {
            print("Errore nel caricamento dei dati:", error)
        }
    }
}

// MARK: - 3. SCHERMATA 1: LISTA E RICERCA
struct CountryListView: View {
    @EnvironmentObject var viewModel: CountryViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Caricamento nazioni...")
                } else {
                    List(viewModel.filteredCountries) { country in
                        HStack(spacing: 15) {
                            // Bandiera remota
                            AsyncImage(url: URL(string: country.flags.png)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 45, height: 30)
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(country.name.common)
                                    .font(.headline)
                                Text("Capitale: \(country.capital?.first ?? "N/D")")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(country.region)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                                
                                Text("\(country.population.formatted()) ab.")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Ricerca")
            .searchable(text: $viewModel.searchText, prompt: "Cerca una nazione...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Regione", selection: $viewModel.selectedRegion) {
                            ForEach(viewModel.regions, id: \.self) { region in
                                Text(region).tag(region)
                            }
                        }
                    } label: {
                        Label("Filtra", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
}

struct CountryMapView: View {
    @EnvironmentObject var viewModel: CountryViewModel
    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $position, selection: $viewModel.selectedCountry) {
            ForEach(viewModel.filteredCountries) { country in
                if let coord = country.coordinate {
                    Marker(country.name.common, coordinate: coord)
                        .tag(country)
                }
            }
        }
        .mapControls {
            MapCompass()
            MapPitchToggle()
        }
        .sheet(item: $viewModel.selectedCountry) { country in
            VStack(spacing: 16) {
                AsyncImage(url: URL(string: country.flags.png)) { image in
                    image.image?.resizable().scaledToFit()
                }
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(country.name.official)
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)

                HStack(spacing: 30) {
                    VStack {
                        Text("Capitale").font(.caption).foregroundStyle(.secondary)
                        Text(country.capital?.first ?? "N/D").font(.headline)
                    }
                    VStack {
                        Text("Popolazione").font(.caption).foregroundStyle(.secondary)
                        Text(country.population.formatted()).font(.headline)
                    }
                }

                Spacer()
            }
            .padding()
            .presentationDetents([.height(300)])
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = CountryViewModel()

    var body: some View {
        TabView {
            CountryListView()
                .tabItem {
                    Label("Nazioni", systemImage: "globe.europe.africa.fill")
                }

            CountryMapView()
                .tabItem {
                    Label("Mappa", systemImage: "map.fill")
                }
        }
        .environmentObject(viewModel)
        .task {
            await viewModel.fetchCountries()
        }
    }
}


#Preview {
    ContentView()
}
