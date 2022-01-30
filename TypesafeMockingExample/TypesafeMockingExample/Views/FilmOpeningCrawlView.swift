//
//  FilmOpeningCrawlView.swift
//  TypesafeMockingExample
//
//  Created by David Furman on 1/29/22.
//

import SwiftUI

struct FilmOpeningCrawlView: View {
    let film: Film

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                Text("Episode \(film.episodeId)")
                    .font(.title)
                Text(film.title)
                    .font(.largeTitle)
                Spacer(minLength: 32)
                Text(film.openingCrawl)
                    .font(.body)
                Spacer(minLength: 16)
            }
        }
        .multilineTextAlignment(.center)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FilmOpeningCrawlView_Previews: PreviewProvider {
    static var previews: some View {
        FilmOpeningCrawlView(film: .mocked())
    }
}
