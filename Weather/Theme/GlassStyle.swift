import SwiftUI

/// Shapes for sparse chrome over atmosphere.
enum AmbientShape {
    static let pill = Capsule(style: .continuous)
    static let soft = RoundedRectangle(cornerRadius: 22, style: .continuous)
}

enum AmbientGlassKind {
    case clear
    case regular
}

extension View {
    @ViewBuilder
    func ambientGlass(
        _ kind: AmbientGlassKind = .clear,
        in shape: some Shape = AmbientShape.pill,
        interactive: Bool = false
    ) -> some View {
        let material: Glass = {
            switch kind {
            case .clear: .clear
            case .regular: .regular
            }
        }()

        if interactive {
            self.glassEffect(material.interactive(), in: shape)
        } else {
            self.glassEffect(material, in: shape)
        }
    }
}
