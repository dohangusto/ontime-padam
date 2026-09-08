//
//  padamTests.swift
//  padamTests
//
//  Created by Ivandohan Samuel Siregar on 08/09/26.
//

import Testing
import Foundation
@testable import padam

struct padamTests {

    @Test func recentSearchDefaults() async throws {
        let defaults = RecentSearch.defaults
        #expect(!defaults.isEmpty)
        #expect(defaults.first?.title == "National Monument")
        #expect(defaults.first?.iconTintName == "blue")
    }

    @Test func addAndRemoveRecentSearches() async throws {
        let vm = await MapViewModel()
        let initialCount = await vm.recentSearches.count
        let customCoord = Coordinate(latitude: -6.123, longitude: 106.456)
        
        await vm.addRecentSearch(title: "Kebakaran Pasar Minggu", subtitle: "Pasar Minggu", coordinate: customCoord)
        let countAfterAdd = await vm.recentSearches.count
        #expect(countAfterAdd == initialCount + 1)
        #expect(await vm.recentSearches.first?.title == "Kebakaran Pasar Minggu")

        if let added = await vm.recentSearches.first {
            await vm.removeRecentSearch(added)
            #expect(await vm.recentSearches.count == initialCount)
        }
    }

    @Test func toggleSavedSources() async throws {
        let vm = await MapViewModel()
        let sample = WaterSource(
            type: .posDamkar,
            name: "Pos Test",
            address: "Jl Test",
            coordinate: Coordinate(latitude: -6.2, longitude: 106.8)
        )

        #expect(await !vm.isSaved(sample))
        await vm.toggleSaved(sample)
        #expect(await vm.isSaved(sample))
        await vm.toggleSaved(sample)
        #expect(await !vm.isSaved(sample))
    }

    @Test func findNearestByType() async throws {
        let vm = await MapViewModel()
        let nearestHidran = await vm.findNearest(type: .hidran)
        #expect(nearestHidran != nil)
        #expect(nearestHidran?.type == .hidran)
        #expect(await vm.selectedSource?.id == nearestHidran?.id)
    }

    @Test func waterSourceTypeDisplayNames() async throws {
        #expect(WaterSourceType.kali.displayName == "Sungai")
        #expect(WaterSourceType.got.displayName == "Got")
        #expect(WaterSourceType.kolamRenang.displayName == "Kolam Renang")
        #expect(WaterSourceType.posDamkar.displayName == "Pos DAMKAR")
        #expect(WaterSourceType.hidran.displayName == "Hidran")
    }
}
