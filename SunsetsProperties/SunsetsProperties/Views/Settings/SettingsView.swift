import SwiftUI

struct SettingsView: View {
    @State private var selectedEmployee: String = ""
    @State private var isLoaded = false
    private let repository: any PropertyRepository

    init(repository: any PropertyRepository) {
        self.repository = repository
    }

    var body: some View {
        NavigationStack {
            Form {
                employeeSection
                keyboardSetupSection
                aboutSection
            }
            .navigationTitle("Configuración")
        }
        .task {
            guard !isLoaded else { return }
            isLoaded = true
            selectedEmployee = (try? await repository.fetchEmployee()) ?? SeedData.employees[0]
        }
    }

    private var employeeSection: some View {
        Section {
            Picker("Empleado activo", selection: $selectedEmployee) {
                ForEach(SeedData.employees, id: \.self) { name in
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

    private var keyboardSetupSection: some View {
        Section("Teclado SunsetsAI") {
            VStack(alignment: .leading, spacing: 8) {
                Label("Cómo activar el teclado", systemImage: "keyboard")
                    .font(.subheadline.weight(.medium))

                VStack(alignment: .leading, spacing: 6) {
                    stepRow(number: "1", text: "Abre Configuración de iOS.")
                    stepRow(number: "2", text: "Ve a General → Teclado → Teclados.")
                    stepRow(number: "3", text: "Toca «Añadir nuevo teclado».")
                    stepRow(number: "4", text: "Selecciona «SunsetsAIKeyboard».")
                    stepRow(number: "5", text: "Activa «Permitir acceso completo» para que el teclado pueda conectarse al catálogo.")
                }
                .padding(.vertical, 4)

                Text("El teclado no estará disponible hasta que se complete esta configuración.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private var aboutSection: some View {
        Section("Acerca de") {
            LabeledContent("Versión", value: appVersion)
            LabeledContent("Organización", value: "Sunsets Real Estate")
        }
    }

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
