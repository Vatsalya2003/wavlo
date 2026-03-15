import SwiftUI

struct WelcomeView: View {

    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var authVM: AuthViewModel

    private var colors: WavloColors { theme.colors }

    var body: some View {
        ZStack {
            colors.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 48)

                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(colors.primaryAccent)
                    Text("Wavlo")
                        .font(Constants.Typography.displayLarge)
                        .foregroundStyle(colors.textPrimary)
                        .padding(.top, 12)
                    Text("Music that knows you.")
                        .font(Constants.Typography.bodyLarge)
                        .foregroundStyle(colors.textSecondary)
                        .padding(.top, 4)

                    Spacer().frame(height: 48)

                    if let msg = authVM.errorMessage {
                        Text(msg)
                            .font(Constants.Typography.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.bottom, 12)
                    }

                    Button {
                        Task { await authVM.signInWithGoogle() }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(colors.textPrimary)
                            Text("Continue with Google")
                                .font(Constants.Typography.bodyLarge)
                                .fontWeight(.semibold)
                                .foregroundStyle(colors.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(colors.bgCard)
                        .clipShape(Capsule())
                    }
                    .disabled(authVM.isLoading)
                    .padding(.horizontal, 24)

                    HStack(spacing: 8) {
                        Rectangle().fill(colors.borderDefault).frame(height: 1)
                        Text("or")
                            .font(Constants.Typography.caption)
                            .foregroundStyle(colors.textMuted)
                        Rectangle().fill(colors.borderDefault).frame(height: 1)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)

                    VStack(spacing: 16) {
                        NavigationLink {
                            SignUpView()
                        } label: {
                            Text("Sign up with Email")
                                .font(Constants.Typography.bodyLarge)
                                .fontWeight(.medium)
                                .foregroundStyle(WavloColors.accentGreen)
                        }
                        NavigationLink {
                            SignInView()
                        } label: {
                            Text("Already have account? Sign in")
                                .font(Constants.Typography.bodyRegular)
                                .foregroundStyle(WavloColors.accentGreen)
                        }
                    }

                    Spacer().frame(height: 48)

                    Text("By continuing, you agree to Wavlo's Terms of Service and Privacy Policy")
                        .font(Constants.Typography.caption)
                        .foregroundStyle(colors.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    WelcomeView()
        .environmentObject(ThemeManager())
        .environmentObject(AuthViewModel())
}
