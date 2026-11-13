//
//  ProfileView.swift
//  AppGeop
//
//  Created by s18 on 13/11/26.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(CountryViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]

    // Campi per il form di Login
    @State private var inputName: String = ""
    @State private var inputEmail: String = ""

    // Primo profilo salvato nel database
    private var currentUser: UserProfile? {
        userProfiles.first
    }

    var body: some View {
        NavigationStack {
            if let user = currentUser {
                loggedInView(user)
            } else {
                loginView
            }
        }
    }

    // MARK: - Utente loggato
    private func loggedInView(_ user: UserProfile) -> some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.name)
                            .font(.title3)
                            .bold()
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Posti Salvati (\(viewModel.savedCountries.count))") {
                if viewModel.savedCountries.isEmpty {
                    Text("Nessun posto salvato al momento.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.savedCountries) { country in
                        HStack(spacing: 12) {
                            FlagImage(urlString: country.flags.png)
                                .frame(width: 35, height: 22)
                                .clipShape(RoundedRectangle(cornerRadius: 3))

                            VStack(alignment: .leading) {
                                Text(country.name.common)
                                    .font(.headline)
                                Text("Capitale: \(country.capital?.first ?? "N/D")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                viewModel.toggleSave(country)
                            } label: {
                                Image(systemName: "bookmark.fill")
                                    .foregroundStyle(.blue)
                            }
                            .buttonStyle(.borderless)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.openInfoForCountry(country)
                        }
                    }
                }
            }

            Section("Account") {
                Button(role: .destructive, action: logout) {
                    Label("Esci (Logout)", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Profilo")
    }

    // MARK: - Login
    private var loginView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.badge.key.fill")
                .font(.system(size: 70))
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("Accedi al Profilo")
                    .font(.title)
                    .bold()
                Text("Inserisci le tue credenziali per salvare la tua sessione.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                TextField("Nome Completo", text: $inputName)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                TextField("Indirizzo Email", text: $inputEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal)

            Button(action: login) {
                Text("Accedi")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(!isFormValid)
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .navigationTitle("Accedi")
    }

    // MARK: - Logica
    // Nome non vuoto ed email con almeno una chiocciola e un punto
    private var isFormValid: Bool {
        let name = inputName.trimmingCharacters(in: .whitespaces)
        let email = inputEmail.trimmingCharacters(in: .whitespaces)
        return !name.isEmpty && email.contains("@") && email.contains(".")
    }

    // Salva l'utente nel database SwiftData
    private func login() {
        let newUser = UserProfile(
            name: inputName.trimmingCharacters(in: .whitespaces),
            email: inputEmail.trimmingCharacters(in: .whitespaces)
        )
        modelContext.insert(newUser)
        inputName = ""
        inputEmail = ""
    }

    // Rimuove l'utente dal database
    private func logout() {
        if let user = currentUser {
            modelContext.delete(user)
        }
    }
}

#Preview {
    ProfileView()
        .environment(CountryViewModel())
        .modelContainer(for: UserProfile.self, inMemory: true)
}
