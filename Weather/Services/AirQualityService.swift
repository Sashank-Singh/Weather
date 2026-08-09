import Foundation

actor AirQualityService {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    func fetch(latitude: Double, longitude: Double, locationName: String) async throws -> AirQualitySnapshot {
        var components = URLComponents(string: "https://air-quality-api.open-meteo.com/v1/air-quality")!
        components.queryItems = [
            .init(name: "latitude", value: String(latitude)),
            .init(name: "longitude", value: String(longitude)),
            .init(
                name: "current",
                value: "us_aqi,pm2_5,pm10,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone"
            ),
            .init(name: "timezone", value: "auto")
        ]

        guard let url = components.url else {
            throw AirQualityError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AirQualityError.badResponse
        }

        let payload = try decoder.decode(OpenMeteoAirQualityResponse.self, from: data)
        return payload.asSnapshot(locationName: locationName)
    }
}

enum AirQualityError: LocalizedError {
    case invalidURL
    case badResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Could not build air quality request."
        case .badResponse: "Air quality service returned an unexpected response."
        }
    }
}

private struct OpenMeteoAirQualityResponse: Decodable {
    let current: Current

    struct Current: Decodable {
        let usAqi: Int
        let pm25: Double
        let pm10: Double
        let carbonMonoxide: Double
        let nitrogenDioxide: Double
        let sulphurDioxide: Double
        let ozone: Double

        enum CodingKeys: String, CodingKey {
            case usAqi = "us_aqi"
            case pm25 = "pm2_5"
            case pm10
            case carbonMonoxide = "carbon_monoxide"
            case nitrogenDioxide = "nitrogen_dioxide"
            case sulphurDioxide = "sulphur_dioxide"
            case ozone
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let intAQI = try? container.decode(Int.self, forKey: .usAqi) {
                usAqi = intAQI
            } else {
                usAqi = Int((try container.decode(Double.self, forKey: .usAqi)).rounded())
            }
            pm25 = try container.decode(Double.self, forKey: .pm25)
            pm10 = try container.decode(Double.self, forKey: .pm10)
            carbonMonoxide = try container.decode(Double.self, forKey: .carbonMonoxide)
            nitrogenDioxide = try container.decode(Double.self, forKey: .nitrogenDioxide)
            sulphurDioxide = try container.decode(Double.self, forKey: .sulphurDioxide)
            ozone = try container.decode(Double.self, forKey: .ozone)
        }
    }

    func asSnapshot(locationName: String) -> AirQualitySnapshot {
        AirQualitySnapshot(
            locationName: locationName,
            aqi: current.usAqi,
            pm25: current.pm25,
            pm10: current.pm10,
            ozone: current.ozone,
            nitrogenDioxide: current.nitrogenDioxide,
            carbonMonoxide: current.carbonMonoxide,
            sulphurDioxide: current.sulphurDioxide
        )
    }
}
