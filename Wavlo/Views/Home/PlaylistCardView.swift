import SwiftUI

/// Card for playlist/album/artist or single item on Home (160×160 image, title, subtitle).
struct PlaylistCardView: View {

    let imageURL: String?
    let title: String
    let subtitle: String?
    let onTap: () -> Void
    @EnvironmentObject private var theme: ThemeManager

    private var colors: WavloColors { theme.colors }

    init(
        imageURL: String?,
        title: String,
        subtitle: String? = nil,
        onTap: @escaping () -> Void
    ) {
        self.imageURL = imageURL
        self.title = title
        self.subtitle = subtitle
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: imageURL.flatMap { URL(string: $0) }) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle()
                            .fill(colors.bgElevated)
                    default:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(width: Constants.Layout.homeCardSize, height: Constants.Layout.homeCardSize)
                .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.homeCardCornerRadius, style: .continuous))

                Text(title)
                    .font(Constants.Typography.bodyLarge)
                    .fontWeight(.medium)
                    .foregroundStyle(colors.textPrimary)
                    .lineLimit(2)
                    .truncationMode(.tail)

                if let sub = subtitle, !sub.isEmpty {
                    Text(sub)
                        .font(Constants.Typography.bodySmall)
                        .foregroundStyle(colors.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(width: Constants.Layout.homeCardSize, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PlaylistCardView(
        imageURL: nil,
        title: "Chill Mix",
        subtitle: "Bollywood Mush",
        onTap: {}
    )
    .environmentObject(ThemeManager())
}
