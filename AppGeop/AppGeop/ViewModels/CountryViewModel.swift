//
//  CountryViewModel.swift
//  AppGeop
//
//  Created by s18 on 13/11/26.
//

import SwiftUI
import MapKit

@Observable
@MainActor
class CountryViewModel {

    // MARK: - Dati
    var countries: [Country] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // MARK: - Navigazione
    var activeTab: AppTab = .map
    var infoPath: [Country] = []              // pila di navigazione della scheda Info

    // MARK: - Mappa
    var mapSearchText: String = ""
    var selectedRegion: String = "Tutti"
    var mapSelectedCountry: Country? = nil    // paese toccato sulla mappa (apre la sheet)

    // MARK: - Info
    var infoSearchText: String = ""

    // MARK: - Preferiti
    var savedCountryIDs: Set<String> = []
    private let savedKey = "savedCountryIDs"

    // MARK: - Visitati
    var visitedCountryIDs: Set<String> = []
    private let visitedKey = "visitedCountryIDs"

    init() {
        savedCountryIDs = Set(UserDefaults.standard.stringArray(forKey: savedKey) ?? [])
        visitedCountryIDs = Set(UserDefaults.standard.stringArray(forKey: visitedKey) ?? [])
    }

    // MARK: - Costanti
    let regions = ["Tutti", "Africa", "Americas", "Asia", "Europe", "Oceania"]

    let regionCoordinates: [String: MKCoordinateRegion] = [
        "Tutti": MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20.0, longitude: 0.0),
            span: MKCoordinateSpan(latitudeDelta: 120.0, longitudeDelta: 120.0)
        ),
        "Africa": MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 2.0, longitude: 16.0),
            span: MKCoordinateSpan(latitudeDelta: 60.0, longitudeDelta: 60.0)
        ),
        "Americas": MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 15.0, longitude: -85.0),
            span: MKCoordinateSpan(latitudeDelta: 90.0, longitudeDelta: 90.0)
        ),
        "Asia": MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 34.0, longitude: 100.0),
            span: MKCoordinateSpan(latitudeDelta: 70.0, longitudeDelta: 70.0)
        ),
        "Europe": MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 50.0, longitude: 15.0),
            span: MKCoordinateSpan(latitudeDelta: 35.0, longitudeDelta: 35.0)
        ),
        "Oceania": MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -22.0, longitude: 140.0),
            span: MKCoordinateSpan(latitudeDelta: 50.0, longitudeDelta: 50.0)
        )
    ]

    // MARK: - Liste filtrate
    var mapFilteredCountries: [Country] {
        if selectedRegion == "Tutti" {
            return countries
        } else {
            return countries.filter { $0.region == selectedRegion }
        }
    }

    var infoFilteredCountries: [Country] {
        let query = infoSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return countries
        } else {
            return countries.filter { country in
                let matchName = country.name.common.localizedCaseInsensitiveContains(query)
                let matchCapital = country.capital?.contains { $0.localizedCaseInsensitiveContains(query) } ?? false
                return matchName || matchCapital
            }
        }
    }

    var savedCountries: [Country] {
        countries.filter { savedCountryIDs.contains($0.cca3) }
    }

    // Paesi visitati, in ordine alfabetico
    var visitedCountries: [Country] {
        countries
            .filter { visitedCountryIDs.contains($0.cca3) }
            .sorted { $0.name.common < $1.name.common }
    }

    // MARK: - Caricamento dati
    func fetchCountries() async {
        guard countries.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            countries = try await CountryService.fetchAll()
        } catch {
            errorMessage = "Impossibile caricare i paesi. Controlla la connessione e riprova."
            print("Errore nel caricamento dei dati dall'API:", error)
        }
    }

    // MARK: - Preferiti
    func isSaved(_ country: Country) -> Bool {
        savedCountryIDs.contains(country.cca3)
    }

    func toggleSave(_ country: Country) {
        if savedCountryIDs.contains(country.cca3) {
            savedCountryIDs.remove(country.cca3)
        } else {
            savedCountryIDs.insert(country.cca3)
        }
        UserDefaults.standard.set(Array(savedCountryIDs), forKey: savedKey)
    }

    // MARK: - Paesi Visitati (stessa logica dei Preferiti)
    func isVisited(_ country: Country) -> Bool {
        visitedCountryIDs.contains(country.cca3)
    }

    func toggleVisited(_ country: Country) {
        if visitedCountryIDs.contains(country.cca3) {
            visitedCountryIDs.remove(country.cca3)
        } else {
            visitedCountryIDs.insert(country.cca3)
        }
        UserDefaults.standard.set(Array(visitedCountryIDs), forKey: visitedKey)
    }

    // MARK: - Navigazione tra schede
    func openInfoForCountry(_ country: Country) {
        infoPath = [country]
        withAnimation(.easeInOut(duration: 0.3)) {
            activeTab = .info
        }
    }
}
