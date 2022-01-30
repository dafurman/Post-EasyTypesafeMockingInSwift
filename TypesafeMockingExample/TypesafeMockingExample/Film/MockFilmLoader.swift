//
//  MockFilmLoader.swift
//  TypesafeMockingExample
//
//  Created by David Furman on 1/29/22.
//

import Foundation

#if DEBUG
final class MockFilmLoader: FilmLoader {
    var films: [String: Film] = [:]

    func loadFilm(episode id: String) async throws -> Film {
        guard let film = films[id] else { throw GenericError.missingData }
        return film
    }

    func loadFilms(episodes ids: [String]) async throws -> [Film] {
        ids.compactMap { films[$0] }
    }
}
#endif
