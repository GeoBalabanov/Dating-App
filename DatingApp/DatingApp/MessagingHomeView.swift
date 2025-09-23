//
//  MessagingHomeView.swift
//  DatingApp
//
//  Created by Georgi Balabanov on 23/09/2025.
//

import SwiftUI
import UIKit

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

struct MessagingHomeView: View {
    @State private var query = ""
    @State private var chats: [MessageSummary] = MockData.seed

    var filtered: [MessageSummary] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return chats }
        return chats.filter { $0.contact.name.lowercased().contains(q) || $0.content.lowercased().contains(q) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AyaBackground(style: .orange, vignette: true)

                List {
                    // Contact header (horizontal)
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 18) {
                                ForEach(MockData.contacts) { c in
                                    VStack(spacing: 6) {
                                        Button {
                                            openThread(c)
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
                    }

                    // Messages
                    Section("Messages") {
                        ForEach(filtered) { m in
                            NavigationLink {
                                ConversationView(thread: .init(
                                    partnerName: m.contact.name,
                                    partnerAvatar: m.contact.image,
                                    messages: MockThreads.thread(for: m.contact.name)
                                ))
                            } label: {
                                Row(summary: m)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {} label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {} label: {
                                    Label("Mute", systemImage: "bell.slash")
                                }.tint(.orange)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color.black.opacity(0.25), for: .navigationBar)
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        // compose new…
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .foregroundStyle(.white)
                    .accessibilityLabel("Compose")
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .automatic))
        }
        .preferredColorScheme(.dark)
    }

    private func openThread(_ c: Contact) {
        // no-op; tapping avatar opens thread via NavigationLink rows already
    }
}

// MARK: - Row

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
                    .accessibilityLabel(summary.isTyping ? "\(summary.contact.name) is typing" : summary.content)
            }

            if summary.unread > 0 {
                Text("\(summary.unread)")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .overlay(Capsule().stroke(Style.Palette.glassStroke, lineWidth: 1))
                    .foregroundStyle(.white)
                .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
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

// MARK: - Mock

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

// uses ChatMessage from ConversationView
enum MockThreads {
    static func thread(for who: String) -> [ChatMessage] {
        [
            .text("Hey \(who)! 👋", isMe: true, time: .now.addingTimeInterval(-3600)),
            .text("I heard you like indie pop — same here.", isMe: true, time: .now.addingTimeInterval(-3500)),
            .text("Yesss! Heard the new Marso?", isMe: false, time: .now.addingTimeInterval(-3400))
        ]
    }
}

#Preview { MessagingHomeView() }

