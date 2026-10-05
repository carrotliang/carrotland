import SwiftUI

struct IslandPresentationPreviews<Compact: View, Minimal: View>: View {
    let compactIdentifier: String
    let minimalIdentifier: String
    private let compact: Compact
    private let minimal: Minimal
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        compactIdentifier: String,
        minimalIdentifier: String,
        @ViewBuilder compact: () -> Compact,
        @ViewBuilder minimal: () -> Minimal
    ) {
        self.compactIdentifier = compactIdentifier
        self.minimalIdentifier = minimalIdentifier
        self.compact = compact()
        self.minimal = minimal()
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                stackedPreviews
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        compactPreview
                        minimalPreview
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    stackedPreviews
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var stackedPreviews: some View {
        VStack(spacing: 12) {
            compactPreview
            minimalPreview
        }
    }

    private var compactPreview: some View {
        compact
            .padding(.horizontal, 14)
            .frame(height: 37)
            .modifier(IslandPreviewCapsule())
            .fixedSize()
            .accessibilityElement(children: .contain)
            .accessibilityLabel("常规形态预览")
            .accessibilityIdentifier(compactIdentifier)
    }

    private var minimalPreview: some View {
        minimal
            .frame(width: 40, height: 37)
            .modifier(IslandPreviewCapsule())
            .fixedSize()
            .accessibilityElement(children: .contain)
            .accessibilityLabel("最小形态预览")
            .accessibilityIdentifier(minimalIdentifier)
    }
}

private struct IslandPreviewCapsule: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.white)
            .background(.black, in: Capsule())
            .overlay {
                Capsule().strokeBorder(Color(.systemGray), lineWidth: 1)
            }
    }
}
