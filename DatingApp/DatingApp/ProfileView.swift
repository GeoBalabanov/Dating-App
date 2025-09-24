//
//  ProfileView.swift
//  DatingApp
//
//  Created by Zhan Hrsitov on 23/09/2025.
//

import SwiftUI
import PhotosUI
import AVFoundation

// MARK: - Profile Screen (full-tracks via Spotify App Remote)

struct ProfileView: View {
    // Avatar
    @State private var selectedItem: PhotosPickerItem?
    @State private var avatarUIImage: UIImage? = nil

    // Voice intro (local playback of your recorded .m4a)
    @StateObject private var voicePlayer = VoiceIntroPlayer()
    @State private var showRecorder = false

    // Spotify
    @StateObject private var spotifyAuth = SpotifyAuth.shared
    @State private var tracks: [SpotifyTrack] = []     // uses SpotifyAPI + has .uri for full play
    @State private var showSearch = false
    @State private var isLoading = false
    @State private var errorText: String?

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(colors: [
                Color(red: 0.06, green: 0.25, blue: 0.10),
                Color(red: 0.90, green: 0.35, blue: 0.10)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // Avatar + name + location
                    VStack(spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            Group {
                                if let ui = avatarUIImage {
                                    Image(uiImage: ui)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white.opacity(0.9), .black.opacity(0.25))
                                }
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 2))
                            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)

                            // Edit -> Photos picker
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white)
                                    .background(
                                        Circle().fill(.ultraThinMaterial)
                                            .frame(width: 36, height: 36)
                                    )
                                    .offset(x: 6, y: 6)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 24)

                        Text("Alexia")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(.white)

                        Text("Eindhoven, Noord Brabant")
                            .foregroundStyle(.white.opacity(0.75))
                    }

                    // Voice Intro
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Voice Intro")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)

                        GlassCard {
                            HStack(spacing: 16) {
                                Text("Play Voice Intro")
                                    .foregroundStyle(.white.opacity(0.85))
                                Spacer()

                                Button {
                                    voicePlayer.togglePlay()
                                } label: {
                                    Image(systemName: voicePlayer.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .frame(width: 42, height: 42)
                                        .background(Circle().fill(.white.opacity(0.14)))
                                        .foregroundStyle(.white)
                                }
                                .buttonStyle(.plain)
                                .disabled(!voicePlayer.hasFile)

                                Button {
                                    showRecorder = true
                                } label: {
                                    Image(systemName: "record.circle")
                                        .font(.system(size: 22, weight: .semibold))
                                        .frame(width: 42, height: 42)
                                        .background(Circle().fill(.white.opacity(0.14)))
                                        .foregroundStyle(.white)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Record a new voice intro")
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Spotify Section (FULL TRACKS via App Remote)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "music.note")
                                Text("Spotify")
                            }
                            .font(.title3.bold())
                            .foregroundStyle(.white)

                            Spacer()
                            Text("Plays in Spotify")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }

                        GlassCard {
                            if !spotifyAuth.isAuthorized {
                                VStack(spacing: 12) {
                                    Text("Connect your Spotify to pick songs and play full tracks (opens the Spotify app).")
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(.white.opacity(0.8))

                                    Button {
                                        Task {
                                            isLoading = true
                                            defer { isLoading = false }
                                            do {
                                                let token = try await spotifyAuth.ensureToken()
                                                tracks = try await SpotifyAPI.topTracks(token: token)
                                            } catch {
                                                errorText = error.localizedDescription
                                            }
                                        }
                                    } label: {
                                        HStack { Image(systemName: "link"); Text("Connect to Spotify") }
                                            .padding(.horizontal, 16).padding(.vertical, 10)
                                            .background(Capsule().fill(.white.opacity(0.2)))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                VStack(alignment: .leading, spacing: 16) {
                                    ForEach(tracks, id: \.id) { t in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(t.name).foregroundStyle(.white.opacity(0.95))
                                                Text(t.artist).italic().foregroundStyle(.white.opacity(0.8))
                                            }
                                            Spacer()
                                            Button {
                                                SpotifyRemote.shared.play(uri: t.uri) // full song in Spotify
                                            } label: {
                                                Image(systemName: "play.fill")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .frame(width: 40, height: 40)
                                                    .background(Circle().fill(.white.opacity(0.14)))
                                                    .foregroundStyle(.white)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }

                                    Divider().overlay(Color.white.opacity(0.12))

                                    HStack {
                                        Text("Add New Song")
                                            .foregroundStyle(.white.opacity(0.75))
                                        Spacer()
                                        Button { showSearch = true } label: {
                                            Image(systemName: "plus")
                                                .font(.system(size: 18, weight: .bold))
                                                .frame(width: 42, height: 42)
                                                .background(Circle().fill(.white.opacity(0.14)))
                                                .foregroundStyle(.white)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }
        }
        // Avatar update
        .onChange(of: selectedItem) { newItem in
            Task {
                guard let item = newItem,
                      let data = try? await item.loadTransferable(type: Data.self),
                      let ui = UIImage(data: data) else { return }
                avatarUIImage = ui
            }
        }
        // Refresh voice intro + load top tracks if already connected
        .onAppear {
            voicePlayer.refreshLatestFile()
            Task {
                guard spotifyAuth.isAuthorized, tracks.isEmpty else { return }
                do { tracks = try await SpotifyAPI.topTracks(token: spotifyAuth.accessToken!) }
                catch { errorText = error.localizedDescription }
            }
        }
        // Sheets & alerts
        .sheet(isPresented: $showRecorder, onDismiss: { voicePlayer.refreshLatestFile() }) {
            RecordingView()
        }
        .sheet(isPresented: $showSearch) {
            SpotifySearchSheet()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didPickSpotifyTrack)) { note in
            if let t = note.object as? SpotifyTrack, !tracks.contains(t) {
                tracks.append(t)
            }
        }
        .alert("Error", isPresented: .constant(errorText != nil), actions: {
            Button("OK") { errorText = nil }
        }, message: { Text(errorText ?? "") })
    }
}

// MARK: - Reusable UI

struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 14)
    }
}

// MARK: - Voice Intro (local player)

final class VoiceIntroPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var hasFile = false

    private var audioPlayer: AVAudioPlayer?
    private(set) var url: URL?

    func refreshLatestFile() {
        url = Self.latestVoiceIntroURL()
        hasFile = (url != nil)
    }

    func togglePlay() {
        if isPlaying { audioPlayer?.stop(); isPlaying = false; return }
        guard let url else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Audio play error:", error)
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { self.isPlaying = false }
    }

    private static func latestVoiceIntroURL() -> URL? {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        guard let items = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return nil }

        let candidates = items.filter {
            $0.lastPathComponent.hasPrefix("voice-intro-") &&
            $0.pathExtension.lowercased() == "m4a"
        }

        return candidates.max { a, b in
            let da = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let db = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return da < db
        }
    }
}

// MARK: - Spotify Search Sheet (adds tracks; full songs play via App Remote)

struct SpotifySearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var spotifyAuth = SpotifyAuth.shared
    @State private var query = ""
    @State private var results: [SpotifyTrack] = []
    @State private var errorText: String?
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField("Search songs or artists", text: $query)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.search)
                        .focused($focused)
                        .onSubmit { Task { await runSearch() } }
                    Button("Search") { Task { await runSearch() } }
                }
                .padding()

                if results.isEmpty {
                    Spacer()
                    Text("Type a song/artist and press Search.")
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    List(results) { t in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(t.name)
                                Text(t.artist).font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "play.fill").foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            NotificationCenter.default.post(name: .didPickSpotifyTrack, object: t)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Add a Song")
            .alert("Error", isPresented: .constant(errorText != nil), actions: {
                Button("OK") { errorText = nil }
            }, message: { Text(errorText ?? "") })
            .onAppear { focused = true }
        }
    }

    private func runSearch() async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        do {
            let token = try await spotifyAuth.ensureToken()
            results = try await SpotifyAPI.searchTracks(token: token, query: q)
        } catch { errorText = error.localizedDescription }
    }
}

extension Notification.Name { static let didPickSpotifyTrack = Notification.Name("didPickSpotifyTrack") }

// MARK: - Preview

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { ProfileView() }
            .preferredColorScheme(.dark)
    }
}



