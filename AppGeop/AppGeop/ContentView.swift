

import SwiftUI
import MapKit


import SwiftUI

struct ContentView: View {
    @AppStorage("isLoggedIn") private var isLogged: Bool = false

    var body: some View {
        if isLogged {
            Text("Utente Loggato") // Verrà sostituita dalla TabView del main subito dopo il merge
        } else {
            LoginView()
        }
    }
}

#Preview {
    ContentView()
    //ContentView().onAppear {
      //  UserDefaults.standard.set(false, forKey: "isLoggedIn")
    //}
}
