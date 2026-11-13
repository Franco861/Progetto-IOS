//
//  RegionNames.swift
//  AppGeop
//
//  Created by s18 on 13/11/26.
//

import Foundation

// L'API restituisce i continenti in inglese
enum RegionNames {
    private static let names = [
        "Africa": "Africa", "Americas": "Americhe", "Asia": "Asia",
        "Europe": "Europa", "Oceania": "Oceania", "Antarctic": "Antartide"
    ]
    static func label(_ region: String) -> String { names[region] ?? region }
}
