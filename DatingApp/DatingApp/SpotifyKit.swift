//
//  SpotifyKit.swift
//  DatingApp
//
//  Created by Zhan Hrsitov on 23/09/2025.
//

//
//  SpotifyKit.swift
//  DatingApp
//
//  Auth (PKCE) + simple Web API wrapper + 30s preview player.
//  Redirect URI: datingapp://spotify-callback
//  Client ID:    cce83efb73cb408a8379a1ea0bd699af
//

//
//  SpotifyKit.swift
//  Full-track control needs App Remote; Web API here is for search/top-tracks.
//  Redirect URI: datingapp://spotify-callback
//  Client ID:    cce83efb73cb408a8379a1ea0bd699af
//

import SwiftUI
import UIKit
import AuthenticationServices
import CryptoKit
import AVFoundation

// MARK: - Public Models

struct SpotifyTrack: Identifiable, Hashable {
    let id: String
    let name: String
    let artist: String
    let uri: String            // <-- needed for full playback
    let previewURL: URL?       // optional (we keep it; not used for full tracks)
    let artworkURL: URL?
}

// MARK: - Auth (PKCE)

@MainActor
final class SpotifyAuth: ObservableObject {
    static let shared = SpotifyAuth()

    private let clientID = "cce83efb73cb408a8379a1ea0bd699af"
    private let redirectURI = "datingapp://spotify-callback"
    private let scopes = "user-top-read"

    @Published private(set) var accessToken: String?
    private var refreshToken: String?
    private var expiry: Date?

    private var codeVerifier: String = ""
    private var codeChallenge: String = ""

    var isAuthorized: Bool { accessToken != nil && (expiry ?? .distantPast) > Date() }

    func signIn() async throws {
        codeVerifier = Self.randomURLSafeString(length: 64)
        codeChallenge = Self.codeChallenge(for: codeVerifier)

        let encRedirect = redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let encScopes = scopes.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let authURL = URL(string:
            "https://accounts.spotify.com/authorize?client_id=\(clientID)&response_type=code&redirect_uri=\(encRedirect)&code_challenge_method=S256&code_challenge=\(codeChallenge)&scope=\(encScopes)"
        )!

        let scheme = redirectURI.components(separatedBy: "://").first!
        let callbackURL = try await Self.startAuthSession(authURL: authURL, callbackScheme: scheme)

        guard
            let comps = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
            let code = comps.queryItems?.first(where: { $0.name == "code" })?.value
        else { throw NSError(domain: "SpotifyAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No code in callback"]) }

        try await exchangeCodeForToken(code: code)
    }

    func ensureToken() async throws -> String {
        if let token = accessToken, let expiry, expiry > Date().addingTimeInterval(30) { return token }
        if let refreshToken { try await refreshAccessToken(refreshToken: refreshToken); return accessToken! }
        try await signIn(); return accessToken!
    }

    private func exchangeCodeForToken(code: String) async throws {
        var req = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = [
            "client_id": clientID,
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI,
            "code_verifier": codeVerifier
        ]
        req.httpBody = Self.formURLEncoded(body).data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: req)
        let tok = try JSONDecoder().decode(TokenResponse.self, from: data)
        accessToken = tok.access_token
        refreshToken = tok.refresh_token
        expiry = Date().addingTimeInterval(TimeInterval(tok.expires_in))
    }

    private func refreshAccessToken(refreshToken: String) async throws {
        var req = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = [
            "client_id": clientID,
            "grant_type": "refresh_token",
            "refresh_token": refreshToken
        ]
        req.httpBody = Self.formURLEncoded(body).data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: req)
        let tok = try JSONDecoder().decode(TokenResponse.self, from: data)
        accessToken = tok.access_token
        if let newRefresh = tok.refresh_token { self.refreshToken = newRefresh }
        expiry = Date().addingTimeInterval(TimeInterval(tok.expires_in))
    }

    private struct TokenResponse: Decodable {
        let access_token: String
        let token_type: String
        let expires_in: Int
        let refresh_token: String?
        let scope: String?
    }

    private static func startAuthSession(authURL: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { cont in
            let sess = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { url, err in
                if let err { cont.resume(throwing: err); return }
                guard let url else {
                    cont.resume(throwing: NSError(domain: "SpotifyAuth", code: -2, userInfo: [NSLocalizedDescriptionKey: "No callback URL"]))
                    return
                }
                cont.resume(returning: url)
            }
            sess.presentationContextProvider = PresentationProvider.shared
            sess.prefersEphemeralWebBrowserSession = true
            sess.start()
        }
    }

    private final class PresentationProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
        static let shared = PresentationProvider()
        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow }) ?? UIWindow()
        }
    }

    private static func formURLEncoded(_ d: [String: String]) -> String {
        d.map { k,v in
            let k = k.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? k
            let v = v.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? v
            return "\(k)=\(v)"
        }.joined(separator: "&")
    }
    private static func randomURLSafeString(length: Int) -> String {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        return String((0..<length).compactMap { _ in chars.randomElement() })
    }
    private static func codeChallenge(for verifier: String) -> String {
        let hash = SHA256.hash(data: Data(verifier.utf8))
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - Web API

enum SpotifyAPI {
    static func topTracks(token: String, limit: Int = 10) async throws -> [SpotifyTrack] {
        var c = URLComponents(string: "https://api.spotify.com/v1/me/top/tracks")!
        c.queryItems = [URLQueryItem(name: "limit", value: "\(limit)")]
        var req = URLRequest(url: c.url!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: req)
        let payload = try JSONDecoder().decode(TracksResponse.self, from: data)
        return payload.items.map { $0.toModel() }
    }

    static func searchTracks(token: String, query: String, limit: Int = 10) async throws -> [SpotifyTrack] {
        var c = URLComponents(string: "https://api.spotify.com/v1/search")!
        c.queryItems = [
            .init(name: "q", value: query),
            .init(name: "type", value: "track"),
            .init(name: "limit", value: "\(limit)")
        ]
        var req = URLRequest(url: c.url!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: req)
        let payload = try JSONDecoder().decode(SearchResponse.self, from: data)
        return payload.tracks.items.map { $0.toModel() }
    }

    private struct TracksResponse: Decodable { let items: [TrackDTO] }
    private struct SearchResponse: Decodable { let tracks: TracksResponse }

    private struct TrackDTO: Decodable {
        struct Artist: Decodable { let name: String }
        struct Album: Decodable { struct Image: Decodable { let url: String }; let images: [Image] }
        let id: String
        let name: String
        let uri: String              // <-- include from API
        let preview_url: String?
        let artists: [Artist]
        let album: Album

        func toModel() -> SpotifyTrack {
            SpotifyTrack(
                id: id,
                name: name,
                artist: artists.first?.name ?? "Unknown",
                uri: uri,
                previewURL: preview_url.flatMap(URL.init(string:)),
                artworkURL: album.images.first.flatMap { URL(string: $0.url) }
            )
        }
    }
}

// (Keep SpotifyPreviewPlayer if you still want 30s previews somewhere)
