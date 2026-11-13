import SwiftUI

struct VisitedView: View {
    @Environment(CountryViewModel.self) private var viewModel
    @State private var searchText: String = ""

    // Tutti i paesi visitati
    private var allVisitedCountries: [Country] {
        viewModel.visitedCountries
    }

    // Filtra SOLO tra i paesi visitati in base al testo cercato
    private var filteredVisitedCountries: [Country] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return allVisitedCountries
        } else {
            return allVisitedCountries.filter { country in
                let matchName = country.name.common.localizedCaseInsensitiveContains(query)
                let matchCapital = country.capital?.contains { $0.localizedCaseInsensitiveContains(query) } ?? false
                return matchName || matchCapital
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if allVisitedCountries.isEmpty {
                    // Stato vuoto: nessun paese ancora visitato
                    ContentUnavailableView {
                        Label("Nessun paese visitato", systemImage: "airplane.departure")
                    } description: {
                        Text("I paesi che segni come visitati appariranno qui nel tuo passaporto.")
                    }
                } else if filteredVisitedCountries.isEmpty {
                    // Ricerca senza risultati tra i visitati
                    ContentUnavailableView.search(text: searchText)
                } else {
                    // Lista dei paesi visitati filtrati
                    List {
                        Section("Totale visitati: \(allVisitedCountries.count)") {
                            ForEach(filteredVisitedCountries) { country in
                                HStack(spacing: 12) {
                                    FlagImage(urlString: country.flags.png)
                                        .frame(width: 40, height: 26)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(country.name.common)
                                            .font(.headline)
                                        Text("Capitale: \(country.capital?.first ?? "N/D")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    // Tasto rapido per rimuovere dai visitati
                                    Button {
                                        viewModel.toggleVisited(country)
                                    } label: {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundStyle(.green)
                                            .font(.title3)
                                    }
                                    .buttonStyle(.borderless)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.openInfoForCountry(country)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Paesi Visitati")
            .searchable(text: $searchText, prompt: "Cerca tra i paesi visitati...")
        }
    }
}

#Preview {
    VisitedView()
        .environment(CountryViewModel())
}
