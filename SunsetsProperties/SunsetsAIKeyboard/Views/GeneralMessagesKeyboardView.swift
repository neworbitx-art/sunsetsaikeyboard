import SwiftUI

struct GeneralMessagesKeyboardView: View {
    let snapshot: KeyboardCatalogSnapshot
    let onSelectMessage: (KBGeneralMessage) -> Void
    let onBack: () -> Void

    private var groupedMessages: [(category: String, messages: [KBGeneralMessage])] {
        var seen: [String] = []
        var groups: [(String, [KBGeneralMessage])] = []
        for message in snapshot.generalMessages {
            if !seen.contains(message.category) {
                seen.append(message.category)
                groups.append((message.category, []))
            }
            if let idx = groups.firstIndex(where: { $0.0 == message.category }) {
                groups[idx].1.append(message)
            }
        }
        return groups.map { (category: $0.0, messages: $0.1) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if snapshot.generalMessages.isEmpty {
                emptyState
            } else {
                messageList
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Color.accentColor)
            }
            Text("Mensajes generales")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var messageList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(groupedMessages, id: \.category) { group in
                    VStack(alignment: .leading, spacing: 4) {
                        if groupedMessages.count > 1 {
                            Text(categoryLabel(group.category))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.top, 4)
                        }
                        ForEach(group.messages) { message in
                            Button {
                                onSelectMessage(message)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(message.title.isEmpty ? "Sin título" : message.title)
                                            .font(.callout.weight(.medium))
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if message.requiresReviewBeforeInsertion {
                                            Image(systemName: "eye")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Text(message.body)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                .padding(10)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(8)
        }
    }

    private func categoryLabel(_ category: String) -> String {
        switch category {
        case "welcome":              return "Bienvenida"
        case "qualification":        return "Filtro de cliente"
        case "reservationPayment":   return "Pago de reserva"
        case "visitCoordination":    return "Coordinación de visita"
        case "followUp":             return "Seguimiento"
        case "contactInfo":          return "Información de contacto"
        default:                     return "Personalizado"
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.bubble")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Sin mensajes configurados")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Cree mensajes en la app de Sunsets Properties.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
