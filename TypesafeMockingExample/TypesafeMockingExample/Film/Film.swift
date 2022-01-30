//
//  Film.swift
//  TypesafeMockingExample
//
//  Created by David Furman on 1/29/22.
//

import Foundation

struct Film: Codable, Identifiable {
    let title: String
    var episodeId: Int
    let openingCrawl: String
    let releaseDate: Date?

    var id: String {
        String(episodeId)
    }
}

#if DEBUG
extension Film {
    static func mocked(episodeId: Int = 1) -> Self {
        .init(
            title: "Star Wars Holiday Special",
            episodeId: episodeId,
            openingCrawl: "If I had the time and a sledgehammer, I would track down every copy of that show and smash it. - George Lucas\n\rIt is a period of civil war.\n\nRebel spaceships, striking\n\nfrom a hidden base, have won\n\ntheir first victory against\n\nthe evil Galactic Empire.\n\n\n\nDuring the battle, Rebel\n\nspies managed to steal secret\r\nplans to the Empire's\n\nultimate weapon, the DEATH\n\nSTAR, an armored space\n\nstation with enough power\n\nto destroy an entire planet.\n\n\n\nPursued by the Empire's\n\nsinister agents, Princess\n\nLeia races home aboard her\n\nstarship, custodian of the\n\nstolen plans that can save her\n\npeople and restore\n\nfreedom to the galaxy...",
            releaseDate: try? Date("1977-05-25", strategy: Date.ParseStrategy(
                format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits)",
                timeZone: .current
            ))
        )
    }
}

extension Film {
    static var episode1: Self {
        .init(
            title: "The Phantom Menace",
            episodeId: 1,
            openingCrawl: "Turmoil has engulfed the\r\nGalactic Republic. The taxation\r\nof trade routes to outlying star\r\nsystems is in dispute.\r\n\r\nHoping to resolve the matter\r\nwith a blockade of deadly\r\nbattleships, the greedy Trade\r\nFederation has stopped all\r\nshipping to the small planet\r\nof Naboo.\r\n\r\nWhile the Congress of the\r\nRepublic endlessly debates\r\nthis alarming chain of events,\r\nthe Supreme Chancellor has\r\nsecretly dispatched two Jedi\r\nKnights, the guardians of\r\npeace and justice in the\r\ngalaxy, to settle the conflict....",
            releaseDate: try? Date("1999-05-19", strategy: Date.ParseStrategy(
                format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits)",
                timeZone: .current
            ))
        )
    }

    static var episode2: Self {
        .init(
            title: "Attack of the Clones",
            episodeId: 1,
            openingCrawl: "There is unrest in the Galactic\r\nSenate. Several thousand solar\r\nsystems have declared their\r\nintentions to leave the Republic.\r\n\r\nThis separatist movement,\r\nunder the leadership of the\r\nmysterious Count Dooku, has\r\nmade it difficult for the limited\r\nnumber of Jedi Knights to maintain \r\npeace and order in the galaxy.\r\n\r\nSenator Amidala, the former\r\nQueen of Naboo, is returning\r\nto the Galactic Senate to vote\r\non the critical issue of creating\r\nan ARMY OF THE REPUBLIC\r\nto assist the overwhelmed\r\nJedi....",
            releaseDate: try? Date("2002-05-16", strategy: Date.ParseStrategy(
                format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits)",
                timeZone: .current
            ))
        )
    }
}
#endif
