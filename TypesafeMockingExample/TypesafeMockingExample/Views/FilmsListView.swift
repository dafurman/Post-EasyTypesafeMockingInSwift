//
//  FilmsListView.swift
//  TypesafeMockingExample
//
//  Created by David Furman on 1/29/22.
//

import SwiftUI

struct FilmsListView: View {
    private enum LoadState {
        case loaded([Film])
        case loading
        case error(Error)
    }

    private let filmLoader: FilmLoader
    @State private var loadState: LoadState = .loading

    init(filmLoader: FilmLoader = NetworkFilmLoader()) {
        self.filmLoader = filmLoader
    }

    var body: some View {
        NavigationView {
            Group {
                switch loadState {
                case .loaded(let films):
                    filmsList(for: films)
                case .loading:
                    ProgressView()
                case .error(let error):
                    Text("An error occured: \(error.localizedDescription)")
                }
            }
            .navigationTitle("Films")
        }
        .task(loadFilms)
    }

    private func filmsList(for films: [Film]) -> some View {
        List(films) { film in
            NavigationLink(destination: FilmOpeningCrawlView(film: film)) {
                filmRow(film)
            }
        }
    }

    private func filmRow(_ film: Film) -> some View {
        VStack(alignment: .leading) {
            Text(film.title)
                .font(.headline)
            Text("Episode \(film.episodeId)")
                .font(.subheadline)
            if let releaseDate = film.releaseDate {
                Text(releaseDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.footnote)
            }
        }
    }

    @Sendable private func loadFilms() async {
        loadState = .loading

        let episodeIds = (1...6).map { "\($0)" } // The API only has episodes 1-6 🤷
        do {
            let films = try await filmLoader.loadFilms(episodes: episodeIds)
            loadState = .loaded(films)
        } catch {
            loadState = .error(error)
        }
    }
}

struct FilmsListView_Previews: PreviewProvider {
    private static var filmLoader: FilmLoader = {
        let films = (1...6).map {
            Film.mocked(episodeId: $0)
        }
        let loader = MockFilmLoader()
        loader.films = .init(uniqueKeysWithValues: films.map { (String($0.episodeId), $0 )})
        return loader
    }()

    static var previews: some View {
        FilmsListView(filmLoader: filmLoader)
    }
}
