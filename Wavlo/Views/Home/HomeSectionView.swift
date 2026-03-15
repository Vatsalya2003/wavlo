import SwiftUI

/// Reusable horizontal scroll section for Home (e.g. "Trending Now", "Jump back in").
struct HomeSectionView<Content: View>: View {

    let title: String
    @ViewBuilder let content: () -> Content
    @EnvironmentObject private var theme: ThemeManager

    private var colors: WavloColors { theme.colors }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Layout.baseSpacing) {
            Text(title)
                .font(Constants.Typography.titleLarge)
                .fontWeight(.bold)
                .foregroundStyle(colors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    content()
                }
                .padding(.horizontal, 1)
            }
        }
    }
}

#Preview {
    HomeSectionView(title: "Trending Now") {
        ForEach(0..<5, id: \.self) { _ in
            RoundedRectangle(cornerRadius: Constants.Layout.homeCardCornerRadius)
                .fill(Color.gray.opacity(0.3))
                .frame(width: Constants.Layout.homeCardSize, height: Constants.Layout.homeCardSize)
        }
    }
    .environmentObject(ThemeManager())
    .padding()
}
