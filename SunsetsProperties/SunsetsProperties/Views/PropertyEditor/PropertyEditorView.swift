import SwiftUI

struct PropertyEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm: PropertyEditorViewModel
    @State private var showingLocationPicker = false

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
                identitySection
                statusSection
                priceSection
                locationSection
                spaceSection
                featuresSection
                requirementsSection
                visitSection

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
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(
                    latitude: vm.latitude,
                    longitude: vm.longitude
                ) { lat, lon, address in
                    vm.latitude = lat
                    vm.longitude = lon
                    vm.formattedAddress = address
                    vm.locationSource = .mapPicker
                    if vm.locationSummary.trimmingCharacters(in: .whitespaces).isEmpty,
                       let address {
                        vm.locationSummary = address
                    }
                }
            }
        }
        .task {
            if let p = property {
                vm.load(from: p)
            } else {
                await vm.prepareForNew()
            }
        }
    }

    // MARK: - Identity

    private var identitySection: some View {
        Section("Identificación") {
            if vm.isGeneratingCode {
                HStack {
                    Text("Código")
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                    Text("Generando…")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                }
            } else {
                LabeledContent("Código", value: vm.internalCode.isEmpty ? "—" : vm.internalCode)
                    .accessibilityLabel("Código interno de propiedad")
            }
            TextField("Título *", text: $vm.title)
                .accessibilityLabel("Título de la propiedad")
            Toggle("Favorita", isOn: $vm.isFavorite)
        }
    }

    // MARK: - Status

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

    // MARK: - Price

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

    // MARK: - Location

    private var locationSection: some View {
        Section("Ubicación") {
            TextField("Resumen de ubicación *", text: $vm.locationSummary)
                .accessibilityLabel("Resumen de ubicación")
            TextField("Etiqueta pública (ej. Zona 14)", text: $vm.publicLocationLabelText)
                .accessibilityLabel("Etiqueta de ubicación pública")
            TextField("Colonia / Zona", text: $vm.neighborhood)
            TextField("Ciudad", text: $vm.city)
            TextField("Departamento", text: $vm.state)
            TextField("País", text: $vm.country)

            Button {
                showingLocationPicker = true
            } label: {
                if let lat = vm.latitude, let lon = vm.longitude {
                    HStack {
                        Image(systemName: "mappin.circle")
                            .foregroundStyle(Color.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Coordenadas confirmadas")
                                .foregroundStyle(.primary)
                            Text(String(format: "%.5f, %.5f", lat, lon))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Label("Seleccionar en mapa…", systemImage: "map")
                }
            }

            if vm.latitude != nil {
                Toggle("Compartir ubicación exacta", isOn: $vm.isExactLocationShareable)
            }

            HStack {
                Text("URL Google Maps")
                Spacer()
                TextField("https://maps.google.com/?q=…", text: $vm.googleMapsURLText)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .multilineTextAlignment(.trailing)
                    .font(.caption)
                    .frame(maxWidth: 200)
            }
        }
    }

    // MARK: - Space

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

    // MARK: - Features

    private var featuresSection: some View {
        Section("Características") {
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
            VStack(alignment: .leading, spacing: 4) {
                Text("Artículos incluidos adicionales (uno por línea)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $vm.includedItemsText)
                    .frame(minHeight: 60)
                    .accessibilityLabel("Artículos incluidos")
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Artículos NO incluidos (uno por línea)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $vm.excludedItemsText)
                    .frame(minHeight: 60)
                    .accessibilityLabel("Artículos no incluidos")
            }
            Picker("Política de mascotas", selection: $vm.petPolicy) {
                ForEach(PetPolicy.allCases) { p in
                    Text(p.label).tag(p)
                }
            }
        }
    }

    // MARK: - Requirements

    private var requirementsSection: some View {
        Section("Requisitos") {
            VStack(alignment: .leading, spacing: 4) {
                Text("Uno por línea")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $vm.requirementsText)
                    .frame(minHeight: 80)
                    .accessibilityLabel("Requisitos, uno por línea")
            }
        }
    }

    // MARK: - Visit

    private var visitSection: some View {
        Section("Instrucciones de visita") {
            TextEditor(text: $vm.visitInstructions)
                .frame(minHeight: 80)
                .accessibilityLabel("Instrucciones de visita")
        }
    }

    // MARK: - Save

    private func save() {
        guard let built = vm.buildProperty() else { return }
        onSave(built)
        dismiss()
    }
}
