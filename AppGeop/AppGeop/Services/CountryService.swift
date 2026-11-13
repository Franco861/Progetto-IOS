//
//  CountryService.swift
//  AppGeop
//
//  Created by s18 on 13/11/26.
//

import Foundation

enum CountryService {
    private static let baseURL = "https://api.restcountries.com/countries/v5"
    private static let fields = "names.common,names.official,codes.alpha_2,codes.alpha_3,capitals,region,subregion,population,area.kilometers,coordinates,flag.url_png,borders,languages,currencies"

    static func fetchAll() async throws -> [Country] {
        var all: [Country] = []
        var offset = 0
        let limit = 100
        while offset < 1000 {
            let page = try await fetchPage(limit: limit, offset: offset)
            all += page.data.objects.compactMap { $0.toCountry() }
            if !page.data.meta.more || page.data.objects.isEmpty { break }
            offset += limit
        }
        return all.sorted {
            $0.localizedName.localizedStandardCompare($1.localizedName) == .orderedAscending
        }
    }

    private static func fetchPage(limit: Int, offset: Int) async throws -> CountriesResponse {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "response_fields", value: fields)
        ]
        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(APIConfig.restCountriesKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard http.statusCode == 200 else {
            print("HTTP \(http.statusCode):", String(data: data, encoding: .utf8) ?? "")
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(CountriesResponse.self, from: data)
    }
}
