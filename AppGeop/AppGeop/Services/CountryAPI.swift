//
//  CountryAPI.swift
//  AppGeop
//
//  Created by s18 on 05/11/26.
//

import Foundation

// Risposta della v5: { "data": { "objects": [...], "meta": {...} } }
struct CountriesResponse: Decodable {
    struct DataBlock: Decodable {
        let objects: [CountryDTO]
        let meta: Meta
    }
    struct Meta: Decodable {
        let total: Int
        let more: Bool
    }
    let data: DataBlock
}

struct CountryDTO: Decodable {
    let alpha3: String
    let alpha2: String?
    let commonName: String
    let officialName: String
    let capitals: [String]
    let region: String
    let population: Int
    let areaKm: Double?
    let lat: Double?
    let lng: Double?
    let flagPNG: String?
    let subregion: String?
    let borders: [String]
    let languages: [String]
    let currencies: [Country.Currency]

    private enum CodingKeys: String, CodingKey {
        case names, codes, capitals, region, subregion, population, area
        case coordinates, flag, borders, languages, currencies
    }
    private struct Names: Decodable { let common: String; let official: String? }
    private struct Codes: Decodable { let alpha_2: String?; let alpha_3: String }
    private struct Area: Decodable { let kilometers: Double? }
    private struct Coordinates: Decodable { let lat: Double?; let lng: Double? }
    private struct Flag: Decodable { let url_png: String? }
    
    private struct Language: Decodable { let name: String? }
    
    private struct CurrencyDTO: Decodable { let name: String?; let symbol: String? }

    // Una capitale può arrivare come oggetto {name: ...} o come semplice stringa
    private struct Capital: Decodable {
        let name: String?

        private enum CodingKeys: String, CodingKey { case name }

        init(from decoder: Decoder) throws {
            if let single = try? decoder.singleValueContainer(),
               let text = try? single.decode(String.self) {
                name = text
                return
            }
            let container = try? decoder.container(keyedBy: CodingKeys.self)
            name = try? container?.decode(String.self, forKey: .name)
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // Obbligatori
        let names = try c.decode(Names.self, forKey: .names)
        let codes = try c.decode(Codes.self, forKey: .codes)
        commonName = names.common
        officialName = names.official ?? names.common
        alpha3 = codes.alpha_3
        alpha2 = codes.alpha_2

        // Facoltativi: se mancano o hanno un formato inatteso non blocco tutto
        capitals = (try? c.decode([Capital].self, forKey: .capitals))?.compactMap { $0.name } ?? []
        region = (try? c.decode(String.self, forKey: .region)) ?? ""
        let pop = (try? c.decode(Double.self, forKey: .population)) ?? 0
        population = pop.isFinite ? Int(pop) : 0
        areaKm = (try? c.decode(Area.self, forKey: .area))?.kilometers
        let coords = try? c.decode(Coordinates.self, forKey: .coordinates)
        lat = coords?.lat
        lng = coords?.lng
        flagPNG = (try? c.decode(Flag.self, forKey: .flag))?.url_png
        subregion = try? c.decode(String.self, forKey: .subregion)
        borders = (try? c.decode([String].self, forKey: .borders)) ?? []
        languages = ((try? c.decode([Language].self, forKey: .languages)) ?? []).compactMap { $0.name }
        currencies = ((try? c.decode([CurrencyDTO].self, forKey: .currencies)) ?? []).compactMap { dto in
            dto.name.map { Country.Currency(name: $0, symbol: dto.symbol) }
        }
    }

    // Traduzione verso il modello usato dall'app
    func toCountry() -> Country {
        // Se manca il PNG, uso la CDN gratuita delle bandiere
        let flagURL = flagPNG
            ?? alpha2.map { "https://flags.restcountries.com/v5/w320/\($0.lowercased()).png" }
            ?? ""

        var latlng: [Double]? = nil
        if let lat, let lng { latlng = [lat, lng] }

        return Country(
            cca3: alpha3,
            cca2: alpha2,
            name: .init(common: commonName, official: officialName),
            capital: capitals.isEmpty ? nil : capitals,
            region: region,
            subregion: subregion,
            population: population,
            flags: .init(png: flagURL),
            latlng: latlng,
            area: areaKm,
            borders: borders,
            languages: languages,
            currencies: currencies
        )
    }
}
