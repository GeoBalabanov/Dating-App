//
//  DreamyBackground.swift
//  DatingApp
//
//  Created by Georgi Balabanov on 23/09/2025.
//

import SwiftUI

// Small helper to use hex colors easily.
extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

/// Photo-free background that mimics your Figma gradients with soft blobs.
/// Rename avoids clashing with any previous `DreamyBackground`.
struct AyaBackground: View {
    enum Style { case pink, orange, green }
    var style: Style = .pink
    var vignette: Bool = true

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Base dark canvas
                LinearGradient(
                    colors: [Color(hex: 0x0B0814), Color(hex: 0x0B0814)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )

                // Hot blob (top-right)
                Circle()
                    .fill(primary)
                    .frame(width: w * 0.95, height: w * 0.95)
                    .blur(radius: 120)
                    .offset(x: w * 0.25, y: -h * 0.18)
                    .blendMode(.screen)
                    .opacity(0.95)

                // Cool blob (left-center)
                Circle()
                    .fill(secondary)
                    .frame(width: w * 0.85, height: w * 0.85)
                    .blur(radius: 150)
                    .offset(x: -w * 0.20, y: h * 0.02)
                    .blendMode(.screen)
                    .opacity(0.75)

                // Soft vertical highlight sweep
                RoundedRectangle(cornerRadius: w)
                    .fill(Color.white.opacity(0.35))
                    .frame(width: w * 0.65, height: h * 0.9)
                    .rotationEffect(.degrees(-8))
                    .offset(x: -w * 0.02, y: -h * 0.02)
                    .blur(radius: 140)
                    .blendMode(.softLight)

                if vignette {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.45)],
                        startPoint: .center, endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
            }
            .ignoresSafeArea()
        }
    }

    // Palette
    private var primary: Color {
        switch style {
        case .pink:   return Color(hex: 0xF03272)
        case .orange: return Color(hex: 0xC94B00)
        case .green:  return Color(hex: 0x69C11C)
        }
    }
    private var secondary: Color {
        switch style {
        case .pink:   return Color(hex: 0x6C1B80)
        case .orange: return Color(hex: 0x5B0A10)
        case .green:  return Color(hex: 0x114D28)
        }
    }
}

#Preview {
    AyaBackground(style: .pink, vignette: true)
}
