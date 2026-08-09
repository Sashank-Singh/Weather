import CoreLocation
import Foundation

@MainActor
@Observable
final class AirQualityViewModel {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded(AirQualitySnapshot)
        case failed(String)
    }

    private let service: AirQualityService
    private let locationService: LocationService

    var phase: Phase = .idle

    /// Optional seed from Weather so we don't re-prompt location.
    private let seededCoordinate: CLLocationCoordinate2D?
    private let seededLocationName: String?

    init(
        service: AirQualityService = AirQualityService(),
        locationService: LocationService? = nil,
        coordinate: CLLocationCoordinate2D? = nil,
        locationName: String? = nil
    ) {
        self.service = service
        self.locationService = locationService ?? LocationService()
        self.seededCoordinate = coordinate
        self.seededLocationName = locationName
    }

    func load() async {
        phase = .loading

        do {
            let latitude: Double
            let longitude: Double
            let name: String

            if let seededCoordinate, let seededLocationName {
                latitude = seededCoordinate.latitude
                longitude = seededCoordinate.longitude
                name = seededLocationName
            } else {
                let location = try await locationService.requestLocation()
                latitude = location.coordinate.latitude
                longitude = location.coordinate.longitude
                name = await locationService.reverseGeocode(location)
            }

            let snapshot = try await service.fetch(
                latitude: latitude,
                longitude: longitude,
                locationName: name
            )
            phase = .loaded(snapshot)
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}
