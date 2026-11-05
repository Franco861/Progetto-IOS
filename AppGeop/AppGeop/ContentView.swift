

import SwiftUI
import MapKit

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

//LOGIN
struct AnimatedMapBackground: View {
    private let latIniziale = 48.8566
    private let lonIniziale = 2.3522
    
    private let latFinale = 19.43260
    private let lonFinale = 99.1332

    var body: some View {
      
        TimelineView(.animation) { context in
            let date = context.date.timeIntervalSince1970
            
            let progress = (sin(date / 30.0 * .pi) + 1.0) / 2.0
            
            let currentLat = latIniziale + (latFinale - latIniziale) * progress
            let currentLon = lonIniziale + (lonFinale - lonIniziale) * progress
            let currentHeading = progress * 20.0

            Map(position: .constant(.camera(MapCamera(
                centerCoordinate: CLLocationCoordinate2D(latitude: currentLat, longitude: currentLon),
                distance: 13_000_000,
                heading: currentHeading,
                pitch: 0
            ))))
            .overlay(Color.black.opacity(0.6))
            .disabled(true)
            .ignoresSafeArea()
        }
    }
}

struct LoginView: View {
    
    @State var username: String = ""
    @State var password: String = ""
    @AppStorage("isLoggedIn") private var isLogged: Bool = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    
    func checkCred (password: String, username: String) {
        if (password.lowercased() == "admin" &&
            username.lowercased() == "admin") {
            isLogged = true;
        }
        
        
        else{
            alertMessage = "Credenziali errate"
            showAlert = true
        }
    }
    
    
    var body: some View {
        ZStack{
            AnimatedMapBackground()
            VStack{
                    HStack{
                    TextField("", text: $username, prompt: Text("Inserisci username")
                        .foregroundColor(.white.opacity(0.7))
                    )
                    
                    Image(systemName: "person.fill")
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .padding(10)
                .background(Color.gray.opacity(0.35))
                .cornerRadius(10)

                
                HStack{
                    SecureField("", text: $password, prompt: Text("Inserisci password")
                        .foregroundColor(.white.opacity(0.7))
                    )
                    
                    Image(systemName: "lock.fill")
                        .foregroundColor(.white.opacity(0.7))
                        
                }
                
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                
                .padding(10)
                .background(Color.gray.opacity(0.35))
                .cornerRadius(10)

                
                Button(action: {
                    checkCred(password: password, username: username)
                }
                ){
                    Text("Login")
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(10)
                        .background(Color.blue)
                        .cornerRadius(10)
                    
                }
            }
            .foregroundColor(Color.white)
            .padding(90)
        }
        .alert("Attenzione", isPresented: $showAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(alertMessage)
                }
        }
        
}





struct SignupView: View {
    @State var nome: String = ""
    @State var cognome: String = ""
    @State var password: String = ""
    @State var email: String = ""
    @State var eta: Int = 0
    @State var campi: Bool = false
    @State private var navigazione: Bool = false
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    enum Field {
            case nome, cognome, email, password
        }
    @FocusState private var focusedField: Field?
    
    func checkCampi(nome: String, cognome: String, password: String, email: String, eta: Int){
        if(
            nome.count > 4 &&
            cognome.count > 4 &&
            password.count > 4 &&
            email.count > 4 &&
            eta>0
        ){
            campi = true;
        }
        
        else{
            campi = false
        }
        
    }
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedMapBackground()
                
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        TextField("", text: $nome, prompt: Text("Nome")
                            .foregroundColor(.white.opacity(0.7)))
                        .focused($focusedField, equals: .nome)
                        .padding(10)
                        .background(focusedField == .nome ? Color.gray.opacity(0.6) : Color.gray.opacity(0.35))
                        .cornerRadius(10)
                            

                        
                        TextField("", text: $cognome, prompt: Text("Cognome").foregroundColor(.white))
                            .focused($focusedField, equals: .cognome)
                            .padding(10)
                            .background(focusedField == .cognome ? Color.gray.opacity(0.6) : Color.gray.opacity(0.35))
                            .cornerRadius(10)

                    }
                    
                    TextField("", text: $email, prompt: Text("Email").foregroundColor(.white))
                        .focused($focusedField, equals: .email)
                        .padding(10)
                        .background(focusedField == .email ? Color.gray.opacity(0.6) : Color.gray.opacity(0.35))
                        .cornerRadius(10)
                    
                    SecureField("", text: $password, prompt: Text("Password").foregroundColor(.white))
                        .focused($focusedField, equals: .password)
                        .padding(10)
                        .background(focusedField == .password ? Color.gray.opacity(0.6) : Color.gray.opacity(0.35))
                        .cornerRadius(10)
                    
                    Button(action: {
                        checkCampi(nome: nome, cognome: cognome, password: password, email: email, eta: eta)
                        
                        if campi {
                            navigazione = true
                        }
                        
                        else {
                            
                        }
                    }) {
                        Text("Signup")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(10)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $navigazione) {
                CountryListView()
            }
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
    @AppStorage("isLoggedIn") private var isLogged: Bool = false
    @StateObject private var viewModel = CountryViewModel()
    
    
    var body: some View {
        if isLogged {
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
        
        else {
            LoginView()
        }
    }
}


#Preview {
    SignupView()
    //ContentView().onAppear {
      //  UserDefaults.standard.set(false, forKey: "isLoggedIn")
    //}
}
