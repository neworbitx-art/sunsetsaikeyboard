import SwiftUI

struct DraftReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm: PropertyEditorViewModel
    @State private var showingConfirmDiscard = false

    let draft: PropertyDraft
    let onSave: (Property) -> Void

    init(draft: PropertyDraft, repository: any PropertyRepository, onSave: @escaping (Property) -> Void) {
        self.draft = draft
        self.onSave = onSave
        let editorVM = PropertyEditorViewModel(repository: repository)
        editorVM.load(from: draft)
        _vm = State(initialValue: editorVM)
    }

    var body: some View {
        NavigationStack {
            Form {
                confidenceHeaderSection

                // Re-use the form sections from the editor but with draft highlighting
                identitySection
                operationSection
                priceSection
                locationSection
                spaceSection
                featuresSection
                visitSection

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
        }
        .task { await vm.prepareForNew() }
    }

    // MARK: - Sections

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

    private var identitySection: some View {
        Section("Identificación") {
            if vm.isGeneratingCode {
                HStack {
                    Text("Código")
                    Spacer()
                    ProgressView().controlSize(.small)
                    Text("Generando…").foregroundStyle(.secondary).font(.callout)
                }
            } else {
                LabeledContent("Código", value: vm.internalCode.isEmpty ? "—" : vm.internalCode)
            }
            draftRow(label: "Título *", field: draft.title) {
                TextField("Título *", text: $vm.title)
            }
        }
    }

    private var operationSection: some View {
        Section("Operación y estado") {
            draftRow(label: "Operación", field: draft.operationType) {
                Picker("Operación *", selection: $vm.operationType) {
                    ForEach(OperationType.allCases) { op in Text(op.label).tag(op) }
                }
                .pickerStyle(.menu)
            }
            draftRow(label: "Estado", field: draft.status) {
                Picker("Estado *", selection: $vm.status) {
                    ForEach(PropertyStatus.allCases) { s in Text(s.label).tag(s) }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var priceSection: some View {
        Section("Precio") {
            draftRow(label: "Precio *", field: draft.price) {
                HStack {
                    Text("Precio *")
                    Spacer()
                    TextField("0.00", text: $vm.priceText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 150)
                }
            }
            draftRow(label: "Moneda", field: draft.currency) {
                HStack {
                    Text("Moneda *")
                    Spacer()
                    TextField("GTQ", text: $vm.currency)
                        .textInputAutocapitalization(.characters)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 80)
                }
            }
            draftRow(label: "Depósito", field: draft.deposit) {
                HStack {
                    Text("Depósito")
                    Spacer()
                    TextField("0.00", text: $vm.depositText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 150)
                }
            }
            draftRow(label: "Mantenimiento", field: draft.maintenanceFee) {
                HStack {
                    Text("Mantenimiento")
                    Spacer()
                    TextField("0.00", text: $vm.maintenanceFeeText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 150)
                }
            }
            draftRow(label: "Mantenimiento incluido", field: draft.maintenanceIncluded) {
                Toggle("Mantenimiento incluido", isOn: $vm.maintenanceIncluded)
            }
        }
    }

    private var locationSection: some View {
        Section("Ubicación") {
            draftRow(label: "Resumen *", field: draft.locationSummary) {
                TextField("Resumen de ubicación *", text: $vm.locationSummary)
            }
        }
    }

    private var spaceSection: some View {
        Section("Inmueble") {
            draftRow(label: "Recámaras", field: draft.bedrooms) {
                HStack {
                    Text("Recámaras")
                    Spacer()
                    TextField("0", text: $vm.bedroomsText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 80)
                }
            }
            draftRow(label: "Baños", field: draft.bathrooms) {
                HStack {
                    Text("Baños")
                    Spacer()
                    TextField("0", text: $vm.bathroomsText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 80)
                }
            }
            draftRow(label: "Parqueos", field: draft.parkingSpaces) {
                HStack {
                    Text("Estacionamientos")
                    Spacer()
                    TextField("0", text: $vm.parkingSpacesText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 80)
                }
            }
            draftRow(label: "Nivel", field: draft.floorNumber) {
                HStack {
                    Text("Nivel / Piso")
                    Spacer()
                    TextField("—", text: $vm.floorNumberText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 80)
                }
            }
        }
    }

    private var featuresSection: some View {
        Section("Características") {
            if draft.amenities.hasValue || !vm.amenitiesText.isEmpty {
                draftRow(label: "Amenidades", field: draft.amenities) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Amenidades (una por línea)").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $vm.amenitiesText).frame(minHeight: 60)
                    }
                }
            }
            if draft.includedAppliances.hasValue || !vm.appliancesText.isEmpty {
                draftRow(label: "Electrodomésticos incl.", field: draft.includedAppliances) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Electrodomésticos incluidos (uno por línea)").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $vm.appliancesText).frame(minHeight: 60)
                    }
                }
            }
            if draft.excludedItems.hasValue || !vm.excludedItemsText.isEmpty {
                draftRow(label: "No incluye", field: draft.excludedItems) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Artículos NO incluidos (uno por línea)").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $vm.excludedItemsText).frame(minHeight: 60)
                    }
                }
            }
        }
    }

    private var visitSection: some View {
        Section("Instrucciones de visita") {
            draftRow(label: "Informes", field: draft.visitInstructions) {
                TextEditor(text: $vm.visitInstructions)
                    .frame(minHeight: 60)
            }
        }
    }

    // MARK: - Draft row wrapper

    private func draftRow<T: Codable & Sendable, Content: View>(
        label: String,
        field: DraftField<T>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Circle()
                    .fill(confidenceColor(field.confidence))
                    .frame(width: 8, height: 8)
                if let warning = field.warning {
                    Text(warning)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            content()
        }
        .padding(.vertical, 2)
    }

    private func confidenceColor(_ c: DraftConfidence) -> Color {
        switch c {
        case .high:    return .green
        case .medium:  return .yellow
        case .low:     return .orange
        case .missing: return .red
        }
    }

    // MARK: - Confirm

    private func confirmAndSave() {
        guard let property = vm.buildProperty() else { return }
        onSave(property)
        dismiss()
    }
}
