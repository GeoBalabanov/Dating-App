//
//  SettingsView.swift
//  DatingApp
//
//  Created by Zhan Hrsitov on 23/09/2025.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.12, green: 0.0, blue: 0.22),
                    Color(red: 0.07, green: 0.0, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Title
                Text("Settings")
                    .font(.system(size: 36, weight: .thin))
                    .kerning(0.5)
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(.top, 24)
                    .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        SettingsSection(
                            title: "Profile",
                            symbol: "person.crop.circle",
                            items: [
                                .link(title: "Edit Profile"),
                                .link(title: "Manage Photos"),
                                .link(title: "Re-record Voice Intro"),
                                .link(title: "Help & Support"),
                                .link(title: "Terms of Service")
                            ]
                        )

                        Divider()
                            .overlay(Color.white.opacity(0.15))
                            .padding(.trailing, 16)

                        SettingsSection(
                            title: "Privacy & Safety",
                            symbol: "shield.lefthalf.filled",
                            items: [
                                .link(title: "Blocked Users"),
                                .link(title: "Privacy Settings"),
                                .link(title: "Report an Issue")
                            ]
                        )

                        SettingsSection(
                            title: "Preferences",
                            symbol: "slider.horizontal.3",
                            items: [
                                .link(title: "Notifications"),
                                .link(title: "Spotify Sync")
                            ]
                        )

                        Spacer(minLength: 80) // breathing room above bottom bar
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
            }
        }
        // ✅ attach the shared glassy bottom bar
        .safeAreaInset(edge: .bottom) {
            BottomGlassyBar()
        }
    }

    // MARK: Shared Bottom Nav (glassy rounded box)
    @ViewBuilder
    private func BottomGlassyBar() -> some View {
        HStack(spacing: 18) {
            // Home -> OnboardingView
            NavigationLink {
                OnboardingView()
            } label: {
                NavIcon(system: "house.fill", label: "Home")
            }
            .buttonStyle(.plain)

            // Chat -> OnboardingView (replace later if needed)
            NavigationLink {
                MessagingHomeView()
            } label: {
                NavIcon(system: "bubble.left.and.bubble.right.fill", label: "Chat")
            }
            .buttonStyle(.plain)

            // Profile -> ProfileView
            NavigationLink {
                ProfileView()
            } label: {
                NavIcon(system: "person.crop.circle", label: "Profile")
            }
            .buttonStyle(.plain)

            // Settings -> SettingsView (current screen; still allowed to push)
            NavigationLink {
                SettingsView()
            } label: {
                NavIcon(system: "gearshape", label: "Settings")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: 16, x: 0, y: 8)
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }

    private struct NavIcon: View {
        let system: String
        let label: String
        var body: some View {
            VStack(spacing: 6) {
                Image(systemName: system)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Section + Row

struct SettingsSection: View {
    enum Item {
        case link(title: String)
    }

    let title: String
    let symbol: String
    let items: [Item]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }

            // Items
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    switch item {
                    case .link(let title):
                        NavigationLink(destination: PlaceholderScreen(title: title)) {
                            HStack {
                                Text(title)
                                    .foregroundStyle(.white.opacity(0.7))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.25))
                            }
                            .contentShape(Rectangle())
                        }
                    }
                }
            }
            .padding(.leading, 28) // indent list under header
        }
    }
}

// MARK: - Placeholder screen for links

struct PlaceholderScreen: View {
    let title: String
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text(title)
                .foregroundStyle(.white)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { SettingsView() }
            .preferredColorScheme(.dark)
    }
}
