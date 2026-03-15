import SwiftUI

struct SignUpView: View {

    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    @State private var nameError: String?
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var confirmError: String?

    private var colors: WavloColors { theme.colors }

    private var isFormValid: Bool {
        ValidationHelper.validateFullName(fullName) == nil
            && ValidationHelper.validateEmail(email) == nil
            && ValidationHelper.validatePassword(password) == nil
            && ValidationHelper.validateConfirmPassword(password, confirm: confirmPassword) == nil
    }

    var body: some View {
        ZStack {
            colors.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let msg = authVM.errorMessage {
                        Text(msg)
                            .font(Constants.Typography.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    field("Full Name", text: $fullName, placeholder: "Your name", error: nameError)
                        .onChange(of: fullName) { _, _ in nameError = ValidationHelper.validateFullName(fullName) }

                    field("Email", text: $email, placeholder: "you@example.com", error: emailError, keyboard: .emailAddress)
                        .onChange(of: email) { _, _ in emailError = ValidationHelper.validateEmail(email) }

                    field("Password", text: $password, placeholder: "Min 8 chars, 1 uppercase, 1 number", error: passwordError, secure: true)
                        .onChange(of: password) { _, _ in passwordError = ValidationHelper.validatePassword(password) }

                    field("Confirm Password", text: $confirmPassword, placeholder: "Same as password", error: confirmError, secure: true)
                        .onChange(of: confirmPassword) { _, _ in confirmError = ValidationHelper.validateConfirmPassword(password, confirm: confirmPassword) }

                    Button {
                        Task { await authVM.signUpWithEmail(name: fullName, email: email, password: password) }
                    } label: {
                        Text("Create Account")
                            .font(Constants.Typography.bodyLarge)
                            .fontWeight(.bold)
                            .foregroundStyle(colors.bgPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(colors.primaryAccent)
                            .clipShape(Capsule())
                    }
                    .disabled(!isFormValid || authVM.isLoading)
                    .padding(.top, 8)
                }
                .padding(24)
            }
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func field(_ label: String, text: Binding<String>, placeholder: String, error: String?, secure: Bool = false, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Constants.Typography.caption)
                .foregroundStyle(colors.textSecondary)
            if secure {
                SecureField(placeholder, text: text)
                    .textContentType(.newPassword)
                    .keyboardType(keyboard)
                    .padding()
                    .background(colors.bgInput)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.smallCornerRadius, style: .continuous))
                    .foregroundStyle(colors.textPrimary)
            } else {
                TextField(placeholder, text: text)
                    .textContentType(label.contains("Email") ? .emailAddress : .name)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(label.contains("Email") ? .never : .words)
                    .padding()
                    .background(colors.bgInput)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.smallCornerRadius, style: .continuous))
                    .foregroundStyle(colors.textPrimary)
            }
            if let err = error, !err.isEmpty {
                Text(err)
                    .font(Constants.Typography.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(ThemeManager())
            .environmentObject(AuthViewModel())
    }
}
