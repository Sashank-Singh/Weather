import CoreLocation
import Foundation
import MapKit

@MainActor
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() async throws -> CLLocation {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            throw LocationError.denied
        default:
            break
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    func reverseGeocode(_ location: CLLocation) async -> String {
        guard let request = MKReverseGeocodingRequest(location: location),
              let item = try? await request.mapItems.first else {
            return "Current Location"
        }

        if let city = item.addressRepresentations?.cityName, !city.isEmpty {
            return city
        }

        if let short = item.address?.shortAddress, !short.isEmpty {
            return short
        }

        return item.name ?? "Current Location"
    }

    func searchPlaces(query: String) async throws -> [PlaceSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        request.resultTypes = [.address, .pointOfInterest]

        let response = try await MKLocalSearch(request: request).start()

        return response.mapItems.prefix(12).compactMap { item in
            let location = item.location
            let name = item.name
                ?? item.addressRepresentations?.cityName
                ?? item.address?.shortAddress
                ?? "Place"

            let subtitleParts = [
                item.addressRepresentations?.cityName,
                item.addressRepresentations?.regionName
            ]
            .compactMap { $0 }
            .filter { !$0.isEmpty && $0 != name }

            let subtitle: String = {
                if !subtitleParts.isEmpty {
                    return subtitleParts.joined(separator: ", ")
                }
                return item.address?.shortAddress ?? ""
            }()

            return PlaceSearchResult(
                name: name,
                subtitle: subtitle == name ? "" : subtitle,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        Task { @MainActor in
            continuation?.resume(returning: location)
            continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}

enum LocationError: LocalizedError {
    case denied

    var errorDescription: String? {
        switch self {
        case .denied:
            "Location access is required to show local weather."
        }
    }
}
