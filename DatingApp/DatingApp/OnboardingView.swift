//
//  OnboardingView.swift
//  DatingApp
//
//  Created by Georgi Balabanov on 22/09/2025.
//

import SwiftUI

struct OnboardingView: View {
    @State private var goToLogin = false

    var body: some View {
        ZStack {
            AyaBackground(style: .pink, vignette: true)

            VStack(alignment: .leading, spacing: Style.Spacing.l) {
                Spacer()

                Text("Listen. Match.\nChat. Meet.")
                    .font(Style.FontStyle.title)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.45), radius: 8, x: 0, y: 2)

                Text("Find love through senses. Whether you are looking for love, connection or just someone to vibe with – you are in the right place!")
                    .font(Style.FontStyle.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineSpacing(2)

                FigmaPrimaryButton(title: "Get Started now", icon: "chevron.right") {
                    goToLogin = true
                }
                .padding(.top, Style.Spacing.m)
            }
            .padding(.horizontal, Style.Spacing.xl)
            .padding(.bottom, 32)
        }
        .navigationDestination(isPresented: $goToLogin) {
            LoginView() // replace with your real login when ready
        }
        .preferredColorScheme(.dark)
    }
}

/// Glassy rounded primary button to match the Figma look.
struct FigmaPrimaryButton: View {
    var title: String
    var icon: String? = nil
    var action: () -> Void

    @Environment(\.isEnabled) private var isEnabled
    @State private var pressed = false

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            HStack(spacing: 10) {
                Text(title)
                    .font(Style.FontStyle.button)
                if let icon {
                    Image(systemName: icon)
                        .font(Style.FontStyle.button)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: Style.Radius.button, style: .continuous)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: Style.Radius.button, style: .continuous)
                    .fill(LinearGradient(colors: [.white.opacity(0.18), .clear],
                                         startPoint: .top, endPoint: .center))
                    .blur(radius: 0.5)

                RoundedRectangle(cornerRadius: Style.Radius.button, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)

                RoundedRectangle(cornerRadius: Style.Radius.button, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.0))
                    .shadow(color: Color.white.opacity(0.18), radius: 14, x: 0, y: 6)
                    .shadow(color: Style.Palette.accentPink.opacity(0.35), radius: 28, x: 0, y: 10)
            }
        )
        .opacity(isEnabled ? 1 : 0.6)
        .scaleEffect(pressed ? 0.98 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: pressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !pressed { pressed = true } }
                .onEnded { _ in pressed = false }
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(Text(title))
    }
}
#Preview {
    NavigationStack { OnboardingView() }
}



