//
//  ConversationView.swift
//  DatingApp
//
//  Created by Georgi Balabanov on 23/09/2025.
//

import SwiftUI
import UIKit

struct ChatMessage: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let isMe: Bool
    let time: Date

    static func text(_ t: String, isMe: Bool, time: Date = .now) -> ChatMessage {
        .init(text: t, isMe: isMe, time: time)
    }
}

struct ConversationThread {
    let partnerName: String
    let partnerAvatar: String?
    var messages: [ChatMessage]
}

struct ConversationView: View {
    @State var thread: ConversationThread
    @State private var draft = ""

    var body: some View {
        ZStack {
            AyaBackground(style: .orange, vignette: true)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(thread.messages) { msg in
                            Bubble(msg)
                                .id(msg.id)
                                .transition(.move(edge: msg.isMe ? .trailing : .leading).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .onChange(of: thread.messages.count) { _ in
                    if let last = thread.messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
        .navigationTitle(thread.partnerName)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Composer(draft: $draft, send: send)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .background(.ultraThinMaterial)
                .overlay(Rectangle().frame(height: 0.5).foregroundStyle(Style.Palette.borderSubtle), alignment: .top)
        }
        .preferredColorScheme(.dark)
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let new = ChatMessage.text(text, isMe: true)
        withAnimation(.easeInOut) {
            thread.messages.append(new)
            draft = ""
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        // demo reply
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut) {
                thread.messages.append(.text("Sounds good!", isMe: false))
            }
        }
    }
}

// MARK: - Pieces

private struct Bubble: View {
    let m: ChatMessage
    init(_ m: ChatMessage) { self.m = m }

    var body: some View {
        HStack {
            if m.isMe { Spacer() }
            Text(m.text)
                .font(.body)
                .foregroundStyle(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(m.isMe ? 0.9 : 0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Style.Palette.glassStroke, lineWidth: 1)
                )
            if !m.isMe { Spacer() }
        }
        .padding(.horizontal, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(m.isMe ? "You" : "Partner") said, \(m.text)")
    }
}

private struct Composer: View {
    @Binding var draft: String
    var send: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField("Message…", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.10))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Style.Palette.glassStroke, lineWidth: 1)
                )
                .foregroundStyle(.white)
                .tint(.white)
                .submitLabel(.send)
                .onSubmit(send)

            Button(action: send) {
                Image(systemName: "paperplane.fill")
                    .font(.title3.weight(.semibold))
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(.ultraThinMaterial))
                    .overlay(Circle().stroke(Style.Palette.glassStroke, lineWidth: 1))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Send")
        }
        .padding(.bottom, 8)
    }
}

#Preview {
    ConversationView(thread: .init(
        partnerName: "Emma",
        partnerAvatar: nil,
        messages: [
            .text("Hey Emma! 👋", isMe: true, time: .now.addingTimeInterval(-3600)),
            .text("Hi! Love your playlist.", isMe: false, time: .now.addingTimeInterval(-3550))
        ]
    ))
}

