import SwiftUI

// Each sheet opening gets a unique UUID so SwiftUI always creates a fresh PropertyEditorView,
// guaranteeing the @State vm is reset and never carries state from a previous session.
private struct EditorSession: Identifiable {
    let id = UUID()
    let property: Property?
}

struct CatalogView: View {
    @State private var viewModel: CatalogViewModel
    @State private var editorSession: EditorSession? = nil
    @State private var propertyToDelete: Property?
    @State private var showDeleteConfirmation: Bool = false
    @State private var showingImport: Bool = false

    private let repository: any PropertyRepository

    init(viewModel: CatalogViewModel, repository: any PropertyRepository) {
        _viewModel = State(initialValue: viewModel)
        self.repository = repository
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Cargando…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredProperties.isEmpty {
                    emptyState
                } else {
                    propertyList
                }
            }
            .navigationTitle("Propiedades")
            .searchable(text: $viewModel.searchText, prompt: "Buscar por título, código o ubicación")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    filterMenu
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingImport = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .accessibilityLabel("Importar anuncio")

                    Button {
                        editorSession = EditorSession(property: nil)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Agregar propiedad")
                }
            }
            .sheet(item: $editorSession) { session in
                PropertyEditorView(
                    property: session.property,
                    repository: repository,
                    onSave: { property in
                        Task { await viewModel.save(property) }
                    }
                )
            }
            .sheet(isPresented: $showingImport) {
                ListingImportView(repository: repository) { property in
                    Task { await viewModel.save(property) }
                }
            }
            .confirmationDialog(
                "¿Eliminar esta propiedad?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Eliminar", role: .destructive) {
                    if let p = propertyToDelete {
                        Task { await viewModel.delete(p) }
                    }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta acción no se puede deshacer.")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("Aceptar") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .task { await viewModel.load() }
    }

    // MARK: - Subviews

    private var propertyList: some View {
        List {
            ForEach(viewModel.filteredProperties) { property in
                NavigationLink {
                    PropertyDetailView(
                        property: property,
                        onEdit: { p in
                            editorSession = EditorSession(property: p)
                        },
                        onFavoriteToggle: { p in
                            Task { await viewModel.toggleFavorite(p) }
                        }
                    )
                } label: {
                    PropertyRowView(property: property)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        propertyToDelete = property
                        showDeleteConfirmation = true
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                    Button {
                        editorSession = EditorSession(property: property)
                    } label: {
                        Label("Editar", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        Task { await viewModel.toggleFavorite(property) }
                    } label: {
                        Label(
                            property.isFavorite ? "Quitar favorita" : "Favorita",
                            systemImage: property.isFavorite ? "star.slash" : "star"
                        )
                    }
                    .tint(.yellow)
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { await viewModel.load() }
    }

    private var emptyState: some View {
        Group {
            if viewModel.properties.isEmpty {
                EmptyStateView(
                    icon: "building.2",
                    title: "Sin propiedades",
                    message: "Toca el botón + para agregar la primera propiedad al catálogo."
                )
            } else {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "Sin resultados",
                    message: "No se encontraron propiedades con los filtros actuales."
                )
            }
        }
    }

    private var filterMenu: some View {
        Menu {
            ForEach(CatalogFilter.allCases) { filter in
                Button {
                    viewModel.selectedFilter = filter
                } label: {
                    if viewModel.selectedFilter == filter {
                        Label(filter.label, systemImage: "checkmark")
                    } else {
                        Text(filter.label)
                    }
                }
            }
        } label: {
            Label(viewModel.selectedFilter.label, systemImage: "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Filtrar propiedades")
    }
}
