import SwiftUI

struct GeneralMessageEditorView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var category: GeneralMessageCategory
    @State private var messageBody: String
    @State private var isEnabled: Bool
    @State private var isKeyboardVisible: Bool
    @State private var requiresReviewBeforeInsertion: Bool

    private let original: GeneralMessageTemplate?
    private let onSave: (GeneralMessageTemplate) -> Void

    init(template: GeneralMessageTemplate?, onSave: @escaping (GeneralMessageTemplate) -> Void) {
        self.original = template
        self.onSave = onSave
        let t = template ?? GeneralMessageTemplate.new()
        _title = State(initialValue: t.title)
        _category = State(initialValue: t.category)
        _messageBody = State(initialValue: t.body)
        _isEnabled = State(initialValue: t.isEnabled)
        _isKeyboardVisible = State(initialValue: t.isKeyboardVisible)
        _requiresReviewBeforeInsertion = State(initialValue: t.requiresReviewBeforeInsertion)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Información") {
                    TextField("Título", text: $title)
                    Picker("Categoría", selection: $category) {
                        ForEach(GeneralMessageCategory.allCases) { cat in
                            Text(cat.label).tag(cat)
                        }
                    }
                }

                Section("Mensaje") {
                    TextEditor(text: $messageBody)
                        .frame(minHeight: 120)
                }

                Section("Configuración") {
                    Toggle("Activo", isOn: $isEnabled)
                    Toggle("Visible en teclado", isOn: $isKeyboardVisible)
                    Toggle("Requiere revisión antes de insertar", isOn: $requiresReviewBeforeInsertion)
                }
            }
            .navigationTitle(original == nil ? "Nuevo mensaje" : "Editar mensaje")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveAndDismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty ||
                              messageBody.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveAndDismiss() {
        let now = Date()
        let saved = GeneralMessageTemplate(
            id: original?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespaces),
            category: category,
            body: messageBody.trimmingCharacters(in: .whitespaces),
            isEnabled: isEnabled,
            isKeyboardVisible: isKeyboardVisible,
            requiresReviewBeforeInsertion: requiresReviewBeforeInsertion,
            sortOrder: original?.sortOrder ?? 0,
            createdAt: original?.createdAt ?? now,
            updatedAt: now
        )
        onSave(saved)
        dismiss()
    }
}
