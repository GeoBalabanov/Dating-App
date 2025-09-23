//
//  chat.swift
//  DatingApp
//
//  Created by Georgi Balabanov on 23/09/2025.
//

import SwiftUI

struct MessagingHomeView: View {
    @State private var searchText = ""
    
    // Sample data
    let contacts = [
        Contact(name: "Emma", image: "person.crop.circle.fill"),
        Contact(name: "Laura", image: "person.crop.circle.fill"),
        Contact(name: "Leona", image: "person.crop.circle.fill"),
        Contact(name: "Amanda", image: "person.crop.circle.fill")
    ]
    
    let messages = [
        Message(contact: "Emma", content: "Typing...", time: "now", isTyping: true),
        Message(contact: "Laura", content: "Hey! I heard you talking about cats haha..", time: "1 hour ago"),
        Message(contact: "Leona", content: "Huuh, we literally have the same top songs!", time: "6 hours ago"),
        Message(contact: "Laura", content: "Yo, can you share your playlist and if you want maybe grab some co..", time: "A day ago")
    ]
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.black, location: 0.0),
                    .init(color: Color.orange.opacity(0.8), location: 0.4),
                    .init(color: Color.red.opacity(0.9), location: 1.0)
                ]),
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top section with search
                VStack(spacing: 20) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.7))
                        
                        TextField("Search", text: $searchText)
                            .foregroundColor(.white)
                            .placeholder(when: searchText.isEmpty) {
                                Text("Search")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        
                        Button(action: {}) {
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white.opacity(0.1))
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(.ultraThinMaterial)
                            )
                    )
                    .padding(.horizontal)
                    
                    // Contact avatars
                    HStack(spacing: 20) {
                        ForEach(contacts, id: \.name) { contact in
                            VStack(spacing: 8) {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: contact.image)
                                            .foregroundColor(.white)
                                            .font(.title2)
                                    )
                                
                                Text(contact.name)
                                    .foregroundColor(.white)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 10)
                
                Spacer().frame(height: 30)
                
                // Messages section
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Messages")
                            .foregroundColor(.white)
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    
                    // Message list
                    LazyVStack(spacing: 0) {
                        ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                            MessageRow(message: message)
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                        }
                    }
                }
                
                Spacer()
                
                // Bottom navigation
                HStack {
                    Button(action: {}) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "house")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "person")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
        }
    }
}

struct MessageRow: View {
    let message: Message
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                )
            
            // Message content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(message.contact)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(message.time)
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)
                }
                
                Text(message.content)
                    .foregroundColor(message.isTyping ? .white.opacity(0.6) : .white.opacity(0.8))
                    .font(.system(size: 15))
                    .italic(message.isTyping)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

// MARK: - Models
struct Contact {
    let name: String
    let image: String
}

struct Message {
    let contact: String
    let content: String
    let time: String
    let isTyping: Bool
    
    init(contact: String, content: String, time: String, isTyping: Bool = false) {
        self.contact = contact
        self.content = content
        self.time = time
        self.isTyping = isTyping
    }
}

// MARK: - Helper Views
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - Extensions
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
    
    func backdrop<V: View>(_ view: V) -> some View {
        self.background(view)
    }
}

// MARK: - Preview
struct MessagingHomeView_Previews: PreviewProvider {
    static var previews: some View {
        MessagingHomeView()
            .preferredColorScheme(.dark)
    }
}
