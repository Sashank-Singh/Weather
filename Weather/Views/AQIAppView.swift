import CoreLocation
import SwiftUI

/// Full-screen AQI experience — plain language, no science jargon.
struct AQIAppView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: AirQualityViewModel
    @Namespace private var glassSpace

    init(coordinate: CLLocationCoordinate2D? = nil, locationName: String? = nil) {
        _model = State(
            initialValue: AirQualityViewModel(
                coordinate: coordinate,
                locationName: locationName
            )
        )
    }

    var body: some View {
        ZStack {
            atmosphere

            switch model.phase {
            case .idle, .loading:
                loadingChrome
            case .failed(let message):
                failureChrome(message)
            case .loaded(let snapshot):
                content(snapshot)
            }
        }
        .preferredColorScheme(preferredScheme)
        .task { await model.load() }
    }

    // MARK: - Atmosphere

    private var atmosphere: some View {
        let category: AQICategory = {
            if case .loaded(let snapshot) = model.phase {
                return snapshot.category
            }
            return .good
        }()

        return ZStack {
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.55, 0.45], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: meshColors(for: category)
            )

            RadialGradient(
                colors: [
                    Color.white.opacity(0.32),
                    .clear
                ],
                center: UnitPoint(x: 0.78, y: 0.14),
                startRadius: 10,
                endRadius: 360
            )

            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.10),
                    Color.black.opacity(0.22)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.85), value: model.phase)
    }

    private func meshColors(for category: AQICategory) -> [Color] {
        let c = category.atmosphere
        // Expand 4 stops into 9 mesh points with soft variation
        let a = c[0], b = c[1], d = c[2], e = c[safe: 3] ?? c[2]
        return [
            a, b, a.opacity(0.95),
            b, d, b.opacity(0.9),
            d, e, e.opacity(0.92)
        ]
    }

    private var preferredScheme: ColorScheme {
        if case .loaded(let snapshot) = model.phase, snapshot.category.prefersDarkContent {
            return .dark
        }
        return .light
    }

    // MARK: - Content

    private func content(_ snapshot: AirQualitySnapshot) -> some View {
        VStack(spacing: 0) {
            topBar(snapshot.locationName)

            Spacer(minLength: 20)

            VStack(spacing: 10) {
                Text("US Air Quality")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.primary.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(1.2)

                Text("\(snapshot.aqi)")
                    .font(.system(size: 112, weight: .ultraLight, design: .rounded))
                    .tracking(-4)
                    .foregroundStyle(Color.primary.opacity(0.95))
                    .contentTransition(.numericText())
                    .shadow(color: .black.opacity(0.12), radius: 24, y: 8)

                Text(snapshot.category.title)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.primary.opacity(0.88))
                    .padding(.horizontal, 28)

                Text(snapshot.category.meaning)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.primary.opacity(0.62))
                    .padding(.horizontal, 36)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 24)

            GlassEffectContainer(spacing: 14) {
                VStack(spacing: 14) {
                    aqiScale(current: snapshot.category)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("What to do")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.primary.opacity(0.45))
                            .textCase(.uppercase)
                            .tracking(0.8)

                        Text(snapshot.category.advice)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.primary.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .ambientGlass(.clear, in: AmbientShape.soft)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    /// Color scale people already know from weather apps / EPA.
    private func aqiScale(current: AQICategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Air quality scale")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.primary.opacity(0.45))
                .textCase(.uppercase)
                .tracking(0.8)

            // Continuous color bar with marker
            GeometryReader { geo in
                let categories = AQICategory.allCases
                let index = CGFloat(categories.firstIndex(of: current) ?? 0)
                let count = CGFloat(categories.count)
                let segment = geo.size.width / count

                ZStack(alignment: .leading) {
                    HStack(spacing: 3) {
                        ForEach(categories, id: \.self) { category in
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(category.swatch)
                                .frame(maxWidth: .infinity)
                                .opacity(category == current ? 1 : 0.45)
                                .scaleEffect(y: category == current ? 1.15 : 1, anchor: .center)
                        }
                    }
                    .frame(height: 12)

                    Circle()
                        .fill(.white)
                        .frame(width: 18, height: 18)
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 1)
                        .overlay {
                            Circle().stroke(current.swatch, lineWidth: 3)
                        }
                        .offset(x: index * segment + segment / 2 - 9)
                }
            }
            .frame(height: 22)

            HStack {
                Text(current.rangeText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("·")
                    .foregroundStyle(Color.primary.opacity(0.35))
                Text(current.shortTitle)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Spacer()
                Text("0–500")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.primary.opacity(0.4))
            }
        }
        .padding(18)
        .ambientGlass(.regular, in: AmbientShape.soft)
        .glassEffectID("aqi-scale", in: glassSpace)
    }

    private func topBar(_ location: String) -> some View {
        HStack {
            GlassEffectContainer {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text(location)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Color.primary.opacity(0.85))
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .ambientGlass(.regular, in: AmbientShape.pill)
                .glassEffectID("aqi-place", in: glassSpace)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.primary.opacity(0.8))
                    .frame(width: 40, height: 40)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .ambientGlass(.regular, in: Circle(), interactive: true)
            .glassEffectID("aqi-close", in: glassSpace)
            .accessibilityLabel("Close air quality")
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    // MARK: - States

    private var loadingChrome: some View {
        VStack {
            topBar("Air Quality")
            Spacer()
            ProgressView()
                .controlSize(.large)
                .tint(.primary.opacity(0.5))
            Spacer()
        }
    }

    private func failureChrome(_ message: String) -> some View {
        VStack(spacing: 16) {
            topBar("Air Quality")
            Spacer()
            Text(message)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.primary.opacity(0.7))
                .padding(.horizontal, 32)

            Button {
                Task { await model.load() }
            } label: {
                Text("Try Again")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .ambientGlass(.regular, in: AmbientShape.pill, interactive: true)

            Spacer()
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    AQIAppView(locationName: "San Francisco")
}
