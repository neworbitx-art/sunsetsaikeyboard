import SwiftUI

struct DraftReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm: PropertyEditorViewModel
    @State private var showingLocationPicker = false
    @State private var showingConfirmDiscard = false
    @State private var showingSaveErrorAlert = false

    let draft: PropertyDraft
    let onSave: (Property) -> Void

    init(draft: PropertyDraft, repository: any PropertyRepository, onSave: @escaping (Property) -> Void) {
        self.draft = draft
        self.onSave = onSave
        let editorVM = PropertyEditorViewModel(repository: repository)
        editorVM.load(from: draft)
        editorVM.seedSuggestedDisplayTitle()
        _vm = State(initialValue: editorVM)
    }

    var body: some View {
        NavigationStack {
            Form {
                confidenceHeaderSection
                PropertyEditorFormSections(vm: vm, draft: draft, onShowLocationPicker: { showingLocationPicker = true })

                if !vm.validationErrors.isEmpty {
                    Section("Errores") {
                        ForEach(vm.validationErrors, id: \.self) { err in
                            Label(err, systemImage: "exclamationmark.circle")
                                .foregroundStyle(.red)
                                .font(.callout)
                        }
                    }
                }
            }
            .navigationTitle("Revisar borrador")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Descartar") { showingConfirmDiscard = true }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Confirmar") { confirmAndSave() }
                        .fontWeight(.semibold)
                        .disabled(vm.isGeneratingCode)
                }
            }
            .confirmationDialog(
                "¿Descartar este borrador?",
                isPresented: $showingConfirmDiscard,
                titleVisibility: .visible
            ) {
                Button("Descartar", role: .destructive) { dismiss() }
                Button("Seguir editando", role: .cancel) {}
            }
            .alert("No se puede guardar", isPresented: $showingSaveErrorAlert) {
                Button("Entendido", role: .cancel) {}
            } message: {
                Text(vm.validationErrors.joined(separator: "\n"))
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(
                    latitude: vm.latitude,
                    longitude: vm.longitude
                ) { lat, lon, address in
                    vm.latitude = lat
                    vm.longitude = lon
                    vm.formattedAddress = address
                    vm.locationSource = .mapPicker
                    if vm.locationSummary.trimmingCharacters(in: .whitespaces).isEmpty {
                        vm.locationSummary = address ?? String(format: "%.5f, %.5f", lat, lon)
                    }
                }
            }
        }
        .task { await vm.prepareForNew() }
        .onChange(of: vm.operationType) { _, _ in
            vm.applySaleFinancingDefaultsIfNeeded()
        }
        .onChange(of: vm.fhaEligibility) { old, _ in
            vm.syncFHAFinancingNote(from: old)
        }
    }

    // MARK: - Confidence legend

    private var confidenceHeaderSection: some View {
        Section {
            confidenceLegend(label: "Alto — detectado con certeza", color: .green)
            confidenceLegend(label: "Medio — revisar y confirmar", color: .yellow)
            confidenceLegend(label: "Bajo — probable; verifique", color: .orange)
            confidenceLegend(label: "Sin detectar — completar manualmente", color: .red)
        } header: {
            Text("Guía de colores")
        } footer: {
            Text("Revise y corrija todos los campos antes de confirmar. Los datos NO se guardan automáticamente.")
                .font(.caption)
        }
    }

    private func confidenceLegend(label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: - Confirm

    private func confirmAndSave() {
        guard let property = vm.buildProperty() else {
            showingSaveErrorAlert = true
            return
        }
        onSave(property)
        dismiss()
    }
}
