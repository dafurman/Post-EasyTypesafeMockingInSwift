//
//  FilmLoader.swift
//  TypesafeMockingExample
//
//  Created by David Furman on 1/29/22.
//

import Foundation

protocol FilmLoader {
    func loadFilm(episode id: String) async throws -> Film
    func loadFilms(episodes ids: [String]) async throws -> [Film]
}
