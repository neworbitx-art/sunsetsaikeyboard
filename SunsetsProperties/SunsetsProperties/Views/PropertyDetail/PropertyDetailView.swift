import SwiftUI

struct PropertyDetailView: View {
    let property: Property
    let onEdit: (Property) -> Void
    let onFavoriteToggle: (Property) -> Void

    var body: some View {
        List {
            headerSection
            priceSection
            locationSection
            spaceSection
            featuresSection
            requirementsSection
            metaSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(property.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    onFavoriteToggle(property)
                } label: {
                    Image(systemName: property.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(property.isFavorite ? .yellow : .secondary)
                }
                .accessibilityLabel(property.isFavorite ? "Quitar de favoritas" : "Agregar a favoritas")

                Button("Editar") {
                    onEdit(property)
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        Section {
            LabeledContent("Código", value: property.internalCode)
            LabeledContent("Operación", value: property.operationType.label)
            HStack {
                Text("Estado")
                Spacer()
                StatusBadge(status: property.status)
            }
            if property.status.isWarning {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Esta propiedad no está disponible para confirmaciones de disponibilidad.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var priceSection: some View {
        Section("Precio") {
            LabeledContent("Precio", value: AppFormatters.currency(property.price, code: property.currency))
            if let fee = property.maintenanceFee {
                LabeledContent(
                    "Mantenimiento",
                    value: AppFormatters.currency(fee, code: property.currency) +
                        (property.maintenanceIncluded ? " (incluido)" : "")
                )
            }
            if let deposit = property.deposit {
                LabeledContent("Depósito", value: AppFormatters.currency(deposit, code: property.currency))
            }
        }
    }

    private var locationSection: some View {
        Section("Ubicación") {
            LabeledContent("Resumen", value: property.locationSummary)
            if let label = property.publicLocationLabel {
                LabeledContent("Etiqueta pública", value: label)
            }
            if let n = property.neighborhood { LabeledContent("Colonia / Zona", value: n) }
            if let c = property.city { LabeledContent("Ciudad", value: c) }
            if let s = property.state { LabeledContent("Departamento", value: s) }
            LabeledContent("País", value: property.country)

            if let lat = property.latitude, let lon = property.longitude,
               property.isExactLocationShareable {
                LabeledContent("Coordenadas",
                               value: String(format: "%.5f, %.5f", lat, lon))
            }
            if let mapsURL = property.googleMapsURL,
               let url = URL(string: mapsURL) {
                Link(destination: url) {
                    Label("Abrir en Google Maps", systemImage: "map")
                }
            }
        }
    }

    private var spaceSection: some View {
        Section("Inmueble") {
            LabeledContent("Recámaras", value: "\(property.bedrooms)")
            LabeledContent("Baños", value: AppFormatters.bathrooms(property.bathrooms))
            if let half = property.halfBathrooms {
                LabeledContent("Medios baños", value: "\(half)")
            }
            LabeledContent("Estacionamientos", value: "\(property.parkingSpaces)")
            LabeledContent("Área", value: AppFormatters.area(property.areaSquareMeters))
            if let floor = property.floorNumber {
                LabeledContent("Nivel", value: "\(floor)")
            }
        }
    }

    private var featuresSection: some View {
        Group {
            if !property.amenities.isEmpty {
                Section("Amenidades") {
                    ForEach(property.amenities, id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle")
                    }
                }
            }
            if !property.includedAppliances.isEmpty {
                Section("Electrodomésticos incluidos") {
                    ForEach(property.includedAppliances, id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle")
                    }
                }
            }
            if !property.includedItems.isEmpty {
                Section("Artículos incluidos") {
                    ForEach(property.includedItems, id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle")
                    }
                }
            }
            if !property.excludedItems.isEmpty {
                Section("No incluye") {
                    ForEach(property.excludedItems, id: \.self) { item in
                        Label(item, systemImage: "xmark.circle")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Section("Mascotas") {
                Text(property.petPolicy.label)
            }
            if let instructions = property.visitInstructions {
                Section("Instrucciones de visita") {
                    Text(instructions)
                }
            }
        }
    }

    private var requirementsSection: some View {
        Group {
            if !property.requirements.isEmpty {
                Section("Requisitos") {
                    ForEach(property.requirements, id: \.self) { req in
                        Label(req, systemImage: "doc.text")
                    }
                }
            }
        }
    }

    private var metaSection: some View {
        Section("Información") {
            LabeledContent("Última verificación", value: AppFormatters.date(property.lastVerifiedAt))
            LabeledContent("Actualizado", value: AppFormatters.date(property.updatedAt))
            LabeledContent("Creado", value: AppFormatters.date(property.createdAt))
        }
    }
}
