//
//  Models.swift
//  DatingApp
//
//  Created by Georgi Balabanov on 23/09/2025.
//

import Foundation

struct Track: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let artist: String
    let previewURL: URL?

    static func from(api json: [String: Any]) -> Track? {
        guard
            let id = json["id"] as? String,
            let name = json["name"] as? String,
            let artists = json["artists"] as? [[String: Any]],
            let firstArtist = artists.first?["name"] as? String
        else { return nil }

        let preview = (json["preview_url"] as? String).flatMap(URL.init(string:))
        return Track(id: id, name: name, artist: firstArtist, previewURL: preview)
    }
}

struct MatchCandidate {
    let name: String
    let location: String
    let avatarAssetName: String?
    var voiceURL: URL?            // 10s intro
    var topTracks: [Track] = []   // filled after Spotify connect
}
