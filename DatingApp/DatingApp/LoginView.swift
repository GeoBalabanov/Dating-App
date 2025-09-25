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
    @State private var goNext = false
    @State private var password: String = ""
    @State private var rememberMe = false
    @State private var showPassword = false
    @FocusState private var focus: Field?
    enum Field { case email, password }

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
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Style.Spacing.xl)
                }
                .padding(.top, 60)

                // Underlined fields
                VStack(spacing: Style.Spacing.l) {

                    UnderlineField(
                        placeholder: "Enter your email",
                        text: $email,
                        isFocused: focus == .email,
                        trailingDot: true
                    )
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .focused($focus, equals: .email)

                    UnderlineSecureField(
                        placeholder: "Enter your password",
                        text: $password,
                        isSecure: !showPassword,
                        isFocused: focus == .password,
                        trailing: {
                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                        }
                    )
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .focused($focus, equals: .password)

                    // Remember / Forgot
                    HStack(spacing: 12) {
                        Toggle(isOn: $rememberMe) {
                            Text("Remember me")
                                .font(Style.FontStyle.caption)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .toggleStyle(.checkbox)

                        Spacer()

                        Button {
                            // forgot password flow
                        } label: {
                            Text("Forgot password?")
                                .font(Style.FontStyle.caption)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Style.Spacing.xl)

                // Big italic CTA as text-like button
                Button {
                    goNext = true
                    // validate & sign in
                } label: {
                    HStack(spacing: 6) {
                        Text("Log in into Aya")
                            .font(.system(size: 28, weight: .regular, design: .rounded).italic())
                            .foregroundStyle(.white)
                        Image(systemName: "chevron.right")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .offset(y: -1)
                            .navigationDestination(isPresented: $goNext) {
                                // TODO: replace with your next screen (e.g., LoginView())
                                MatchProfileView()
                                
                            }
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 8)

                // Social (outlined capsules)
                VStack(spacing: Style.Spacing.m) {
                    OutlinedSocialButton(
                        title: "Log in with Facebook",
                        brandLetter: "f"
                    ) {
                        // facebook sign-in
                    }
                    OutlinedSocialButton(
                        title: "Log in with Google",
                        brandLetter: "G"
                    ) {
                        // google sign-in
                    }
                }
                .padding(.horizontal, Style.Spacing.xl)

                // Footer
                HStack(spacing: 6) {
                    Text("Don’t have an account?")
                        .foregroundStyle(.white.opacity(0.9))
                        .font(Style.FontStyle.caption)
                    Button {
                        // navigate to sign-up
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
        .onTapGesture { hideKeyboard() } // dismiss keyboard on background tap
    }

    private func hideKeyboard() {
        focus = nil
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

// MARK: - Underline components

private struct UnderlineField: View {
    var placeholder: String
    @Binding var text: String
    var isFocused: Bool
    var trailingDot: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                TextField(placeholder, text: $text)
                    .foregroundStyle(.white)
                    .tint(.white)
                    .placeholderStyle()
                if trailingDot {
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 3, height: 3)
                        .padding(.trailing, 2)
                        .accessibilityHidden(true)
                }
            }
            DatingApp.underline(isFocused: isFocused)
        }
    }
}

private struct UnderlineSecureField<Trailing: View>: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool
    var isFocused: Bool
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .foregroundStyle(.white)
                        .tint(.white)
                        .placeholderStyle()
                } else {
                    TextField(placeholder, text: $text)
                        .foregroundStyle(.white)
                        .tint(.white)
                        .placeholderStyle()
                }
                trailing()
            }
            DatingApp.underline(isFocused: isFocused)
        }
    }
}

@ViewBuilder
private func underline(isFocused: Bool) -> some View {
    Rectangle()
        .fill(Color.white.opacity(isFocused ? 0.9 : 0.65))
        .frame(height: 1)
        .shadow(radius: isFocused ? 2 : 0)
}

// MARK: - Outlined social button (with brand letter in a circle)

private struct OutlinedSocialButton: View {
    var title: String
    var brandLetter: String  // "f" or "G"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .overlay(
                        Text(brandLetter)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    )
                    .frame(width: 44, height: 44)

                Text(title)
                    .font(Style.FontStyle.button)
                    .foregroundStyle(.white)

                Spacer()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            Capsule().fill(Color.white.opacity(0.06))
        )
        .overlay(
            Capsule().stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Helpers

private extension View {
    /// Dimmed italic placeholder look like your mock.
    func placeholderStyle() -> some View {
        self
            .font(Style.FontStyle.body.italic())
            .foregroundStyle(.white.opacity(0.9))
    }
}

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


