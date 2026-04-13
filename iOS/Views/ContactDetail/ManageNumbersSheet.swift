import SwiftUI

struct ManageNumbersSheet: View {
    let contactId: String
    let contactName: String
    @Binding var identifiers: [ContactIdentifier]
    @Binding var isPresented: Bool

    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        // Current identifiers
                        ForEach(identifiers) { identifier in
                            IdentifierRow(
                                identifier: identifier,
                                onDelete: {
                                    identifiers.removeAll { $0.id == identifier.id }
                                    save()
                                }
                            )
                        }

                        // Add button
                        Button { showAddSheet = true } label: {
                            HStack {
                                Image(systemName: "plus")
                                    .font(.system(size: 14))
                                Text("ADD NUMBER OR IDENTIFIER")
                                    .font(AppTheme.bodyText)
                            }
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                    .strokeBorder(AppTheme.cardBorder, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                            )
                        }

                        // Info text
                        VStack(alignment: .leading, spacing: 6) {
                            Text("WHY LINK MULTIPLE NUMBERS?")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textSecondary)

                            Text("WHEN A CONTACT CHANGES THEIR PHONE NUMBER, ADD THE NEW ONE HERE. ALL MESSAGE AND CALL HISTORY FROM BOTH NUMBERS WILL BE COMBINED INTO ONE ANALYTICS VIEW.")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(AppTheme.textMuted)
                                .lineSpacing(3)
                        }
                        .padding(.top, 12)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("LINKED NUMBERS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("DONE") {
                        save()
                        isPresented = false
                    }
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(AppTheme.textPrimary)
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddIdentifierSheet(onAdd: { newId in
                    identifiers.append(newId)
                    save()
                })
                .presentationDetents([.height(360)])
            }
        }
    }

    private func save() {
        ContactProfile.saveLinkedIdentifiers(identifiers, forContactId: contactId)
    }
}

struct IdentifierRow: View {
    let identifier: ContactIdentifier
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: identifier.icon)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(identifier.value.uppercased())
                    .font(AppTheme.bodyText)
                    .foregroundStyle(AppTheme.textPrimary)

                HStack(spacing: 8) {
                    Text(identifier.type.rawValue.uppercased())
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(AppTheme.textMuted)

                    if let label = identifier.label {
                        Text(label.uppercased())
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(AppTheme.textMuted)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                            )
                    }
                }
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.accentRed.opacity(0.7))
            }
        }
        .padding(12)
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

struct AddIdentifierSheet: View {
    let onAdd: (ContactIdentifier) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var value = ""
    @State private var type: ContactIdentifier.IdentifierType = .phone
    @State private var label = ""

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                Text("ADD IDENTIFIER")
                    .font(AppTheme.cardTitle)
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.top, 20)

                // Type picker
                HStack(spacing: 8) {
                    ForEach([ContactIdentifier.IdentifierType.phone, .email], id: \.rawValue) { t in
                        Button {
                            type = t
                        } label: {
                            Text(t.rawValue.uppercased())
                                .font(AppTheme.caption)
                                .foregroundStyle(type == t ? AppTheme.textPrimary : AppTheme.textMuted)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(AppTheme.cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .strokeBorder(type == t ? AppTheme.accentRed.opacity(0.4) : AppTheme.cardBorder, lineWidth: 1)
                                        )
                                )
                        }
                    }
                }

                // Value input
                TextField("", text: $value, prompt: Text(type == .phone ? "+1 (555) 000-0000" : "EMAIL@EXAMPLE.COM").foregroundStyle(AppTheme.textMuted))
                    .font(AppTheme.bodyText)
                    .foregroundStyle(AppTheme.textPrimary)
                    .keyboardType(type == .phone ? .phonePad : .emailAddress)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                            .fill(AppTheme.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                    .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                            )
                    )

                // Label input
                TextField("", text: $label, prompt: Text("LABEL (OPTIONAL): PERSONAL, WORK, OLD NUMBER").foregroundStyle(AppTheme.textMuted))
                    .font(AppTheme.bodyText)
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                            .fill(AppTheme.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                    .strokeBorder(AppTheme.cardBorder, lineWidth: 1)
                            )
                    )

                // Add button
                Button {
                    guard !value.isEmpty else { return }
                    onAdd(ContactIdentifier(
                        value: value,
                        type: type,
                        label: label.isEmpty ? nil : label,
                        addedDate: Date()
                    ))
                    dismiss()
                } label: {
                    Text("ADD")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                .fill(AppTheme.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                        .strokeBorder(value.isEmpty ? AppTheme.cardBorder : AppTheme.textSecondary, lineWidth: 1)
                                )
                        )
                }
                .disabled(value.isEmpty)

                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }
}

