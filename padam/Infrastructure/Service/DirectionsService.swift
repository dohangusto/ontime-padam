//
//  DirectionsService.swift
//  padam
//
//  Travel-time / route lookup for a SINGLE selected point only. MapKit
//  directions calls are rate-limited and expensive, so this is never run across
//  the whole dataset — only on demand for the point the operator is inspecting.
//

import Foundation
import MapKit

struct RouteEstimate {
    let travelTime: TimeInterval
    let distanceMeters: CLLocationDistance
    let polyline: MKPolyline
}

enum DirectionsService {
    /// Requests a driving route from the fire location to a water source.
    /// Returns nil if MapKit can't produce a route.
    static func route(from origin: Coordinate, to destination: Coordinate) async -> RouteEstimate? {
        let request = MKDirections.Request()
        request.source = MKMapItem(
            location: CLLocation(latitude: origin.latitude, longitude: origin.longitude),
            address: nil
        )
        request.destination = MKMapItem(
            location: CLLocation(latitude: destination.latitude, longitude: destination.longitude),
            address: nil
        )
        request.transportType = .automobile

        guard let route = try? await MKDirections(request: request).calculate().routes.first else {
            return nil
        }
        return RouteEstimate(
            travelTime: route.expectedTravelTime,
            distanceMeters: route.distance,
            polyline: route.polyline
        )
    }
}
