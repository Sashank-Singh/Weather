import CoreLocation
import Foundation

@MainActor
@Observable
final class WeatherViewModel {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded(WeatherSnapshot)
        case failed(String)
    }

    private let weatherService: WeatherService
    private let locationService: LocationService
    private let defaults: UserDefaults
    private let savedLocationsKey = "weather.savedLocations"
    private let selectedLocationIDKey = "weather.selectedLocationID"

    var phase: Phase = .idle
    var usesCelsius = true
    var coordinate: CLLocationCoordinate2D?
    var locationName: String?
    var savedLocations: [SavedLocation] = []
    var selectedLocationID: UUID?

    init(
        weatherService: WeatherService = WeatherService(),
        locationService: LocationService? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.weatherService = weatherService
        self.locationService = locationService ?? LocationService()
        self.defaults = defaults
        loadPersistedLocations()
    }

    var selectedLocation: SavedLocation? {
        savedLocations.first { $0.id == selectedLocationID } ?? savedLocations.first
    }

    func load() async {
        await refreshWeather(usingGPSIfNeeded: true)
    }

    func selectLocation(_ location: SavedLocation) async {
        selectedLocationID = location.id
        persist()
        await refreshWeather(usingGPSIfNeeded: location.isCurrent)
    }

    func addAndSelect(place: PlaceSearchResult) async {
        if let existing = savedLocations.first(where: {
            !$0.isCurrent &&
            abs($0.latitude - place.latitude) < 0.01 &&
            abs($0.longitude - place.longitude) < 0.01
        }) {
            await selectLocation(existing)
            return
        }

        let location = SavedLocation(
            name: place.name,
            latitude: place.latitude,
            longitude: place.longitude,
            isCurrent: false
        )
        savedLocations.append(location)
        selectedLocationID = location.id
        persist()
        await refreshWeather(usingGPSIfNeeded: false)
    }

    func useCurrentLocation() async {
        if let current = savedLocations.first(where: \.isCurrent) {
            await selectLocation(current)
        } else {
            let current = SavedLocation.currentPlaceholder()
            savedLocations.insert(current, at: 0)
            selectedLocationID = current.id
            persist()
            await refreshWeather(usingGPSIfNeeded: true)
        }
    }

    func removeLocation(_ location: SavedLocation) async {
        guard !location.isCurrent else { return }
        savedLocations.removeAll { $0.id == location.id }
        if selectedLocationID == location.id {
            selectedLocationID = savedLocations.first?.id
        }
        persist()
        await refreshWeather(usingGPSIfNeeded: selectedLocation?.isCurrent ?? true)
    }

    func searchPlaces(query: String) async throws -> [PlaceSearchResult] {
        try await locationService.searchPlaces(query: query)
    }

    // MARK: - Weather fetch

    private func refreshWeather(usingGPSIfNeeded: Bool) async {
        phase = .loading

        do {
            let active = try await resolveActiveLocation(usingGPSIfNeeded: usingGPSIfNeeded)
            coordinate = active.coordinate
            locationName = active.name

            let snapshot = try await weatherService.fetch(
                latitude: active.latitude,
                longitude: active.longitude,
                locationName: active.name
            )
            phase = .loaded(snapshot)
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    private func resolveActiveLocation(usingGPSIfNeeded: Bool) async throws -> SavedLocation {
        if usingGPSIfNeeded || selectedLocation?.isCurrent == true || selectedLocation == nil {
            let location = try await locationService.requestLocation()
            let name = await locationService.reverseGeocode(location)

            if let index = savedLocations.firstIndex(where: \.isCurrent) {
                savedLocations[index].name = name
                savedLocations[index].latitude = location.coordinate.latitude
                savedLocations[index].longitude = location.coordinate.longitude
                selectedLocationID = savedLocations[index].id
                persist()
                return savedLocations[index]
            } else {
                let current = SavedLocation(
                    name: name,
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    isCurrent: true
                )
                savedLocations.insert(current, at: 0)
                selectedLocationID = current.id
                persist()
                return current
            }
        }

        guard let selected = selectedLocation else {
            return try await resolveActiveLocation(usingGPSIfNeeded: true)
        }
        return selected
    }

    // MARK: - Persistence

    private func loadPersistedLocations() {
        if let data = defaults.data(forKey: savedLocationsKey),
           let decoded = try? JSONDecoder().decode([SavedLocation].self, from: data),
           !decoded.isEmpty {
            savedLocations = decoded
        } else {
            savedLocations = [.currentPlaceholder()]
        }

        if let idString = defaults.string(forKey: selectedLocationIDKey),
           let id = UUID(uuidString: idString),
           savedLocations.contains(where: { $0.id == id }) {
            selectedLocationID = id
        } else {
            selectedLocationID = savedLocations.first?.id
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(savedLocations) {
            defaults.set(data, forKey: savedLocationsKey)
        }
        if let selectedLocationID {
            defaults.set(selectedLocationID.uuidString, forKey: selectedLocationIDKey)
        }
    }

    // MARK: - Display helpers

    func displayTemperature(_ value: Double) -> String {
        let converted = usesCelsius ? value : (value * 9 / 5) + 32
        return "\(Int(converted.rounded()))°"
    }

    func displayWind(_ kmh: Double) -> String {
        if usesCelsius {
            return "\(Int(kmh.rounded()))"
        }
        let mph = kmh * 0.621371
        return "\(Int(mph.rounded()))"
    }

    func unitLabel() -> String {
        usesCelsius ? "C" : "F"
    }
}
