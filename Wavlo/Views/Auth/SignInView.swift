import SwiftUI

struct SignInView: View {

    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var email = ""
    @State private var password = ""

    private var colors: WavloColors { theme.colors }

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

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(Constants.Typography.caption)
                            .foregroundStyle(colors.textSecondary)
                        TextField("you@example.com", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .padding()
                            .background(colors.bgInput)
                            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.smallCornerRadius, style: .continuous))
                            .foregroundStyle(colors.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(Constants.Typography.caption)
                            .foregroundStyle(colors.textSecondary)
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .padding()
                            .background(colors.bgInput)
                            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.smallCornerRadius, style: .continuous))
                            .foregroundStyle(colors.textPrimary)
                    }

                    NavigationLink {
                        ForgotPasswordView()
                    } label: {
                        Text("Forgot Password?")
                            .font(Constants.Typography.bodySmall)
                            .foregroundStyle(WavloColors.accentGreen)
                    }

                    Button {
                        Task { await authVM.signInWithEmail(email: email, password: password) }
                    } label: {
                        Text("Sign In")
                            .font(Constants.Typography.bodyLarge)
                            .fontWeight(.bold)
                            .foregroundStyle(colors.bgPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(colors.primaryAccent)
                            .clipShape(Capsule())
                    }
                    .disabled(email.isEmpty || password.isEmpty || authVM.isLoading)
                    .padding(.top, 8)

                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(Constants.Typography.bodySmall)
                            .foregroundStyle(colors.textSecondary)
                        NavigationLink("Sign up") {
                            SignUpView()
                        }
                        .font(Constants.Typography.bodySmall)
                        .foregroundStyle(WavloColors.accentGreen)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                }
                .padding(24)
            }
        }
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SignInView()
            .environmentObject(ThemeManager())
            .environmentObject(AuthViewModel())
    }
}
