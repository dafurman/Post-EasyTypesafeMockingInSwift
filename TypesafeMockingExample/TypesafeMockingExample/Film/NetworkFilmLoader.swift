//
//  NetworkFilmLoader.swift
//  TypesafeMockingExample
//
//  Created by David Furman on 1/29/22.
//

import Foundation

final class NetworkFilmLoader: FilmLoader {
    func loadFilm(episode id: String) async throws -> Film {
        let url = URL(string: "https://swapi.dev/api/films/\(id)")!
        return try await NetworkResourceLoader().loadResource(at: url)
    }

    func loadFilms(episodes ids: [String]) async throws -> [Film] {
        try await withThrowingTaskGroup(of: Film.self) { group in
            for id in ids {
                group.addTask {
                    try await self.loadFilm(episode: id)
                }
            }

            var films: [Film] = []
            for try await film in group {
                films.append(film)
            }
            return films.sorted { $0.episodeId < $1.episodeId }
        }
    }
}
