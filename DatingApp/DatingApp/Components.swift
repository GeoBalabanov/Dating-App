//
//  Components.swift
//  DatingApp
//
//  Created by Georgi Balabanov on 22/09/2025.
//

import SwiftUI

struct PrimaryButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
        }
        .background(
            RoundedRectangle(cornerRadius: Style.Radius.button, style: .continuous)
                .fill(Color.white.opacity(0.14))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Style.Radius.button, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        )
        .shadow(radius: 10, y: 4)
        .accessibilityLabel(Text(title))
    }
}

struct GlassPlate<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        content()
            .padding(Style.Spacing.l)
            .background(.ultraThinMaterial, in:
                RoundedRectangle(cornerRadius: Style.Radius.card, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Style.Radius.card, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
    }
}
