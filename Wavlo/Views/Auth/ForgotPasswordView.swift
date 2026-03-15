import SwiftUI

struct ForgotPasswordView: View {

    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var didSend = false

    private var colors: WavloColors { theme.colors }

    var body: some View {
        ZStack {
            colors.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if didSend {
                        Text("Reset link sent! Check your email.")
                            .font(Constants.Typography.bodyRegular)
                            .foregroundStyle(WavloColors.accentGreen)
                            .padding(.horizontal)
                    } else if let msg = authVM.errorMessage {
                        Text(msg)
                            .font(Constants.Typography.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    if !didSend {
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

                        Button {
                            Task {
                                await authVM.sendPasswordReset(email: email)
                                if authVM.errorMessage == nil { didSend = true }
                            }
                        } label: {
                            Text("Send Reset Link")
                                .font(Constants.Typography.bodyLarge)
                                .fontWeight(.bold)
                                .foregroundStyle(colors.bgPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(colors.primaryAccent)
                                .clipShape(Capsule())
                        }
                        .disabled(email.isEmpty || authVM.isLoading)
                        .padding(.top, 8)
                    }

                    Button("Back to Sign In") {
                        dismiss()
                    }
                    .font(Constants.Typography.bodyRegular)
                    .foregroundStyle(WavloColors.accentGreen)
                    .padding(.top, 24)
                }
                .padding(24)
            }
        }
        .navigationTitle("Forgot Password")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
            .environmentObject(ThemeManager())
            .environmentObject(AuthViewModel())
    }
}
