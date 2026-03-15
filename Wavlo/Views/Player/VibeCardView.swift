import SwiftUI

struct VibeCardView: View {

    let title: String
    let subtitle: String
    let imageURL: String?
    let accentColor: Color
    @EnvironmentObject private var theme: ThemeManager

    private var colors: WavloColors { theme.colors }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: imageURL.flatMap(URL.init)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(accentColor.opacity(0.3))
                default:
                    ProgressView()
                }
            }
            .frame(height: 120)
            .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Constants.Typography.titleMedium)
                    .foregroundStyle(colors.textPrimary)
                Text(subtitle)
                    .font(Constants.Typography.caption)
                    .foregroundStyle(colors.textSecondary)
            }
            .padding(12)
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius, style: .continuous))
    }
}

#Preview {
    let theme = ThemeManager()
    return VibeCardView(
        title: "Chill Vibes",
        subtitle: "Relaxing beats",
        imageURL: nil,
        accentColor: theme.colors.primaryAccent
    )
    .environmentObject(theme)
    .frame(width: 160)
    .padding()
    .background(Color(hex: "0d0d0d"))
}
