import SwiftUI

struct PropertyEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm = PropertyEditorViewModel()
    let property: Property?
    let onSave: (Property) -> Void

    var isEditing: Bool { property != nil }

    var body: some View {
        NavigationStack {
            Form {
                identitySection
                statusSection
                priceSection
                locationSection
                spaceSection
                featuresSection
                requirementsSection
                visitSection

                if !vm.validationErrors.isEmpty {
                    Section {
                        ForEach(vm.validationErrors, id: \.self) { error in
                            Label(error, systemImage: "exclamationmark.circle")
                                .foregroundStyle(.red)
                                .font(.callout)
                        }
                    } header: {
                        Text("Errores")
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
                }
            }
        }
        .onAppear {
            if let p = property { vm.load(from: p) }
        }
    }

    private var identitySection: some View {
        Section("Identificación") {
            TextField("Título *", text: $vm.title)
                .accessibilityLabel("Título de la propiedad")
            TextField("Código interno *", text: $vm.internalCode)
                .textInputAutocapitalization(.characters)
                .accessibilityLabel("Código interno")
            Toggle("Favorita", isOn: $vm.isFavorite)
        }
    }

    private var statusSection: some View {
        Section("Operación y estado") {
            Picker("Operación *", selection: $vm.operationType) {
                ForEach(OperationType.allCases) { op in
                    Text(op.label).tag(op)
                }
            }
            Picker("Estado *", selection: $vm.status) {
                ForEach(PropertyStatus.allCases) { s in
                    Text(s.label).tag(s)
                }
            }
        }
    }

    private var priceSection: some View {
        Section("Precio") {
            HStack {
                Text("Precio *")
                Spacer()
                TextField("0.00", text: $vm.priceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 150)
            }
            HStack {
                Text("Moneda *")
                Spacer()
                TextField("GTQ", text: $vm.currency)
                    .textInputAutocapitalization(.characters)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 80)
            }
            HStack {
                Text("Mantenimiento")
                Spacer()
                TextField("0.00", text: $vm.maintenanceFeeText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 150)
            }
            Toggle("Mantenimiento incluido", isOn: $vm.maintenanceIncluded)
            HStack {
                Text("Depósito")
                Spacer()
                TextField("0.00", text: $vm.depositText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 150)
            }
        }
    }

    private var locationSection: some View {
        Section("Ubicación") {
            TextField("Resumen de ubicación *", text: $vm.locationSummary)
                .accessibilityLabel("Resumen de ubicación")
            TextField("Colonia / Zona", text: $vm.neighborhood)
            TextField("Ciudad", text: $vm.city)
            TextField("Departamento", text: $vm.state)
            TextField("País", text: $vm.country)
        }
    }

    private var spaceSection: some View {
        Section("Inmueble") {
            HStack {
                Text("Recámaras")
                Spacer()
                TextField("0", text: $vm.bedroomsText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 80)
            }
            HStack {
                Text("Baños")
                Spacer()
                TextField("1", text: $vm.bathroomsText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 80)
            }
            HStack {
                Text("Medios baños")
                Spacer()
                TextField("0", text: $vm.halfBathroomsText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 80)
            }
            HStack {
                Text("Estacionamientos")
                Spacer()
                TextField("0", text: $vm.parkingSpacesText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 80)
            }
            HStack {
                Text("Área (m²)")
                Spacer()
                TextField("0", text: $vm.areaText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 100)
            }
        }
    }

    private var featuresSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("Amenidades (una por línea)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $vm.amenitiesText)
                    .frame(minHeight: 80)
                    .accessibilityLabel("Amenidades, una por línea")
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Electrodomésticos incluidos (uno por línea)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $vm.appliancesText)
                    .frame(minHeight: 60)
                    .accessibilityLabel("Electrodomésticos incluidos")
            }
            Picker("Política de mascotas", selection: $vm.petPolicy) {
                ForEach(PetPolicy.allCases) { p in
                    Text(p.label).tag(p)
                }
            }
        } header: {
            Text("Características")
        }
    }

    private var requirementsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("Uno por línea")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $vm.requirementsText)
                    .frame(minHeight: 80)
                    .accessibilityLabel("Requisitos, uno por línea")
            }
        } header: {
            Text("Requisitos")
        }
    }

    private var visitSection: some View {
        Section("Instrucciones de visita") {
            TextEditor(text: $vm.visitInstructions)
                .frame(minHeight: 80)
                .accessibilityLabel("Instrucciones de visita")
        }
    }

    private func save() {
        guard let built = vm.buildProperty() else { return }
        onSave(built)
        dismiss()
    }
}
