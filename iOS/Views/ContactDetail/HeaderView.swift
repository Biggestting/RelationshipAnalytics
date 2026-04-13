import SwiftUI

struct HeaderView: View {
    let contact: ContactProfile
    @State private var showManageNumbers = false
    @State private var identifiers: [ContactIdentifier] = []

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(AppTheme.cardBackground)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                    )

                Text(contact.initials)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Text(contact.name.uppercased())
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.textPrimary)

            Text(contact.talkingSinceFormatted.uppercased())
                .font(AppTheme.cardSubtitle)
                .foregroundStyle(AppTheme.textSecondary)

            // Linked numbers display
            if identifiers.count > 0 {
                Button { showManageNumbers = true } label: {
                    VStack(spacing: 4) {
                        ForEach(identifiers.prefix(2)) { identifier in
                            HStack(spacing: 6) {
                                Image(systemName: identifier.icon)
                                    .font(.system(size: 9))
                                    .foregroundStyle(AppTheme.textMuted)

                                Text(identifier.value)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(AppTheme.textSecondary)

                                if let label = identifier.label {
                                    Text(label.uppercased())
                                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                                        .foregroundStyle(AppTheme.textMuted)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 2)
                                                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                                        )
                                }
                            }
                        }

                        if identifiers.count > 2 {
                            Text("+\(identifiers.count - 2) MORE")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(AppTheme.textMuted)
                        }

                        // Badge showing number count
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                                .font(.system(size: 8))
                            Text("\(identifiers.count) LINKED")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                        }
                        .foregroundStyle(AppTheme.textMuted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                        )
                    }
                }
            } else {
                // No numbers — show add button
                Button { showManageNumbers = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 9))
                        Text("ADD NUMBER")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                    }
                    .foregroundStyle(AppTheme.textMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                    )
                }
            }

            Text(contact.talkingDuration.uppercased())
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .onAppear {
            identifiers = ContactProfile.loadLinkedIdentifiers(forContactId: contact.id) ?? contact.identifiers
        }
        .sheet(isPresented: $showManageNumbers) {
            ManageNumbersSheet(
                contactId: contact.id,
                contactName: contact.name,
                identifiers: $identifiers,
                isPresented: $showManageNumbers
            )
        }
    }
}

