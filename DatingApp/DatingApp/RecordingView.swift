//
//  RecordingView.swift
//  DatingApp
//
//  Created by Zhan Hrsitov on 23/09/2025.
//

import SwiftUI
import AVFoundation

// MARK: - View

struct RecordVoiceView: View {
    @StateObject private var recorder = VoiceRecorder(durationLimit: 10)
    @State private var showPermissionAlert = false
    
    var body: some View {
        ZStack {
            // Background gradient similar to your mock
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
                
                Text("Share a 10-second intro about yourself. This helps others connect to your personality!")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 28)
                
                // Timer
                Text("\(recorder.formattedElapsed)/\(recorder.formattedLimit)")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.top, 8)
                
                // Mic button
                Button(action: {
                    Haptics.tap()
                    handleMicTap()
                }) {
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
                                // pulsing ring while recording
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
                     : "Tap the microphone to start recording! Share something about yourself!")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.75))
                .padding(.horizontal, 36)
                .padding(.top, 8)
                
                Spacer()
                
                // Continue button (enabled only if we have a file)
                Button {
                    Haptics.tap()
                    // TODO: push to the next screen; you have recorder.recordedURL
                    print("Recorded file:", recorder.recordedURL?.path ?? "none")
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
               actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text("Enable microphone access in Settings to record your intro.")
        })
        .onAppear {
            recorder.prepareSession() // set category early for smoother first tap
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

// MARK: - Recorder

final class VoiceRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    enum PermissionState { case undetermined, denied, granted }
    
    @Published var isRecording = false
    @Published var elapsed: TimeInterval = 0
    @Published var recordedURL: URL?
    
    let durationLimit: TimeInterval
    private var timer: Timer?
    private var session = AVAudioSession.sharedInstance()
    private var recorder: AVAudioRecorder?
    
    @Published private(set) var permissionState: PermissionState = .undetermined
    
    init(durationLimit: TimeInterval) {
        self.durationLimit = durationLimit
        super.init()
        refreshPermissionState()
    }
    
    // Session & permission
    func prepareSession() {
        do {
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session error:", error)
        }
    }
    
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
    
    // Recording
    func start() {
        stop(clean: true) // reset if needed
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
            // Start
            guard recorder?.record() == true else { return }
            isRecording = true
            elapsed = 0
            recordedURL = nil
            
            // UI timer
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] t in
                guard let self = self else { return }
                self.elapsed += 0.05
                if self.elapsed >= self.durationLimit {
                    self.stop()
                }
            }
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
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isRecording = false
            self.timer?.invalidate()
            self.timer = nil
            if flag {
                self.recordedURL = recorder.url
            } else {
                self.recordedURL = nil
            }
        }
    }
    
    // Utilities
    static func newFileURL() -> URL {
        let filename = "voice-intro-\(UUID().uuidString).m4a"
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
    }
    
    var formattedElapsed: String { Self.format(time: elapsed) }
    var formattedLimit: String { Self.format(time: durationLimit) }
    
    static func format(time: TimeInterval) -> String {
        let t = max(0, Int(time.rounded()))
        let m = t / 60
        let s = t % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Haptics helper

enum Haptics {
    static func tap() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

// MARK: - Preview

struct RecordVoiceView_Previews: PreviewProvider {
    static var previews: some View {
        RecordVoiceView()
            .preferredColorScheme(.dark)
    }
}
