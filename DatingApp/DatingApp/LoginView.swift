//
//  LoginView.swift
//  DatingApp
//
//  Created by Georgi Balabanov on 22/09/2025.
//

import SwiftUI

struct LoginView: View {
    // MARK: - State
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword = false
    @State private var rememberMe = false

    var body: some View {
        ZStack {
            AyaBackground(style: .pink, vignette: true)

            VStack(spacing: Style.Spacing.l) {
                // Header
                VStack(spacing: Style.Spacing.s) {
                    Text("Welcome to Aya")
                        .font(Style.FontStyle.title)
                        .foregroundStyle(.white)
                        .shadow(radius: 6)

                    Text("Create your account and find meaningful connections")
                        .font(Style.FontStyle.subtitle)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Style.Spacing.xl)
                }
                .padding(.top, 60)

                // Form (glass)
                VStack(spacing: Style.Spacing.m) {
                    GlassTextField(
                        title: "Enter your email",
                        text: $email,
                        keyboard: .emailAddress,
                        textContentType: .emailAddress
                    )

                    GlassSecureField(
                        title: "Enter your password",
                        text: $password,
                        isSecure: !showPassword
                    ) {
                        // trailing eye toggle
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .buttonStyle(.plain)
                    }

                    HStack {
                        Toggle(isOn: $rememberMe) {
                            Text("Remember me")
                                .font(Style.FontStyle.caption)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .toggleStyle(.checkbox)

                        Spacer()

                        Button {
                            // forgot password action
                        } label: {
                            Text("Forgot password?")
                                .font(Style.FontStyle.caption)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 2)
                }
                .padding(Style.Spacing.l)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Style.Radius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Style.Radius.card, style: .continuous)
                        .stroke(Style.Palette.borderSubtle, lineWidth: 1)
                )
                .padding(.horizontal, Style.Spacing.xl)

                // Primary CTA
                FigmaPrimaryButton(title: "Log in into Aya", icon: "chevron.right") {
                    // handle login (validate email/password)
                }
                .padding(.horizontal, Style.Spacing.xl)

                // Social logins (glass buttons)
                VStack(spacing: Style.Spacing.m) {
                    GlassWideButton(
                        title: "Log in with Facebook",
                        systemImage: "person.fill" // swap with your own FB asset if you add one
                    ) {
                        // facebook login
                    }
                    GlassWideButton(
                        title: "Log in with Google",
                        systemImage: "person.fill" // swap with Google asset
                    ) {
                        // google login
                    }
                }
                .padding(.horizontal, Style.Spacing.xl)

                // Footer
                HStack(spacing: 6) {
                    Text("Don’t have an account?")
                        .foregroundStyle(.white.opacity(0.85))
                        .font(Style.FontStyle.caption)
                    Button {
                        // navigate to sign up
                    } label: {
                        Text("Create one")
                            .font(Style.FontStyle.caption)
                            .foregroundStyle(.white)
                            .underline()
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 24)

                Spacer(minLength: 0)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Components (local to this file)

// TextField with glass underline style
private struct GlassTextField: View {
    var title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField(title, text: $text)
                .keyboardType(keyboard)
                .textContentType(textContentType)
                .foregroundStyle(.white)
                .tint(.white)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)

            Divider()
                .background(Color.white.opacity(0.8))
        }
    }
}

// Secure/Text field with trailing accessory (eye)
private struct GlassSecureField<Trailing: View>: View {
    var title: String
    @Binding var text: String
    var isSecure: Bool
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if isSecure {
                    SecureField(title, text: $text)
                        .foregroundStyle(.white)
                        .tint(.white)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                } else {
                    TextField(title, text: $text)
                        .foregroundStyle(.white)
                        .tint(.white)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
                trailing()
            }

            Divider()
                .background(Color.white.opacity(0.8))
        }
    }
}

// Wide glass button (used for social)
private struct GlassWideButton: View {
    var title: String
    var systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.headline)
                Text(title)
                    .font(Style.FontStyle.button)
                Spacer()
            }
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: Style.Radius.button, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Style.Radius.button, style: .continuous)
                .stroke(Style.Palette.glassStroke, lineWidth: 1)
        )
        .shadow(color: Style.Palette.accentPink.opacity(0.25), radius: 18, x: 0, y: 8)
    }
}

// Checkbox-style toggle to mimic your design’s small “Remember me”
private struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            Button {
                configuration.isOn.toggle()
            } label: {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .buttonStyle(.plain)

            configuration.label
        }
    }
}

private extension ToggleStyle where Self == CheckboxToggleStyle {
    static var checkbox: CheckboxToggleStyle { CheckboxToggleStyle() }
}

#Preview {
    LoginView()
}
