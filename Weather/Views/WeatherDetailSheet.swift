import SwiftUI

/// Modal opened from “Feels like” — hourly, daily high/low, sunrise / sunset.
struct WeatherDetailSheet: View {
    let snapshot: WeatherSnapshot
    let model: WeatherViewModel

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    todayHighLow
                    sunTimes
                    hourlySection
                    dailySection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

    // MARK: - Today high / low

    private var todayHighLow: some View {
        Group {
            if let today = snapshot.daily.first {
                HStack(spacing: 12) {
                    highLowCard(
                        title: "High",
                        value: model.displayTemperature(today.high),
                        symbol: "thermometer.sun.fill",
                        tint: .orange
                    )
                    highLowCard(
                        title: "Low",
                        value: model.displayTemperature(today.low),
                        symbol: "thermometer.snowflake",
                        tint: .cyan
                    )
                }
            }
        }
    }

    private func highLowCard(title: String, value: String, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: symbol)
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(tint.opacity(0.9))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText())
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Sunrise / Sunset

    private var sunTimes: some View {
        HStack(spacing: 12) {
            sunCard(
                title: "Sunrise",
                time: snapshot.sunrise,
                symbol: "sunrise.fill"
            )
            sunCard(
                title: "Sunset",
                time: snapshot.sunset,
                symbol: "sunset.fill"
            )
        }
    }

    private func sunCard(title: String, time: Date?, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: symbol)
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.orange.opacity(0.9))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                Text(timeText(time))
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Hourly

    private var hourlySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Hourly")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(snapshot.hourly.prefix(24).enumerated()), id: \.element.id) { index, hour in
                        hourlyCell(hour, isNow: index == 0)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
            .padding(.vertical, 12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private func hourlyCell(_ hour: HourlyForecast, isNow: Bool) -> some View {
        VStack(spacing: 10) {
            Text(isNow ? "Now" : hour.date.formatted(.dateTime.hour()))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            Image(systemName: hour.symbolName)
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(iconColor(for: hour))
                .frame(height: 28)

            Text(model.displayTemperature(hour.temperature))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .contentTransition(.numericText())
                .monospacedDigit()
        }
        .frame(width: 58)
        .padding(.vertical, 8)
    }

    private func iconColor(for hour: HourlyForecast) -> Color {
        iconColor(for: hour.condition, isDay: hour.isDay)
    }

    // MARK: - Daily

    private var dailySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("This Week")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(snapshot.daily.prefix(7).enumerated()), id: \.element.id) { index, day in
                    dailyRow(day, isToday: index == 0)
                    if index < min(snapshot.daily.count, 7) - 1 {
                        Divider()
                            .opacity(0.35)
                            .padding(.leading, 4)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private func dailyRow(_ day: DailyForecast, isToday: Bool) -> some View {
        HStack(spacing: 14) {
            Text(isToday ? "Today" : day.date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .frame(width: 56, alignment: .leading)

            Image(systemName: day.condition.symbolName(isDay: true))
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(iconColor(for: day.condition, isDay: true))
                .frame(width: 28)

            Spacer(minLength: 8)

            Text(model.displayTemperature(day.low))
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)
                .contentTransition(.numericText())
                .monospacedDigit()

            TemperatureRangeBar(
                low: day.low,
                high: day.high,
                range: weekTemperatureRange
            )
            .frame(width: 86, height: 4)

            Text(model.displayTemperature(day.high))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .frame(width: 40, alignment: .trailing)
                .contentTransition(.numericText())
                .monospacedDigit()
        }
        .padding(.vertical, 10)
    }

    private var weekTemperatureRange: ClosedRange<Double> {
        let lows = snapshot.daily.map(\.low)
        let highs = snapshot.daily.map(\.high)
        guard let min = lows.min(), let max = highs.max(), min < max else {
            return 0...1
        }
        return min...max
    }

    private func iconColor(for condition: WeatherCondition, isDay: Bool) -> Color {
        switch condition {
        case .clear:
            isDay ? Color.orange : Color.indigo.opacity(0.85)
        case .partlyCloudy:
            isDay ? Color.orange.opacity(0.85) : Color.indigo.opacity(0.75)
        case .rain, .drizzle, .thunderstorm:
            Color.blue.opacity(0.85)
        case .snow:
            Color.cyan.opacity(0.9)
        case .fog, .cloudy:
            Color.secondary
        }
    }

    private func timeText(_ date: Date?) -> String {
        guard let date else { return "--" }
        return date.formatted(.dateTime.hour().minute())
    }
}

private struct TemperatureRangeBar: View {
    let low: Double
    let high: Double
    let range: ClosedRange<Double>

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let span = max(range.upperBound - range.lowerBound, 1)
            let start = CGFloat((low - range.lowerBound) / span) * width
            let end = CGFloat((high - range.lowerBound) / span) * width

            Capsule()
                .fill(Color.primary.opacity(0.12))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.cyan.opacity(0.75), .orange.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(end - start, 6))
                        .offset(x: start)
                }
        }
    }
}

#Preview {
    WeatherDetailSheet(
        snapshot: WeatherSnapshot(
            locationName: "San Francisco",
            temperature: 13,
            apparentTemperature: 12,
            condition: .fog,
            humidity: 90,
            windSpeed: 10,
            uvIndex: 1,
            isDay: true,
            sunrise: Date(),
            sunset: Date().addingTimeInterval(3600 * 8),
            hourly: [],
            daily: []
        ),
        model: WeatherViewModel()
    )
}
