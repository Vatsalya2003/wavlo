import SwiftUI

/// Single onboarding / welcome screen: new design with auth options (Google, Sign up, Sign in).
struct OnboardingView: View {

    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var authVM: AuthViewModel

    private var colors: WavloColors { theme.colors }

    var body: some View {
        ZStack {
            Color(hex: "0d0d0d").ignoresSafeArea()

            VStack(spacing: 0) {
                // Top image with smooth fade into background
                ZStack(alignment: .bottom) {
                    Image("onboarding_bg")
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: UIScreen.main.bounds.height * 0.48)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.0),
                                    Color.black.opacity(0.4),
                                    Color(hex: "0d0d0d")
                                ]),
                                startPoint: .center,
                                endPoint: .bottom
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text("MUSIC DIFFERENT GENRES AND MOODS!!!")
                        .font(.system(size: 8, weight: .semibold, design: .default))
                        .foregroundColor(Color(hex: "F5EFEB"))
                        .tracking(2)
                        .textCase(.uppercase)
                        .padding(.top, 20)
                        .padding(.horizontal, 24)

                    Text("Discover Your\nPlaylist Music On\nWavlo")
                        .font(.system(size: 29, weight: .black))
                        .foregroundColor(Color(hex: "D9ED92"))
                        .lineSpacing(4)
                        .padding(.top, 10)
                        .padding(.horizontal, 24)

                    if let msg = authVM.errorMessage {
                        Text(msg)
                            .font(Constants.Typography.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                    }

                    Button {
                        Task { await authVM.signInWithGoogle() }
                    } label: {
                        HStack(spacing: 12) {
                            Text("G")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                            Text("Continue With Google")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(hex: "F5EFEB"))
                        .clipShape(Capsule())
                    }
                    .disabled(authVM.isLoading)
                    .padding(.horizontal, 24)
                    .padding(.top, 30)

                    NavigationLink {
                        SignUpView()
                    } label: {
                        Text("Sign up with Email")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "D9ED92"))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 16)

                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "F5EFEB"))
                        NavigationLink {
                            SignInView()
                        } label: {
                            Text("Sign in")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "F5EFEB"))
                                .underline()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)

                    Text("By continuing, you agree to the Terms of Service & Privacy Policy")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "F5EFEB").opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 30)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "0d0d0d"))
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: false)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(ThemeManager())
        .environmentObject(AuthViewModel())
}
