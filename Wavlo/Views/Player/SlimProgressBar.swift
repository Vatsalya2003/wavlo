import SwiftUI

struct SlimProgressBar: View {

    let progress: Double
    let colors: WavloColors
    var onSeek: ((Double) -> Void)?

    @State private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            let width = max(1, geo.size.width)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(colors.textMuted.opacity(0.3))
                    .frame(height: 3)

                Capsule()
                    .fill(colors.primaryAccent)
                    .frame(width: width * progress, height: 3)
            }
            .frame(height: 3)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .frame(height: 44)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let x = value.location.x
                        let newProgress = min(max(0, x / width), 1)
                        onSeek?(newProgress)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .frame(height: 44)
    }
}

#Preview {
    SlimProgressBar(progress: 0.3, colors: WavloColors.dark)
        .padding()
        .background(WavloColors.dark.bgPrimary)
}
