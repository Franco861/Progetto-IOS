//
//  QuizViewModel.swift
//  AppGeop
//
//  Created by s18 on 13/11/26.
//

import SwiftUI

enum QuizMode: String, CaseIterable, Identifiable {
    case capitale = "Capitale"
    case bandiera = "Bandiera"
    var id: String { rawValue }
}

struct QuizQuestion {
    let correct: Country
    let options: [Country]
}

@Observable
@MainActor
class QuizViewModel {
    let roundLength = 10
    var mode: QuizMode = .capitale
    var question: QuizQuestion?
    var selectedID: String?
    var score = 0
    var asked = 0

    var isRoundOver: Bool { asked >= roundLength }

    func restart(from countries: [Country]) {
        score = 0
        asked = 0
        next(from: countries)
    }

    func next(from countries: [Country]) {
        let pool = mode == .capitale
            ? countries.filter { $0.capital?.first != nil }
            : countries
        guard pool.count >= 4, let correct = pool.randomElement() else { return }
        let wrong = Array(pool.filter { $0.cca3 != correct.cca3 }.shuffled().prefix(3))
        question = QuizQuestion(correct: correct, options: ([correct] + wrong).shuffled())
        selectedID = nil
    }

    func answer(_ country: Country) {
        guard selectedID == nil, let q = question else { return }
        selectedID = country.cca3
        asked += 1
        if country.cca3 == q.correct.cca3 { score += 1 }
    }
}
