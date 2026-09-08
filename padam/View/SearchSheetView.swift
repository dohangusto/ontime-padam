//
//  SearchSheetView.swift
//  padam
//
//  Initial / searching state, modeled on Apple Maps: a capsule search bar that
//  lives in the small detent, expands to full height with the keyboard when
//  tapped, and shows rich suggestion rows as the operator types. The field sets
//  the FIRE LOCATION (not a general place search); the operator can also drop a
//  pin directly on the map.
//

import SwiftUI
import MapKit

struct SearchSheetView: View {
    @Bindable var search: LocationSearchService
    @Binding var query: String
    var onResolve: (Coordinate) -> Void
    /// Called when the field gains focus (expand the sheet to full height).
    var onActivate: () -> Void
    /// Called when the operator cancels search (collapse back to the small detent).
    var onDeactivate: () -> Void

    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            searchBar

            if fieldFocused || !search.suggestions.isEmpty {
                suggestionsSection
            } else {
                Spacer(minLength: 0)
                DataAttributionFooter()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .onChange(of: fieldFocused) { _, focused in
            if focused { onActivate() }
        }
    }

    // MARK: Search bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Cari lokasi kebakaran (alamat / patokan)", text: $query)
                    .focused($fieldFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .onChange(of: query) { _, newValue in
                        search.updateQuery(newValue)
                    }
                    .onSubmit { resolveText() }
                if !query.isEmpty {
                    Button {
                        query = ""
                        search.updateQuery("")
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.quaternary, in: Capsule())

            if fieldFocused {
                Button("Batal") { cancelSearch() }
                    .font(.body)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.2), value: fieldFocused)
    }

    // MARK: Suggestions

    @ViewBuilder
    private var suggestionsSection: some View {
        if search.suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Ketik alamat atau patokan lokasi kebakaran.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            List(search.suggestions, id: \.self) { completion in
                Button {
                    resolve(completion)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(completion.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            if !completion.subtitle.isEmpty {
                                Text(completion.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    // MARK: Actions

    private func cancelSearch() {
        query = ""
        search.updateQuery("")
        fieldFocused = false
        onDeactivate()
    }

    private func resolve(_ completion: MKLocalSearchCompletion) {
        fieldFocused = false
        Task {
            if let coordinate = await search.resolve(completion) {
                onResolve(coordinate)
            }
        }
    }

    private func resolveText() {
        fieldFocused = false
        Task {
            if let coordinate = await search.resolve(text: query) {
                onResolve(coordinate)
            }
        }
    }
}

/// Data source + year, required to be visible somewhere in the app.
struct DataAttributionFooter: View {
    var body: some View {
        Text(AppInfo.dataAttribution)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 8)
    }
}
