import SwiftUI

struct ProfileView: View {
    @Environment(CountryViewModel.self) private var viewModel

    @AppStorage("isLoggedIn") private var isLogged: Bool = false
    @AppStorage("loggedUsername") private var loggedUsername: String = ""

    private var currentUser: UserProfile? {
        let users = UserStorage.loadUsers()
        if !loggedUsername.isEmpty,
           let matched = users.first(where: { $0.username.caseInsensitiveCompare(loggedUsername) == .orderedSame }) {
            return matched
        }
        return users.first
    }

    var body: some View {
        NavigationStack {
            if let user = currentUser {
                loggedInView(user)
            } else {
                ContentUnavailableView {
                    Label("Nessun profilo attivo", systemImage: "person.crop.circle.badge.exclamationmark")
                } description: {
                    Text("Effettua nuovamente l'accesso per visualizzare il tuo profilo.")
                } actions: {
                    Button("Torna al Login", action: logout)
                        .buttonStyle(.borderedProminent)
                }
                .navigationTitle("Profilo")
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
                        Text("\(user.nome) \(user.cognome)")
                            .font(.title3)
                            .bold()
                        Text("@\(user.username) • \(user.email)")
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
                                Text(country.localizedName)
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

    // MARK: - Logica Logout
    private func logout() {
        loggedUsername = ""
        isLogged = false
    }
}

#Preview {
    ProfileView()
        .environment(CountryViewModel())
}
