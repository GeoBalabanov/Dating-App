//
//  OnboardingView.swift
//  DatingApp
//
//  Created by Georgi Balabanov on 22/09/2025.
//

import SwiftUI

struct OnboardingLandingView: View {
    @State private var goNext = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background: your Aya gradient with a soft vignette
                AyaBackground(style: .pink, vignette: true)
                    .ignoresSafeArea()

                // A subtle dark radial to help the bottom text read on bright areas
                RadialGradient(colors: [.black.opacity(0.05), .black.opacity(0.35)],
                               center: .bottomTrailing,
                               startRadius: 40, endRadius: 520)
                    .blendMode(.multiply)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Spacer() // push content to the bottom like the design

                    // Headline
                    Text("Listen. Match.\nChat. Meet.")
                        .font(.system(size: 35, weight: .heavy, design: .none))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.45), radius: 8, x: 0, y: 2)

                    // Sub-copy
                    Text("Find love through senses. Whether you are looking for love, connection or just someone to vibe with – you are in the right place!")
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineSpacing(2)
                        .shadow(color: .black.opacity(0.45), radius: 6, x: 0, y: 2)

                    // CTA
                    Button {
                        goNext = true
                    } label: {
                        HStack(spacing: 8) {
                            Text("Get Started now")
                                .font(.system(size: 25, weight: .regular, design: .rounded).italic())
                            Image(systemName: "chevron.right")
                                .font(.title3.weight(.light))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        // make it feel like text on glass, very light
                        .background(.ultraThinMaterial.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.35), lineWidth: 0)
                        )
                        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)

                    // Safe bottom space
                    Spacer().frame(height: 22)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .navigationDestination(isPresented: $goNext) {
                // TODO: replace with your next screen (e.g., LoginView())
                LoginView()
            }
            .preferredColorScheme(.dark)
        }
    }
}

#Preview {
    OnboardingLandingView()
}




