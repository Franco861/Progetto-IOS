import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("isLoggedIn") private var isLogged: Bool = false
    @State private var viewModel = CountryViewModel()

    var body: some View {
        @Bindable var vm = viewModel

        if isLogged {
            TabView(selection: $vm.activeTab) {
                UnifiedMapView()
                    .tabItem { Label("Mappa", systemImage: "map.fill") }
                    .tag(AppTab.map)

                CountryInfoView()
                    .tabItem { Label("Info", systemImage: "info.circle.fill") }
                    .tag(AppTab.info)

                ClassificheView()
                    .tabItem { Label("Classifiche", systemImage: "trophy.fill") }
                    .tag(AppTab.classifiche)


                GeoQuizView()
                    .tabItem { Label("Quiz", systemImage: "questionmark.circle.fill") }
                    .tag(AppTab.quiz)

                ProfileView()
                    .tabItem { Label("Profilo", systemImage: "person.fill") }
                    .tag(AppTab.profile)
            }
            .environment(viewModel)
            .task {
                await viewModel.fetchCountries()
            }
        } else {
            LoginView()
        }
    }
}

// MARK: - Componenti condivisi

struct FlagImage: View {
    let urlString: String
    var contentMode: ContentMode = .fill

    var body: some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            if let image = phase.image {
                image.resizable().aspectRatio(contentMode: contentMode)
            } else {
                Color.gray.opacity(0.3)
            }
        }
    }
}

struct LoadErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Connessione assente", systemImage: "wifi.slash")
        } description: {
            Text(message)
        } actions: {
            Button("Riprova", action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Label(title, systemImage: icon)
            Spacer()
            Text(value).bold().multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
