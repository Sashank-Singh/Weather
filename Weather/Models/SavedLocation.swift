import CoreLocation
import Foundation

struct SavedLocation: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    /// True when this entry represents device GPS (name may update).
    var isCurrent: Bool

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double,
        isCurrent: Bool = false
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.isCurrent = isCurrent
    }

    static func currentPlaceholder(name: String = "Current Location") -> SavedLocation {
        SavedLocation(name: name, latitude: 0, longitude: 0, isCurrent: true)
    }
}

struct PlaceSearchResult: Identifiable, Equatable, Sendable {
    let id = UUID()
    let name: String
    let subtitle: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
