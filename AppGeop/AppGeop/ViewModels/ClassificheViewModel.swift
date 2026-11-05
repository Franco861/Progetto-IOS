//
//  ClassificheViewModel.swift
//  AppGeop
//
//  Created by s18 on 05/11/26.
//

import SwiftUI

enum RankingCriterion: String, CaseIterable, Identifiable {
    case population = "Popolazione"
    case area = "Superficie"
    case density = "Densità"

    var id: String { rawValue }

    var unit: String {
        switch self {
        case .population: return "ab."
        case .area: return "km²"
        case .density: return "ab./km²"
        }
    }

    func format(_ value: Double) -> String {
        switch self {
        case .density:
            return value.formatted(.number.precision(.fractionLength(0...1)))
        default:
            return Int(value).formatted()
        }
    }
}

struct RankedCountry: Identifiable {
    let rank: Int
    let country: Country
    let value: Double
    let fraction: Double   // 0...1, rispetto al valore massimo della classifica

    var id: String { country.id }
}

@Observable
@MainActor
final class ClassificheViewModel {
    var criterion: RankingCriterion = .population
    var limit: Int = 10          // 0 = tutti i paesi
    var ascending: Bool = false
    var selectedRegion: String = "Tutti"
    var searchText: String = ""

    let limits = [10, 25, 50, 0]

    // L'API restituisce i continenti in inglese
    private let regionNames: [String: String] = [
        "Africa": "Africa",
        "Americas": "Americhe",
        "Asia": "Asia",
        "Europe": "Europa",
        "Oceania": "Oceania",
        "Antarctic": "Antartide"
    ]

    func regionLabel(_ region: String) -> String {
        regionNames[region] ?? region
    }

    func regions(from countries: [Country]) -> [String] {
        let found = Set(countries.map { $0.region }).filter { !$0.isEmpty }
        return ["Tutti"] + found.sorted()
    }

    private func value(of country: Country) -> Double? {
        switch criterion {
        case .population:
            return Double(country.population)
        case .area:
            return country.area
        case .density:
            guard let area = country.area, area > 0 else { return nil }
            return Double(country.population) / area
        }
    }

    func ranking(from countries: [Country]) -> [RankedCountry] {
        let pool = selectedRegion == "Tutti"
            ? countries
            : countries.filter { $0.region == selectedRegion }

        let valid: [(country: Country, value: Double)] = pool.compactMap { country in
            guard let v = value(of: country), v > 0 else { return nil }
            return (country, v)
        }

        let sorted = valid.sorted { ascending ? $0.value < $1.value : $0.value > $1.value }

        // Posizione reale in classifica (calcolata prima di ricerca e limite)
        let ranked = sorted.enumerated().map { index, item in
            (rank: index + 1, country: item.country, value: item.value)
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let shown: [(rank: Int, country: Country, value: Double)]
        let reference: Double

        if query.isEmpty {
            shown = limit == 0 ? ranked : Array(ranked.prefix(limit))
            reference = shown.map { $0.value }.max() ?? 1   // barra relativa ai paesi mostrati
        } else {
            shown = ranked.filter { item in
                item.country.name.common.localizedCaseInsensitiveContains(query) ||
                (item.country.capital?.contains { $0.localizedCaseInsensitiveContains(query) } ?? false)
            }
            reference = ranked.map { $0.value }.max() ?? 1  // con la ricerca, relativa all'intera classifica
        }

        return shown.map { item in
            let fraction = criterion == .density
                ? log10(1 + item.value) / log10(1 + reference)
                : item.value / reference
            return RankedCountry(rank: item.rank, country: item.country,
                                 value: item.value, fraction: fraction)
        }
    }
}
