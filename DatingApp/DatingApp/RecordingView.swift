//
//  RecordingView.swift
//  DatingApp
//
//  Created by Zhan Hrsitov on 23/09/2025.
//

import SwiftUI
import AVFoundation

// MARK: - Recording Screen

struct RecordingView: View {
    @StateObject private var recorder = RecordingEngine(durationLimit: 10) // seconds
    @State private var showPermissionAlert = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.18, blue: 0.27),
                    Color(red: 0.58, green: 0.23, blue: 0.47)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                Text("Record Your Voice")
                    .font(.system(size: 32, weight: .thin))
                    .kerning(0.5)
                    .foregroundStyle(.white.opacity(0.95))

                Text("Share a short voice intro. Tap the mic to start and tap again to stop.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 28)

                // Timer
                Text("\(recorder.formattedElapsed)/\(recorder.formattedLimit)")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.top, 8)

                // Mic button
                Button {
                    Haptics.tap()
                    handleMicTap()
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                .radialGradient(
                                    colors: [
                                        Color.white.opacity(0.06),
                                        Color.black.opacity(0.25)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 140
                                )
                            )
                            .frame(width: 180, height: 180)
                            .shadow(color: .black.opacity(0.4), radius: 18, x: 0, y: 10)
                            .overlay(
                                Circle()
                                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                            )
                            .overlay(
                                Circle()
                                    .stroke(lineWidth: recorder.isRecording ? 8 : 0)
                                    .foregroundStyle(.white.opacity(0.18))
                                    .scaleEffect(recorder.isRecording ? 1.12 : 1.0)
                                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: recorder.isRecording)
                            )

                        Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 52, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(recorder.isRecording ? "Stop recording" : "Start recording")

                Text(recorder.isRecording
                     ? "Recording… tap to stop"
                     : "Tap the microphone to start recording")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.75))
                .padding(.horizontal, 36)
                .padding(.top, 8)

                Spacer()

                // Continue button (enabled if we have a file)
                Button {
                    Haptics.tap()
                    if let url = recorder.recordedURL {
                        print("Recorded file: \(url.path)")
                        // Navigate to next screen or upload using `url`
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Continue")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 22, weight: .semibold))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(
                        Capsule().fill(.white.opacity(recorder.recordedURL == nil ? 0.18 : 0.28))
                    )
                    .overlay(
                        Capsule().stroke(.white.opacity(0.25), lineWidth: 1)
                    )
                    .foregroundStyle(.white.opacity(recorder.recordedURL == nil ? 0.55 : 0.95))
                }
                .disabled(recorder.recordedURL == nil)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
        }
        .alert("Microphone Access Needed",
               isPresented: $showPermissionAlert,
               actions: { Button("OK", role: .cancel) {} },
               message: { Text("Enable microphone access in Settings to record your intro.") })
        .onAppear {
            recorder.prepareSession() // set up audio session early
        }
    }

    private func handleMicTap() {
        switch recorder.permissionState {
        case .undetermined:
            recorder.requestPermission { granted in
                if granted { recorder.start() } else { showPermissionAlert = true }
            }
        case .denied:
            showPermissionAlert = true
        case .granted:
            recorder.isRecording ? recorder.stop() : recorder.start()
        }
    }
}

// MARK: - Recording Engine

final class RecordingEngine: NSObject, ObservableObject, AVAudioRecorderDelegate {
    enum PermissionState { case undetermined, denied, granted }

    @Published var isRecording = false
    @Published var elapsed: TimeInterval = 0
    @Published var recordedURL: URL?
    @Published private(set) var permissionState: PermissionState = .undetermined

    let durationLimit: TimeInterval
    private var timer: Timer?
    private let session = AVAudioSession.sharedInstance()
    private var recorder: AVAudioRecorder?

    init(durationLimit: TimeInterval) {
        self.durationLimit = durationLimit
        super.init()
        refreshPermissionState()
        observeInterruptions()
    }

    // Permissions
    func refreshPermissionState() {
        switch session.recordPermission {
        case .undetermined: permissionState = .undetermined
        case .denied:       permissionState = .denied
        case .granted:      permissionState = .granted
        @unknown default:   permissionState = .undetermined
        }
    }

    func requestPermission(_ completion: @escaping (Bool) -> Void) {
        session.requestRecordPermission { [weak self] allowed in
            DispatchQueue.main.async {
                self?.refreshPermissionState()
                completion(allowed)
            }
        }
    }

    // Session setup
    func prepareSession() {
        do {
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: [])
            print("Audio session ready. Route:", session.currentRoute)
        } catch {
            print("Audio session error:", error)
        }
    }

    // Start/Stop
    func start() {
        stop(clean: true) // reset previous state

        refreshPermissionState()
        guard permissionState == .granted else {
            print("Recording blocked: permission =", permissionState)
            return
        }
        prepareSession()

        let url = Self.newFileURL()
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.delegate = self
            recorder?.isMeteringEnabled = true
            recorder?.prepareToRecord()

            let ok = recorder?.record() ?? false
            if !ok {
                print("AVAudioRecorder.record() returned false")
                return
            }

            isRecording = true
            elapsed = 0
            recordedURL = nil

            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.elapsed += 0.05
                if self.elapsed >= self.durationLimit {
                    self.stop()
                }
            }
            if let timer { RunLoop.main.add(timer, forMode: .common) }

            print("Recording started →", url.lastPathComponent)
        } catch {
            print("Failed to start recording:", error)
        }
    }

    func stop(clean: Bool = false) {
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        isRecording = false
        if clean {
            recordedURL = nil
            elapsed = 0
        } else {
            recordedURL = recorder?.url
        }
    }

    // Delegate
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isRecording = false
            self.timer?.invalidate()
            self.timer = nil
            self.recordedURL = flag ? recorder.url : nil
            print("Recording finished:", flag, self.recordedURL?.path ?? "nil")
        }
    }

    // Interruptions (phone call, Siri, etc.)
    private func observeInterruptions() {
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: session, queue: .main) { [weak self] note in
            guard let self else { return }
            guard let info = note.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
            if type == .began, self.isRecording {
                self.stop()
                print("Recording interrupted and stopped.")
            }
        }
    }

    // Utils
    static func newFileURL() -> URL {
        let name = "voice-intro-\(UUID().uuidString).m4a"
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(name)
    }

    var formattedElapsed: String { Self.format(time: elapsed) }
    var formattedLimit: String { Self.format(time: durationLimit) }

    static func format(time: TimeInterval) -> String {
        let t = max(0, Int((time).rounded()))
        return String(format: "%d:%02d", t/60, t%60)
        }
}

// MARK: - Haptics

enum Haptics {
    static func tap() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

// MARK: - Preview

struct RecordingView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingView()
            .preferredColorScheme(.dark)
    }
}
