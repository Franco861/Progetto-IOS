//
//  MapView.swift
//  AppGeop
//
//  Created by s18 on 13/11/26.
//

import SwiftUI
import MapKit

// MARK: - Schermata Mappa
struct UnifiedMapView: View {
    @Environment(CountryViewModel.self) private var viewModel
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20.0, longitude: 0.0),
            span: MKCoordinateSpan(latitudeDelta: 120.0, longitudeDelta: 120.0)
        )
    )
    @State private var showSheet = false
    @State private var isLocating = false
    @State private var statusMessage: String?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        @Bindable var vm = viewModel

        ZStack(alignment: .top) {
            MapReader { proxy in
                Map(position: $position) {
                    // Un solo segnaposto: quello del paese selezionato
                    if let country = viewModel.mapSelectedCountry,
                       let coord = country.coordinate {
                        Marker(country.name.common, coordinate: coord)
                    }
                }
                .mapControls {
                    MapCompass()
                    MapPitchToggle()
                }
                .onTapGesture { point in
                    guard let coord = proxy.convert(point, from: .local) else { return }
                    isSearchFocused = false
                    Task { await selectCountry(at: coord) }
                }
            }
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 8) {
                // Barra di ricerca
                HStack {
                    Image(systemName: "globe")
                        .foregroundStyle(.blue)

                    TextField("Cerca continente o nazione...", text: $vm.mapSearchText)
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                        .onSubmit { handleMapSearch() }

                    if !viewModel.mapSearchText.isEmpty {
                        Button {
                            clearSearch()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Menu {
                        Picker("Continente", selection: $vm.selectedRegion) {
                            ForEach(viewModel.regions, id: \.self) { region in
                                Text(regionTitle(region)).tag(region)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title3)
                            .foregroundStyle(viewModel.selectedRegion != "Tutti" ? .blue : .primary)
                    }
                    .onChange(of: viewModel.selectedRegion) { _, newRegion in
                        moveToRegion(newRegion)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                .padding(.horizontal)

                suggestions
            }
            .padding(.top, 10)

            // Messaggio temporaneo (oceano, errore di rete...)
            if let statusMessage {
                VStack {
                    Spacer()
                    Text(statusMessage)
                        .font(.subheadline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
            }
        }
        .sheet(isPresented: $showSheet) {
            if let country = viewModel.mapSelectedCountry {
                CountryDetailSheet(country: country)
            }
        }
    }

    // MARK: - Suggerimenti di ricerca
    @ViewBuilder
    private var suggestions: some View {
        let query = viewModel.mapSearchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if isSearchFocused && !query.isEmpty {
            let regions = matchingRegions(query)
            let countries = matchingCountries(query)

            VStack(spacing: 0) {
                ForEach(regions, id: \.self) { region in
                    Button {
                        viewModel.selectedRegion = region
                        viewModel.mapSearchText = RegionNames.label(region)
                        moveToRegion(region)
                        isSearchFocused = false
                    } label: {
                        HStack {
                            Image(systemName: "globe.europe.africa.fill").foregroundStyle(.blue)
                            Text("Continente: \(RegionNames.label(region))")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                }

                ForEach(countries.prefix(3)) { country in
                    Button {
                        focusOn(country)
                    } label: {
                        HStack {
                            Image(systemName: "building.2.fill").foregroundStyle(.orange)
                            VStack(alignment: .leading) {
                                Text(country.name.common)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Capitale: \(country.capital?.first ?? "N/D")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "mappin.circle.fill").foregroundStyle(.red)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        }
    }

    // MARK: - Tocco sulla mappa → paese (geocodifica inversa)
    private func selectCountry(at coord: CLLocationCoordinate2D) async {
        guard !isLocating else { return }   // evita richieste in parallelo
        isLocating = true
        defer { isLocating = false }

        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)

        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)

            guard let code = placemarks.first?.isoCountryCode,
                  let country = viewModel.countries.first(where: {
                      $0.cca2?.uppercased() == code.uppercased()
                  })
            else {
                deselect()
                showMessage("Nessun paese in questo punto")
                return
            }

            viewModel.mapSelectedCountry = country
            showSheet = true
        } catch {
            if (error as? CLError)?.code == .geocodeFoundNoResult {
                deselect()
                showMessage("Nessun paese in questo punto")
            } else {
                showMessage("Impossibile riconoscere il paese. Riprova tra poco.")
            }
        }
    }

    private func deselect() {
        viewModel.mapSelectedCountry = nil
        showSheet = false
    }

    // MARK: - Ricerca
    private func matchingRegions(_ query: String) -> [String] {
        viewModel.regions.filter { region in
            region != "Tutti" &&
            (region.localizedCaseInsensitiveContains(query) ||
             RegionNames.label(region).localizedCaseInsensitiveContains(query))
        }
    }

    private func matchingCountries(_ query: String) -> [Country] {
        viewModel.countries.filter {
            $0.name.common.localizedCaseInsensitiveContains(query) ||
            ($0.capital?.contains { $0.localizedCaseInsensitiveContains(query) } ?? false)
        }
    }

    private func handleMapSearch() {
        let query = viewModel.mapSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        if let region = matchingRegions(query).first {
            viewModel.selectedRegion = region
            moveToRegion(region)
            isSearchFocused = false
        } else if let country = matchingCountries(query).first {
            focusOn(country)
        }
    }

    private func clearSearch() {
        viewModel.mapSearchText = ""
        viewModel.selectedRegion = "Tutti"
        deselect()
        moveToRegion("Tutti")
    }

    // Mostra un paese trovato con la ricerca: marker, zoom e sheet
    private func focusOn(_ country: Country) {
        isSearchFocused = false
        viewModel.mapSearchText = country.name.common
        viewModel.mapSelectedCountry = country

        if let coord = country.coordinate {
            withAnimation(.easeInOut(duration: 1.0)) {
                position = .region(
                    MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 25, longitudeDelta: 25)
                    )
                )
            }
        }
        showSheet = true
    }

    private func moveToRegion(_ regionName: String) {
        guard let region = viewModel.regionCoordinates[regionName] else { return }
        withAnimation(.easeInOut(duration: 1.2)) {
            position = .region(region)
        }
    }

    private func regionTitle(_ region: String) -> String {
        region == "Tutti" ? "Tutti" : RegionNames.label(region)
    }

    private func showMessage(_ text: String) {
        withAnimation { statusMessage = text }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            if statusMessage == text {
                withAnimation { statusMessage = nil }
            }
        }
    }
}

// MARK: - Sheet con la breve descrizione del paese
struct CountryDetailSheet: View {
    let country: Country
    @Environment(CountryViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    private var summary: String {
        var text = country.name.common
        if let capital = country.capital?.first {
            text += " ha come capitale \(capital)"
        } else {
            text += " è un paese"
        }
        text += " e conta circa \(country.population.formatted()) abitanti"
        if let area = country.area {
            text += " su \(Int(area).formatted()) km²"
        }
        return text + "."
    }

    var body: some View {
        VStack(spacing: 14) {
            FlagImage(urlString: country.flags.png, contentMode: .fit)
                .frame(height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(country.name.official)
                .font(.title3)
                .bold()
                .multilineTextAlignment(.center)

            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                dismiss()
                viewModel.openInfoForCountry(country)
            } label: {
                Label("Vai alle info", systemImage: "info.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                viewModel.toggleSave(country)
            } label: {
                Label(
                    viewModel.isSaved(country) ? "Rimuovi dai Salvati" : "Salva Posto",
                    systemImage: viewModel.isSaved(country) ? "bookmark.fill" : "bookmark"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                viewModel.toggleVisited(country)
            } label: {
                Label(
                    viewModel.isVisited(country) ? "Rimuovi dai Visitati" : "Aggiungi ai Visitati",
                    systemImage: viewModel.isVisited(country) ? "checkmark.seal.fill" : "checkmark.seal"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(viewModel.isVisited(country) ? .red : .green)

            Spacer()
        }
        .padding()
        .presentationDetents([.height(430)])
        .presentationBackgroundInteraction(.enabled)
    }
}

#Preview {
    UnifiedMapView()
        .environment(CountryViewModel())
}
