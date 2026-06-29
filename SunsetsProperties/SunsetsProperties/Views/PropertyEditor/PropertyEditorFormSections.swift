import SwiftUI

/// Shared editable form sections used by both `PropertyEditorView` (editor mode,
/// `draft == nil`) and `DraftReviewView` (review mode, `draft != nil`).
/// Confidence indicator dots appear only in review mode.
struct PropertyEditorFormSections: View {
    @Bindable var vm: PropertyEditorViewModel
    var draft: PropertyDraft? = nil
    /// Called when the map-picker button is tapped. The parent view owns the
    /// sheet state so it can be attached to the NavigationStack — the safe
    /// presentation host on physical iOS devices.
    var onShowLocationPicker: (() -> Void)? = nil

    private var isReviewMode: Bool { draft != nil }

    var body: some View {
        identitySection
        operationSection
        priceSection
        locationSection
        spaceSection
        featuresSection
        requirementsSection
        if vm.operationType == .sale || vm.operationType == .rentOrSale {
            financingSection
        }
        visitSection
        listingTextSection
        if !isReviewMode {
            publicDescriptionSection
        }
    }

    // MARK: - Confidence helpers

    /// Wraps `content` in a confidence-indicator row when a draft field is
    /// present (review mode). In editor mode the content is rendered as-is.
    @ViewBuilder
    private func confidenceRow<T: Codable & Sendable, Content: View>(
        _ field: DraftField<T>?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if let field {
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
        } else {
            content()
        }
    }

    private func confidenceColor(_ c: DraftConfidence) -> Color {
        switch c {
        case .high:    return .green
        case .medium:  return .yellow
        case .low:     return .orange
        case .missing: return .red
        }
    }

    // MARK: - Identity

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
                    .accessibilityLabel("Código interno de propiedad")
            }
            confidenceRow(draft?.propertyType) {
                Picker("Tipo de propiedad", selection: $vm.propertyType) {
                    ForEach(PropertyType.allCases) { type in
                        Text(type.label).tag(type)
                    }
                }
            }
            confidenceRow(isReviewMode ? DraftField<String>(
                value: vm.displayTitle.isEmpty ? nil : vm.displayTitle,
                confidence: vm.displayTitle.isEmpty ? .missing : .medium,
                warning: vm.displayTitle.isEmpty
                    ? "Ingrese un título para la propiedad."
                    : "Sugerido — edite si es necesario."
            ) : nil) {
                TextField(
                    vm.suggestedDisplayTitle.isEmpty ? "Título del anuncio" : vm.suggestedDisplayTitle,
                    text: $vm.displayTitle
                )
                .accessibilityLabel("Título del anuncio")
            }
            if !isReviewMode {
                Toggle("Favorita", isOn: $vm.isFavorite)
            }
        }
    }

    // MARK: - Operation & Status

    private var operationSection: some View {
        Section("Operación y estado") {
            confidenceRow(draft?.operationType) {
                Picker("Operación *", selection: $vm.operationType) {
                    ForEach(OperationType.allCases) { op in
                        Text(op.label).tag(op)
                    }
                }
            }
            confidenceRow(draft?.status) {
                Picker("Estado *", selection: $vm.status) {
                    ForEach(PropertyStatus.allCases) { s in
                        Text(s.label).tag(s)
                    }
                }
            }
        }
    }

    // MARK: - Price

    private var priceSection: some View {
        Section("Precio") {
            confidenceRow(draft?.price) {
                HStack {
                    Text("Precio *")
                    Spacer()
                    TextField("0.00", text: $vm.priceText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 150)
                }
            }
            confidenceRow(draft?.currency) {
                HStack {
                    Text("Moneda *")
                    Spacer()
                    TextField("GTQ", text: $vm.currency)
                        .textInputAutocapitalization(.characters)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 80)
                }
            }
            confidenceRow(draft?.maintenanceFee) {
                HStack {
                    Text("Mantenimiento")
                    Spacer()
                    TextField("0.00", text: $vm.maintenanceFeeText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 150)
                }
            }
            confidenceRow(draft?.maintenanceIncluded) {
                Toggle("Mantenimiento incluido", isOn: $vm.maintenanceIncluded)
            }
            confidenceRow(draft?.deposit) {
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
    }

    // MARK: - Location

    private var locationSection: some View {
        Section("Ubicación") {
            confidenceRow(draft?.locationSummary) {
                TextField("Resumen de ubicación *", text: $vm.locationSummary)
                    .accessibilityLabel("Resumen de ubicación")
            }
            TextField("Etiqueta pública (ej. Zona 14)", text: $vm.publicLocationLabelText)
                .accessibilityLabel("Etiqueta de ubicación pública")
            TextField("Colonia / Zona", text: $vm.neighborhood)
            TextField("Ciudad", text: $vm.city)
            TextField("Departamento", text: $vm.state)
            TextField("País", text: $vm.country)

            Button {
                onShowLocationPicker?()
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
            HStack {
                Text("URL Waze")
                Spacer()
                TextField("https://waze.com/ul?q=…", text: $vm.wazeURLText)
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
            confidenceRow(draft?.bedrooms) {
                HStack {
                    Text("Recámaras")
                    Spacer()
                    TextField("0", text: $vm.bedroomsText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 80)
                }
            }
            confidenceRow(draft?.bathrooms) {
                HStack {
                    Text("Baños")
                    Spacer()
                    TextField("1", text: $vm.bathroomsText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 80)
                }
            }
            HStack {
                Text("Medios baños")
                Spacer()
                TextField("0", text: $vm.halfBathroomsText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 80)
            }
            confidenceRow(draft?.parkingSpaces) {
                HStack {
                    Text("Estacionamientos")
                    Spacer()
                    TextField("0", text: $vm.parkingSpacesText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 80)
                }
            }
            confidenceRow(draft?.areaSquareMeters) {
                HStack {
                    Text("Área (m²)")
                    Spacer()
                    TextField("0", text: $vm.areaText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 100)
                }
            }
            confidenceRow(draft?.floorNumber) {
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

    // MARK: - Features

    private var featuresSection: some View {
        Section("Características") {
            confidenceRow(draft?.amenities) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Amenidades (una por línea)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $vm.amenitiesText)
                        .frame(minHeight: 80)
                        .accessibilityLabel("Amenidades, una por línea")
                }
            }
            confidenceRow(draft?.includedAppliances) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Electrodomésticos incluidos (uno por línea)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $vm.appliancesText)
                        .frame(minHeight: 60)
                        .accessibilityLabel("Electrodomésticos incluidos")
                }
            }
            confidenceRow(draft?.includedItems) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Artículos incluidos adicionales (uno por línea)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $vm.includedItemsText)
                        .frame(minHeight: 60)
                        .accessibilityLabel("Artículos incluidos")
                }
            }
            confidenceRow(draft?.excludedItems) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Artículos NO incluidos (uno por línea)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $vm.excludedItemsText)
                        .frame(minHeight: 60)
                        .accessibilityLabel("Artículos no incluidos")
                }
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
            confidenceRow(draft?.requirements) {
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
    }

    // MARK: - Financing (sale / rent-or-sale only)

    private var financingSection: some View {
        Section("Financiamiento") {
            confidenceRow(draft?.sellerFinancingStatus) {
                Picker("Financ. del vendedor", selection: $vm.sellerFinancingStatus) {
                    ForEach(SellerFinancingStatus.allCases) { s in
                        Text(s.label).tag(s)
                    }
                }
            }
            Toggle("Asistencia bancaria disponible", isOn: $vm.bankFinancingAssistanceAvailable)
            confidenceRow(draft?.fhaEligibility) {
                Picker("Elegibilidad FHA", selection: $vm.fhaEligibility) {
                    ForEach(FHAEligibility.allCases) { e in
                        Text(e.label).tag(e)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Notas de financiamiento (opcional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $vm.financingNotesText)
                    .frame(minHeight: 60)
                    .accessibilityLabel("Notas de financiamiento")
            }

            // IUSI
            LabeledContent("IUSI (monto)") {
                TextField("Q 0.00", text: $vm.iusiAmountText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            LabeledContent("Frecuencia IUSI") {
                TextField("anual / semestral…", text: $vm.iusiFrequencyText)
                    .multilineTextAlignment(.trailing)
            }
            DatePicker(
                "Verificado el",
                selection: Binding(
                    get: { vm.iusiVerifiedAt ?? Date() },
                    set: { vm.iusiVerifiedAt = $0 }
                ),
                displayedComponents: .date
            )
            if vm.iusiVerifiedAt != nil {
                Button("Quitar fecha de verificación", role: .destructive) {
                    vm.iusiVerifiedAt = nil
                }
                .font(.callout)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Notas IUSI (opcional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $vm.iusiNotesText)
                    .frame(minHeight: 60)
                    .accessibilityLabel("Notas IUSI")
            }
        }
    }

    // MARK: - Visit

    private var visitSection: some View {
        Section("Instrucciones de visita") {
            confidenceRow(draft?.visitInstructions) {
                TextEditor(text: $vm.visitInstructions)
                    .frame(minHeight: 80)
                    .accessibilityLabel("Instrucciones de visita")
            }
        }
    }

    // MARK: - Listing text (both modes)

    private var listingTextSection: some View {
        Section("Texto del anuncio (Información general)") {
            confidenceRow(draft?.publicListingText) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isReviewMode
                         ? "Texto sanitizado del anuncio. Se usará en la respuesta de Información general del teclado."
                         : "Texto sanitizado importado del anuncio. Se usa como cuerpo principal de Información general en el teclado.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $vm.publicListingText)
                        .frame(minHeight: 150)
                        .accessibilityLabel("Texto sanitizado del anuncio")
                }
            }
        }
    }

    // MARK: - Short description (editor only)

    private var publicDescriptionSection: some View {
        Section("Descripción corta (opcional)") {
            TextEditor(text: $vm.publicDescription)
                .frame(minHeight: 80)
                .accessibilityLabel("Descripción corta de la propiedad")
        }
    }
}
