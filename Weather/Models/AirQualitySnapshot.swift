import Foundation
import SwiftUI

struct AirQualitySnapshot: Sendable, Equatable {
    let locationName: String
    let aqi: Int
    let pm25: Double
    let pm10: Double
    let ozone: Double
    let nitrogenDioxide: Double
    let carbonMonoxide: Double
    let sulphurDioxide: Double

    var category: AQICategory {
        .from(aqi: aqi)
    }
}

enum AQICategory: String, Sendable, Equatable, CaseIterable {
    case good
    case moderate
    case unhealthySensitive
    case unhealthy
    case veryUnhealthy
    case hazardous

    static func from(aqi: Int) -> AQICategory {
        switch aqi {
        case ...50: .good
        case 51...100: .moderate
        case 101...150: .unhealthySensitive
        case 151...200: .unhealthy
        case 201...300: .veryUnhealthy
        default: .hazardous
        }
    }

    var title: String {
        switch self {
        case .good: "Good"
        case .moderate: "Moderate"
        case .unhealthySensitive: "Unhealthy for Sensitive Groups"
        case .unhealthy: "Unhealthy"
        case .veryUnhealthy: "Very Unhealthy"
        case .hazardous: "Hazardous"
        }
    }

    /// Short label for the scale strip.
    var shortTitle: String {
        switch self {
        case .good: "Good"
        case .moderate: "Moderate"
        case .unhealthySensitive: "Sensitive"
        case .unhealthy: "Unhealthy"
        case .veryUnhealthy: "Very Unhealthy"
        case .hazardous: "Hazardous"
        }
    }

    var rangeText: String {
        switch self {
        case .good: "0–50"
        case .moderate: "51–100"
        case .unhealthySensitive: "101–150"
        case .unhealthy: "151–200"
        case .veryUnhealthy: "201–300"
        case .hazardous: "301+"
        }
    }

    var advice: String {
        switch self {
        case .good:
            "Air looks clear. Great day to be outside."
        case .moderate:
            "Air is okay for most people. If you get irritated easily, take it easy outdoors."
        case .unhealthySensitive:
            "Kids, older adults, and anyone with lung or heart issues should limit long outdoor activity."
        case .unhealthy:
            "The air may bother everyone. Cut back on outdoor exercise."
        case .veryUnhealthy:
            "Health alert. Stay indoors as much as you can."
        case .hazardous:
            "Emergency-level air. Remain indoors and keep windows closed."
        }
    }

    var meaning: String {
        switch self {
        case .good:
            "Little or no risk from outdoor air."
        case .moderate:
            "Acceptable air quality for most people."
        case .unhealthySensitive:
            "Higher risk if you’re sensitive to air pollution."
        case .unhealthy:
            "Everyone may start to feel effects."
        case .veryUnhealthy:
            "Serious health risk for everyone."
        case .hazardous:
            "Dangerous air for the whole community."
        }
    }

    var swatch: Color {
        switch self {
        case .good: Color(red: 0.30, green: 0.78, blue: 0.52)
        case .moderate: Color(red: 0.96, green: 0.84, blue: 0.28)
        case .unhealthySensitive: Color(red: 0.98, green: 0.62, blue: 0.28)
        case .unhealthy: Color(red: 0.92, green: 0.30, blue: 0.30)
        case .veryUnhealthy: Color(red: 0.62, green: 0.28, blue: 0.78)
        case .hazardous: Color(red: 0.55, green: 0.12, blue: 0.22)
        }
    }

    /// Richer multi-stop atmosphere.
    var atmosphere: [Color] {
        switch self {
        case .good:
            [
                Color(red: 0.22, green: 0.62, blue: 0.48),
                Color(red: 0.38, green: 0.78, blue: 0.58),
                Color(red: 0.62, green: 0.90, blue: 0.72),
                Color(red: 0.84, green: 0.96, blue: 0.90)
            ]
        case .moderate:
            [
                Color(red: 0.82, green: 0.68, blue: 0.18),
                Color(red: 0.94, green: 0.82, blue: 0.30),
                Color(red: 0.98, green: 0.92, blue: 0.52),
                Color(red: 0.98, green: 0.96, blue: 0.82)
            ]
        case .unhealthySensitive:
            [
                Color(red: 0.86, green: 0.48, blue: 0.18),
                Color(red: 0.95, green: 0.64, blue: 0.32),
                Color(red: 0.98, green: 0.78, blue: 0.48),
                Color(red: 0.98, green: 0.90, blue: 0.76)
            ]
        case .unhealthy:
            [
                Color(red: 0.72, green: 0.18, blue: 0.22),
                Color(red: 0.90, green: 0.34, blue: 0.34),
                Color(red: 0.94, green: 0.55, blue: 0.48),
                Color(red: 0.96, green: 0.78, blue: 0.74)
            ]
        case .veryUnhealthy:
            [
                Color(red: 0.38, green: 0.14, blue: 0.52),
                Color(red: 0.58, green: 0.28, blue: 0.72),
                Color(red: 0.74, green: 0.48, blue: 0.84),
                Color(red: 0.88, green: 0.74, blue: 0.92)
            ]
        case .hazardous:
            [
                Color(red: 0.32, green: 0.06, blue: 0.14),
                Color(red: 0.52, green: 0.12, blue: 0.24),
                Color(red: 0.68, green: 0.28, blue: 0.36),
                Color(red: 0.80, green: 0.48, blue: 0.52)
            ]
        }
    }

    var prefersDarkContent: Bool {
        switch self {
        case .good, .moderate, .unhealthySensitive: false
        case .unhealthy, .veryUnhealthy, .hazardous: true
        }
    }
}
