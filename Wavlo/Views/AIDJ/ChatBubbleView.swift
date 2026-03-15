import SwiftUI

struct ChatBubbleView: View {

    let message: ChatMessage
    @EnvironmentObject private var theme: ThemeManager

    private var colors: WavloColors { theme.colors }

    var isUser: Bool {
        message.role == "user"
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 48) }
            if !isUser {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(colors.primaryAccent)
            }
            Text(message.text)
                .font(Constants.Typography.bodyRegular)
                .foregroundStyle(isUser ? colors.bgPrimary : colors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isUser ? colors.primaryAccent : colors.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            if !isUser { Spacer(minLength: 48) }
        }
        .padding(.horizontal, 4)
    }
}

#Preview {
    VStack(spacing: 12) {
        ChatBubbleView(message: ChatMessage(role: "user", text: "Play something chill", timestamp: Date()))
        ChatBubbleView(message: ChatMessage(role: "assistant", text: "Here are some relaxing tracks for you!", timestamp: Date()))
    }
    .environmentObject(ThemeManager())
    .padding()
    .background(Color(hex: "0d0d0d"))
}
