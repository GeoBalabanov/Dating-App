//
//  MessagingHomeView.swift
//  DatingApp
//
//  Created by Georgi Balabanov on 23/09/2025.
//

import SwiftUI
import UIKit

// =============================================================
// MARK: - Lightweight models (scoped to this file only)
// =============================================================

struct Contact: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let image: String? // asset name or nil to use SF Symbol fallback
}

struct MessageSummary: Identifiable, Hashable {
    let id = UUID()
    let contact: Contact
    let content: String
    let time: Date
    var isTyping: Bool = false
    var unread: Int = 0
}

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
    let partner: Contact
    var messages: [ChatMessage]
}

// =============================================================
// MARK: - Messaging Home (rows are transparent)
// =============================================================

struct MessagingHomeView: View {
    @State private var query = ""
    @State private var chats: [MessageSummary] = MockData.seed

    private var filtered: [MessageSummary] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return chats }
        return chats.filter { $0.contact.name.lowercased().contains(q) || $0.content.lowercased().contains(q) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AyaBackground(style: .orange, vignette: true)

                List {
                    // Contacts header (horizontal bubbles)
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 18) {
                                ForEach(MockData.contacts) { c in
                                    VStack(spacing: 6) {
                                        NavigationLink {
                                            ConversationView(thread: startingThread(for: c))
                                        } label: {
                                            AvatarCircle(imageName: c.image, size: 56)
                                        }
                                        .buttonStyle(.plain)
                                        Text(c.name)
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.9))
                                    }
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                        }
                        .listRowBackground(Color.clear)
                    } header: { EmptyView() }

                    // Messages list — transparent rows
                    Section {
                        ForEach(filtered) { m in
                            NavigationLink {
                                ConversationView(thread: startingThread(for: m.contact))
                            } label: {
                                Row(summary: m) // no custom background inside
                            }
                            .listRowBackground(Color.clear)            // <- keeps gradient visible
                            .listRowSeparatorTint(.white.opacity(0.15))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation { chats.removeAll { $0.id == m.id } }
                                } label: { Label("Delete", systemImage: "trash") }

                                Button { } label: {
                                    Label("Mute", systemImage: "bell.slash")
                                }.tint(.orange)
                            }
                        }
                    } header: {
                        Text("MESSAGES")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)                    // remove default list bg
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color.black.opacity(0.15), for: .navigationBar) // subtle
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: { Image(systemName: "square.and.pencil") }
                    .foregroundStyle(.white)
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .automatic))
        }
        .preferredColorScheme(.dark)
    }

    private func startingThread(for c: Contact) -> ConversationThread {
        ConversationThread(
            partner: c,
            messages: [
                .text("Hey \(c.name)! 👋", isMe: true, time: .now.addingTimeInterval(-3600)),
                .text("Hi! Love your playlist.", isMe: false, time: .now.addingTimeInterval(-3550))
            ]
        )
    }
}

// =============================================================
// MARK: - Conversation Screen (inline)
// =============================================================

struct ConversationView: View {
    @State var thread: ConversationThread
    @State private var draft = ""
    @State private var isPartnerTyping = false
    @State private var botCtx: BotContext

    init(thread: ConversationThread) {
        self._thread = State(initialValue: thread)
        self._botCtx = State(initialValue: .init(
            partnerName: thread.partner.name,
            musicHints: ["Marso", "indie pop", "deep house", "neo-soul"],
            city: "Eindhoven"
        ))
    }

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
                        if isPartnerTyping { TypingDots().id("typing") }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .onChange(of: thread.messages.count) { _ in
                    if let last = thread.messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
                .onChange(of: isPartnerTyping) { _ in
                    proxy.scrollTo("typing", anchor: .bottom)
                }
            }
        }
        .navigationTitle(thread.partner.name)
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
        withAnimation(.easeInOut) {
            thread.messages.append(.text(text, isMe: true))
            draft = ""
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // bot reply
        isPartnerTyping = true
        let delay = Double.random(in: 0.8...1.6)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            var ctx = botCtx
            let reply = BotBrain.reply(to: text, context: &ctx)
            botCtx = ctx
            withAnimation(.easeInOut) {
                isPartnerTyping = false
                thread.messages.append(.text(reply, isMe: false))
            }
        }
    }
}

// =============================================================
// MARK: - Cells & UI Pieces (no row background here)
// =============================================================

private struct Row: View {
    let summary: MessageSummary
    var body: some View {
        HStack(spacing: 12) {
            AvatarCircle(imageName: summary.contact.image, size: 48)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(summary.contact.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(summary.time, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Text(summary.isTyping ? "Typing…" : summary.content)
                    .lineLimit(1)
                    .font(.callout)
                    .foregroundStyle(summary.isTyping ? .white : .white.opacity(0.85))
                    .italic(summary.isTyping)
            }

            if summary.unread > 0 {
                Text("\(summary.unread)")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .overlay(Capsule().stroke(Style.Palette.glassStroke, lineWidth: 1))
                    .foregroundStyle(.white)
            }
        }
        .contentShape(Rectangle()) // keeps full-row tap target
    }
}

private struct AvatarCircle: View {
    var imageName: String?
    var size: CGFloat = 48
    var body: some View {
        Group {
            if let n = imageName, UIImage(named: n) != nil {
                Image(n).resizable().scaledToFill()
            } else {
                Image(systemName: "person.fill")
                    .resizable().scaledToFit()
                    .padding(size * 0.22)
                    .foregroundStyle(.white.opacity(0.88))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .background(Circle().fill(.ultraThinMaterial))
        .overlay(Circle().stroke(Style.Palette.glassStroke, lineWidth: 1))
    }
}

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
        }
        .padding(.bottom, 8)
    }
}

private struct TypingDots: View {
    @State private var phase: CGFloat = 0
    var body: some View {
        HStack {
            Spacer()
            HStack(spacing: 6) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 6, height: 6)
                        .offset(y: sin(phase + CGFloat(i) * 0.8) * 3)
                        .animation(.easeInOut(duration: 0.6).repeatForever(), value: phase)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Style.Palette.glassStroke, lineWidth: 1)
            )
            Spacer()
        }
        .onAppear { phase = .pi / 2 }
        .padding(.horizontal, 6)
    }
}

// =============================================================
// MARK: - Tiny on-device bot
// =============================================================

struct BotContext {
    var partnerName: String
    var myName: String = "You"
    var musicHints: [String] = ["indie pop", "Marso", "house", "RnB"]
    var city: String? = nil
    var lastUserMessages: [String] = []
}

enum BotBrain {
    static func reply(to userText: String, context: inout BotContext) -> String {
        let text = userText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        context.lastUserMessages.append(userText)
        if context.lastUserMessages.count > 10 { context.lastUserMessages.removeFirst() }

        if text.isEmpty { return rand(["?", "tell me more :)", "say that again?"]) }
        if has(text, ["hello","hey","hi","yo","hiya","sup"]) { return rand(["Hey there! 👋","Hi! How’s your day going?","Hey! Nice to hear from you."]) }
        if has(text, ["music","song","track","spotify","playlist"]) {
            let tag = rand(context.musicHints)
            return rand([
                "Same! I’ve been looping \(tag) lately. What’s your current top song?",
                "I’m into \(tag) these days — got any recs?",
                "Love music chats. Drop me a song you’re vibing to."
            ])
        }
        if has(text, ["marso","kradena","artist"]) {
            return rand([
                "Marso slaps 🔥 — **Kradena** is stuck in my head.",
                "Oooh Marso — what’s your favorite track?",
                "Right?? Marso’s production is so clean."
            ])
        }
        if has(text, ["coffee","grab","meet","hang","drink"]) {
            let whereTxt = context.city.map { " around \($0)" } ?? ""
            return rand([
                "I’m down! There’s a cozy spot\(whereTxt). When works for you?",
                "Sounds fun — I’m free this weekend.",
                "Let’s do it! Afternoon or evening?"
            ])
        }
        if has(text, ["thanks","thank you","ty","thx"]) { return rand(["Anytime!","No problem 😊","You got it!"]) }
        if has(text, ["lol","haha","lmao","rofl"]) { return rand(["😂","Hahaha love it","lol same"]) }

        return rand([
            "Tell me more 🔎",
            "Ooh interesting — what made you say that?",
            "Nice. How did you get into that?",
            "Curious — what’s your hot take?"
        ])
    }

    private static func has(_ text: String, _ keys: [String]) -> Bool { keys.contains { text.contains($0) } }
    private static func rand<T>(_ a: [T]) -> T { a[Int.random(in: 0..<a.count)] }
}

// =============================================================
// MARK: - Mock seed
// =============================================================

enum MockData {
    static let contacts: [Contact] = [
        .init(name: "Emma",   image: nil),
        .init(name: "Laura",  image: nil),
        .init(name: "Leona",  image: nil),
        .init(name: "Amanda", image: nil),
    ]
    static let seed: [MessageSummary] = [
        .init(contact: contacts[0], content: "Typing…", time: .now, isTyping: true, unread: 1),
        .init(contact: contacts[1], content: "Hey! I heard you talking about cats haha..", time: .now.addingTimeInterval(-3600)),
        .init(contact: contacts[2], content: "We literally have the same top songs!", time: .now.addingTimeInterval(-21600)),
        .init(contact: contacts[3], content: "Can you share your playlist? Maybe coffee too..", time: .now.addingTimeInterval(-86400))
    ]
}

// =============================================================
// MARK: - Preview
// =============================================================

#Preview { MessagingHomeView() }




