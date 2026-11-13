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
}
