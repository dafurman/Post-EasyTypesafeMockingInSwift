# Easy Typesafe Mocking in Swift

I often feel that one of one of the greatest deterrents to writing good tests or Xcode previews is just taking the time to set up mock data in the first place. We're going to go through the process of making a basic app, complete with networking and previews, and then see how we can make this process easier and more scalable at the end. 

If you're just interested in seeing the improved solution to mocking, skip to the "Extensions to the Rescue!" section.

## Getting Started

Let's set up a basic project that performs some real networking. That means we'll need a real endpoint. I'm a big Star Wars fan, so I'll be using https://swapi.dev.

For this project, we're going to create a simple table of Star Wars films in chronological order. When we tap on a film, we'll then be taken to a screen that resembles the opening title crawl of the movie. Let's get started by creating a new Xcode project as an iOS app.

## Creating the Film Model

SWAPI has a description of its `films` resource [here](https://swapi.dev/documentation#films). We can see a list of attributes of a film, so let's create a Swift model to match a subset of some of the data we'll care about. Let's also make our model `Codable` and `Identifiable`. That'll come in handy later.

```swift
struct Film: Codable, Identifiable {
    let title: String
    let episodeId: Int
    let openingCrawl: String
    let releaseDate: Date?

    var id: String {
        title
    }
}
```

Great! We're all set with the model. Now to actually retrieve it from SWAPI.

## Creating the Network Layer

Let's start off by a generic means of loading any resource from SWAPI.

```swift
struct NetworkResourceLoader<T: Decodable> {
    func loadResource(at url: URL) async throws -> T {
        let request = URLRequest(url: url)
        let (data, _) = try await URLSession.shared.data(for: request)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase // We'll do this because our swift model property names differ from SWAPI's naming conventions. They follow web conventions, but we want to use Swift conventions.

        let resource = try decoder.decode(T.self, from: data)
        return resource
    }
}
```

Great, now let's focus on loading `Film`s. As [@DaveAbrahams](https://twitter.com/daveabrahams) suggested in his [Protocol-Oriented Programming in Swift WWDC presentation](https://developer.apple.com/videos/play/wwdc2015-408/?time=882), we're going to start with a protocol.

<video src="https://github.com/dafurman/Post-EasyTypesafeMockingInSwift/raw/main/Assets/Start%20with%20a%20Protocol.mp4"></video>

```swift
protocol FilmLoader {
    func loadFilm(episode id: String) async throws -> Film
    func loadFilms(episodes ids: [String]) async throws -> [Film]
}
```

From this, we can create two conforming types, `NetworkFilmLoader` and `MockFilmLoader`. Using our `NetworkResourceLoader`, creation of the `NetworkFilmLoader` becomes trivial:

```swift
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
```

### Creating a Mock Loader

We'll start off by creating another conformer to `FilmLoader` - `MockFilmLoader`, and when using mocking, it's valuable to be able to inject data that you want a mock to return, so let's fill out this class with that requirement:

```swift
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
```

You'll need to add this too, so that we can have an error to throw if mock data hasn't been filled out.

```swift
enum GenericError: Error {
    case missingData
}
```

Now we're at a pretty good place, we've got our `Film` model, a way to load real data, and a way to prepare and load mocked data. Doing all this without something to show for it is kind of dull though, let's create the views and put all this to use.

## Creating the Views

We're going to replace `ContentView` with a new `FilmsListView`, where we'll show a list of each Star Wars movie, along with some information - your basic table view. Let's get started by remaining focused on the data. Additionally, don't worry about previews right now, just comment them out for now. We'll get to that in a bit.

```swift
struct FilmsListView: View {
    // 1.
    private enum LoadState {
        case loaded([Film])
        case loading
        case error(Error)
    }

    private let filmLoader: FilmLoader
    @State private var loadState: LoadState = .loading
  
  	// 2.
    init(filmLoader: FilmLoader = NetworkFilmLoader()) {
        self.filmLoader = filmLoader
    }

    var body: some View {
        Text("TODO")
    }                             
}
```

1. For views that will be showing different states, I like to clearly define these states in an enum, and when a state may have associated data to show, I'll use an associated value in the enum.
2. We want to support dependency injection here, using `FilmLoader` as our property instead of a concrete `NetworkFilmLoader`. However, we'll use `NetworkFilmLoader` as the default value, to keep accessing this view easier in most places where it'd be used in the app.

Let's continue on by filling out the rest of the `FilmsListView`, to actually load and display data. Feel free to just copy-paste the rest of this:

```swift
struct FilmsListView: View {
  	...(copy paste the part below)
  
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
          filmRow(film)
        }
    }

    private func filmRow(_ film: Film) -> some View {
        VStack(alignment: .leading) {
            Text(film.title)
                .font(.headline)
            Text("Episode \(film.episodeId)")
                .font(.subheadline)
            Text(film.releaseDate.formatted(date: .abbreviated, time: .omitted))
                .font(.footnote)
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
```

One last thing, change `StarWarsExampleApp` to display our `FilmDetailView`:

```swift
@main
struct StarWarsExampleApp: App {
    var body: some Scene {
        WindowGroup {
            FilmsListView()
        }
    }
}
```

Now run the app and you'll see the list be populated with 6 films, using real data from SWAPI!

<img src="https://github.com/dafurman/Post-EasyTypesafeMockingInSwift/blob/main/Assets/First%20Run.png" alt="First Run" style="zoom:67%;" />

Nice! Now all we've got to do is create our view to show the opening crawl of each film, but that one's easy:

```swift
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
```

Now go back to `FilmsListView` to attach the navigation link:

```sw
private func filmsList(for films: [Film]) -> some View {
    List(films) { film in
        NavigationLink(destination: FilmOpeningCrawlView(film: film)) {
            filmRow(film)
        }
    }
}
```

And we're now done with the functionality of our app. Run it and check it out!

<video src="https://github.com/dafurman/Post-EasyTypesafeMockingInSwift/raw/main/Assets/Full%20Run.mp4"></video>

## Mocking the Data

Seeing real data is satisfying and all, but remember how we skipped the previews intentionally? Now it's time to fix that. Let's start with `FilmsListView`.

```swift
struct FilmsListView_Previews: PreviewProvider {
    private static let dateParseStrategy = Date.ParseStrategy(
        format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits)",
        timeZone: .current
    )

    private static var filmLoader: FilmLoader = {
        let films = (1...6).map {
            Film(
                title: "Film Title",
                episodeId: $0, // This is necessary to keep unique, for the List to work
                openingCrawl: "This is a lengthy opening crawl",
                releaseDate: try? Date("2000-01-01", strategy: dateParseStrategy)
            )
        }
        let loader = MockFilmLoader() // Use a mock loader instead of the real one.
        loader.films = .init(uniqueKeysWithValues: films.map { (String($0.episodeId), $0 )})
        return loader
    }()

    static var previews: some View {
        FilmsListView(filmLoader: filmLoader)
    }
}
```

Trigger the preview to refresh with ⌥+⌘+P and you'll see your list with some mocked data.

Let's do the same for `FilmOpeningCrawlView`:

```swift
struct FilmOpeningCrawlView_Previews: PreviewProvider {
    private static let dateParseStrategy = Date.ParseStrategy(
        format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits)",
        timeZone: .current
    )

    private static let film = Film(
        title: "Film Title",
        episodeId: 1,
        openingCrawl: "It is a period of civil war.\n\nRebel spaceships, striking\n\nfrom a hidden base, have won\n\ntheir first victory against\n\nthe evil Galactic Empire.\n\n\n\nDuring the battle, Rebel\n\nspies managed to steal secret\r\nplans to the Empire's\n\nultimate weapon, the DEATH\n\nSTAR, an armored space\n\nstation with enough power\n\nto destroy an entire planet.\n\n\n\nPursued by the Empire's\n\nsinister agents, Princess\n\nLeia races home aboard her\n\nstarship, custodian of the\n\nstolen plans that can save her\n\npeople and restore\n\nfreedom to the galaxy...", // We'll want to use a more realistic string to verify the layout of this view, as this string is used here.
        releaseDate: try? Date("2000-01-01", strategy: dateParseStrategy)
    )

    static var previews: some View {
        FilmOpeningCrawlView(film: film)
    }
}
```

Now that we've got a working app, and working previews, we're done right?

Well no, because there's an architectural issue with our code We're violating the [*Don't Repeat Yourself*](https://en.wikipedia.org/wiki/Don't_repeat_yourself) principle of software development. It's not particularly egregious right now because we're only doing this in two places, but could you imagine if we were building a full IMDB-style app? We'd need to be mocking `Film`s all over the place in Previews, not to mention unit tests. Our current implementation doesn't scale well.

## Extensions to the Rescue!

I love type extensions in Swift. They're really easy to add, and generally are a good way to follow the [SOLID](https://en.wikipedia.org/wiki/SOLID) open-closed princple.

Instead of manually initializing a `Film` to mock it, let's just create a static mocked version of it, to be reused anywhere in the app:

```swift
extension Film {
    static func mocked(episodeId: Int = 1) -> Self {
        .init(
            title: "Star Wars Holiday Special",
            episodeId: episodeId,
            openingCrawl: "If I had the time and a sledgehammer, I would track down every copy of that show and smash it. - George Lucas",
            releaseDate: try? Date("1978-11-17", strategy: Date.ParseStrategy(
                format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits)",
                timeZone: .current
            ))
        )
    }
}
```

Now let's go back and use it in our previews:

```swift
struct FilmOpeningCrawlView_Previews: PreviewProvider {
    static var previews: some View {
        FilmOpeningCrawlView(film: .mocked())
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
```

Isn't that so much simpler? It's less code and this mock is reusable anywhere in your app.

This pattern is also incredibly flexible. I've added support for passing an `episodeId` to the mock, for the sake of being `Identifiable` in a `List`, but you can do whatever you want with these, and configure them with whatever parameters you may want. For example, if you want different types of `Film` mocks, you could do something like this:

```swift
extension Film {
    static var mockEpisode1: Self {
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

    static var mockEpisode2: Self {
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
```

You can even add mocks to types that are imported into your project, like from Swift Packages or from Apollo!

## Preventing Mocks from Getting into Release Builds

There's something important to mention here. In the example I've given, these static var mocks will be compiled in release builds. As long as you're careful not to actually use a mock outside of WIP placeholders, tests, and previews, you'll be fine. However, if you want to be even more careful to ensure users don't see your mocks on accident, you may want to consider wrapping your mocks in preprocessor flags, like this:

```swift
#if DEBUG
extension Film {
  static func mocked() -> Self { ... }
}
#endif
```

You could also handle this at the file level, placing mock extensions in separate files, and only compiling those files in debug builds.

---

I hope this makes the creation of previews and tests easier for you! 😀

Here's a link to the completed project: https://github.com/dafurman/Post-EasyTypesafeMockingInSwift
