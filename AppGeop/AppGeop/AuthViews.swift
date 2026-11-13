import SwiftUI
import MapKit

// MARK: - 1. SFONDO MAPPA ANIMATA
struct AnimatedMapBackground: View {
    private let latIniziale = 48.8566
    private let lonIniziale = 2.3522
    
    private let latFinale = 19.43260
    private let lonFinale = 99.1332

    var body: some View {
        TimelineView(.animation) { context in
            let date = context.date.timeIntervalSince1970
            let progress = (sin(date / 30.0 * .pi) + 1.0) / 2.0
            
            let currentLat = latIniziale + (latFinale - latIniziale) * progress
            let currentLon = lonIniziale + (lonFinale - lonIniziale) * progress
            let currentHeading = progress * 20.0

            Map(position: .constant(.camera(MapCamera(
                centerCoordinate: CLLocationCoordinate2D(latitude: currentLat, longitude: currentLon),
                distance: 13_000_000,
                heading: currentHeading,
                pitch: 0
            ))))
            .overlay(Color.black.opacity(0.6))
            .disabled(true)
            .ignoresSafeArea()
        }
    }
}

// MARK: - 2. SCHERMATA DI LOGIN
struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @AppStorage("isLoggedIn") private var isLogged: Bool = false
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    enum Field {
        case username, password
    }
    @FocusState private var focusedField: Field?
    
    private func checkCred() {
        let cleanUser = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanPass = password.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if cleanPass == "admin" && cleanUser == "admin" {
            isLogged = true
        } else {
            alertMessage = "Credenziali errate"
            showAlert = true
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedMapBackground()
                
                VStack(spacing: 12) {
                    // CAMPO USERNAME
                    HStack {
                        TextField("", text: $username, prompt: Text("Inserisci username")
                            .foregroundColor(.white.opacity(0.7))
                        )
                        .focused($focusedField, equals: .username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        
                        Image(systemName: "person.fill")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(12)
                    .background(focusedField == .username ? Color.gray.opacity(0.6) : Color.gray.opacity(0.35))
                    .cornerRadius(10)
                    
                    // CAMPO PASSWORD
                    HStack {
                        SecureField("", text: $password, prompt: Text("Inserisci password")
                            .foregroundColor(.white.opacity(0.7))
                        )
                        .focused($focusedField, equals: .password)
                        
                        Image(systemName: "lock.fill")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(12)
                    .background(focusedField == .password ? Color.gray.opacity(0.6) : Color.gray.opacity(0.35))
                    .cornerRadius(10)
                    
                    // BOTTONE LOGIN
                    Button(action: checkCred) {
                        Text("Login")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.top, 4)
                    
                    // LINK VERSO SIGNUP
                    NavigationLink {
                        SignupView()
                    } label: {
                        HStack(spacing: 4) {
                            Text("Non hai un account?")
                                .foregroundColor(.white.opacity(0.8))
                            Text("Registrati")
                                .bold()
                                .foregroundColor(.blue)
                        }
                        .font(.footnote)
                        .padding(.top, 8)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: focusedField)
                .foregroundStyle(.white)
                .padding(.horizontal, 36)
            }
            .ignoresSafeArea()
            .toolbar(.hidden, for: .navigationBar)
            .alert("Attenzione", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
}

// MARK: - 3. SCHERMATA DI REGISTRAZIONE
struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isLoggedIn") private var isLogged: Bool = false
    
    @State private var nome: String = ""
    @State private var cognome: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var eta: Int = 18
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    enum Field {
        case nome, cognome, email, password
    }
    @FocusState private var focusedField: Field?
    
    private func validaERegistra() {
        let nomeTrim = nome.trimmingCharacters(in: .whitespacesAndNewlines)
        let cognomeTrim = cognome.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailTrim = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let passTrim = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if nomeTrim.count > 4 &&
           cognomeTrim.count > 4 &&
           emailTrim.count > 4 &&
           passTrim.count > 4 &&
           eta > 0 {
            // Imposta l'utente come loggato: ContentView passerà in automatico all'app principale
            isLogged = true
        } else {
            alertMessage = "Compila tutti i campi con almeno 5 caratteri."
            showAlert = true
        }
    }
    
    var body: some View {
        ZStack {
            AnimatedMapBackground()
            
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    TextField("", text: $nome, prompt: Text("Nome").foregroundColor(.white.opacity(0.7)))
                        .focused($focusedField, equals: .nome)
                        .padding(12)
                        .background(focusedField == .nome ? Color.gray.opacity(0.6) : Color.gray.opacity(0.35))
                        .cornerRadius(10)
                    
                    TextField("", text: $cognome, prompt: Text("Cognome").foregroundColor(.white.opacity(0.7)))
                        .focused($focusedField, equals: .cognome)
                        .padding(12)
                        .background(focusedField == .cognome ? Color.gray.opacity(0.6) : Color.gray.opacity(0.35))
                        .cornerRadius(10)
                }
                
                TextField("", text: $email, prompt: Text("Email").foregroundColor(.white.opacity(0.7)))
                    .focused($focusedField, equals: .email)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .padding(12)
                    .background(focusedField == .email ? Color.gray.opacity(0.6) : Color.gray.opacity(0.35))
                    .cornerRadius(10)
                
                SecureField("", text: $password, prompt: Text("Password").foregroundColor(.white.opacity(0.7)))
                    .focused($focusedField, equals: .password)
                    .padding(12)
                    .background(focusedField == .password ? Color.gray.opacity(0.6) : Color.gray.opacity(0.35))
                    .cornerRadius(10)
                
                Button(action: validaERegistra) {
                    Text("Signup")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 4)
                
                // TORNA AL LOGIN SENZA IMPILARE VISTE
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Text("Hai già un account?")
                            .foregroundColor(.white.opacity(0.8))
                        Text("Accedi")
                            .bold()
                            .foregroundColor(.blue)
                    }
                    .font(.footnote)
                    .padding(.top, 8)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: focusedField)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
        .alert("Errore", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}

#Preview {
    LoginView()
}
