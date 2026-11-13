//
//  Country.swift
//  AppGeop
//
//  Created by s18 on 13/11/26.
//

import Foundation
import CoreLocation

struct Country: Codable, Identifiable, Hashable {
    var id: String { cca3 }
    let cca3: String
    let cca2: String?
    let name: CountryName
    let capital: [String]?
    let region: String
    let subregion: String?
    let population: Int
    let flags: CountryFlags
    let latlng: [Double]?
    let area: Double?
    let borders: [String]
    let languages: [String]
    let currencies: [Currency]

    struct CountryName: Codable, Hashable { let common: String; let official: String }
    struct CountryFlags: Codable, Hashable { let png: String }
    struct Currency: Codable, Hashable { let name: String; let symbol: String? }

    var coordinate: CLLocationCoordinate2D? {
        guard let latlng, latlng.count >= 2 else { return nil }
        return CLLocationCoordinate2D(latitude: latlng[0], longitude: latlng[1])
    }

    // Condivisa da Classifiche e dal dettaglio
    var density: Double? {
        guard let area, area > 0 else { return nil }
        return Double(population) / area
    }
    
    private static let italianLocale = Locale(identifier: "it_IT")

        /// Nome del paese tradotto in italiano tramite il codice ISO alpha-2
        var localizedName: String {
            guard let cca2,
                  let translated = Self.italianLocale.localizedString(forRegionCode: cca2)
            else {
                return name.common
            }
            return translated
        }

        /// Ricerca case-insensitive e senza accenti su nome IT, nome EN e capitale
        func matches(query: String) -> Bool {
            let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
            if localizedName.range(of: query, options: options) != nil { return true }
            if name.common.range(of: query, options: options) != nil { return true }
            if capital?.contains(where: { $0.range(of: query, options: options) != nil }) == true {
                return true
            }
            return false
        }
}
