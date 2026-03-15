import SwiftUI

struct OnboardingView: View {

    @EnvironmentObject private var theme: ThemeManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    private var colors: WavloColors { theme.colors }

    var body: some View {
        ZStack {
            colors.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text("Music without borders")
                    .font(Constants.Typography.displayLarge)
                    .foregroundStyle(colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text("Create playlists, find new tracks and listen to your favorite music anytime!")
                    .font(Constants.Typography.bodyLarge)
                    .foregroundStyle(colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 16)

                Spacer()

                Button {
                    hasCompletedOnboarding = true
                } label: {
                    Text("Get started")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(theme.colors.primaryAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(ThemeManager())
}
