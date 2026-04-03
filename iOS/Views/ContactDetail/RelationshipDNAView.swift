import SwiftUI

/// Generates a unique visual "fingerprint" for each relationship.
/// The pattern is deterministic — same data always produces the same art.
///
/// Data mapping:
/// - Message frequency → wave amplitude
/// - Reply time ratio → hue shift
/// - Sent/received balance → symmetry
/// - Active streak → ring density
/// - You-start % → rotation offset
/// - Total messages → number of layers
struct RelationshipDNAView: View {
    let stats: MessageStats
    let contactName: String

    // Derived parameters from data
    private var seed: Int {
        abs(contactName.hashValue)
    }

    private var layers: Int {
        min(max(stats.totalMessages / 50, 4), 12)
    }

    private var balance: Double {
        stats.sentPercentage / 100.0 // 0-1, 0.5 = perfectly balanced
    }

    private var replyRatio: Double {
        guard stats.theirReplyTime > 0 else { return 0.5 }
        let ratio = stats.yourReplyTime / (stats.yourReplyTime + stats.theirReplyTime)
        return min(max(ratio, 0), 1)
    }

    private var intensity: Double {
        let activeDays = Double(stats.messageActivity.filter { $0.count > 0 }.count)
        let totalDays = Double(max(stats.messageActivity.count, 1))
        return activeDays / totalDays
    }

    var body: some View {
        VStack(spacing: 16) {
            // DNA Art
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let maxRadius = min(size.width, size.height) / 2.2

                // Background ring
                let bgPath = Circle().path(in: CGRect(
                    x: center.x - maxRadius,
                    y: center.y - maxRadius,
                    width: maxRadius * 2,
                    height: maxRadius * 2
                ))
                context.stroke(bgPath, with: .color(AppTheme.cardBorder), lineWidth: 0.5)

                // Generate layers
                for layer in 0..<layers {
                    let progress = Double(layer) / Double(layers)
                    let radius = maxRadius * (0.2 + progress * 0.8)

                    drawDNALayer(
                        context: &context,
                        center: center,
                        radius: radius,
                        layer: layer,
                        progress: progress,
                        size: size
                    )
                }

                // Center dot
                let dotSize: CGFloat = 6
                let dotRect = CGRect(x: center.x - dotSize/2, y: center.y - dotSize/2, width: dotSize, height: dotSize)
                context.fill(Circle().path(in: dotRect), with: .color(AppTheme.accentRed))

            }
            .frame(height: 280)

            // Data legend
            HStack(spacing: 16) {
                DNALegendItem(label: "LAYERS", value: "\(layers)")
                DNALegendItem(label: "BALANCE", value: "\(Int(balance * 100))%")
                DNALegendItem(label: "INTENSITY", value: "\(Int(intensity * 100))%")
            }
        }
    }

    private func drawDNALayer(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        layer: Int,
        progress: Double,
        size: CGSize
    ) {
        let points = 120
        let baseAmplitude = radius * 0.08 * (1 + intensity)

        // Each layer uses different message activity data
        let activitySlice = getActivitySlice(for: layer)

        var path = Path()
        for i in 0..<points {
            let angle = (Double(i) / Double(points)) * .pi * 2
            let rotatedAngle = angle + (stats.youStartPercentage / 100.0) * .pi * 0.5

            // Wave modulation from activity data
            let activityIndex = i % max(activitySlice.count, 1)
            let activityValue = activitySlice.isEmpty ? 0.5 : Double(activitySlice[activityIndex].intensity) / 4.0

            // Asymmetry from sent/received balance
            let balanceWave = sin(angle * 2 + Double(layer)) * (balance - 0.5) * 2

            let amplitude = baseAmplitude * (0.3 + activityValue * 0.7 + balanceWave * 0.3)
            let wave = sin(angle * Double(3 + layer) + Double(seed % 7)) * amplitude

            let r = radius + wave
            let x = center.x + CGFloat(cos(rotatedAngle)) * r
            let y = center.y + CGFloat(sin(rotatedAngle)) * r

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()

        // Color: white with opacity based on layer depth
        let opacity = 0.08 + (1 - progress) * 0.25

        // Accent: innermost layers get a hint of red based on reply ratio
        if layer < 2 {
            let redAmount = replyRatio * 0.3
            context.stroke(
                path,
                with: .color(Color(red: 1, green: 1 - redAmount, blue: 1 - redAmount).opacity(opacity + 0.1)),
                lineWidth: 1.2
            )
        } else {
            context.stroke(path, with: .color(AppTheme.textPrimary.opacity(opacity)), lineWidth: 0.8)
        }
    }

    private func getActivitySlice(for layer: Int) -> [DayActivity] {
        let total = stats.messageActivity.count
        guard total > 0 else { return [] }
        let sliceSize = total / max(layers, 1)
        let start = (layer * sliceSize) % total
        let end = min(start + sliceSize, total)
        return Array(stats.messageActivity[start..<end])
    }
}

struct DNALegendItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.textPrimary)
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(AppTheme.textMuted)
        }
    }
}

#Preview {
    RelationshipDNAView(stats: MockDataProvider.messageStats, contactName: "Nina")
        .padding()
        .background(Color.black)
}
