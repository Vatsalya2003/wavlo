import SwiftUI

struct GenreFilterView: View {

    @Binding var selectedGenre: String
    @EnvironmentObject private var theme: ThemeManager

    let genres = ["All", "Pop", "Rock", "Hip-Hop", "EDM", "Bollywood", "Indie", "R&B", "Classical", "Punjabi", "Lo-fi"]

    private var colors: WavloColors { theme.colors }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(genres, id: \.self) { genre in
                    let isSelected = selectedGenre == genre
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedGenre = genre
                        }
                    } label: {
                        Text(genre)
                            .font(Constants.Typography.pill)
                            .foregroundStyle(isSelected ? .white : colors.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(isSelected ? colors.primaryAccent : colors.bgElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(colors.borderDefault, lineWidth: isSelected ? 0 : 1)
                            )
                            .scaleEffect(isSelected ? 1.05 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Constants.Layout.screenPadding)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    GenreFilterView(selectedGenre: .constant("All"))
        .environmentObject(ThemeManager())
        .background(Color(hex: "0d0d0d"))
}
