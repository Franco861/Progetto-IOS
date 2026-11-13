//
//  InfoView.swift
//  AppGeop
//
//  Created by s18 on 13/11/26.
//

import SwiftUI

// MARK: - Lista paesi
struct CountryInfoView: View {
    @Environment(CountryViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack(path: $vm.infoPath) {
            content
                .navigationTitle("Info Posti")
                .searchable(text: $vm.infoSearchText, prompt: "Cerca città o nazione...")
                .navigationDestination(for: Country.self) { country in
                    CountryDetailFullView(country: country)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.countries.isEmpty {
            ProgressView("Caricamento in corso...")
        } else if let message = viewModel.errorMessage, viewModel.countries.isEmpty {
            LoadErrorView(message: message) {
                Task { await viewModel.fetchCountries() }
            }
        } else if viewModel.infoFilteredCountries.isEmpty {
            ContentUnavailableView.search(text: viewModel.infoSearchText)
        } else {
            List(viewModel.infoFilteredCountries) { country in
                NavigationLink(value: country) {
                    HStack(spacing: 15) {
                        FlagImage(urlString: country.flags.png)
                            .frame(width: 45, height: 30)
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(country.localizedName)
                                .font(.headline)
                            Text("Capitale: \(country.capital?.first ?? "N/D")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            viewModel.toggleSave(country)
                        } label: {
                            Image(systemName: viewModel.isSaved(country) ? "bookmark.fill" : "bookmark")
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

// MARK: - Dettaglio completo
struct CountryDetailFullView: View {
    let country: Country
    @Environment(CountryViewModel.self) private var viewModel

    
    private var neighbors: [Country] {
        country.borders.compactMap { code in
            viewModel.countries.first { $0.cca3 == code }
        }
    }

    private var rows: [(icon: String, title: String, value: String)] {
        var r: [(icon: String, title: String, value: String)] = [
            ("building.2", "Capitale", country.capital?.joined(separator: ", ") ?? "N/D"),
            ("globe", "Continente", RegionNames.label(country.region))
        ]
        if let sub = country.subregion, !sub.isEmpty {
            r.append(("location", "Sottoregione", sub))
        }
        r.append(("person.3", "Popolazione", "\(country.population.formatted()) ab."))
        if let area = country.area {
            r.append(("square.dashed", "Superficie", "\(Int(area).formatted()) km²"))
        }
        if let density = country.density {
            let text = density.formatted(.number.precision(.fractionLength(0...1)))
            r.append(("person.2", "Densità", "\(text) ab./km²"))
        }
        if !country.languages.isEmpty {
            r.append(("bubble.left.and.bubble.right", "Lingue",
                      country.languages.joined(separator: ", ")))
        }
        if !country.currencies.isEmpty {
            let text = country.currencies.map { currency in
                currency.symbol.map { "\(currency.name) (\($0))" } ?? currency.name
            }.joined(separator: ", ")
            r.append(("eurosign.circle", "Valuta", text))
        }
        return r
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                FlagImage(urlString: country.flags.png, contentMode: .fit)
                    .frame(maxHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 5)

                Text(country.localizedName)
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                        InfoRow(icon: row.icon, title: row.title, value: row.value)
                        if index < rows.count - 1 {
                            Divider()
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                bordersSection

                Button {
                    viewModel.toggleSave(country)
                } label: {
                    Label(
                        viewModel.isSaved(country) ? "Rimuovi dai Salvati" : "Salva questo Posto",
                        systemImage: viewModel.isSaved(country) ? "bookmark.fill" : "bookmark"
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
        .navigationTitle(country.localizedName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var bordersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Paesi confinanti", systemImage: "arrow.triangle.branch")
                .font(.headline)

            if neighbors.isEmpty {
                Text("Nessun confine terrestre")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(neighbors) { neighbor in
                            NavigationLink(value: neighbor) {
                                Text(neighbor.localizedName)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    CountryInfoView()
        .environment(CountryViewModel())
}
