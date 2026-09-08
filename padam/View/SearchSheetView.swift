//
//  SearchSheetView.swift
//  padam
//
//  Apple Maps native style bottom sheet supporting:
//  1. Collapsed state (IMG_4786) with "Cari titik kebakaran" placeholder, mic, avatar.
//  2. Half-expanded state (IMG_4787) with "Sumber Air >" circular category buttons (no Siri suggestions).
//  3. Full-expanded state (IMG_4788) with "Sumber Air >" followed by "Recents >" list.
//  4. Active search state (IMG_4789) with "Recents >" and "Find Nearby" 5-type list, plus live autocomplete.
//

import SwiftUI
import MapKit

struct SearchSheetView: View {
    @Bindable var search: LocationSearchService
    @Binding var query: String
    var recentSearches: [RecentSearch]
    var onSelectRecent: (RecentSearch) -> Void
    var onDeleteRecent: (RecentSearch) -> Void
    var onSelectCategory: (WaterSourceType) -> Void
    var onResolve: (Coordinate, String?, String?) -> Void
    var onActivate: () -> Void
    var onDeactivate: () -> Void
    var isExpanded: Bool = false

    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            searchBar
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 10)

            if isExpanded || fieldFocused {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        if fieldFocused {
                            activeSearchContent
                        } else {
                            browsingContent
                        }

                        DataAttributionFooter()
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                }
            } else {
                Spacer(minLength: 0)
            }
        }
        .onChange(of: fieldFocused) { _, focused in
            if focused {
                onActivate()
            }
        }
    }

    // MARK: Search Bar (Capsule with Magnifying Glass, Mic, Avatar / Cancel)

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)

                TextField("Cari titik kebakaran", text: $query)
                    .focused($fieldFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .font(.system(size: 16))
                    .onChange(of: query) { _, newValue in
                        search.updateQuery(newValue)
                    }
                    .onSubmit { resolveText() }

                if !query.isEmpty {
                    Button {
                        query = ""
                        search.updateQuery("")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Image(systemName: "mic.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.quaternary.opacity(0.85), in: Capsule())

            if fieldFocused {
                Button {
                    cancelSearch()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .background(.quaternary.opacity(0.85), in: Circle())
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            } else {
                // Profile Avatar icon matching Apple Maps top-right profile
                Button {} label: {
                    ZStack {
                        Circle()
                            .fill(.quaternary.opacity(0.85))
                            .frame(width: 36, height: 36)

                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.snappy(duration: 0.25), value: fieldFocused)
    }

    // MARK: Browsing Content (IMG_4787 Half & IMG_4788 Full)

    @ViewBuilder
    private var browsingContent: some View {
        // Section: "Sumber Air >" (IMG_4787 / IMG_4788)
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Sumber Air")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(WaterSourceType.allCases) { type in
                        WaterSourceCategoryButton(type: type) {
                            onSelectCategory(type)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }

        // Section: "Recents >" (IMG_4788)
        if !recentSearches.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader(title: "Recents")

                VStack(spacing: 0) {
                    ForEach(Array(recentSearches.prefix(5).enumerated()), id: \.element.id) { index, item in
                        RecentSearchRow(
                            recent: item,
                            onSelect: { onSelectRecent(item) },
                            onDelete: { onDeleteRecent(item) }
                        )

                        if index < min(recentSearches.count, 5) - 1 {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    // MARK: Active Search Content (IMG_4789)

    @ViewBuilder
    private var activeSearchContent: some View {
        if !query.isEmpty && !search.suggestions.isEmpty {
            // Live autocomplete suggestions
            VStack(alignment: .leading, spacing: 8) {
                ForEach(search.suggestions, id: \.self) { completion in
                    Button {
                        resolve(completion)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title3)
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
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .padding(.leading, 38)
                }
            }
            .padding(12)
            .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            // Section 1: "Recents >" (IMG_4789)
            if !recentSearches.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader(title: "Recents")

                    VStack(spacing: 0) {
                        ForEach(Array(recentSearches.prefix(3).enumerated()), id: \.element.id) { index, item in
                            RecentSearchRow(
                                recent: item,
                                onSelect: { onSelectRecent(item) },
                                onDelete: { onDeleteRecent(item) }
                            )

                            if index < min(recentSearches.count, 3) - 1 {
                                Divider()
                                    .padding(.leading, 56)
                            }
                        }
                    }
                    .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }

            // Section 2: "Find Nearby" (IMG_4789)
            VStack(alignment: .leading, spacing: 10) {
                Text("Find Nearby")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)

                VStack(spacing: 0) {
                    ForEach(Array(WaterSourceType.allCases.enumerated()), id: \.element.id) { index, type in
                        FindNearbyRow(type: type) {
                            onSelectCategory(type)
                        }

                        if index < WaterSourceType.allCases.count - 1 {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    // MARK: Helpers

    private func sectionHeader(title: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.secondary)
        }
    }

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
                onResolve(coordinate, completion.title, completion.subtitle)
            }
        }
    }

    private func resolveText() {
        fieldFocused = false
        let submittedText = query
        Task {
            if let coordinate = await search.resolve(text: submittedText) {
                onResolve(coordinate, submittedText, "Hasil Pencarian")
            }
        }
    }
}

/// Data source + year attribution
struct DataAttributionFooter: View {
    var body: some View {
        Text(AppInfo.dataAttribution)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    SearchSheetView(
        search: LocationSearchService(),
        query: .constant(""),
        recentSearches: RecentSearch.defaults,
        onSelectRecent: { _ in },
        onDeleteRecent: { _ in },
        onSelectCategory: { _ in },
        onResolve: { _, _, _ in },
        onActivate: {},
        onDeactivate: {},
        isExpanded: true
    )
    .background(.black)
}
