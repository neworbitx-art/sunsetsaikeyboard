import SwiftUI

struct PropertyEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm: PropertyEditorViewModel
    @State private var showingSaveErrorAlert = false

    let property: Property?
    let onSave: (Property) -> Void

    var isEditing: Bool { property != nil }

    init(property: Property?, repository: any PropertyRepository, onSave: @escaping (Property) -> Void) {
        self.property = property
        self.onSave = onSave
        _vm = State(initialValue: PropertyEditorViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            Form {
                PropertyEditorFormSections(vm: vm)

                if !vm.validationErrors.isEmpty {
                    Section("Errores") {
                        ForEach(vm.validationErrors, id: \.self) { error in
                            Label(error, systemImage: "exclamationmark.circle")
                                .foregroundStyle(.red)
                                .font(.callout)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Editar propiedad" : "Nueva propiedad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") { save() }
                        .fontWeight(.semibold)
                        .disabled(vm.isGeneratingCode)
                }
            }
            .alert("No se puede guardar", isPresented: $showingSaveErrorAlert) {
                Button("Entendido", role: .cancel) {}
            } message: {
                Text(vm.validationErrors.joined(separator: "\n"))
            }
        }
        .task(id: property?.id ?? "new") {
            if let p = property {
                vm.load(from: p)
            } else {
                await vm.prepareForNew()
            }
        }
        .onChange(of: vm.operationType) { _, _ in
            vm.applySaleFinancingDefaultsIfNeeded()
        }
        .onChange(of: vm.fhaEligibility) { old, _ in
            vm.syncFHAFinancingNote(from: old)
        }
    }

    private func save() {
        guard let built = vm.buildProperty() else {
            showingSaveErrorAlert = true
            return
        }
        onSave(built)
        dismiss()
    }
}
