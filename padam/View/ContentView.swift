//
//  ContentView.swift
//  padam
//
//  The home screen IS the map. A bottom sheet is always present (never fully
//  dismissed): it drives search → results → detail while the map behind stays
//  interactive. Mimics Apple Maps' three-detent sheet.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @State private var vm = MapViewModel()
    @State private var search = LocationSearchService()

    @State private var query = ""
    @State private var detent: PresentationDetent = .height(96)
    @State private var routePolyline: MKPolyline?

    private static let smallDetent: PresentationDetent = .height(96)

    var body: some View {
        mapView
            .ignoresSafeArea()
            .sheet(isPresented: .constant(true)) {
                sheetContent
                    .presentationDetents([Self.smallDetent, .medium, .large], selection: $detent)
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                    .presentationContentInteraction(.scrolls)
                    .interactiveDismissDisabled()
                    .presentationBackground(.regularMaterial)
            }
    }

    // MARK: Map

    private var mapView: some View {
        MapReader { proxy in
            Map(position: $vm.cameraPosition) {
                if vm.phase == .search {
                    // Browsing: show every source, aggregated by zoom level.
                    ForEach(vm.clusters) { cluster in
                        Annotation(annotationTitle(cluster), coordinate: cluster.coordinate.clLocationCoordinate) {
                            annotationContent(for: cluster)
                        }
                        .annotationTitles(.hidden)
                    }
                } else {
                    // Results: focus the map on the recommended sources only.
                    ForEach(vm.allRankedSources) { ranked in
                        Annotation(ranked.source.name, coordinate: ranked.source.coordinate.clLocationCoordinate) {
                            SourcePinView(type: ranked.source.type,
                                          isSelected: vm.selectedSource?.id == ranked.source.id)
                                .onTapGesture { openDetail(ranked.source) }
                        }
                        .annotationTitles(.hidden)
                    }
                }

                if let fire = vm.fireLocation {
                    Annotation("Lokasi Kebakaran", coordinate: fire.clLocationCoordinate) {
                        FireMarkerView()
                    }
                }

                if let routePolyline {
                    MapPolyline(routePolyline).stroke(.blue, lineWidth: 5)
                }
            }
            .mapStyle(vm.mapStyleIsSatellite ? .hybrid : .standard)
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                vm.onCameraChanged(region: context.region)
            }
            .onTapGesture(coordinateSpace: .local) { point in
                guard vm.phase == .search, let coordinate = proxy.convert(point, from: .local) else { return }
                dropFire(at: Coordinate(coordinate))
            }
        }
    }

    @ViewBuilder
    private func annotationContent(for cluster: MapCluster) -> some View {
        if cluster.isCluster {
            ClusterBubbleView(count: cluster.count)
                .onTapGesture { vm.zoomIn(on: cluster.coordinate) }
        } else if let source = cluster.singleSource {
            SourcePinView(type: source.type, isSelected: vm.selectedSource?.id == source.id)
                .onTapGesture { handleSingleTap(source) }
        }
    }

    private func annotationTitle(_ cluster: MapCluster) -> String {
        cluster.singleSource?.name ?? "\(cluster.count)"
    }

    // MARK: Sheet content (search → results → detail)

    @ViewBuilder
    private var sheetContent: some View {
        if let selected = vm.selectedSource, let ranked = rankedFor(selected) {
            DetailSheetView(
                ranked: ranked,
                fireLocation: vm.fireLocation,
                satellite: $vm.mapStyleIsSatellite,
                onBack: closeDetail,
                onRouteReady: { routePolyline = $0 }
            )
        } else if vm.phase == .results {
            ResultsSheetView(
                groups: vm.rankedGroups,
                isExpanded: detent == .large,
                onSelect: openDetail,
                onChangeLocation: resetToSearch
            )
        } else {
            SearchSheetView(
                search: search,
                query: $query,
                onResolve: dropFire,
                onActivate: { detent = .large },
                onDeactivate: { detent = Self.smallDetent }
            )
        }
    }

    // MARK: Actions

    private func dropFire(at coordinate: Coordinate) {
        vm.setFireLocation(coordinate)
        detent = .medium
    }

    private func handleSingleTap(_ source: WaterSource) {
        if vm.phase == .results {
            openDetail(source)
        } else {
            vm.zoomIn(on: source.coordinate)
        }
    }

    private func openDetail(_ source: WaterSource) {
        routePolyline = nil
        vm.select(source)
        detent = .large
    }

    private func closeDetail() {
        vm.selectedSource = nil
        routePolyline = nil
        detent = .medium
    }

    private func resetToSearch() {
        vm.backToSearch()
        query = ""
        search.updateQuery("")
        routePolyline = nil
        detent = Self.smallDetent
    }

    // MARK: Helpers

    /// Finds the ranked wrapper for a source; falls back to computing distance
    /// from the fire location for points outside the top-3 (e.g. tapped on map).
    private func rankedFor(_ source: WaterSource) -> RankedWaterSource? {
        if let existing = vm.allRankedSources.first(where: { $0.source.id == source.id }) {
            return existing
        }
        if let fire = vm.fireLocation {
            return RankedWaterSource(source: source, distanceMeters: fire.distance(to: source.coordinate))
        }
        return nil
    }
}

#Preview {
    ContentView()
}
