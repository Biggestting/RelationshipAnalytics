import SwiftUI

struct RelationshipDNAView: View {
    let stats: MessageStats
    let contactName: String

    @State private var showInfo = false

    private var seed: Int { abs(contactName.hashValue) }

    private var layers: Int {
        min(max(stats.totalMessages / 50, 4), 12)
    }

    private var balance: Double {
        stats.sentPercentage / 100.0
    }

    private var replyRatio: Double {
        guard stats.theirReplyTime > 0 else { return 0.5 }
        return min(max(stats.yourReplyTime / (stats.yourReplyTime + stats.theirReplyTime), 0), 1)
    }

    private var intensity: Double {
        let activeDays = Double(stats.messageActivity.filter { $0.count > 0 }.count)
        let totalDays = Double(max(stats.messageActivity.count, 1))
        return activeDays / totalDays
    }

    // Color palette derived from data
    private var palette: [Color] {
        let hueBase = Double(seed % 360) / 360.0
        return [
            Color(hue: hueBase, saturation: 0.7, brightness: 0.95),                          // primary
            Color(hue: (hueBase + 0.08).truncatingRemainder(dividingBy: 1), saturation: 0.6, brightness: 0.9),  // shift 1
            Color(hue: (hueBase + 0.55).truncatingRemainder(dividingBy: 1), saturation: 0.5, brightness: 0.85), // complement
            AppTheme.accentRed,                                                                // accent
            Color(hue: (hueBase + 0.3).truncatingRemainder(dividingBy: 1), saturation: 0.4, brightness: 0.8),   // tertiary
        ]
    }

    var body: some View {
        VStack(spacing: 14) {
            // DNA Art
            ZStack(alignment: .topTrailing) {
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let maxRadius = min(size.width, size.height) / 2.2

                    // Subtle background ring
                    let bgPath = Circle().path(in: CGRect(
                        x: center.x - maxRadius, y: center.y - maxRadius,
                        width: maxRadius * 2, height: maxRadius * 2
                    ))
                    context.stroke(bgPath, with: .color(AppTheme.cardBorder), lineWidth: 0.5)

                    // Generate colored layers
                    for layer in 0..<layers {
                        let progress = Double(layer) / Double(layers)
                        let radius = maxRadius * (0.2 + progress * 0.8)
                        drawDNALayer(
                            context: &context, center: center, radius: radius,
                            layer: layer, progress: progress, size: size
                        )
                    }

                    // Center dot
                    let dotSize: CGFloat = 8
                    let dotRect = CGRect(x: center.x - dotSize/2, y: center.y - dotSize/2, width: dotSize, height: dotSize)
                    context.fill(Circle().path(in: dotRect), with: .color(palette[0]))
                }
                .frame(height: 280)

                // Info button
                Button { showInfo.toggle() } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.textMuted)
                }
                .padding(8)
            }

            // Legend with info tooltips
            HStack(spacing: 12) {
                DNALegendItem(
                    label: "LAYERS",
                    value: "\(layers)",
                    hint: "MORE MESSAGES = MORE RINGS"
                )
                DNALegendItem(
                    label: "BALANCE",
                    value: "\(Int(balance * 100))%",
                    hint: "50% = EQUAL GIVE AND TAKE"
                )
                DNALegendItem(
                    label: "INTENSITY",
                    value: "\(Int(intensity * 100))%",
                    hint: "HOW OFTEN YOU TALK"
                )
            }
        }
        .sheet(isPresented: $showInfo) {
            DNAInfoSheet()
                .presentationDetents([.medium])
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
        let points = 180
        let baseAmplitude = radius * 0.10 * (1 + intensity)
        let activitySlice = getActivitySlice(for: layer)

        var path = Path()
        for i in 0..<points {
            let angle = (Double(i) / Double(points)) * .pi * 2
            let rotatedAngle = angle + (stats.youStartPercentage / 100.0) * .pi * 0.5

            let activityIndex = i % max(activitySlice.count, 1)
            let activityValue = activitySlice.isEmpty ? 0.5 : Double(activitySlice[activityIndex].intensity) / 4.0
            let balanceWave = sin(angle * 2 + Double(layer)) * (balance - 0.5) * 2

            let amplitude = baseAmplitude * (0.3 + activityValue * 0.7 + balanceWave * 0.3)
            let wave = sin(angle * Double(3 + layer) + Double(seed % 7)) * amplitude

            let r = radius + wave
            let x = center.x + CGFloat(cos(rotatedAngle)) * r
            let y = center.y + CGFloat(sin(rotatedAngle)) * r

            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.closeSubpath()

        // Pick color from palette based on layer position
        let colorIndex = layer % palette.count
        let layerColor = palette[colorIndex]

        // Opacity: inner layers are more vivid, outer layers fade
        let opacity = 0.25 + (1 - progress) * 0.55

        // Line width: thicker for inner layers, thinner for outer
        let lineWidth: CGFloat = 2.5 - progress * 1.5  // 2.5 → 1.0

        context.stroke(path, with: .color(layerColor.opacity(opacity)), lineWidth: lineWidth)

        // Add a subtle glow on the innermost layers
        if layer < 3 {
            context.stroke(path, with: .color(layerColor.opacity(opacity * 0.3)), lineWidth: lineWidth + 2)
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

// MARK: - Legend with hover hints

struct DNALegendItem: View {
    let label: String
    let value: String
    let hint: String

    @State private var showHint = false

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.textPrimary)

            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.textMuted)

            if showHint {
                Text(hint)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(AppTheme.textSecondary)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) { showHint.toggle() }
        }
    }
}

// MARK: - Info Sheet

struct DNAInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("RELATIONSHIP DNA")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("A UNIQUE VISUAL FINGERPRINT GENERATED FROM YOUR CONVERSATION DATA. EVERY CONTACT PRODUCES A DIFFERENT PATTERN.")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineSpacing(3)

                    Rectangle().fill(AppTheme.divider).frame(height: 1)

                    DNAInfoRow(
                        icon: "circle.hexagongrid",
                        title: "LAYERS",
                        description: "THE NUMBER OF RINGS. MORE MESSAGES = MORE LAYERS. RANGES FROM 4 (NEW CONTACT) TO 12 (DEEP HISTORY)."
                    )

                    DNAInfoRow(
                        icon: "scale.3d",
                        title: "BALANCE",
                        description: "HOW EVENLY YOU BOTH CONTRIBUTE. 50% MEANS EQUAL GIVE AND TAKE. UNBALANCED CONVERSATIONS CREATE ASYMMETRIC SHAPES."
                    )

                    DNAInfoRow(
                        icon: "bolt.fill",
                        title: "INTENSITY",
                        description: "HOW CONSISTENTLY YOU TALK. 100% MEANS YOU MESSAGE EVERY DAY. HIGHER INTENSITY = WILDER, MORE DYNAMIC WAVES."
                    )

                    Rectangle().fill(AppTheme.divider).frame(height: 1)

                    Text("WHAT SHAPES THE PATTERN")
                        .font(AppTheme.cardTitle)
                        .foregroundStyle(AppTheme.textPrimary)

                    DNAInfoRow(
                        icon: "waveform.path",
                        title: "WAVE SHAPE",
                        description: "DRIVEN BY YOUR DAILY MESSAGE ACTIVITY. BUSY DAYS CREATE LARGER PEAKS, QUIET DAYS CREATE VALLEYS."
                    )

                    DNAInfoRow(
                        icon: "paintpalette",
                        title: "COLORS",
                        description: "EACH CONTACT GETS A UNIQUE COLOR PALETTE BASED ON THEIR NAME. INNER RINGS ARE MORE VIVID, OUTER RINGS FADE."
                    )

                    DNAInfoRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: "ROTATION",
                        description: "THE PATTERN'S ROTATION IS SET BY WHO STARTS CONVERSATIONS MORE. HIGH INITIATOR % = MORE ROTATED."
                    )

                    DNAInfoRow(
                        icon: "circle.lefthalf.filled",
                        title: "SYMMETRY",
                        description: "BALANCED CONVERSATIONS (50/50 SENT/RECEIVED) PRODUCE SYMMETRICAL SHAPES. LOPSIDED CHATS CREATE ASYMMETRY."
                    )

                    Text("TAP ANY METRIC BELOW THE DNA TO SEE ITS EXPLANATION.")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(AppTheme.textMuted)
                        .padding(.top, 8)
                }
                .padding(20)
            }
        }
    }
}

struct DNAInfoRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 20, alignment: .center)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(description)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(AppTheme.textMuted)
                    .lineSpacing(2)
            }
        }
    }
}

