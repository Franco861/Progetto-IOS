import Foundation
import SwiftData


@Model
final class UserProfile {
    var nome: String
    var cognome: String
    var email: String
    var username: String
    var password: String
    
    init(nome: String, cognome: String, email: String, username: String, password: String) {
        self.nome = nome
        self.cognome = cognome
        self.email = email
        self.username = username
        self.password = password
    }
}
