import SwiftUI
import UIKit

extension View {

    /// Adds a "Done" button above the keyboard that dismisses it when tapped.
    func wavloKeyboardDismissToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .foregroundStyle(WavloColors.accentTeal)
            }
        }
    }

    /// Card style: background, corner radius, padding from design system.
    func wavloCardStyle() -> some View {
        self
            .padding(Constants.Layout.cardPadding)
            .background(Color.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Constants.Layout.cardCornerRadius, style: .continuous)
                    .stroke(Color.borderDefault, lineWidth: 1)
            )
    }

    /// Section header typography and spacing.
    func wavloSectionHeaderStyle() -> some View {
        self
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(Color.textPrimary)
    }

    /// Pill-style button (full corner radius from design system).
    func wavloPillButtonStyle() -> some View {
        self
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.buttonCornerRadius, style: .continuous))
    }

    /// Small control corners (e.g. chips, tags).
    func wavloSmallCornerStyle() -> some View {
        self
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.smallCornerRadius, style: .continuous))
    }

    /// Screen horizontal padding.
    func wavloScreenPadding() -> some View {
        self.padding(.horizontal, Constants.Layout.screenPadding)
    }
}
