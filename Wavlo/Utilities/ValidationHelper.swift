import Foundation

enum ValidationHelper {

    /// Returns nil if valid, otherwise error message.
    static func validateFullName(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Name is required." }
        if trimmed.count < 2 { return "Name must be at least 2 characters." }
        return nil
    }

    /// Returns nil if valid, otherwise error message.
    static func validateEmail(_ email: String) -> String? {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Email is required." }
        if !isValidEmailFormat(trimmed) { return "Please enter a valid email address." }
        return nil
    }

    /// Password: min 8 chars, at least 1 uppercase, at least 1 number.
    static func validatePassword(_ password: String) -> String? {
        if password.isEmpty { return "Password is required." }
        if password.count < 8 { return "Password must be at least 8 characters." }
        if !password.contains(where: { $0.isUppercase }) { return "Password needs at least one uppercase letter." }
        if !password.contains(where: { $0.isNumber }) { return "Password needs at least one number." }
        return nil
    }

    static func validateConfirmPassword(_ password: String, confirm: String) -> String? {
        if confirm.isEmpty { return "Please confirm your password." }
        if password != confirm { return "Passwords do not match." }
        return nil
    }

    private static func isValidEmailFormat(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("@") else { return false }
        let parts = trimmed.split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2, parts[0].isEmpty == false, parts[1].contains(".") else { return false }
        return true
    }
}
