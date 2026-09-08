//
//  MapViewModel.swift
//  padam
//
//  Drives the single-screen experience: the map plus the always-present bottom
//  sheet. Data loading and ranking live in services (WaterSourceLoader,
//  RankingService, MapClustering) so this type stays thin and UI-focused.
//

import SwiftUI
import MapKit

@MainActor
@Observable
final class MapViewModel {

    /// The phase the operator is in. The sheet renders differently per phase.
    enum Phase {
        case search   // no fire location set yet
        case results  // fire location set, showing ranked groups
    }

    // MARK: Static data

    /// Jakarta mainland, used to auto-zoom on launch.
    static let jakartaRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -6.2000, longitude: 106.8167),
        span: MKCoordinateSpan(latitudeDelta: 0.42, longitudeDelta: 0.42)
    )

    // MARK: State

    private(set) var allSources: [WaterSource]

    var cameraPosition: MapCameraPosition = .region(jakartaRegion)
    var mapStyleIsSatellite = false

    /// The fire location the operator is refilling for. `nil` means initial/search.
    private(set) var fireLocation: Coordinate?
    private(set) var rankedGroups: [RankedGroup] = []

    /// The point the operator has tapped/opened for detail.
    var selectedSource: WaterSource?

    /// Visible region, updated as the camera moves; drives clustering and keeps
    /// the number of on-screen annotations bounded regardless of dataset size.
    var visibleRegion: MKCoordinateRegion = jakartaRegion

    var phase: Phase { fireLocation == nil ? .search : .results }

    // MARK: Init

    init(loader: WaterSourceLoader = WaterSourceLoader()) {
        self.allSources = loader.loadAll()
    }

    // MARK: Derived

    /// Water-source pins aggregated for the current zoom level. Only sources
    /// within (a padded box around) the visible region are considered, so the
    /// annotation count stays bounded even when zoomed in on a dense dataset.
    var clusters: [MapCluster] {
        let visible = allSources.filter { isInPaddedVisibleRegion($0.coordinate) }
        let cellSize = MapClustering.cellSize(forLongitudeSpan: visibleRegion.span.longitudeDelta)
        return MapClustering.cluster(visible, cellSizeDegrees: cellSize)
    }

    private func isInPaddedVisibleRegion(_ coordinate: Coordinate) -> Bool {
        let latPad = visibleRegion.span.latitudeDelta * 0.75
        let lonPad = visibleRegion.span.longitudeDelta * 0.75
        let dLat = abs(coordinate.latitude - visibleRegion.center.latitude)
        let dLon = abs(coordinate.longitude - visibleRegion.center.longitude)
        return dLat <= latPad && dLon <= lonPad
    }

    /// The ranked groups flattened into the display order (used by the full list).
    var allRankedSources: [RankedWaterSource] {
        rankedGroups.flatMap(\.sources)
    }

    // MARK: Actions

    /// Sets the fire location, re-ranks, and frames the map on it.
    func setFireLocation(_ coordinate: Coordinate) {
        fireLocation = coordinate
        rankedGroups = RankingService.rank(sources: allSources, from: coordinate)
        selectedSource = nil
        frame(on: coordinate, spanDegrees: 0.05)
    }

    /// Returns to the initial search state to correct a wrong fire location.
    func backToSearch() {
        fireLocation = nil
        rankedGroups = []
        selectedSource = nil
        withAnimation {
            cameraPosition = .region(Self.jakartaRegion)
        }
    }

    func select(_ source: WaterSource) {
        selectedSource = source
        frame(on: source.coordinate, spanDegrees: 0.01)
    }

    func onCameraChanged(region: MKCoordinateRegion) {
        visibleRegion = region
    }

    /// Zooms in a step, centered on the tapped cluster/point.
    func zoomIn(on coordinate: Coordinate) {
        let newSpan = max(visibleRegion.span.longitudeDelta / 2.5, 0.004)
        frame(on: coordinate, spanDegrees: newSpan)
    }

    // MARK: Helpers

    private func frame(on coordinate: Coordinate, spanDegrees: Double) {
        withAnimation {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate.clLocationCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: spanDegrees, longitudeDelta: spanDegrees)
                )
            )
        }
    }
}
