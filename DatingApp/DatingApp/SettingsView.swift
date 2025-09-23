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
        .overlay(
            BottomBar(selected: .settings),
            alignment: .bottom
        )
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

// MARK: - Bottom Bar

enum TabKind { case settings, home, profile }

struct BottomBar: View {
    var selected: TabKind

    var body: some View {
        HStack {
            tab(icon: "gearshape", tab: .settings)
            Spacer()
            tab(icon: "house", tab: .home)
            Spacer()
            tab(icon: "person", tab: .profile)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private func tab(icon: String, tab: TabKind) -> some View {
        let isSelected = selected == tab
        Image(systemName: icon + (isSelected ? ".fill" : ""))
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(isSelected ? .white : .white.opacity(0.55))
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .onTapGesture {
                // Hook up navigation to other tabs here if you use TabView/Router.
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

// MARK: - Preview / App entry

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { SettingsView() }
            .preferredColorScheme(.dark)
    }
}
