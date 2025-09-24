//
//  MatchProfileView.swift
//  DatingApp
//
//  Created by Georgi Balabanov on 24/09/2025.
//

import SwiftUI
import AVFoundation

// MARK: - Matching profile page (dummy Spotify, blurred avatar, no edit)

struct MatchProfileView: View {
    // Dummy candidate
    private let candidate = Candidate(
        name: "Alexia",
        location: "Eindhoven, Noord Brabant",
        avatarAsset: "alexia_photo",                       // optional asset name
        voiceFile: AudioFileRef(name: "voice_intro", ext: "m4a") // plays if present, else simulates
    )

    // Dummy Spotify songs (drop files in bundle with these names to hear real audio)
    private let songs: [Song] = [
        .init(title: "Blinding Lights",  artist: "The Weeknd", file: AudioFileRef(name: "blinding_lights",  ext: "m4a")),
        .init(title: "Save Your Tears",  artist: "The Weeknd", file: AudioFileRef(name: "save_your_tears",  ext: "m4a")),
        .init(title: "Starboy",          artist: "The Weeknd", file: AudioFileRef(name: "starboy",          ext: "m4a")),
    ]

    // Voice state
    @State private var voice = PlayState()
    // Track state
    @State private var playingSongID: UUID?
    @State private var trackProgress: [UUID: CGFloat] = [:]

    var body: some View {
        ZStack {
            AyaBackground(style: .orange, vignette: true).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer().frame(height: 36)

                    // Avatar with soft blur overlay (no edit button)
                    BlurredAvatar(imageName: candidate.avatarAsset, size: 200, blur: 100)

                    // Name & location
                    VStack(spacing: 8) {
                        Text(candidate.name)
                            .font(.system(size: 40, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(candidate.location)
                            .font(.title3.italic())
                            .foregroundStyle(.white.opacity(0.95))
                    }

                    // Voice Intro
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader("Voice Intro")

                        GlassBar(
                            title: voice.isPlaying ? "Playing…" : "Play Voice Intro",
                            isPlaying: voice.isPlaying,
                            progress: voice.progress,
                            playTap: toggleVoice
                        )
                    }
                    .padding(.horizontal, 24)

                    // Spotify card (dummy)
                    SpotifyCardStatic(
                        songs: songs,
                        playingSongID: playingSongID,
                        progress: trackProgress,
                        playTap: toggleSong
                    )
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)
                }
            }
        }
        .onDisappear { AudioStub.shared.stopAll() }
        .preferredColorScheme(.dark)
    }

    // MARK: Actions

    private func toggleVoice() {
        if voice.isPlaying {
            AudioStub.shared.stop(.voice)
            voice.stop()
        } else {
            AudioStub.shared.play(
                .voice,
                bundleFile: candidate.voiceFile,
                simulatedDuration: 10,
                onProgress: { voice.progress = $0 },
                onFinish: { voice.stop() }
            )
            voice.start()
        }
    }

    private func toggleSong(_ song: Song) {
        if playingSongID == song.id {
            AudioStub.shared.stop(.track)
            playingSongID = nil
            trackProgress[song.id] = 0
            return
        }
        playingSongID = song.id
        trackProgress[song.id] = 0
        AudioStub.shared.play(
            .track,
            bundleFile: song.file,
            simulatedDuration: 30,
            onProgress: { pct in trackProgress[song.id] = pct },
            onFinish: {
                trackProgress[song.id] = 1
                playingSongID = nil
            }
        )
    }
}

// MARK: - UI Pieces

private struct SectionHeader: View {
    var title: String
    init(_ t: String) { title = t }
    var body: some View {
        Text(title)
            .font(.system(size: 28, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BlurredAvatar: View {
    var imageName: String?
    var size: CGFloat
    var blur: CGFloat = 6

    var body: some View {
        ZStack {
            avatar
                .blur(radius: blur)                       // blur on photo
                .overlay(Color.black.opacity(0.1))        // subtle dim for contrast
                .clipShape(Circle())

            // Slightly sharper inner layer for a nice “glow”
            avatar
                .clipShape(Circle())
                .scaleEffect(0.94)
                .opacity(0.7)
        }
        .frame(width: size, height: size)
        .background(Circle().fill(.ultraThinMaterial))
        .overlay(Circle().stroke(Style.Palette.glassStroke, lineWidth: 1))
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
    }

    @ViewBuilder private var avatar: some View {
        if let n = imageName, UIImage(named: n) != nil {
            Image(n).resizable().scaledToFill()
        } else {
            Image(systemName: "person.fill")
                .resizable().scaledToFit()
                .padding(size * 0.22)
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}

private struct GlassBar: View {
    var title: String
    var isPlaying: Bool
    var progress: CGFloat
    var playTap: () -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)

            GeometryReader { geo in
                Color.white.opacity(0.06)
                    .frame(width: max(0, progress) * geo.size.width)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            }
            .allowsHitTesting(false)

            HStack(spacing: 16) {
                Text(title)
                    .font(.title3.italic())
                    .foregroundStyle(.white.opacity(0.95))
                    .lineLimit(1)

                Spacer()

                Button(action: playTap) {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 56, height: 56)
                        .overlay(Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white))
                        .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
        }
        .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(.white.opacity(0.18), lineWidth: 1))
        .shadow(color: .black.opacity(0.28), radius: 16, x: 0, y: 8)
        .frame(maxWidth: .infinity)
    }
}

private struct SpotifyCardStatic: View {
    let songs: [Song]
    var playingSongID: UUID?
    var progress: [UUID: CGFloat]
    var playTap: (Song) -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.35), radius: 28, x: 0, y: 18)

            VStack(spacing: 18) {
                // Header: Spotify | Preview
                HStack {
                    Label {
                        Text("Spotify")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                    } icon: {
                        Image(systemName: "music.note")
                            .font(.title3.weight(.bold))
                    }
                    .foregroundStyle(.white)

                    Spacer()

                    Text("Preview")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)

                VStack(spacing: 22) {
                    ForEach(songs) { s in
                        SongRow(
                            song: s,
                            isPlaying: playingSongID == s.id,
                            progress: progress[s.id] ?? 0,
                            tap: { playTap(s) }
                        )
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 20)
            }
        }
    }
}

private struct SongRow: View {
    let song: Song
    var isPlaying: Bool
    var progress: CGFloat
    var tap: () -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)

            GeometryReader { geo in
                Color.white.opacity(0.06)
                    .frame(width: max(0, progress) * geo.size.width)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .allowsHitTesting(false)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(song.title)
                        .font(.title3.italic())
                        .foregroundStyle(.white.opacity(0.95))
                        .lineLimit(1)
                    Text(song.artist)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 6)

                Button(action: tap) {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                        )
                        .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 1))
        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
    }
}

// MARK: - Models

private struct AudioFileRef: Hashable {
    let name: String
    let ext: String
}

private struct Candidate {
    let name: String
    let location: String
    let avatarAsset: String?
    let voiceFile: AudioFileRef
}

private struct Song: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let artist: String
    let file: AudioFileRef? // if nil, playback simulates
}

private struct PlayState {
    var isPlaying = false
    var progress: CGFloat = 0
    mutating func start() { isPlaying = true }
    mutating func stop()  { isPlaying = false; progress = 0 }
}

// MARK: - Tiny audio helper (file if present, otherwise simulated)

private final class AudioStub {
    static let shared = AudioStub()

    enum Channel { case voice, track }

    private var players: [Channel: AVAudioPlayer] = [:]
    private var timers: [Channel: Timer] = [:]
    private var progressHandlers: [Channel: (CGFloat) -> Void] = [:]
    private var finishHandlers: [Channel: () -> Void] = [:]

    func play(_ channel: Channel,
              bundleFile: AudioFileRef?,
              simulatedDuration: TimeInterval,
              onProgress: @escaping (CGFloat) -> Void,
              onFinish: @escaping () -> Void) {

        stop(channel)
        progressHandlers[channel] = onProgress
        finishHandlers[channel] = onFinish

        // try real file first
        if let f = bundleFile,
           let url = Bundle.main.url(forResource: f.name, withExtension: f.ext),
           let p = try? AVAudioPlayer(contentsOf: url) {

            // ensure audio plays even if device is muted
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try? AVAudioSession.sharedInstance().setActive(true, options: [])

            players[channel] = p
            p.prepareToPlay()
            p.play()

            let t = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
                guard let self else { timer.invalidate(); return }
                let pct = min(1, p.duration == 0 ? 0 : p.currentTime / p.duration)
                onProgress(CGFloat(pct))
                if pct >= 1 { timer.invalidate(); self.finish(channel) }
            }
            timers[channel] = t
            RunLoop.main.add(t, forMode: .common)
            return
        }

        // simulated progress
        var elapsed: TimeInterval = 0
        onProgress(0)
        let d = max(0.01, simulatedDuration)
        let t = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self else { return }
            elapsed += 0.05
            let pct = min(1, elapsed / d)
            onProgress(CGFloat(pct))
            if pct >= 1 { timer.invalidate(); self.finish(channel) }
        }
        timers[channel] = t
        RunLoop.main.add(t, forMode: .common)
    }

    func stop(_ channel: Channel) {
        timers[channel]?.invalidate(); timers[channel] = nil
        players[channel]?.stop(); players[channel] = nil
        progressHandlers[channel]?(0); progressHandlers[channel] = nil
        finishHandlers[channel] = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    func stopAll() { stop(.voice); stop(.track) }

    private func finish(_ channel: Channel) {
        players[channel]?.stop(); players[channel] = nil
        timers[channel]?.invalidate(); timers[channel] = nil
        progressHandlers[channel]?(1); progressHandlers[channel] = nil
        if let f = finishHandlers[channel] { finishHandlers[channel] = nil; f() }
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}

#Preview {
    MatchProfileView()
}
