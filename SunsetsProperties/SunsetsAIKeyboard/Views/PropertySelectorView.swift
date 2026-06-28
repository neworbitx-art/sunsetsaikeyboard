import SwiftUI

struct PropertySelectorView: View {
    let snapshot: KeyboardCatalogSnapshot
    let preferences: KeyboardPreferences
    let onSelect: (KeyboardSafeProperty) -> Void
    let onCancel: () -> Void

    @State private var searchText = ""
    @State private var selectedTab: SelectorTab = .all

    enum SelectorTab: String, CaseIterable, Identifiable {
        case all         = "Todos"
        case available   = "Disponibles"
        case unavailable = "No disponibles"
        case favorites   = "Favoritos"
        case recents     = "Recientes"

        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            tabBar
            Divider()
            if !searchText.isEmpty {
                propertyList(searchFiltered)
            } else {
                propertyList(tabFiltered)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button("Cancelar") { onCancel() }
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()

            TextField("Buscar propiedad…", text: $searchText)
                .font(.callout)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 200)

            Spacer()

            Text("Cancelar")
                .font(.callout)
                .foregroundStyle(.clear)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(SelectorTab.allCases) { tab in
                    let count = tabCount(tab)
                    if count > 0 || tab == .all {
                        Button {
                            selectedTab = tab
                        } label: {
                            HStack(spacing: 4) {
                                Text(tab.rawValue)
                                    .font(.caption.weight(selectedTab == tab ? .semibold : .regular))
                                if count > 0 {
                                    Text("\(count)")
                                        .font(.caption2)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(
                                            selectedTab == tab
                                                ? Color.accentColor.opacity(0.2)
                                                : Color(.tertiarySystemFill)
                                        )
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                selectedTab == tab
                                    ? Color.accentColor.opacity(0.1)
                                    : Color.clear
                            )
                            .foregroundStyle(selectedTab == tab ? Color.accentColor : .secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Filtered lists

    private var searchFiltered: [KeyboardSafeProperty] {
        let query = searchText.lowercased().folding(options: .diacriticInsensitive, locale: .current)
        return snapshot.properties.filter {
            $0.displayTitle.lowercased().folding(options: .diacriticInsensitive, locale: .current).contains(query) ||
            $0.internalCode.lowercased().contains(query) ||
            $0.locationSummary.lowercased().folding(options: .diacriticInsensitive, locale: .current).contains(query)
        }
    }

    private var tabFiltered: [KeyboardSafeProperty] {
        switch selectedTab {
        case .all:
            return snapshot.properties
        case .available:
            return snapshot.properties.filter { $0.isAvailable }
        case .unavailable:
            return snapshot.properties.filter { !$0.isAvailable }
        case .favorites:
            return snapshot.properties.filter { $0.isFavorite }
        case .recents:
            let recentIDs = preferences.recentPropertyIDs
            return recentIDs.compactMap { id in snapshot.properties.first { $0.id == id } }
        }
    }

    private func tabCount(_ tab: SelectorTab) -> Int {
        switch tab {
        case .all:         return snapshot.properties.count
        case .available:   return snapshot.properties.filter { $0.isAvailable }.count
        case .unavailable: return snapshot.properties.filter { !$0.isAvailable }.count
        case .favorites:   return snapshot.properties.filter { $0.isFavorite }.count
        case .recents:
            let ids = preferences.recentPropertyIDs
            return ids.filter { id in snapshot.properties.contains { $0.id == id } }.count
        }
    }

    // MARK: - Property list

    private func propertyList(_ properties: [KeyboardSafeProperty]) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if properties.isEmpty {
                    Text("Sin propiedades")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    ForEach(properties) { property in
                        propertyRow(property)
                        Divider().padding(.leading, 12)
                    }
                }
            }
        }
    }

    // MARK: - Property row

    private func propertyRow(_ property: KeyboardSafeProperty) -> some View {
        Button {
            onSelect(property)
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(property.displayTitle)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text("\(property.internalCode) · \(property.displayLocation)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                statusBadge(property.status)
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Status badge

    private func statusBadge(_ status: String) -> some View {
        Text(statusLabel(status))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor(status).opacity(0.15))
            .foregroundStyle(statusColor(status))
            .clipShape(Capsule())
    }

    private func statusLabel(_ status: String) -> String {
        switch status {
        case "available": return "Disponible"
        case "reserved":  return "Reservada"
        case "rented":    return "Rentada"
        case "sold":      return "Vendida"
        case "inactive":  return "Inactiva"
        default:          return status
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "available": return .green
        case "reserved":  return .orange
        case "rented":    return .blue
        case "sold":      return .purple
        default:          return .gray
        }
    }
}
