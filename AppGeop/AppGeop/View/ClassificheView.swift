//
//  ClassificheView.swift
//  AppGeop
//
//  Created by s18 on 05/11/26.
//

import SwiftUI

struct ClassificheView: View {
    @Environment(CountryViewModel.self) private var viewModel
    @State private var rankVM = ClassificheViewModel()

    var body: some View {
        @Bindable var vm = rankVM
        let items = rankVM.ranking(from: viewModel.countries)

        NavigationStack {
            VStack(spacing: 0) {
                Picker("Criterio", selection: $vm.criterion) {
                    ForEach(RankingCriterion.allCases) { criterion in
                        Text(criterion.rawValue).tag(criterion)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top])
                .padding(.bottom, 8)

                regionChips

                if viewModel.isLoading && viewModel.countries.isEmpty {
                    Spacer()
                    ProgressView("Caricamento in corso...")
                    Spacer()
                } else if items.isEmpty {
                    if rankVM.searchText.isEmpty {
                        ContentUnavailableView(
                            "Nessun dato",
                            systemImage: "trophy",
                            description: Text("Non ci sono paesi da mostrare.")
                        )
                    } else {
                        ContentUnavailableView.search(text: rankVM.searchText)
                    }
                } else {
                    List(items) { item in
                        NavigationLink {
                            CountryDetailFullView(country: item.country)
                        } label: {
                            RankingRow(item: item, criterion: rankVM.criterion)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Classifiche")
            .searchable(text: $vm.searchText, prompt: "Cerca paese o capitale...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Mostra", selection: $vm.limit) {
                            ForEach(rankVM.limits, id: \.self) { n in
                                Text(n == 0 ? "Tutti" : "Primi \(n)").tag(n)
                            }
                        }
                        Toggle("Ordine crescente", isOn: $vm.ascending)
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }

    // Filtro per continente
    private var regionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(rankVM.regions(from: viewModel.countries), id: \.self) { region in
                    let isSelected = rankVM.selectedRegion == region
                    Button {
                        rankVM.selectedRegion = region
                    } label: {
                        Text(rankVM.regionLabel(region))
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }
}

struct RankingRow: View {
    let item: RankedCountry
    let criterion: RankingCriterion

    var body: some View {
        HStack(spacing: 12) {
            Text("\(item.rank)")
                .font(.headline)
                .foregroundStyle(item.rank <= 3 ? .orange : .secondary)
                .frame(width: 32, alignment: .trailing)

            AsyncImage(url: URL(string: item.country.flags.png)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.gray.opacity(0.3)
                }
            }
            .frame(width: 40, height: 27)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.country.name.common)
                    .font(.headline)
                Text("\(criterion.format(item.value)) \(criterion.unit)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ProgressView(value: item.fraction)
                    .tint(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ClassificheView()
        .environment(CountryViewModel())
}
