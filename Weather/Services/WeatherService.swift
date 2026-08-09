import Foundation

actor WeatherService {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    func fetch(latitude: Double, longitude: Double, locationName: String) async throws -> WeatherSnapshot {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            .init(name: "latitude", value: String(latitude)),
            .init(name: "longitude", value: String(longitude)),
            .init(name: "current", value: "temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m"),
            .init(name: "hourly", value: "temperature_2m,weather_code,is_day,uv_index"),
            .init(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset"),
            .init(name: "timezone", value: "auto"),
            .init(name: "forecast_days", value: "7")
        ]

        guard let url = components.url else {
            throw WeatherError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw WeatherError.badResponse
        }

        let payload = try decoder.decode(OpenMeteoResponse.self, from: data)
        return payload.asSnapshot(locationName: locationName)
    }
}

enum WeatherError: LocalizedError {
    case invalidURL
    case badResponse
    case decoding

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Could not build weather request."
        case .badResponse: "Weather service returned an unexpected response."
        case .decoding: "Could not read weather data."
        }
    }
}

// MARK: - Open-Meteo Decoding

private struct OpenMeteoResponse: Decodable {
    let current: Current
    let hourly: Hourly
    let daily: Daily

    struct Current: Decodable {
        let temperature2m: Double
        let relativeHumidity2m: Int
        let apparentTemperature: Double
        let isDay: Int
        let weatherCode: Int
        let windSpeed10m: Double

        enum CodingKeys: String, CodingKey {
            case temperature2m = "temperature_2m"
            case relativeHumidity2m = "relative_humidity_2m"
            case apparentTemperature = "apparent_temperature"
            case isDay = "is_day"
            case weatherCode = "weather_code"
            case windSpeed10m = "wind_speed_10m"
        }
    }

    struct Hourly: Decodable {
        let time: [String]
        let temperature2m: [Double]
        let weatherCode: [Int]
        let isDay: [Int]
        let uvIndex: [Double]

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case weatherCode = "weather_code"
            case isDay = "is_day"
            case uvIndex = "uv_index"
        }
    }

    struct Daily: Decodable {
        let time: [String]
        let weatherCode: [Int]
        let temperature2mMax: [Double]
        let temperature2mMin: [Double]
        let sunrise: [String]
        let sunset: [String]

        enum CodingKeys: String, CodingKey {
            case time
            case weatherCode = "weather_code"
            case temperature2mMax = "temperature_2m_max"
            case temperature2mMin = "temperature_2m_min"
            case sunrise
            case sunset
        }
    }

    func asSnapshot(locationName: String) -> WeatherSnapshot {
        let hourFormatter = DateFormatter()
        hourFormatter.locale = Locale(identifier: "en_US_POSIX")
        hourFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"

        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayFormatter.dateFormat = "yyyy-MM-dd"

        let now = Date()
        let upcomingHourly: [HourlyForecast] = zip(hourly.time.indices, hourly.time)
            .compactMap { index, timeString in
                guard let date = hourFormatter.date(from: timeString), date >= now.addingTimeInterval(-3600) else { return nil }
                guard index < hourly.temperature2m.count,
                      index < hourly.weatherCode.count,
                      index < hourly.isDay.count else { return nil }

                return HourlyForecast(
                    date: date,
                    temperature: hourly.temperature2m[index],
                    condition: .from(wmoCode: hourly.weatherCode[index]),
                    isDay: hourly.isDay[index] == 1
                )
            }
            .prefix(24)
            .map { $0 }

        let currentHourIndex = hourly.time.firstIndex { timeString in
            guard let date = hourFormatter.date(from: timeString) else { return false }
            return abs(date.timeIntervalSince(now)) < 45 * 60
        } ?? 0

        let uv = Int((hourly.uvIndex[safe: currentHourIndex] ?? 0).rounded())

        let days: [DailyForecast] = zip(daily.time.indices, daily.time).compactMap { index, timeString in
            guard let date = dayFormatter.date(from: timeString) else { return nil }
            guard index < daily.temperature2mMax.count,
                  index < daily.temperature2mMin.count,
                  index < daily.weatherCode.count else { return nil }

            return DailyForecast(
                date: date,
                high: daily.temperature2mMax[index],
                low: daily.temperature2mMin[index],
                condition: .from(wmoCode: daily.weatherCode[index])
            )
        }

        let sunrise = daily.sunrise.first.flatMap { hourFormatter.date(from: $0) }
        let sunset = daily.sunset.first.flatMap { hourFormatter.date(from: $0) }

        return WeatherSnapshot(
            locationName: locationName,
            temperature: current.temperature2m,
            apparentTemperature: current.apparentTemperature,
            condition: .from(wmoCode: current.weatherCode),
            humidity: current.relativeHumidity2m,
            windSpeed: current.windSpeed10m,
            uvIndex: uv,
            isDay: current.isDay == 1,
            sunrise: sunrise,
            sunset: sunset,
            hourly: upcomingHourly,
            daily: days
        )
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
