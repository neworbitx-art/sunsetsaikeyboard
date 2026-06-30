import SwiftUI

struct SettingsView: View {
    @State private var selectedEmployee: String = ""
    @State private var isLoaded = false
    @State private var isPublishing = false
    @State private var showClearConfirmation = false

    private let repository: any PropertyRepository
    private let cacheService: CatalogCacheService
    private let maintenanceService: StorageMaintenanceService
    private let menuPreferences: KeyboardMenuPreferencesService

    init(
        repository: any PropertyRepository,
        cacheService: CatalogCacheService,
        maintenanceService: StorageMaintenanceService,
        menuPreferences: KeyboardMenuPreferencesService
    ) {
        self.repository = repository
        self.cacheService = cacheService
        self.maintenanceService = maintenanceService
        self.menuPreferences = menuPreferences
    }

    var body: some View {
        NavigationStack {
            Form {
                employeeSection
                keyboardMenuSection
                catalogSyncSection
                keyboardSetupSection
                dataManagementSection
                aboutSection
            }
            .navigationTitle("Configuración")
        }
        .task {
            guard !isLoaded else { return }
            isLoaded = true
            selectedEmployee = (try? await repository.fetchEmployee()) ?? EmployeeDirectory.all[0]
        }
        .confirmationDialog(
            "¿Borrar todos los datos locales?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Borrar todo", role: .destructive) {
                Task { await performClearAll() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta acción elimina el catálogo de propiedades, el caché del teclado y todas las preferencias locales. No se puede deshacer.")
        }
    }

    // MARK: - Employee section

    private var employeeSection: some View {
        Section {
            Picker("Empleado activo", selection: $selectedEmployee) {
                ForEach(EmployeeDirectory.all, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
            .onChange(of: selectedEmployee) { _, newValue in
                Task { try? await repository.setEmployee(newValue) }
            }
        } header: {
            Text("Identidad")
        } footer: {
            Text("Solo para uso interno. La autenticación real estará disponible en una versión futura.")
        }
    }

    // MARK: - Keyboard menu section

    private var keyboardMenuSection: some View {
        Section {
            ForEach(Array(menuPreferences.actions.enumerated()), id: \.element.id) { index, action in
                Toggle(isOn: Binding(
                    get: { menuPreferences.actions[index].isEnabled },
                    set: { enabled in
                        menuPreferences.actions[index].isEnabled = enabled
                        menuPreferences.save()
                        Task { await cacheService.publish(repository: repository) }
                    }
                )) {
                    HStack {
                        Text(action.label)
                        Spacer()
                        if action.rentOnly {
                            Text("Renta")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.12))
                                .clipShape(Capsule())
                        } else if action.saleOnly {
                            Text("Venta")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        } header: {
            Text("Menú del teclado")
        } footer: {
            Text("Selecciona las acciones visibles en el menú del teclado. Los cambios se publican automáticamente.")
        }
    }

    // MARK: - Catalog sync section

    private var catalogSyncSection: some View {
        Section {
            if let error = cacheService.lastError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.callout)
            }

            LabeledContent("Última actualización") {
                if let date = cacheService.lastPublishedAt {
                    Text(AppFormatters.date(date))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Nunca")
                        .foregroundStyle(.secondary)
                }
            }

            LabeledContent("Versión del catálogo", value: "\(cacheService.catalogVersion)")
            LabeledContent("Tamaño del caché", value: cacheService.formattedCacheSize)
            LabeledContent("App Group", value: cacheService.appGroupAvailable ? "Disponible" : "No disponible")

            // Property diagnostics
            LabeledContent("Total de propiedades", value: "\(cacheService.totalPropertyCount)")
            LabeledContent("Publicadas en teclado") {
                Text("\(cacheService.publishedPropertyCount)")
                    .foregroundStyle(.secondary)
            }
            if cacheService.excludedPropertyCount > 0 {
                LabeledContent("Excluidas (sin código)") {
                    Text("\(cacheService.excludedPropertyCount)")
                        .foregroundStyle(.orange)
                }
            }
            if !cacheService.publishedInternalCodes.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Códigos publicados")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(cacheService.publishedInternalCodes.sorted().joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }

            // Message diagnostics
            LabeledContent("Total de mensajes generales", value: "\(cacheService.totalMessageCount)")
            LabeledContent("Mensajes publicados en teclado") {
                Text("\(cacheService.publishedMessageCount)")
                    .foregroundStyle(.secondary)
            }

            Button {
                Task { await publishCatalog() }
            } label: {
                if isPublishing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Actualizando…")
                    }
                } else {
                    Text("Actualizar catálogo del teclado")
                }
            }
            .disabled(isPublishing)

        } header: {
            Text("Teclado SunsetsAI — Catálogo")
        } footer: {
            Text("El catálogo se actualiza automáticamente al guardar, eliminar o cambiar el estado de una propiedad. Use esta acción para forzar una actualización manual.")
        }
    }

    // MARK: - Keyboard setup section

    private var keyboardSetupSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label("Cómo activar el teclado", systemImage: "keyboard")
                    .font(.subheadline.weight(.medium))

                VStack(alignment: .leading, spacing: 8) {
                    stepRow(number: "1", text: "Abre Configuración de iOS.")
                    stepRow(number: "2", text: "Ve a General → Teclado → Teclados.")
                    stepRow(number: "3", text: "Toca «Añadir nuevo teclado».")
                    stepRow(number: "4", text: "Selecciona «SunsetsAIKeyboard».")
                    stepRow(number: "5", text: "Activa «Permitir acceso completo» para que el teclado pueda leer el catálogo.")
                    stepRow(number: "6", text: "Abre un campo de texto (por ejemplo, en Messenger o WhatsApp).")
                    stepRow(number: "7", text: "Usa el botón del globo terrestre (🌐) para cambiar al teclado Sunsets.")
                }
                .padding(.vertical, 4)

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Label("Importante", systemImage: "info.circle")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text("• El teclado no puede leer la conversación abierta.")
                    Text("• Debe seleccionar manualmente la propiedad correcta.")
                    Text("• Las respuestas generadas deben revisarse y enviarse manualmente.")
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Instrucciones de configuración")
        }
    }

    // MARK: - Data management section

    private var dataManagementSection: some View {
        Section {
            LabeledContent("Catálogo principal", value: maintenanceService.formattedMainCatalogSize)
            LabeledContent("Respaldo de migración", value: maintenanceService.formattedBackupSize)

            Button("Borrar todos los datos locales", role: .destructive) {
                showClearConfirmation = true
            }
        } header: {
            Text("Administración de datos")
        } footer: {
            Text("Al borrar los datos locales se elimina el catálogo, el caché del teclado y todas las preferencias. Los datos en la nube (cuando estén disponibles) no se verán afectados.")
        }
    }

    // MARK: - About section

    private var aboutSection: some View {
        Section("Acerca de") {
            LabeledContent("Versión", value: appVersion)
            LabeledContent("Organización", value: "Sunsets Real Estate")
        }
    }

    // MARK: - Actions

    private func publishCatalog() async {
        isPublishing = true
        defer { isPublishing = false }
        await cacheService.publish(repository: repository)
    }

    private func performClearAll() async {
        try? await maintenanceService.clearAllLocalData()
        selectedEmployee = ""
    }

    // MARK: - Helpers

    private func stepRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption.weight(.bold))
                .frame(width: 20, height: 20)
                .background(Color.accentColor.opacity(0.15))
                .clipShape(Circle())
                .foregroundStyle(Color.accentColor)
            Text(text)
                .font(.callout)
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
