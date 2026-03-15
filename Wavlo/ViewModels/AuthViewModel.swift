import Foundation
import FirebaseAuth
import UIKit
import SwiftUI
import Combine

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var authState: AuthState = .loading
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let authService = AuthService.shared
    private var authHandle: AuthStateDidChangeListenerHandle?

    enum AuthState: Equatable {
        case loading
        case unauthenticated
        case emailNotVerified
        case authenticated
    }

    var currentUser: User? { authService.currentUser }
    var displayName: String? { authService.currentUser?.displayName ?? authService.currentUser?.email?.components(separatedBy: "@").first }
    var email: String? { authService.currentUser?.email }
    var isEmailVerified: Bool { authService.isEmailVerified }
    var providerName: String {
        if authService.currentUser?.providerData.first?.providerID.contains("google") == true {
            return AuthProvider.google.rawValue
        }
        return AuthProvider.email.rawValue
    }

    init() {
        authHandle = authService.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.evaluateAuthState(user: user)
            }
        }
    }

    deinit {
        if let h = authHandle {
            authService.removeStateDidChangeListener(h)
        }
    }

    private func evaluateAuthState(user: User?) {
        guard let user = user else {
            authState = .unauthenticated
            return
        }
        if user.isEmailVerified {
            authState = .authenticated
        } else {
            authState = .emailNotVerified
        }
    }

    func signUpWithEmail(name: String, email: String, password: String) async {
        errorMessage = nil
        if let err = ValidationHelper.validateFullName(name) {
            errorMessage = err
            return
        }
        if let err = ValidationHelper.validateEmail(email) {
            errorMessage = err
            return
        }
        if let err = ValidationHelper.validatePassword(password) {
            errorMessage = err
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.signUpWithEmail(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            authState = .emailNotVerified
        } catch {
            errorMessage = AuthService.message(for: error)
        }
    }

    func signInWithEmail(email: String, password: String) async {
        errorMessage = nil
        if let err = ValidationHelper.validateEmail(email) {
            errorMessage = err
            return
        }
        if email.isEmpty || password.isEmpty {
            errorMessage = "Email and password are required."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.signInWithEmail(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            if authService.isEmailVerified {
                authState = .authenticated
            } else {
                authState = .emailNotVerified
            }
        } catch {
            errorMessage = AuthService.message(for: error)
        }
    }

    func signInWithGoogle() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.signInWithGoogle()
            authState = .authenticated
        } catch {
            if (error as NSError).code != -5 {
                errorMessage = AuthService.message(for: error)
            }
        }
    }

    func signOut() {
        errorMessage = nil
        do {
            try authService.signOut()
            authState = .unauthenticated
        } catch {
            errorMessage = AuthService.message(for: error)
        }
    }

    func sendVerificationEmail() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.sendEmailVerification()
        } catch {
            errorMessage = AuthService.message(for: error)
        }
    }

    func reloadAndCheckVerified() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.reloadUser()
            if authService.isEmailVerified {
                authState = .authenticated
            }
        } catch {
            errorMessage = AuthService.message(for: error)
        }
    }

    func sendPasswordReset(email: String) async {
        errorMessage = nil
        if let err = ValidationHelper.validateEmail(email) {
            errorMessage = err
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.sendPasswordReset(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
        } catch {
            errorMessage = AuthService.message(for: error)
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
