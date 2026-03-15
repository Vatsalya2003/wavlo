import Foundation
import UIKit
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

enum AuthProvider: String {
    case email = "Email"
    case google = "Google"
}

final class AuthService {

    static let shared = AuthService()
    private let auth = Auth.auth()

    private init() {}

    var currentUser: User? { auth.currentUser }
    var isEmailVerified: Bool { auth.currentUser?.isEmailVerified ?? false }

    func signUpWithEmail(email: String, password: String) async throws {
        try await auth.createUser(withEmail: email, password: password)
        try await auth.currentUser?.sendEmailVerification()
    }

    func signInWithEmail(email: String, password: String) async throws {
        try await auth.signIn(withEmail: email, password: password)
    }

    func signInWithGoogle() async throws {
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = await windowScene.windows.first?.rootViewController else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller"])
        }
        let config = GIDConfiguration(clientID: FirebaseApp.app()?.options.clientID ?? "")
        GIDSignIn.sharedInstance.configuration = config
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google Sign-In failed"])
        }
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
        try await auth.signIn(with: credential)
    }

    func signOut() throws {
        GIDSignIn.sharedInstance.signOut()
        try auth.signOut()
    }

    func sendEmailVerification() async throws {
        try await auth.currentUser?.sendEmailVerification()
    }

    func sendPasswordReset(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }

    func reloadUser() async throws {
        try await auth.currentUser?.reload()
    }

    func addStateDidChangeListener(_ handler: @escaping (Auth, User?) -> Void) -> AuthStateDidChangeListenerHandle {
        auth.addStateDidChangeListener(handler)
    }

    func removeStateDidChangeListener(_ handle: AuthStateDidChangeListenerHandle) {
        auth.removeStateDidChangeListener(handle)
    }

    /// User-friendly message for Firebase auth errors.
    static func message(for error: Error) -> String {
        let ns = error as NSError
        guard ns.domain == AuthErrorDomain else {
            return error.localizedDescription
        }
        guard let code = AuthErrorCode(_bridgedNSError: ns) else {
            return error.localizedDescription
        }
        switch code.code {
        case .emailAlreadyInUse: return "This email is already registered. Try signing in instead."
        case .invalidEmail: return "Please enter a valid email address."
        case .weakPassword: return "Password is too weak. Use at least 8 characters with a number and uppercase letter."
        case .userNotFound: return "No account found with this email. Try signing up."
        case .wrongPassword: return "Incorrect password. Try again or reset your password."
        case .tooManyRequests: return "Too many attempts. Please wait a moment and try again."
        case .networkError: return "Network error. Check your internet connection."
        default: return error.localizedDescription
        }
    }
}
