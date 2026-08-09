import SwiftUI

/// Search, switch, and save multiple places.
struct LocationPickerSheet: View {
    @Bindable var model: WeatherViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var results: [PlaceSearchResult] = []
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            List {
                if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    searchSection
                }

                savedSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Locations")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search city or place")
            .onChange(of: query) { _, newValue in
                scheduleSearch(newValue)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    // MARK: - Search

    @ViewBuilder
    private var searchSection: some View {
        Section("Search") {
            if isSearching {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Searching…")
                        .foregroundStyle(.secondary)
                }
            } else if let searchError {
                Text(searchError)
                    .foregroundStyle(.secondary)
            } else if results.isEmpty {
                Text("No places found")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(results) { place in
                    Button {
                        Task {
                            await model.addAndSelect(place: place)
                            dismiss()
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(place.name)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                            if !place.subtitle.isEmpty {
                                Text(place.subtitle)
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    // MARK: - Saved

    private var savedSection: some View {
        Section("Saved") {
            ForEach(model.savedLocations) { location in
                Button {
                    Task {
                        await model.selectLocation(location)
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: location.isCurrent ? "location.fill" : "mappin.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(location.isCurrent ? Color.accentColor : Color.secondary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(location.isCurrent ? "Current Location" : location.name)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)

                            if location.isCurrent, !location.name.isEmpty, location.name != "Current Location" {
                                Text(location.name)
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        if location.id == model.selectedLocationID {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    if !location.isCurrent {
                        Button(role: .destructive) {
                            Task { await model.removeLocation(location) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }

            Button {
                Task {
                    await model.useCurrentLocation()
                    dismiss()
                }
            } label: {
                Label("Use Current Location", systemImage: "location.circle")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
            }
        }
    }

    // MARK: - Search debounce

    private func scheduleSearch(_ text: String) {
        searchTask?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= 2 else {
            results = []
            searchError = nil
            isSearching = false
            return
        }

        isSearching = true
        searchError = nil

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }

            do {
                let places = try await model.searchPlaces(query: trimmed)
                guard !Task.isCancelled else { return }
                results = places
                isSearching = false
            } catch {
                guard !Task.isCancelled else { return }
                results = []
                searchError = error.localizedDescription
                isSearching = false
            }
        }
    }
}

#Preview {
    LocationPickerSheet(model: WeatherViewModel())
}
