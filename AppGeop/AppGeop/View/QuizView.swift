//
//  QuizView.swift
//  AppGeop
//
//  Created by s18 on 13/11/26.
//

import SwiftUI

struct GeoQuizView: View {
    @Environment(CountryViewModel.self) private var viewModel
    @State private var quiz = QuizViewModel()
    @AppStorage("quizBest") private var best = 0

    private var showResult: Bool {
        quiz.isRoundOver && quiz.selectedID == nil
    }

    var body: some View {
        @Bindable var quizBinding = quiz

        NavigationStack {
            VStack(spacing: 20) {
                if viewModel.isLoading && viewModel.countries.isEmpty {
                    Spacer()
                    ProgressView("Caricamento in corso...")
                    Spacer()
                } else if let message = viewModel.errorMessage, viewModel.countries.isEmpty {
                    LoadErrorView(message: message) {
                        Task { await viewModel.fetchCountries() }
                    }
                } else {
                    Picker("Modalità", selection: $quizBinding.mode) {
                        ForEach(QuizMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: quiz.mode) { _, _ in
                        quiz.restart(from: viewModel.countries)
                    }

                    HStack {
                        Label("Punti: \(quiz.score)/\(quiz.asked)", systemImage: "star.fill")
                        Spacer()
                        Text("Record: \(best)")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)

                    if showResult {
                        resultView
                    } else if let question = quiz.question {
                        questionView(question)
                    } else {
                        ProgressView("Preparo le domande...")
                    }

                    Spacer()
                }
            }
            .padding()
            .navigationTitle("Geocuriosità")
            .task(id: viewModel.countries.count) {
                if quiz.question == nil {
                    quiz.next(from: viewModel.countries)
                }
            }
        }
    }

    private func questionView(_ question: QuizQuestion) -> some View {
        VStack(spacing: 16) {
            if quiz.mode == .capitale {
                Text("Qual è la capitale di \(question.correct.name.common)?")
                    .font(.title3)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 8)
            } else {
                Text("Di quale paese è questa bandiera?")
                    .font(.title3)
                    .bold()
                FlagImage(urlString: question.correct.flags.png, contentMode: .fit)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            ForEach(question.options) { option in
                Button {
                    quiz.answer(option)
                } label: {
                    Text(label(for: option))
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(color(for: option, in: question))
                .disabled(quiz.selectedID != nil)
            }

            if quiz.selectedID != nil {
                Button(quiz.isRoundOver ? "Vedi risultato" : "Avanti") {
                    if quiz.isRoundOver {
                        best = max(best, quiz.score)
                        quiz.selectedID = nil          // passa alla schermata del risultato
                    } else {
                        quiz.next(from: viewModel.countries)
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var resultView: some View {
        VStack(spacing: 12) {
            Text("Round concluso!")
                .font(.title2)
                .bold()
            Text("Hai totalizzato \(quiz.score) su \(quiz.roundLength)")
            Button("Gioca ancora") {
                quiz.restart(from: viewModel.countries)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 40)
    }

    private func label(for country: Country) -> String {
        quiz.mode == .capitale ? (country.capital?.first ?? "N/D") : country.name.common
    }

    private func color(for country: Country, in question: QuizQuestion) -> Color {
        guard let selected = quiz.selectedID else { return .blue }
        if country.cca3 == question.correct.cca3 { return .green }
        if country.cca3 == selected { return .red }
        return .gray
    }
}

#Preview {
    GeoQuizView()
        .environment(CountryViewModel())
}
