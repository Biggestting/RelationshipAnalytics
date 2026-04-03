import SwiftUI

enum VisualMode: String, CaseIterable {
    case dna = "DNA"
    case wrapped = "WRAPPED"
}

struct VisualInsightsCard: View {
    let stats: MessageStats
    let callStats: CallStats
    let contactName: String

    @State private var mode: VisualMode = .dna

    var body: some View {
        VStack(spacing: 0) {
            // Toggle header
            HStack(spacing: 0) {
                ForEach(VisualMode.allCases, id: \.rawValue) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            mode = option
                        }
                    } label: {
                        VStack(spacing: 6) {
                            HStack(spacing: 5) {
                                Image(systemName: option == .dna ? "circle.hexagongrid.fill" : "sparkles")
                                    .font(.system(size: 10))
                                Text(option.rawValue)
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                            }
                            .foregroundStyle(mode == option ? AppTheme.textPrimary : AppTheme.textMuted)

                            Rectangle()
                                .fill(mode == option ? AppTheme.textPrimary : Color.clear)
                                .frame(height: 1)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 6)
            .background(AppTheme.cardBackground)

            // Content
            switch mode {
            case .dna:
                RelationshipDNAView(stats: stats, contactName: contactName)
                    .padding(16)
                    .transition(.opacity)

            case .wrapped:
                YearWrappedView(stats: stats, callStats: callStats, contactName: contactName)
                    .padding(.vertical, 8)
                    .transition(.opacity)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                        .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                )
        )
    }
}

#Preview {
    VisualInsightsCard(
        stats: MockDataProvider.messageStats,
        callStats: MockDataProvider.callStats,
        contactName: "Nina"
    )
    .padding()
    .background(Color.black)
}
