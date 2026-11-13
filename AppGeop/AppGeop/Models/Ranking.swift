//
//  Ranking.swift
//  AppGeop
//
//  Created by s18 on 13/11/26.
//

import Foundation

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
