import SwiftUI

/// Shared frame for a type's heading, controls, and presentation previews.
struct IslandTypeCard<Content: View>: View {
    let isRunning: Bool
    private let content: Content

    init(
        isRunning: Bool,
        @ViewBuilder content: () -> Content
    ) {
        self.isRunning = isRunning
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isRunning ? Color.green : Color(.separator), lineWidth: 1)
            }
    }
}
