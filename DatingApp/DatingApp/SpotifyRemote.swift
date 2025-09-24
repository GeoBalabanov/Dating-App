//
//  SpotifyRemote.swift
//  DatingApp
//
//  Created by Zhan Hrsitov on 23/09/2025.
//

import Foundation
import UIKit
import SpotifyiOS

@MainActor
final class SpotifyRemote: NSObject, ObservableObject {
    static let shared = SpotifyRemote()

    private let clientID = "cce83efb73cb408a8379a1ea0bd699af"
    private let redirectURL = URL(string: "datingapp://spotify-callback")!

    private lazy var configuration = SPTConfiguration(clientID: clientID, redirectURL: redirectURL)
    private lazy var appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)

    @Published var isConnected = false

    private override init() {
        super.init()
        appRemote.delegate = self
    }

    /// Play a Spotify track URI. If not connected, this will open Spotify, authorize, and then play.
    func play(uri: String) {
        if appRemote.isConnected {
            appRemote.playerAPI?.play(uri, callback: nil)
        } else {
            // New SDK: this returns Void (no URL). It launches Spotify for auth + playback.
            appRemote.authorizeAndPlayURI(uri)
        }
    }

    /// Forward redirect URLs from your App.onOpenURL here.
    func handleCallbackURL(_ url: URL) {
        let params = appRemote.authorizationParameters(from: url)

        if let accessToken = params?[SPTAppRemoteAccessTokenKey] {
            appRemote.connectionParameters.accessToken = accessToken
            appRemote.connect()
        } else if let errorDesc = params?[SPTAppRemoteErrorDescriptionKey] {
            print("AppRemote auth error:", errorDesc)
        }
    }

    func disconnect() {
        if appRemote.isConnected { appRemote.disconnect() }
    }
}

extension SpotifyRemote: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        isConnected = true
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { _, error in
            if let error { print("subscribe error:", error) }
        })
        print("Spotify App Remote connected")
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        isConnected = false
        print("Spotify App Remote failed:", error?.localizedDescription ?? "unknown")
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        isConnected = false
        print("Spotify App Remote disconnected:", error?.localizedDescription ?? "unknown")
    }
}

extension SpotifyRemote: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        // Optional: update UI if you want to reflect play/pause or track name
        print("Now playing:", playerState.track.name, "paused:", playerState.isPaused)
    }
}
