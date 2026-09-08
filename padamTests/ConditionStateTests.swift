//
//  ConditionStateTests.swift
//  padamTests
//
//  Verifies the single condition classifier: real hydrant/pos-damkar values,
//  mixed and blank fields, and the critical invariant that an unusable or
//  unknown point never resolves to the "usable" (safe) state.
//

import Testing
import Foundation
@testable import padam

struct ConditionStateTests {

    @Test("Recorded-working values classify as usable")
    func usableValues() {
        #expect(ConditionState.classify("BISA DIGUNAKAN") == .usable)
        #expect(ConditionState.classify("BAIK") == .usable)
        #expect(ConditionState.classify("baik") == .usable) // case-insensitive
        #expect(ConditionState.classify(" BAIK ") == .usable) // trimmed
    }

    @Test("Recorded-broken values classify as unusable")
    func unusableValues() {
        #expect(ConditionState.classify("TIDAK BISA DIGUNAKAN") == .unusable)
        #expect(ConditionState.classify("RUSAK") == .unusable)
        #expect(ConditionState.classify("tidak bisa digunakan") == .unusable)
    }

    @Test("Missing or blank condition defaults to unknown, never usable")
    func missingDefaultsToUnknown() {
        #expect(ConditionState.classify(nil) == .unknown)
        #expect(ConditionState.classify("") == .unknown)
        #expect(ConditionState.classify("   ") == .unknown)
        #expect(ConditionState.classify(nil) != .usable)
    }

    @Test("Mixed and unrecognised conditions resolve to unknown")
    func mixedResolvesToUnknown() {
        #expect(ConditionState.classify("BAIK | RUSAK") == .unknown)
        #expect(ConditionState.classify("RUSAK | BAIK") == .unknown)
        #expect(ConditionState.classify("SEDANG DIPERBAIKI") == .unknown)
    }

    @Test("An unusable point never counts as a candidate")
    func unusableIsNotCandidate() {
        #expect(ConditionState.unusable.isCandidate == false)
        #expect(ConditionState.usable.isCandidate == true)
        #expect(ConditionState.unknown.isCandidate == true)
    }
}
