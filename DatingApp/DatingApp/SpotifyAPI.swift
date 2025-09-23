//
//  SpotifyAPI.swift
//  DatingApp
//
//  Created by Georgi Balabanov on 23/09/2025.
//

import Foundation

enum SpotifyAPI {
    static func fetchTopTracks(limit: Int = 5, completion: @escaping ([SpotifyTrack]) -> Void) {
        SpotifyAuthManager.shared.validAccessToken { token in
            guard let token else { DispatchQueue.main.async { completion([]) }; return }

            var comps = URLComponents(string: "https://api.spotify.com/v1/me/top/tracks")!
            comps.queryItems = [.init(name: "limit", value: "\(limit)")]
            var req = URLRequest(url: comps.url!)
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: req) { data, _, _ in
                guard let data,
                      let dto = try? JSONDecoder().decode(TopTracksResponse.self, from: data) else {
                    DispatchQueue.main.async { completion([]) }
                    return
                }
                let tracks = dto.items.map {
                    SpotifyTrack(
                        id: $0.id,
                        name: $0.name,
                        artist: $0.artists.first?.name ?? "Unknown",
                        previewURL: $0.preview_url.flatMap(URL.init(string:))
                    )
                }
                DispatchQueue.main.async { completion(tracks) }
            }.resume()
        }
    }
}
