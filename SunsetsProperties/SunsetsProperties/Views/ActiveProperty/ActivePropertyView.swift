import SwiftUI

struct ActivePropertyView: View {
    @State private var viewModel: ActivePropertyViewModel
    @State private var showingSelector = false
    @State private var showClearConfirmation = false
    @State private var warningProperty: Property?

    init(viewModel: ActivePropertyViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let active = viewModel.activeProperty {
                    activeContent(active)
                } else {
                    emptyContent
                }
            }
            .navigationTitle("Propiedad activa")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cambiar") {
                        showingSelector = true
                    }
                }
            }
            .sheet(isPresented: $showingSelector) {
                PropertySelectorView(
                    properties: viewModel.allProperties,
                    onSelect: { property in
                        handleSelection(property)
                    }
                )
            }
            .confirmationDialog(
                "¿Establecer como propiedad activa?",
                isPresented: .constant(warningProperty != nil),
                titleVisibility: .visible
            ) {
                if let p = warningProperty {
                    Button("Establecer como activa", role: .destructive) {
                        Task { await viewModel.setActive(p) }
                        warningProperty = nil
                    }
                    Button("Cancelar", role: .cancel) { warningProperty = nil }
                }
            } message: {
                if let p = warningProperty {
                    Text("Esta propiedad está \(p.status.label.lowercased()). Se mostrará un aviso en el teclado para no confirmar disponibilidad.")
                }
            }
            .confirmationDialog(
                "¿Quitar propiedad activa?",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Quitar", role: .destructive) {
                    Task { await viewModel.clearActive() }
                }
                Button("Cancelar", role: .cancel) {}
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("Aceptar") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .task { await viewModel.load() }
    }

    private func activeContent(_ property: Property) -> some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(property.displayTitle.isEmpty ? property.internalCode : property.displayTitle)
                                .font(.title2.weight(.bold))
                            Text(property.internalCode)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if property.isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                        }
                    }

                    HStack(spacing: 8) {
                        StatusBadge(status: property.status)
                        OperationBadge(operation: property.operationType)
                    }

                    if property.status.isWarning {
                        Label(
                            "Propiedad no disponible — el teclado mostrará advertencia.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(.orange)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Detalles") {
                LabeledContent("Precio", value: AppFormatters.currency(property.price, code: property.currency))
                LabeledContent("Ubicación", value: property.locationSummary)
                LabeledContent("Última verificación", value: AppFormatters.date(property.lastVerifiedAt))
            }

            Section {
                NavigationLink("Ver detalles completos") {
                    PropertyDetailView(
                        property: property,
                        onEdit: { _ in },
                        onFavoriteToggle: { _ in }
                    )
                }
            }

            Section {
                Button("Cambiar propiedad activa") {
                    showingSelector = true
                }
                Button("Quitar propiedad activa", role: .destructive) {
                    showClearConfirmation = true
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyContent: some View {
        VStack(spacing: 20) {
            EmptyStateView(
                icon: "house.circle",
                title: "Sin propiedad activa",
                message: "Selecciona una propiedad para activarla y usarla en el teclado."
            )
            Button("Seleccionar propiedad") {
                showingSelector = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func handleSelection(_ property: Property) {
        showingSelector = false
        if property.status.isWarning {
            warningProperty = property
        } else {
            Task { await viewModel.setActive(property) }
        }
    }
}

struct PropertySelectorView: View {
    let properties: [Property]
    let onSelect: (Property) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    var filtered: [Property] {
        if search.trimmingCharacters(in: .whitespaces).isEmpty { return properties }
        let q = search.lowercased().folding(options: .diacriticInsensitive, locale: .current)
        return properties.filter {
            $0.displayTitle.lowercased().folding(options: .diacriticInsensitive, locale: .current).contains(q) ||
            $0.internalCode.lowercased().contains(q) ||
            $0.locationSummary.lowercased().folding(options: .diacriticInsensitive, locale: .current).contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { property in
                Button {
                    onSelect(property)
                } label: {
                    PropertyRowView(property: property)
                }
                .foregroundStyle(.primary)
            }
            .listStyle(.insetGrouped)
            .searchable(text: $search, prompt: "Buscar propiedad")
            .navigationTitle("Seleccionar propiedad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}
