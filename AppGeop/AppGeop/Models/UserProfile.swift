import Foundation

struct UserProfile: Codable, Identifiable, Equatable {
    var id: String { username.lowercased() }
    var nome: String
    var cognome: String
    var email: String
    var username: String
    var password: String
}

enum UserStorage {
    private static let usersKey = "savedUserProfiles_v1"

    static func loadUsers() -> [UserProfile] {
        guard let data = UserDefaults.standard.data(forKey: usersKey),
              let users = try? JSONDecoder().decode([UserProfile].self, from: data) else {
            return []
        }
        return users
    }

    static func saveUsers(_ users: [UserProfile]) {
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: usersKey)
        }
    }

    static func addUser(_ user: UserProfile) {
        var users = loadUsers()
        users.append(user)
        saveUsers(users)
    }
}
