//
//  ContentView.swift
//  padam
//
//  The home screen is an interactive native MapKit map with Apple Maps style floating
//  overlays (Weather Pill, Map Controls) and a persistent 3-detent bottom sheet.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @State private var vm = MapViewModel()
    @State private var search = LocationSearchService()

    @State private var query = ""
    @State private var detent: PresentationDetent = Self.smallDetent
    @State private var routePolyline: MKPolyline?

    private static let smallDetent: PresentationDetent = .height(72)

    var body: some View {
        ZStack(alignment: .top) {
            mapView
                .ignoresSafeArea()

            // Top Overlays: Weather Pill (top-left) matching IMG_4786 / IMG_4790
            VStack {
                HStack {
                    WeatherPillView(
                        temperature: vm.weatherTemperature,
                        areaName: vm.weatherArea
                    )
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 54) // below notch / dynamic island

                Spacer()

                // Floating Map Controls (bottom-right)
                HStack {
                    Spacer()
                    MapFloatingControlsView(
                        isSatellite: $vm.mapStyleIsSatellite,
                        hydrantsHidden: vm.hiddenTypes.contains(.hidran),
                        onToggleHydrants: { vm.toggleLayer(.hidran) },
                        onRecenter: {
                            if let fire = vm.fireLocation {
                                vm.zoomIn(on: fire)
                            } else {
                                vm.backToSearch()
                            }
                        }
                    )
                }
                .padding(.trailing, 16)
                .padding(.bottom, 96) // above collapsed sheet
            }
        }
        .sheet(isPresented: .constant(true)) {
            sheetContent
                .presentationDetents([Self.smallDetent, .medium, .large], selection: $detent)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .presentationContentInteraction(.scrolls)
                .interactiveDismissDisabled()
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(34)
                .presentationBackground {
                    SheetGlassBackground(isFullyExpanded: detent == .large)
                }
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
                    // Results: focus the map on the recommended sources only,
                    // honoring the hydrant layer toggle.
                    ForEach(vm.allRankedSources.filter { !vm.hiddenTypes.contains($0.type) }) { ranked in
                        Annotation(ranked.source.name, coordinate: ranked.source.coordinate.clLocationCoordinate) {
                            SourcePinView(
                                type: ranked.source.type,
                                isSelected: vm.selectedSource?.id == ranked.source.id
                            )
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
                guard let coordinate = proxy.convert(point, from: .local) else { return }
                dropFire(at: Coordinate(coordinate), title: "Titik Peta Dipilih", subtitle: "Koordinat Kustom")
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
                isSaved: vm.isSaved(selected),
                isSmall: detent == Self.smallDetent,
                isFullyExpanded: detent == .large,
                onToggleSave: { vm.toggleSaved(selected) },
                onBack: closeDetail,
                onRouteReady: { routePolyline = $0 }
            )
        } else if vm.phase == .results {
            ResultsSheetView(
                groups: vm.rankedGroups,
                availableTypes: vm.availableTypes,
                locationTitle: vm.fireLocationTitle,
                locationSubtitle: vm.fireLocationSubtitle,
                isSmall: detent == Self.smallDetent,
                isExpanded: detent == .large,
                onSelect: openDetail,
                onChangeLocation: resetToSearch
            )
        } else {
            SearchSheetView(
                search: search,
                query: $query,
                recentSearches: vm.recentSearches,
                onSelectRecent: handleSelectRecent,
                onDeleteRecent: { vm.removeRecentSearch($0) },
                onSelectCategory: handleSelectCategory,
                onResolve: { coord, title, subtitle in
                    dropFire(at: coord, title: title, subtitle: subtitle)
                },
                onActivate: {
                    withAnimation(.snappy) {
                        detent = .large
                    }
                },
                onDeactivate: {
                    withAnimation(.snappy) {
                        detent = Self.smallDetent
                    }
                },
                isExpanded: detent != Self.smallDetent,
                isFullyExpanded: detent == .large
            )
        }
    }

    // MARK: Actions

    private func handleSelectRecent(_ item: RecentSearch) {
        dropFire(at: item.coordinate, title: item.title, subtitle: item.subtitle)
    }

    private func handleSelectCategory(_ type: WaterSourceType) {
        if let nearest = vm.findNearest(type: type) {
            openDetail(nearest)
        }
    }

    private func dropFire(at coordinate: Coordinate, title: String? = nil, subtitle: String? = nil) {
        vm.setFireLocation(coordinate, title: title, subtitle: subtitle)
        withAnimation(.snappy) {
            detent = .medium
        }
    }

    private func handleSingleTap(_ source: WaterSource) {
        openDetail(source)
    }

    private func openDetail(_ source: WaterSource) {
        routePolyline = nil
        vm.select(source)
        withAnimation(.snappy) {
            detent = .large
        }
    }

    private func closeDetail() {
        vm.selectedSource = nil
        routePolyline = nil
        withAnimation(.snappy) {
            detent = vm.phase == .results ? .medium : Self.smallDetent
        }
    }

    private func resetToSearch() {
        vm.backToSearch()
        query = ""
        search.updateQuery("")
        routePolyline = nil
        withAnimation(.snappy) {
            detent = Self.smallDetent
        }
    }

    // MARK: Helpers

    /// Finds the ranked wrapper for a source. Reuses the exact object computed by
    /// the ranking (including demoted unusable points) so the distance shown on
    /// detail always matches the list. Only falls back — from the fire location,
    /// or the map center when no fire is set — for points off the ranked lists.
    private func rankedFor(_ source: WaterSource) -> RankedWaterSource? {
        let ranked = vm.rankedGroups.flatMap { $0.sources + $0.unusable }
        if let existing = ranked.first(where: { $0.source.id == source.id }) {
            return existing
        }
        let refCoord = vm.fireLocation ?? Coordinate(vm.visibleRegion.center)
        return RankedWaterSource(source: source, distanceMeters: refCoord.distance(to: source.coordinate))
    }
}

#Preview {
    ContentView()
}
