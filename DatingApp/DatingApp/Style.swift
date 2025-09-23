//
//  Style.swift
//  DatingApp
//
//  Created by Georgi Balabanov on 22/09/2025.
//

import SwiftUI

/// Design tokens & tiny helpers used across the app.
enum Style {

    // MARK: - Radii
    enum Radius {
        static let card: CGFloat   = 16
        static let button: CGFloat = 28
        static let chip: CGFloat   = 12
    }

    // MARK: - Spacing scale
    enum Spacing {
        static let xs: CGFloat = 6
        static let s:  CGFloat = 8
        static let m:  CGFloat = 16
        static let l:  CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 40
    }

    // MARK: - Typography
    enum FontStyle {
        // Use TextStyle initializers, then chain weight() to avoid the compile error.
        static let title:    Font = .system(.largeTitle, design: .rounded).weight(.bold)
        static let subtitle: Font = .system(.title3,     design: .rounded)               // regular
        static let body:     Font = .system(.body,       design: .rounded)
        static let button:   Font = .system(.headline,   design: .rounded).weight(.semibold)
        static let caption:  Font = .system(.caption,    design: .rounded)
    }

    // MARK: - Colors / Palette
    enum Palette {
        static let textPrimary   = Color.white
        static let textSecondary = Color.white.opacity(0.85)

        // Glass UI accents
        static let glassFill     = Color.white.opacity(0.14)
        static let glassStroke   = Color.white.opacity(0.28)
        static let borderSubtle  = Color.white.opacity(0.12)

        // Brand tints (used for glows, accents)
        static let accentPink    = Color(red: 1.00, green: 0.30, blue: 0.60)
        static let accentOrange  = Color(red: 0.85, green: 0.38, blue: 0.00)
        static let accentGreen   = Color(red: 0.41, green: 0.76, blue: 0.15)

        // Base dark backdrop if needed
        static let backgroundDark = Color(red: 0.043, green: 0.031, blue: 0.078)
    }

    // MARK: - Shadows (numbers only; apply with .shadow)
    enum Shadow {
        static let softRadius: CGFloat = 12
        static let softY: CGFloat = 4
    }
}

/// A lightweight glass card modifier you can reuse anywhere.
private struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = Style.Radius.card

    func body(content: Content) -> some View {
        content
            .padding(Style.Spacing.l)
            .background(.ultraThinMaterial, in:
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Style.Palette.borderSubtle, lineWidth: 1)
            )
    }
}

extension View {
    /// Apply a frosted glass look with subtle border.
    func glassCard(cornerRadius: CGFloat = Style.Radius.card) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}
