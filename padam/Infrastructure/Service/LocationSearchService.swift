//
//  LocationSearchService.swift
//  padam
//
//  Wraps MapKit local search for setting the FIRE LOCATION. Suggestions come
//  from MKLocalSearchCompleter as the operator types; resolving a suggestion (or
//  raw text) to a coordinate uses MKLocalSearch.
//
//  Biased to the Jakarta region so results are locally relevant.
//

import Foundation
import MapKit

@MainActor
@Observable
final class LocationSearchService: NSObject, MKLocalSearchCompleterDelegate {

    private let completer = MKLocalSearchCompleter()

    /// Live suggestions for the current query text.
    private(set) var suggestions: [MKLocalSearchCompletion] = []

    override init() {
        super.init()
        completer.delegate = self
        completer.region = MapViewModel.jakartaRegion
        completer.resultTypes = [.address, .pointOfInterest]
    }

    /// Updates the query; clears suggestions when empty.
    func updateQuery(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            suggestions = []
            completer.cancel()
            return
        }
        completer.queryFragment = trimmed
    }

    /// Resolves a tapped suggestion to a concrete coordinate.
    func resolve(_ completion: MKLocalSearchCompletion) async -> Coordinate? {
        let request = MKLocalSearch.Request(completion: completion)
        request.region = MapViewModel.jakartaRegion
        return await search(request)
    }

    /// Resolves free-text (e.g. the operator pressed return) to a coordinate.
    func resolve(text: String) async -> Coordinate? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.region = MapViewModel.jakartaRegion
        return await search(request)
    }

    private func search(_ request: MKLocalSearch.Request) async -> Coordinate? {
        let response = try? await MKLocalSearch(request: request).start()
        guard let item = response?.mapItems.first else { return nil }
        return Coordinate(item.location.coordinate)
    }

    // MARK: MKLocalSearchCompleterDelegate

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results
        Task { @MainActor in self.suggestions = results }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in self.suggestions = [] }
    }
}
