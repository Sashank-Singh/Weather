import SwiftUI

/// Full-bleed photographic sky — looks like outside, not a flat fill.
struct SkyAtmosphere: View {
    let condition: WeatherCondition
    let isDay: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                photoSky
                    .scaleEffect(1.08 + 0.02 * sin(t * 0.05))
                    .offset(x: CGFloat(sin(t * 0.03) * 6))

                // Light atmospheric wash so glass + type stay readable
                readabilityWash

                weatherOverlay(t: t)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 1.0), value: condition)
        .animation(.easeInOut(duration: 1.0), value: isDay)
    }

    private var photoSky: some View {
        Image(photoName)
            .resizable()
            .scaledToFill()
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .clipped()
            .overlay {
                // Very light grade — keep the photo looking like a photo
                LinearGradient(
                    colors: gradeColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .blendMode(.softLight)
                .opacity(0.22)
            }
    }

    private var readabilityWash: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black.opacity(isDay ? 0.10 : 0.28),
                    .clear
                ],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.22)
            )

            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(isDay ? 0.22 : 0.45)
                ],
                startPoint: UnitPoint(x: 0.5, y: 0.52),
                endPoint: .bottom
            )
        }
    }

    @ViewBuilder
    private func weatherOverlay(t: Double) -> some View {
        switch condition {
        case .drizzle:
            rain(t: t, density: 0.35)
        case .rain:
            rain(t: t, density: 0.8)
        case .thunderstorm:
            rain(t: t, density: 1.0)
            Color.white.opacity(lightning(t))
        case .snow:
            snow(t: t)
        case .fog:
            // Extra soft drifting mist over the photo
            Rectangle()
                .fill(Color.white.opacity(0.08 + 0.04 * sin(t * 0.2)))
                .blur(radius: 40)
                .offset(x: CGFloat(sin(t * 0.1) * 20), y: 80)
        default:
            EmptyView()
        }
    }

    private func rain(t: Double, density: Double) -> some View {
        Canvas { context, size in
            let count = Int(50 + density * 70)
            for i in 0..<count {
                let seed = Double(i * 89)
                let x = (seed * 13.1).truncatingRemainder(dividingBy: Double(size.width))
                let y = (t * (260 + Double(i % 5) * 50) + seed * 40)
                    .truncatingRemainder(dividingBy: Double(size.height) + 24) - 16
                var path = Path()
                path.move(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x + 1.2, y: y + 12 + density * 8))
                context.stroke(path, with: .color(.white.opacity(0.14 + density * 0.1)), lineWidth: 0.8)
            }
        }
    }

    private func snow(t: Double) -> some View {
        Canvas { context, size in
            for i in 0..<60 {
                let seed = Double(i * 47)
                let sway = sin(t * 0.65 + seed) * 16
                let x = (seed * 17.9).truncatingRemainder(dividingBy: Double(size.width)) + sway
                let y = (t * (20 + Double(i % 4) * 7) + seed * 25)
                    .truncatingRemainder(dividingBy: Double(size.height) + 14) - 8
                let r = 1.3 + Double(i % 3) * 0.8
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                    with: .color(.white.opacity(0.5))
                )
            }
        }
    }

    private func lightning(_ t: Double) -> Double {
        let v = sin(t * 6.8)
        return v > 0.97 ? min(0.2, (v - 0.97) * 4) : 0
    }

    private var photoName: String {
        // Assets present: SkyClear, SkyCloudy, SkyFog, SkyNight, SkyRain
        if !isDay {
            switch condition {
            case .rain, .thunderstorm, .drizzle:
                return "SkyRain"
            case .fog:
                return "SkyFog"
            case .cloudy, .partlyCloudy, .snow:
                return "SkyNight"
            case .clear:
                return "SkyNight"
            }
        }

        switch condition {
        case .clear:
            return "SkyClear"
        case .partlyCloudy:
            return "SkyCloudy"
        case .cloudy, .snow:
            return "SkyCloudy"
        case .fog:
            return "SkyFog"
        case .drizzle, .rain, .thunderstorm:
            return "SkyRain"
        }
    }

    private var gradeColors: [Color] {
        if !isDay {
            return [
                Color(red: 0.15, green: 0.2, blue: 0.4),
                Color(red: 0.25, green: 0.28, blue: 0.38)
            ]
        }
        switch condition {
        case .clear:
            return [Color(red: 0.4, green: 0.7, blue: 1.0), Color(red: 0.95, green: 0.9, blue: 0.75)]
        case .fog:
            return [Color(red: 0.7, green: 0.75, blue: 0.85), Color(red: 0.9, green: 0.9, blue: 0.92)]
        case .rain, .thunderstorm:
            return [Color(red: 0.3, green: 0.4, blue: 0.55), Color(red: 0.45, green: 0.5, blue: 0.55)]
        default:
            return [Color.white.opacity(0.2), Color.white.opacity(0.1)]
        }
    }
}
