import SwiftUI
import Combine

// MARK: - Hex Initializer

extension Color {

    /// Creates a Color from a hex string (e.g. "7F77DD", "#7F77DD", "0d0d0d").
    /// Supports 6-digit RGB and optional leading "#".
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme-Aware Color System

enum WavloTheme {
    case dark, light
}

struct WavloColors {

    let bgPrimary: Color
    let bgCard: Color
    let bgCardMiniPLayer: Color
    let bgElevated: Color
    let bgInput: Color
    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color
    let borderSubtle: Color
    let borderDefault: Color
    /// Theme-aware primary accent: navy in dark mode, harbor in light mode.
    let primaryAccent: Color

    // Accents (same in both themes)
    static let accentGreen = Color(hex: "D9ED92")
    static let accentGreenDark = Color(hex: "1AA34A")
    static let accentGreenLight = Color(hex: "1ED760")
    static let accentNavy = Color(hex: "2F4156")
    static let accentTeal = Color(hex: "B0C0CC") // harbor

    // Core brand colors (for reference anywhere)
    static let navy = Color(hex: "2F4156")
    static let beige = Color(hex: "F5EFEB")
    static let obsidian = Color(hex: "2A2A2A")

    // Dark theme — Obsidian base, Beige text, Navy accent
    static let dark = WavloColors(
        bgPrimary: Color(hex: "2A2A2A"),
        bgCard: Color(hex: "323232"),
        bgCardMiniPLayer: Color(hex: "323232"),
        bgElevated: Color(hex: "3A3A3A"),
        bgInput: Color(hex: "3E3E3E"),
        textPrimary: Color(hex: "F5EFEB"),
        textSecondary: Color(hex: "C8C0B8"),
        textMuted: Color(hex: "8A8480"),
        borderSubtle: Color(hex: "3A3A3A"),
        borderDefault: Color(hex: "4A4A4A"),
        primaryAccent: Color(hex: "D9ED92")
    )

    // Light theme — Beige base, Navy text, Harbor accent
    static let light = WavloColors(
        bgPrimary: Color(hex: "F5EFEB"),
        bgCard: Color(hex: "EDE7E2"),
        bgCardMiniPLayer: Color(hex: "323232"),
        bgElevated: Color(hex: "E5DFD9"),
        bgInput: Color(hex: "DDD7D1"),
        textPrimary: Color(hex: "2F4156"),
        textSecondary: Color(hex: "4A6178"),
        textMuted: Color(hex: "7A8E9E"),
        borderSubtle: Color(hex: "DDD7D1"),
        borderDefault: Color(hex: "C8C0B8"),
        primaryAccent: Color(hex: "567C8D")
    )
}

// MARK: - Theme Manager (persists isDarkMode, provides current WavloColors)

final class ThemeManager: ObservableObject {

    @AppStorage("isDarkMode") var isDarkMode: Bool = true

    var colors: WavloColors {
        isDarkMode ? .dark : .light
    }

    var isDarkModeBinding: Binding<Bool> {
        Binding(
            get: { [weak self] in
                self?.isDarkMode ?? true
            },
            set: { [weak self] newValue in
                guard let self = self else { return }
                self.isDarkMode = newValue
                self.objectWillChange.send()
            }
        )
    }
}

// MARK: - Backward compatibility (default to dark theme; migrate views to theme.colors)

extension Color {

    static let backgroundPrimary = WavloColors.dark.bgPrimary
    static let backgroundCard = WavloColors.dark.bgCard
    static let backgroundElevated = WavloColors.dark.bgElevated
    static let backgroundInput = WavloColors.dark.bgInput
    static let textPrimary = WavloColors.dark.textPrimary
    static let textSecondary = WavloColors.dark.textSecondary
    static let textMuted = WavloColors.dark.textMuted
    static let borderSubtle = WavloColors.dark.borderSubtle
    static let borderDefault = WavloColors.dark.borderDefault
    static let accentPurple = WavloColors.accentGreen
    static let accentTeal = WavloColors.accentTeal
}

