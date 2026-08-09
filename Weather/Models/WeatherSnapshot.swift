import Foundation

struct WeatherSnapshot: Sendable, Equatable {
    let locationName: String
    let temperature: Double
    let apparentTemperature: Double
    let condition: WeatherCondition
    let humidity: Int
    let windSpeed: Double
    let uvIndex: Int
    let isDay: Bool
    let sunrise: Date?
    let sunset: Date?
    let hourly: [HourlyForecast]
    let daily: [DailyForecast]
}

struct HourlyForecast: Identifiable, Sendable, Equatable {
    let id = UUID()
    let date: Date
    let temperature: Double
    let condition: WeatherCondition
    let isDay: Bool

    /// Apple Weather–style SF Symbol for this hour.
    var symbolName: String {
        condition.symbolName(isDay: isDay)
    }
}

struct DailyForecast: Identifiable, Sendable, Equatable {
    let id = UUID()
    let date: Date
    let high: Double
    let low: Double
    let condition: WeatherCondition
}

enum WeatherCondition: String, Sendable, Equatable {
    case clear
    case partlyCloudy
    case cloudy
    case fog
    case drizzle
    case rain
    case snow
    case thunderstorm

    var symbolName: String {
        symbolName(isDay: true)
    }

    func symbolName(isDay: Bool) -> String {
        switch self {
        case .clear:
            isDay ? "sun.max.fill" : "moon.stars.fill"
        case .partlyCloudy:
            isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case .cloudy:
            "cloud.fill"
        case .fog:
            "cloud.fog.fill"
        case .drizzle:
            "cloud.drizzle.fill"
        case .rain:
            "cloud.rain.fill"
        case .snow:
            "cloud.snow.fill"
        case .thunderstorm:
            "cloud.bolt.rain.fill"
        }
    }

    var title: String {
        switch self {
        case .clear: "Clear"
        case .partlyCloudy: "Partly Cloudy"
        case .cloudy: "Cloudy"
        case .fog: "Fog"
        case .drizzle: "Drizzle"
        case .rain: "Rain"
        case .snow: "Snow"
        case .thunderstorm: "Thunderstorm"
        }
    }

    static func from(wmoCode: Int) -> WeatherCondition {
        switch wmoCode {
        case 0: .clear
        case 1, 2: .partlyCloudy
        case 3: .cloudy
        case 45, 48: .fog
        case 51, 53, 55, 56, 57: .drizzle
        case 61, 63, 65, 66, 67, 80, 81, 82: .rain
        case 71, 73, 75, 77, 85, 86: .snow
        case 95, 96, 99: .thunderstorm
        default: .cloudy
        }
    }
}
