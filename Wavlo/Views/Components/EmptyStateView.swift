import SwiftUI

struct EmptyStateView: View {

    let iconName: String
    let title: String
    let subtitle: String
    let buttonTitle: String?
    let onButtonTap: (() -> Void)?

    init(
        iconName: String = "music.note.list",
        title: String,
        subtitle: String,
        buttonTitle: String? = nil,
        onButtonTap: (() -> Void)? = nil
    ) {
        self.iconName = iconName
        self.title = title
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.onButtonTap = onButtonTap
    }

    @EnvironmentObject private var theme: ThemeManager
    private var colors: WavloColors { theme.colors }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(colors.textMuted)
            Text(title)
                .font(Constants.Typography.titleLarge)
                .foregroundStyle(colors.textPrimary)
            Text(subtitle)
                .font(Constants.Typography.bodyRegular)
                .foregroundStyle(colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if let buttonTitle, let onButtonTap {
                Button(action: onButtonTap) {
                    Text(buttonTitle)
                        .font(Constants.Typography.bodyLarge)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(WavloColors.accentGreen)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.vertical, 40)
    }
}

#Preview {
    EmptyStateView(
        title: "It's quiet in here",
        subtitle: "Create your first playlist and fill it with vibes.",
        buttonTitle: "+ Create Playlist",
        onButtonTap: {}
    )
    .environmentObject(ThemeManager())
}

