import SwiftUI

// MARK: - Keyboard screen states

enum KeyboardScreen {
    case loading
    case error(String)
    case noProperty(KeyboardCatalogSnapshot)
    case replies(KeyboardCatalogSnapshot, KeyboardSafeProperty)
    case selector(KeyboardCatalogSnapshot)
    case preview(KeyboardCatalogSnapshot, KeyboardSafeProperty, String)
    case generalMessages(KeyboardCatalogSnapshot, KeyboardSafeProperty?)
    case messagePreview(KeyboardCatalogSnapshot, KeyboardSafeProperty?, KBGeneralMessage)
}

// MARK: - Root view

struct KeyboardRootView: View {
    let onInsertText: (String) -> Void
    let onAdvanceToNextKeyboard: () -> Void
    let needsInputModeSwitchKey: Bool
    let reloadTrigger: Int  // incremented by KeyboardViewController on each viewWillAppear

    @State private var screen: KeyboardScreen = .loading
    @State private var isStale = false
    @State private var loadedVersion: Int = -1
    private let reader = CatalogReader()
    private let prefs = KeyboardPreferences()

    var body: some View {
        VStack(spacing: 0) {
            mainContent
            if needsInputModeSwitchKey {
                globeBar
            }
        }
        .background(Color(.systemGroupedBackground))
        .task(id: reloadTrigger) { await loadCatalog() }
    }

    // MARK: - Main content

    @ViewBuilder
    private var mainContent: some View {
        switch screen {
        case .loading:
            loadingView

        case .error(let message):
            errorView(message: message)

        case .noProperty(let snapshot):
            noPropertyView(snapshot: snapshot)

        case .replies(let snapshot, let property):
            repliesView(snapshot: snapshot, property: property)

        case .selector(let snapshot):
            PropertySelectorView(
                snapshot: snapshot,
                preferences: prefs,
                onSelect: { property in
                    prefs.keyboardSelectedPropertyID = property.id
                    prefs.recordRecentSelection(property.id)
                    screen = .replies(snapshot, property)
                },
                onCancel: {
                    // Return to previous valid state
                    if case .selector = screen {
                        let resolvedID = prefs.resolveSelectedPropertyID()
                        let property = resolvedID.flatMap { id in snapshot.properties.first { $0.id == id } }
                        if let property {
                            screen = .replies(snapshot, property)
                        } else {
                            screen = .noProperty(snapshot)
                        }
                    }
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .preview(let snapshot, let property, let text):
            ResponsePreviewView(
                text: text,
                propertyTitle: property.displayTitle,
                onInsert: {
                    onInsertText(text)
                    screen = .replies(snapshot, property)
                },
                onBack: {
                    screen = .replies(snapshot, property)
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .generalMessages(let snapshot, let property):
            GeneralMessagesKeyboardView(
                snapshot: snapshot,
                onSelectMessage: { message in
                    if message.requiresReviewBeforeInsertion {
                        screen = .messagePreview(snapshot, property, message)
                    } else {
                        onInsertText(message.body)
                        if let p = property {
                            screen = .replies(snapshot, p)
                        } else {
                            screen = .noProperty(snapshot)
                        }
                    }
                },
                onBack: {
                    if let p = property {
                        screen = .replies(snapshot, p)
                    } else {
                        screen = .noProperty(snapshot)
                    }
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .messagePreview(let snapshot, let property, let message):
            ResponsePreviewView(
                text: message.body,
                propertyTitle: message.title,
                onInsert: {
                    onInsertText(message.body)
                    if let p = property {
                        screen = .replies(snapshot, p)
                    } else {
                        screen = .noProperty(snapshot)
                    }
                },
                onBack: {
                    screen = .generalMessages(snapshot, property)
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Loading view

    private var loadingView: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("Cargando catálogo…")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error view

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(.orange)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            Button("Reintentar") {
                Task { await loadCatalog() }
            }
            .font(.callout)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - No-property view (Screen A)

    private func noPropertyView(snapshot: KeyboardCatalogSnapshot) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2")
                .font(.title2)
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text("Ninguna propiedad seleccionada")
                    .font(.callout.weight(.medium))
                Text("Seleccione una propiedad para generar respuestas.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Button {
                    screen = .selector(snapshot)
                } label: {
                    Label("Ver propiedades", systemImage: "building.2")
                        .font(.callout.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button {
                    screen = .generalMessages(snapshot, nil)
                } label: {
                    Label("Mensajes generales", systemImage: "text.bubble")
                        .font(.callout.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Replies view (Screen B)

    private func repliesView(snapshot: KeyboardCatalogSnapshot, property: KeyboardSafeProperty) -> some View {
        VStack(spacing: 0) {
            propertyHeader(snapshot: snapshot, property: property)
            if isStale {
                staleWarning
            }
            if property.hasWarning {
                propertyWarning(property: property)
            }
            Divider()
            categoryGrid(snapshot: snapshot, property: property)
        }
    }

    private func propertyHeader(snapshot: KeyboardCatalogSnapshot, property: KeyboardSafeProperty) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text("Sunsets AI")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                    if let name = prefs.employeeName {
                        Text("· \(name)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(property.displayTitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("\(property.internalCode) · \(property.displayLocation)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                screen = .generalMessages(snapshot, property)
            } label: {
                Image(systemName: "text.bubble")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
            }

            Button {
                screen = .selector(snapshot)
            } label: {
                Text("Cambiar")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var staleWarning: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.caption)
            Text("Catálogo desactualizado. Abra Sunsets Properties para actualizar.")
                .font(.caption2)
            Spacer()
        }
        .foregroundStyle(.orange)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.1))
    }

    private func propertyWarning(property: KeyboardSafeProperty) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
            Text("Esta propiedad está \(property.statusLabel.lowercased()). No se generarán confirmaciones de disponibilidad.")
                .font(.caption2)
            Spacer()
        }
        .foregroundStyle(.orange)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.1))
    }

    private func categoryGrid(snapshot: KeyboardCatalogSnapshot, property: KeyboardSafeProperty) -> some View {
        // Use configured menu actions when available; fall back to legacy TemplateEngine list for old snapshots.
        let actions: [(id: String, label: String)]
        if snapshot.menuActions.isEmpty {
            actions = TemplateEngine.applicableCategories(for: property)
        } else {
            actions = snapshot.menuActions
                .filter { action in
                    guard action.isEnabled else { return false }
                    if action.rentOnly { return property.isForRent }
                    if action.saleOnly { return property.isForSale }
                    return true
                }
                .map { ($0.id, $0.label) }
        }

        return ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(actions, id: \.id) { action in
                    Button {
                        let text = generateText(actionID: action.id, property: property, snapshot: snapshot)
                        screen = .preview(snapshot, property, text)
                    } label: {
                        Text(action.label)
                            .font(.callout)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(8)
        }
    }

    private func generateText(actionID: String, property: KeyboardSafeProperty, snapshot: KeyboardCatalogSnapshot) -> String {
        switch actionID {
        case "welcome":
            return snapshot.generalMessages
                .filter { $0.category == "welcome" }
                .sorted { $0.sortOrder < $1.sortOrder }
                .first?.body
                ?? "Configure un mensaje de bienvenida en la sección Mensajes."
        case "qualification":
            return snapshot.generalMessages
                .filter { $0.category == "qualification" }
                .sorted { $0.sortOrder < $1.sortOrder }
                .first?.body
                ?? "Configure un mensaje de filtro de cliente en la sección Mensajes."
        default:
            return TemplateEngine.generate(categoryID: actionID, for: property, employeeName: prefs.employeeName)
        }
    }

    // MARK: - Globe button

    private var globeBar: some View {
        Button(action: onAdvanceToNextKeyboard) {
            HStack(spacing: 4) {
                Image(systemName: "globe")
                    .font(.caption)
                Text("Cambiar teclado")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemGroupedBackground))
        }
    }

    // MARK: - Load catalog

    private func loadCatalog() async {
        do {
            let snapshot = try reader.readSnapshot()
            let stale = reader.isStale(snapshot)

            await MainActor.run {
                isStale = stale

                // Skip full screen rebuild when catalog version is unchanged
                guard loadedVersion != snapshot.catalogVersion else { return }
                loadedVersion = snapshot.catalogVersion

                updateScreen(with: snapshot)
            }
        } catch {
            await MainActor.run {
                // Don't override a working screen with an error (e.g. on a re-check)
                if case .loading = screen {
                    screen = .error(error.localizedDescription)
                }
            }
        }
    }

    @MainActor
    private func updateScreen(with snapshot: KeyboardCatalogSnapshot) {
        switch screen {
        case .loading, .error:
            let resolvedID = prefs.resolveSelectedPropertyID()
            let property = resolvedID.flatMap { id in snapshot.properties.first { $0.id == id } }
            screen = property.map { .replies(snapshot, $0) } ?? .noProperty(snapshot)

        case .noProperty:
            screen = .noProperty(snapshot)

        case .replies(_, let current):
            let refreshed = snapshot.properties.first { $0.id == current.id }
            screen = refreshed.map { .replies(snapshot, $0) } ?? .noProperty(snapshot)

        case .selector:
            screen = .selector(snapshot)

        case .preview(_, let property, let text):
            let refreshed = snapshot.properties.first { $0.id == property.id }
            if let refreshed { screen = .preview(snapshot, refreshed, text) }

        case .generalMessages(_, let property):
            let refreshed = property.flatMap { p in snapshot.properties.first { $0.id == p.id } }
            screen = .generalMessages(snapshot, refreshed)

        case .messagePreview(_, let property, let message):
            let refreshed = property.flatMap { p in snapshot.properties.first { $0.id == p.id } }
            screen = .messagePreview(snapshot, refreshed, message)
        }
    }
}
