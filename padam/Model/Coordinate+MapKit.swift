//
//  Coordinate+MapKit.swift
//  padam
//
//  Bridges the pure `Coordinate` model to MapKit/CoreLocation types. Kept in a
//  separate file so the core model and ranking logic stay free of MapKit.
//

import CoreLocation
import MapKit

extension Coordinate {
    var clLocationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(_ coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
