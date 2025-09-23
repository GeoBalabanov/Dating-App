//
//  SpotifyModels.swift
//  DatingApp
//
//  Created by Georgi Balabanov on 23/09/2025.
//

import Foundation

struct SpotifyTrack: Identifiable, Hashable {
    let id: String
    let name: String
    let artist: String
    let previewURL: URL?
}

struct TopTracksResponse: Decodable {
    let items: [TrackItem]
    struct TrackItem: Decodable {
        let id: String
        let name: String
        let preview_url: String?
        let artists: [Artist]
        struct Artist: Decodable { let name: String }
    }
}
