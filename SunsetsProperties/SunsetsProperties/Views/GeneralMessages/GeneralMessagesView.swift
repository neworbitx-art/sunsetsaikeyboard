import SwiftUI

struct GeneralMessagesView: View {

    @State private var vm: GeneralMessagesViewModel
    @State private var showingEditor = false
    @State private var editingTemplate: GeneralMessageTemplate? = nil

    init(vm: GeneralMessagesViewModel) {
        _vm = State(initialValue: vm)
    }

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView("Cargando mensajes…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.templates.isEmpty {
                    emptyState
                } else {
                    templateList
                }
            }
            .navigationTitle("Mensajes generales")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editingTemplate = nil
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor, onDismiss: {
                editingTemplate = nil
            }) {
                GeneralMessageEditorView(
                    template: editingTemplate,
                    onSave: { template in
                        Task { await vm.save(template) }
                    }
                )
            }
            .alert("Error", isPresented: .constant(vm.error != nil)) {
                Button("OK") { }
            } message: {
                Text(vm.error ?? "")
            }
        }
        .task { await vm.load() }
    }

    // MARK: - Template list

    private var templateList: some View {
        List {
            ForEach(vm.templates) { template in
                templateRow(template)
            }
            .onMove { source, destination in
                Task { await vm.reorder(from: source, to: destination) }
            }
            .onDelete { offsets in
                let ids = offsets.map { vm.templates[$0].id }
                Task {
                    for id in ids { await vm.delete(id: id) }
                }
            }
        }
        .environment(\.editMode, .constant(.active))
    }

    private func templateRow(_ template: GeneralMessageTemplate) -> some View {
        Button {
            editingTemplate = template
            showingEditor = true
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(template.title.isEmpty ? "Sin título" : template.title)
                        .font(.headline)
                        .foregroundStyle(template.isEnabled ? .primary : .secondary)
                    Spacer()
                    if template.isKeyboardVisible {
                        Image(systemName: "keyboard")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                HStack(spacing: 8) {
                    Text(GeneralMessageCategory(rawValue: template.category.rawValue)?.label ?? template.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                    if !template.isEnabled {
                        Text("Desactivado")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(template.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.bubble")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Sin mensajes generales")
                .font(.headline)
            Text("Crea mensajes reutilizables como bienvenida, información de contacto y seguimiento.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Crear primer mensaje") {
                editingTemplate = nil
                showingEditor = true
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
