import SwiftUI

struct CallLogCard: View {
    let records: [CallRecord]
    @State private var showAll = false

    private var displayedRecords: [CallRecord] {
        showAll ? records : Array(records.prefix(5))
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("CALL LOG")
                        .font(AppTheme.cardTitle)
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Text("\(records.count) CALLS")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textMuted)
                }

                // Call records list
                VStack(spacing: 0) {
                    ForEach(Array(displayedRecords.enumerated()), id: \.element.id) { index, record in
                        if index > 0 {
                            Rectangle()
                                .fill(AppTheme.divider)
                                .frame(height: 1)
                        }

                        HStack(spacing: 10) {
                            // Direction + type icon
                            ZStack {
                                Image(systemName: iconName(for: record))
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(record.answered ? AppTheme.textSecondary : AppTheme.accentRed)
                            }
                            .frame(width: 20)

                            // Direction arrow
                            Image(systemName: record.direction == .outgoing ? "arrow.up.right" : "arrow.down.left")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(record.direction == .outgoing ? AppTheme.textSecondary : AppTheme.textMuted)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(callTypeLabel(record))
                                        .font(AppTheme.caption)
                                        .foregroundStyle(record.answered ? AppTheme.textPrimary : AppTheme.accentRed)

                                    if !record.answered {
                                        Text("MISSED")
                                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                                            .foregroundStyle(AppTheme.accentRed)
                                    }
                                }

                                Text(record.dateFormatted.uppercased())
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(AppTheme.textMuted)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(record.timeFormatted.uppercased())
                                    .font(AppTheme.caption)
                                    .foregroundStyle(AppTheme.textSecondary)

                                if record.answered {
                                    Text(record.durationFormatted)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(AppTheme.textMuted)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                // Show more/less
                if records.count > 5 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAll.toggle()
                        }
                    } label: {
                        Text(showAll ? "SHOW LESS" : "SHOW ALL \(records.count)")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                    }
                }
            }
        }
    }

    private func iconName(for record: CallRecord) -> String {
        switch record.type {
        case .audio: return "phone.fill"
        case .faceTimeVideo: return "video.fill"
        case .faceTimeAudio: return "phone.arrow.up.right.fill"
        }
    }

    private func callTypeLabel(_ record: CallRecord) -> String {
        switch record.type {
        case .audio: return "PHONE"
        case .faceTimeVideo: return "FACETIME VIDEO"
        case .faceTimeAudio: return "FACETIME AUDIO"
        }
    }
}

