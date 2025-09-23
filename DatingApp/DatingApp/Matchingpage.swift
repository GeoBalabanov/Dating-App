//
//  Matchingpage.swift
//  DatingApp
//
//  Created by Georgi Balabanov on 23/09/2025.
//

import SwiftUI
import AVFoundation

// MARK: - Matching profile page (UI + dummy audio)

struct MatchProfileView: View {
    // Replace with your candidate model later
    private let candidate = Candidate(
        name: "Madeline",
        location: "Eindhoven, Noord Brabant",
        avatarAsset: "madeline_photo",          // add to Assets if you have it
        voiceFile: ("voice_intro", "m4a"),      // Bundle file name + ext
        trackTitle: "Kradena",
        trackArtist: "Marso",
        trackPreviewFile: ("marso_preview", "m4a")
    )

    @State private var voiceState = PlayState()
    @State private var trackState = PlayState()

    var body: some View {
        ZStack {
            // Blurred background
            backgroundImage(name: candidate.avatarAsset)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer().frame(height: 40)

                // Avatar
                ZStack {
                    Circle().fill(.ultraThinMaterial)
                    avatarImage(name: candidate.avatarAsset)
                        .clipShape(Circle())
                }
                .frame(width: 180, height: 180)
                .shadow(radius: 12)

                // Name & location
                VStack(spacing: 4) {
                    Text(candidate.name)
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(candidate.location)
                        .font(.callout.italic())
                        .foregroundStyle(.white.opacity(0.9))
                }

                Divider().overlay(Color.white.opacity(0.6)).padding(.horizontal, 60)

                // Voice Intro
                VStack(spacing: 14) {
                    Text("Voice Intro")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)

                    GlassButton(
                        title: voiceState.isPlaying ? "Playing…" : "Play Voice intro",
                        icon: voiceState.isPlaying ? "pause.fill" : "play.fill",
                        progress: voiceState.progress
                    ) {
                        toggleVoice()
                    }
                }
                .padding(.horizontal, 40)

                Divider().overlay(Color.white.opacity(0.6)).padding(.horizontal, 60)

                // Music Taste
                VStack(spacing: 14) {
                    Text("Music Taste")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)

                    TrackCard(
                        title: candidate.trackTitle,
                        artist: candidate.trackArtist,
                        isPlaying: trackState.isPlaying,
                        progress: trackState.progress
                    ) {
                        toggleTrack()
                    }
                }
                .padding(.horizontal, 40)

                Spacer()

                // Bottom nav icons (placeholders to match your UI)
                HStack {
                    Spacer()
                    Image(systemName: "gearshape")
                    Spacer()
                    Image(systemName: "house")
                    Spacer()
                    Image(systemName: "person.crop.circle")
                    Spacer()
                }
                .font(.title2.weight(.medium))
                .foregroundStyle(.white)
                .padding(.bottom, 20)
            }
        }
        .onDisappear {
            // Stop any playing audio when leaving the screen
            AudioStubPlayer.shared.stopAll()
        }
    }

    // MARK: Actions

    private func toggleVoice() {
        if voiceState.isPlaying {
            AudioStubPlayer.shared.stop(.voice)
            voiceState.stop()
        } else {
            AudioStubPlayer.shared.play(
                .voice,
                file: candidate.voiceFile,
                simulatedDuration: 10,
                onProgress: { voiceState.progress = $0 },
                onFinish: { voiceState.stop() }
            )
            voiceState.start()
        }
    }

    private func toggleTrack() {
        if trackState.isPlaying {
            AudioStubPlayer.shared.stop(.track)
            trackState.stop()
        } else {
            AudioStubPlayer.shared.play(
                .track,
                file: candidate.trackPreviewFile,
                simulatedDuration: 30,
                onProgress: { trackState.progress = $0 },
                onFinish: { trackState.stop() }
            )
            trackState.start()
        }
    }
}

// MARK: - View helpers

private func backgroundImage(name: String?) -> some View {
    Group {
        if let n = name, UIImage(named: n) != nil {
            Image(n).resizable().scaledToFill()
                .blur(radius: 40)
                .overlay(Color.black.opacity(0.25))
        } else {
            // Fallback gradient without using Color(hex:)
            LinearGradient(
                colors: [
                    Color(.sRGB, red: 195/255, green: 20/255,  blue: 50/255,  opacity: 1),
                    Color(.sRGB, red: 36/255,  green: 11/255,  blue: 54/255,  opacity: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private func avatarImage(name: String?) -> some View {
    Group {
        if let n = name, UIImage(named: n) != nil {
            Image(n).resizable().scaledToFill()
        } else {
            Image(systemName: "person.fill")
                .resizable().scaledToFit()
                .padding(30)
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}

// MARK: - Components

private struct GlassButton: View {
    var title: String
    var icon: String
    var progress: CGFloat // 0...1
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)

                // Progress overlay
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        GeometryReader { geo in
                            Color.white.opacity(0.08)
                                .frame(width: max(0, progress) * geo.size.width)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    )
                    .allowsHitTesting(false)

                HStack {
                    Text(title)
                        .font(.system(.title3, design: .rounded).italic())
                        .foregroundStyle(.white.opacity(0.95))
                    Spacer()
                    Image(systemName: icon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
        }
        .buttonStyle(.plain)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
    }
}

private struct TrackCard: View {
    var title: String
    var artist: String
    var isPlaying: Bool
    var progress: CGFloat
    var playPause: () -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)

            // Progress overlay
            GeometryReader { geo in
                Color.white.opacity(0.06)
                    .frame(width: max(0, progress) * geo.size.width)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .allowsHitTesting(false)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(artist)
                        .font(.headline.italic())
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Button(action: playPause) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
    }
}

// MARK: - Data + state

private struct Candidate {
    let name: String
    let location: String
    let avatarAsset: String?
    let voiceFile: (name: String, ext: String)
    let trackTitle: String
    let trackArtist: String
    let trackPreviewFile: (name: String, ext: String)
}

private struct PlayState {
    var isPlaying = false
    var progress: CGFloat = 0
    mutating func start() { isPlaying = true }
    mutating func stop()  { isPlaying = false; progress = 0 }
}

// MARK: - Audio player that works with or without files (dummy mode)

private final class AudioStubPlayer: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioStubPlayer()

    enum Channel { case voice, track }

    private var players: [Channel: AVAudioPlayer] = [:]
    private var timers: [Channel: Timer] = [:]
    private var durations: [Channel: TimeInterval] = [:]
    private var progressHandlers: [Channel: (CGFloat) -> Void] = [:]
    private var finishHandlers: [Channel: () -> Void] = [:]

    /// Play a file if present in Bundle, otherwise simulate for `simulatedDuration` seconds
    func play(_ channel: Channel,
              file: (name: String, ext: String),
              simulatedDuration: TimeInterval,
              onProgress: @escaping (CGFloat) -> Void,
              onFinish: @escaping () -> Void) {

        stop(channel) // stop any existing

        progressHandlers[channel] = onProgress
        finishHandlers[channel] = onFinish

        if let url = Bundle.main.url(forResource: file.name, withExtension: file.ext),
           let p = try? AVAudioPlayer(contentsOf: url) {
            players[channel] = p
            durations[channel] = p.duration
            p.delegate = self
            p.prepareToPlay()
            p.play()
            startPolling(channel: channel, duration: p.duration)
        } else {
            // Simulated playback
            durations[channel] = simulatedDuration
            var elapsed: TimeInterval = 0
            onProgress(0)
            let t = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
                guard let self else { return }
                elapsed += 0.05
                let d = max(0.01, simulatedDuration)
                let progress = min(1, elapsed / d)
                onProgress(CGFloat(progress))
                if progress >= 1 {
                    timer.invalidate()
                    self.finish(channel)
                }
            }
            timers[channel] = t
            RunLoop.main.add(t, forMode: .common)
        }
    }

    func stop(_ channel: Channel) {
        timers[channel]?.invalidate()
        timers[channel] = nil
        players[channel]?.stop()
        players[channel] = nil
        progressHandlers[channel]?(0)
        progressHandlers[channel] = nil
        finishHandlers[channel] = nil
        durations[channel] = nil
    }

    func stopAll() {
        stop(.voice); stop(.track)
    }

    // MARK: AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard let entry = players.first(where: { $0.value == player }) else { return }
        let channel = entry.key
        finish(channel)
    }

    // MARK: helpers

    private func startPolling(channel: Channel, duration: TimeInterval) {
        let t = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self, let p = self.players[channel] else { timer.invalidate(); return }
            let progress = min(1, p.duration == 0 ? 0 : p.currentTime / p.duration)
            self.progressHandlers[channel]?(CGFloat(progress))
            if progress >= 1 {
                timer.invalidate()
                self.finish(channel)
            }
        }
        timers[channel] = t
        RunLoop.main.add(t, forMode: .common)
    }

    private func finish(_ channel: Channel) {
        players[channel]?.stop()
        players[channel] = nil
        timers[channel]?.invalidate()
        timers[channel] = nil
        progressHandlers[channel]?(1)
        progressHandlers[channel] = nil
        if let finish = finishHandlers[channel] {
            finishHandlers[channel] = nil
            finish()
        }
    }
}

#Preview {
    MatchProfileView()
}


