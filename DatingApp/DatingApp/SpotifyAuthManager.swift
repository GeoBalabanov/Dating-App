//
//  SpotifyAuthManager.swift
//  DatingApp
//
//  Created by Georgi Balabanov on 23/09/2025.
//

import Foundation
import AuthenticationServices
import CryptoKit

final class SpotifyAuthManager: NSObject, ObservableObject {
    static let shared = SpotifyAuthManager()

    // MARK: config
    private let clientID = "cce83efb73cb408a8379a1ea0bd699af"         // <- set me
    private let redirectURI = URL(string: "datingapp://spotify-callback")!   // <- matches URL Type

    private let authorizeURL = URL(string: "https://accounts.spotify.com/authorize")!
    private let tokenURL     = URL(string: "https://accounts.spotify.com/api/token")!
    private let scope        = "user-top-read"

    // MARK: token storage (simple)
    struct Tokens: Codable { let access: String; let refresh: String; let expiresAt: Date }
    @Published private(set) var tokens: Tokens? {
        didSet {
            if let t = tokens, let data = try? JSONEncoder().encode(t) {
                UserDefaults.standard.set(data, forKey: "spotify_tokens")
            } else {
                UserDefaults.standard.removeObject(forKey: "spotify_tokens")
            }
        }
    }

    private override init() {
        super.init()
        if let data = UserDefaults.standard.data(forKey: "spotify_tokens"),
           let t = try? JSONDecoder().decode(Tokens.self, from: data) {
            tokens = t
        }
    }

    // MARK: PKCE
    private var codeVerifier = ""
    private var session: ASWebAuthenticationSession?

    func signIn() {
        codeVerifier = Self.randomString(length: 64)
        let codeChallenge = Self.codeChallenge(for: codeVerifier)

        var comps = URLComponents(url: authorizeURL, resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            .init(name: "client_id", value: clientID),
            .init(name: "response_type", value: "code"),
            .init(name: "redirect_uri", value: redirectURI.absoluteString),
            .init(name: "scope", value: scope),
            .init(name: "code_challenge_method", value: "S256"),
            .init(name: "code_challenge", value: codeChallenge),
            .init(name: "show_dialog", value: "true")
        ]
        let url = comps.url!

        session = ASWebAuthenticationSession(url: url, callbackURLScheme: redirectURI.scheme) { [weak self] callbackURL, error in
            guard let self, let callbackURL, error == nil else { return }
            self.handleCallback(url: callbackURL)
        }
        session?.presentationContextProvider = self
        session?.prefersEphemeralWebBrowserSession = true
        session?.start()
    }

    private func handleCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else { return }

        // exchange code for tokens
        var req = URLRequest(url: tokenURL)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "client_id": clientID,
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI.absoluteString,
            "code_verifier": codeVerifier
        ]
        req.httpBody = body.urlEncodedData()

        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            guard let self, let data = data,
                  let tok = try? JSONDecoder().decode(TokenResponse.self, from: data) else { return }
            let expiresAt = Date().addingTimeInterval(TimeInterval(tok.expires_in))
            DispatchQueue.main.async {
                self.tokens = .init(access: tok.access_token, refresh: tok.refresh_token!, expiresAt: expiresAt)
            }
        }.resume()
    }

    func validAccessToken(completion: @escaping (String?) -> Void) {
        guard let t = tokens else { completion(nil); return }
        if t.expiresAt > Date().addingTimeInterval(30) {
            completion(t.access); return
        }
        refresh { ok in completion(ok ? self.tokens?.access : nil) }
    }

    private func refresh(completion: @escaping (Bool) -> Void) {
        guard let refresh = tokens?.refresh else { completion(false); return }

        var req = URLRequest(url: tokenURL)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = [
            "client_id": clientID,
            "grant_type": "refresh_token",
            "refresh_token": refresh
        ]
        req.httpBody = body.urlEncodedData()

        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            guard let self, let data = data,
                  let tok = try? JSONDecoder().decode(TokenResponse.self, from: data) else { completion(false); return }
            let expiresAt = Date().addingTimeInterval(TimeInterval(tok.expires_in))
            DispatchQueue.main.async {
                self.tokens = .init(access: tok.access_token,
                                    refresh: tok.refresh_token ?? refresh,
                                    expiresAt: expiresAt)
                completion(true)
            }
        }.resume()
    }
}

// MARK: - Helpers

extension SpotifyAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { .init() }
}

private struct TokenResponse: Decodable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let refresh_token: String?
    let scope: String?
}

private extension Dictionary where Key == String, Value == String {
    func urlEncodedData() -> Data {
        map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&").data(using: .utf8) ?? Data()
    }
}

private extension SpotifyAuthManager {
    static func randomString(length: Int) -> String {
        let chars = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return String((0..<length).map { _ in chars.randomElement()! })
    }
    static func codeChallenge(for verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64URLEncodedString()
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
