//
//  NetworkResourceLoader.swift
//  TypesafeMockingExample
//
//  Created by David Furman on 1/29/22.
//

import Foundation

final class NetworkResourceLoader<T: Decodable> {
    func loadResource(at url: URL) async throws -> T {
        let request = URLRequest(url: url)
        let (data, _) = try await URLSession.shared.data(for: request)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        let resource = try decoder.decode(T.self, from: data)
        return resource
    }
}
