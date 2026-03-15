import SwiftUI

struct MoodSelectorView: View {

    @Binding var selectedMood: String
    let onSelect: (String) -> Void
    @EnvironmentObject private var theme: ThemeManager

    private var colors: WavloColors { theme.colors }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Constants.Layout.baseSpacing) {
                ForEach(Constants.moods, id: \.name) { mood in
                    Button {
                        selectedMood = mood.name
                        onSelect(mood.name)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: mood.icon)
                                .font(.system(size: 14))
                            Text(mood.name.capitalized)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(selectedMood == mood.name ? colors.bgPrimary : colors.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(selectedMood == mood.name ? colors.primaryAccent : colors.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.pillCornerRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 1)
        }
    }
}

#Preview {
    MoodSelectorView(selectedMood: .constant("chill"), onSelect: { _ in })
        .environmentObject(ThemeManager())
        .padding()
        .background(Color(hex: "0d0d0d"))
}
