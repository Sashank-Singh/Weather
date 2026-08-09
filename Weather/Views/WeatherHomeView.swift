import CoreLocation
import SwiftUI

/// Ultra-minimal chrome over a photo-real sky.
struct WeatherHomeView: View {
    @State private var model = WeatherViewModel()
    @State private var showDetails = false
    @State private var showAQI = false
    @State private var showLocations = false
    @Namespace private var glassSpace

    var body: some View {
        ZStack {
            atmosphere

            switch model.phase {
            case .idle, .loading:
                loadingView
            case .failed(let message):
                failureView(message)
            case .loaded(let snapshot):
                loadedView(snapshot)
            }
        }
        .preferredColorScheme(colorScheme)
        .task {
            await model.load()
            applyScreenshotLaunchArgumentIfNeeded()
        }
        .sheet(isPresented: $showDetails) {
            if case .loaded(let snapshot) = model.phase {
                WeatherDetailSheet(snapshot: snapshot, model: model)
            }
        }
        .sheet(isPresented: $showLocations) {
            LocationPickerSheet(model: model)
        }
        .fullScreenCover(isPresented: $showAQI) {
            AQIAppView(
                coordinate: model.coordinate,
                locationName: model.locationName
            )
        }
    }

    /// `-shot aqi|details|locations` for README preview captures.
    private func applyScreenshotLaunchArgumentIfNeeded() {
        guard let index = ProcessInfo.processInfo.arguments.firstIndex(of: "-shot"),
              ProcessInfo.processInfo.arguments.indices.contains(index + 1)
        else { return }

        switch ProcessInfo.processInfo.arguments[index + 1] {
        case "aqi": showAQI = true
        case "details": showDetails = true
        case "locations": showLocations = true
        default: break
        }
    }

    @ViewBuilder
    private var atmosphere: some View {
        switch model.phase {
        case .loaded(let snapshot):
            SkyAtmosphere(condition: snapshot.condition, isDay: snapshot.isDay)
        default:
            SkyAtmosphere(condition: .clear, isDay: true)
        }
    }

    private var colorScheme: ColorScheme {
        if case .loaded(let snapshot) = model.phase, !snapshot.isDay {
            return .dark
        }
        return .light
    }

    private func loadedView(_ snapshot: WeatherSnapshot) -> some View {
        let usesC = model.usesCelsius

        return VStack(spacing: 0) {
            HStack(alignment: .center) {
                placePill(snapshot.locationName)
                Spacer()
                unitToggle(usesC: usesC)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)

            Spacer()

            VStack(spacing: 10) {
                Text(model.displayTemperature(snapshot.temperature))
                    .font(.system(size: 108, weight: .ultraLight, design: .rounded))
                    .tracking(-4)
                    .foregroundStyle(Color.primary.opacity(0.95))
                    .shadow(color: .black.opacity(snapshot.isDay ? 0.08 : 0.35), radius: 30, y: 10)
                    .contentTransition(.numericText())
                    .id(usesC)

                Text(snapshot.condition.title)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.primary.opacity(0.62))
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)

            Spacer()

            GlassEffectContainer(spacing: 12) {
                VStack(spacing: 12) {
                    Button {
                        showDetails = true
                    } label: {
                        Text("Feels like \(model.displayTemperature(snapshot.apparentTemperature))")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.primary.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .ambientGlass(.clear, in: AmbientShape.pill, interactive: true)
                    .glassEffectID("feels", in: glassSpace)
                    .accessibilityHint("Shows hourly forecast, daily high low, and sunrise sunset")

                    Button {
                        showAQI = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "aqi.medium")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Air Quality")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(Color.primary.opacity(0.85))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .ambientGlass(.regular, in: AmbientShape.pill, interactive: true)
                    .glassEffectID("aqi", in: glassSpace)
                    .accessibilityHint("Opens air quality")
                }
            }
            .padding(.bottom, 36)
        }
    }

    private func placePill(_ name: String) -> some View {
        GlassEffectContainer {
            Button {
                showLocations = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text(name)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .opacity(0.55)
                }
                .foregroundStyle(Color.primary.opacity(0.85))
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .ambientGlass(.regular, in: AmbientShape.pill, interactive: true)
            .glassEffectID("place", in: glassSpace)
            .accessibilityLabel("Location \(name)")
            .accessibilityHint("Choose or add a location")
        }
    }

    private func unitToggle(usesC: Bool) -> some View {
        GlassEffectContainer {
            HStack(spacing: 0) {
                unitChip("C", selected: usesC) {
                    guard !model.usesCelsius else { return }
                    withAnimation(.smooth(duration: 0.28)) { model.usesCelsius = true }
                }
                unitChip("F", selected: !usesC) {
                    guard model.usesCelsius else { return }
                    withAnimation(.smooth(duration: 0.28)) { model.usesCelsius = false }
                }
            }
            .padding(3)
            .ambientGlass(.regular, in: AmbientShape.pill)
            .glassEffectID("units", in: glassSpace)
        }
    }

    private func unitChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(selected ? Color.primary : Color.primary.opacity(0.35))
                .frame(width: 34, height: 30)
                .background {
                    if selected {
                        Capsule().fill(Color.primary.opacity(0.12))
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var loadingView: some View {
        ProgressView()
            .controlSize(.large)
            .tint(.primary.opacity(0.45))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func failureView(_ message: String) -> some View {
        VStack(spacing: 16) {
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    WeatherHomeView()
}
