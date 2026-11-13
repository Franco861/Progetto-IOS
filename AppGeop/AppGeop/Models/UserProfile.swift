import Foundation
import SwiftData

@Model
final class UserProfile {
    var name: String
    var email: String
    
    init(name: String, email: String) {
        self.name = name
        self.email = email
    }
}
