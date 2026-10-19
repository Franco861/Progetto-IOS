import SwiftUI
import MapKit

// 1. MODELLO DATI ROBUSTO (REST Countries API)
struct Country: Codable, Identifiable, Hashable {
    var id: String { cca3 }
    let cca3: String
    let name: CountryName
    let capital: [String]?
    let region: String
    let population: Int
    let flags: CountryFlags
    let latlng: [Double]?

    struct CountryName: Codable, Hashable {
        let common: String
        let official: String
    }

    struct CountryFlags: Codable, Hashable {
        let png: String
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latlng = latlng, latlng.count >= 2 else { return nil }
        return CLLocationCoordinate2D(latitude: latlng[0], longitude: latlng[1])
    }
}

// 2. VIEWMODEL CONDIVISO (@Observable)
@Observable
@MainActor
class CountryViewModel {
    var countries: [Country] = []
    var mapSearchText: String = ""
    var infoSearchText: String = ""
    var selectedRegion: String = "Tutti"
    var isLoading: Bool = false
    var selectedCountry: Country? = nil
    var activeTab: Int = 0 // 0: Mappa, 1: Info, 2: Profilo
    
    var savedCountryIDs: Set<String> = ["ITA", "FRA", "JPN"]

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

    func fetchCountries() async {
        guard countries.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "https://restcountries.com/v3.1/all?fields=cca3,name,capital,region,population,flags,latlng") else { return }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let decoded = try JSONDecoder().decode([Country].self, from: data)
                self.countries = decoded.sorted { $0.name.common < $1.name.common }
            }
        } catch {
            print("Errore nel caricamento dei dati dall'API:", error)
        }
    }
    
    func toggleSave(_ country: Country) {
        if savedCountryIDs.contains(country.cca3) {
            savedCountryIDs.remove(country.cca3)
        } else {
            savedCountryIDs.insert(country.cca3)
        }
    }
    
    func openInfoForCountry(_ country: Country) {
        selectedCountry = country
        infoSearchText = country.name.common
        withAnimation(.easeInOut(duration: 0.3)) {
            activeTab = 1
        }
    }
}

// 3. SCHERMATA 1: MAPPA E CONTINENTI
struct UnifiedMapView: View {
    @Environment(CountryViewModel.self) private var viewModel
    @State private var position: MapCameraPosition = .automatic
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        @Bindable var vm = viewModel

        ZStack(alignment: .top) {
            Map(position: $position, selection: $vm.selectedCountry) {
                ForEach(viewModel.mapFilteredCountries) { country in
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
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "globe")
                        .foregroundStyle(.blue)

                    TextField("Cerca continente o città/nazione...", text: $vm.mapSearchText)
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                        .onSubmit {
                            handleMapSearch()
                        }
                    
                    if !viewModel.mapSearchText.isEmpty {
                        Button(action: {
                            viewModel.mapSearchText = ""
                            viewModel.selectedRegion = "Tutti"
                            moveToRegion("Tutti")
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Menu {
                        Picker("Continente", selection: $vm.selectedRegion) {
                            ForEach(viewModel.regions, id: \.self) { region in
                                Text(region).tag(region)
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

                if isSearchFocused && !viewModel.mapSearchText.isEmpty {
                    let query = viewModel.mapSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
                    let matchingRegions = viewModel.regions.filter { $0.localizedCaseInsensitiveContains(query) }
                    let matchingCountries = viewModel.countries.filter {
                        $0.name.common.localizedCaseInsensitiveContains(query) ||
                        ($0.capital?.contains { $0.localizedCaseInsensitiveContains(query) } ?? false)
                    }

                    VStack(spacing: 0) {
                        ForEach(matchingRegions, id: \.self) { region in
                            Button {
                                viewModel.selectedRegion = region
                                viewModel.mapSearchText = region
                                moveToRegion(region)
                                isSearchFocused = false
                            } label: {
                                HStack {
                                    Image(systemName: "globe.europe.africa.fill").foregroundStyle(.blue)
                                    Text("Continente: \(region)").font(.headline).foregroundStyle(.primary)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                            }
                        }
                        
                        ForEach(matchingCountries.prefix(3)) { country in
                            Button {
                                isSearchFocused = false
                                viewModel.openInfoForCountry(country)
                            } label: {
                                HStack {
                                    Image(systemName: "building.2.fill").foregroundStyle(.orange)
                                    VStack(alignment: .leading) {
                                        Text(country.name.common).font(.headline).foregroundStyle(.primary)
                                        Text("Capitale: \(country.capital?.first ?? "N/D")").font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.right.circle.fill").foregroundStyle(.blue)
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
            .padding(.top, 10)
        }
        .sheet(item: $vm.selectedCountry) { country in
            CountryDetailSheet(country: country)
        }
    }

    private func handleMapSearch() {
        let query = viewModel.mapSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty { return }
        
        // 1. Cerca se corrisponde a un continente
        if let match = viewModel.regions.first(where: { $0.localizedCaseInsensitiveContains(query) }) {
            viewModel.selectedRegion = match
            moveToRegion(match)
            isSearchFocused = false
            return
        }
        
        // 2. Cerca se corrisponde a una nazione o capitale e reindirizza alla scheda Info
        if let countryMatch = viewModel.countries.first(where: {
            $0.name.common.localizedCaseInsensitiveContains(query) ||
            ($0.capital?.contains { $0.localizedCaseInsensitiveContains(query) } ?? false)
        }) {
            isSearchFocused = false
            viewModel.openInfoForCountry(countryMatch)
        }
    }

    private func moveToRegion(_ regionName: String) {
        guard let regionSpan = viewModel.regionCoordinates[regionName] else { return }
        withAnimation(.easeInOut(duration: 1.2)) {
            position = .region(regionSpan)
        }
    }
}

// 4. SCHERMATA 2: INFO CITTÀ E NAZIONI
struct CountryInfoView: View {
    @Environment(CountryViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.countries.isEmpty {
                    ProgressView("Caricamento in corso...")
                } else {
                    List(viewModel.infoFilteredCountries) { country in
                        NavigationLink {
                            CountryDetailFullView(country: country)
                        } label: {
                            HStack(spacing: 15) {
                                AsyncImage(url: URL(string: country.flags.png)) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        Color.gray.opacity(0.3)
                                    }
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

                                Button {
                                    viewModel.toggleSave(country)
                                } label: {
                                    Image(systemName: viewModel.savedCountryIDs.contains(country.cca3) ? "bookmark.fill" : "bookmark")
                                        .foregroundStyle(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Info Posti")
            .searchable(text: $vm.infoSearchText, prompt: "Cerca città o nazione...")
            .onSubmit(of: .search) {
                // Gestisce l'invio da tastiera sulla scheda Info
            }
        }
    }
}

// VISTA DETTAGLIATA
struct CountryDetailFullView: View {
    let country: Country
    @Environment(CountryViewModel.self) private var viewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AsyncImage(url: URL(string: country.flags.png)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                    } else {
                        Color.gray.opacity(0.3)
                    }
                }
                .frame(maxHeight: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 5)

                Text(country.name.official)
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    HStack {
                        Label("Capitale", systemImage: "building.2")
                        Spacer()
                        Text(country.capital?.first ?? "N/D").bold()
                    }
                    Divider()
                    HStack {
                        Label("Continente", systemImage: "globe")
                        Spacer()
                        Text(country.region).bold()
                    }
                    Divider()
                    HStack {
                        Label("Popolazione", systemImage: "person.3")
                        Spacer()
                        Text("\(country.population.formatted()) ab.").bold()
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Button(action: {
                    viewModel.toggleSave(country)
                }) {
                    Label(
                        viewModel.savedCountryIDs.contains(country.cca3) ? "Rimuovi dai Salvati" : "Salva questo Posto",
                        systemImage: viewModel.savedCountryIDs.contains(country.cca3) ? "bookmark.fill" : "bookmark"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 10)
            }
            .padding()
        }
        .navigationTitle(country.name.common)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// SHEET DI DETTAGLIO RAPIDO
struct CountryDetailSheet: View {
    let country: Country
    @Environment(CountryViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 16) {
            AsyncImage(url: URL(string: country.flags.png)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFit()
                } else {
                    Color.gray.opacity(0.3)
                }
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

            Button(action: {
                viewModel.toggleSave(country)
            }) {
                Label(
                    viewModel.savedCountryIDs.contains(country.cca3) ? "Rimuovi dai Salvati" : "Salva Posto",
                    systemImage: viewModel.savedCountryIDs.contains(country.cca3) ? "bookmark.fill" : "bookmark"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)

            Spacer()
        }
        .padding()
        .presentationDetents([.height(340)])
    }
}

// 5. SCHERMATA 3: PROFILO
struct ProfileView: View {
    @Environment(CountryViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mario Rossi")
                                .font(.title3)
                                .bold()
                            Text("mario.rossi@example.com")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Posti Salvati (\(viewModel.savedCountries.count))") {
                    if viewModel.savedCountries.isEmpty {
                        Text("Nessun posto salvato al momento.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.savedCountries) { country in
                            HStack(spacing: 12) {
                                AsyncImage(url: URL(string: country.flags.png)) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        Color.gray.opacity(0.3)
                                    }
                                }
                                .frame(width: 35, height: 22)
                                .clipShape(RoundedRectangle(cornerRadius: 3))

                                VStack(alignment: .leading) {
                                    Text(country.name.common)
                                        .font(.headline)
                                    Text("Capitale: \(country.capital?.first ?? "N/D")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button {
                                    viewModel.toggleSave(country)
                                } label: {
                                    Image(systemName: "bookmark.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                Section("Impostazioni") {
                    Label("Notifiche", systemImage: "bell")
                    Label("Privacy e Sicurezza", systemImage: "lock")
                    Label("Modalità Scura", systemImage: "moon")
                }
            }
            .navigationTitle("Profilo")
        }
    }
}

// 6. CONTENT VIEW CON BARRA A 3 SCHEDE
struct ContentView: View {
    @State private var viewModel = CountryViewModel()

    var body: some View {
        @Bindable var vm = viewModel

        TabView(selection: $vm.activeTab) {
            UnifiedMapView()
                .tabItem {
                    Label("Mappa", systemImage: "map.fill")
                }
                .tag(0)

            CountryInfoView()
                .tabItem {
                    Label("Info", systemImage: "info.circle.fill")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Label("Profilo", systemImage: "person.fill")
                }
                .tag(2)
        }
        .environment(viewModel)
        .task {
            await viewModel.fetchCountries()
        }
    }
}

#Preview {
    ContentView()
}
