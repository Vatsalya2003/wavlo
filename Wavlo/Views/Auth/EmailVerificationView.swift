import SwiftUI

struct EmailVerificationView: View {

    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var authVM: AuthViewModel

    private var colors: WavloColors { theme.colors }
    private var userEmail: String { authVM.email ?? "your email" }

    var body: some View {
        ZStack {
            colors.bgPrimary.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(colors.primaryAccent)

                Text("Verify your email")
                    .font(Constants.Typography.titleLarge)
                    .foregroundStyle(colors.textPrimary)

                Text("We sent a verification link to \(userEmail). Open your email and tap the link to verify.")
                    .font(Constants.Typography.bodyRegular)
                    .foregroundStyle(colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                if let msg = authVM.errorMessage {
                    Text(msg)
                        .font(Constants.Typography.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    Task { await authVM.reloadAndCheckVerified() }
                } label: {
                    Text("I've verified → Continue")
                        .font(Constants.Typography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundStyle(colors.bgPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(colors.primaryAccent)
                        .clipShape(Capsule())
                }
                .disabled(authVM.isLoading)
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Button {
                    Task { await authVM.sendVerificationEmail() }
                } label: {
                    Text("Resend Email")
                        .font(Constants.Typography.bodyRegular)
                        .foregroundStyle(WavloColors.accentGreen)
                }
                .disabled(authVM.isLoading)

                Spacer()

                Button("Back to Sign In") {
                    try? AuthService.shared.signOut()
                    authVM.authState = .unauthenticated
                }
                .font(Constants.Typography.bodySmall)
                .foregroundStyle(colors.textMuted)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Verify Email")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    EmailVerificationView()
        .environmentObject(ThemeManager())
        .environmentObject(AuthViewModel())
}
