import SwiftUI

struct ListingImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm: ListingImportViewModel
    @State private var showingDraftReview = false

    private let repository: any PropertyRepository
    private let onSave: (Property) -> Void

    init(repository: any PropertyRepository, onSave: @escaping (Property) -> Void) {
        self.repository = repository
        self.onSave = onSave
        _vm = State(initialValue: ListingImportViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                pasteArea
                    .padding()

                Divider()

                analyzeButton
                    .padding()

                if case .failed(let msg) = vm.importState {
                    errorBanner(msg)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Importar anuncio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .sheet(isPresented: $showingDraftReview) {
                if let draft = vm.draft {
                    DraftReviewView(
                        draft: draft,
                        repository: repository,
                        onSave: { property in
                            onSave(property)
                            dismiss()
                        }
                    )
                }
            }
            .onChange(of: vm.importState) { _, newState in
                if case .ready = newState { showingDraftReview = true }
            }
        }
    }

    // MARK: - Subviews

    private var pasteArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pega el texto del anuncio")
                .font(.headline)
            Text("Incluye el texto completo del aviso de renta o venta. El analizador detectará precio, ubicación, características y más.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
                    .frame(minHeight: 200)

                if vm.rawText.isEmpty {
                    Text("Pega aquí el anuncio…")
                        .foregroundStyle(.tertiary)
                        .padding(12)
                }

                TextEditor(text: $vm.rawText)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 200)
                    .padding(6)
            }

            if !vm.rawText.isEmpty {
                HStack {
                    Spacer()
                    Button("Limpiar") { vm.reset() }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var analyzeButton: some View {
        Group {
            if case .parsing = vm.importState {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Analizando anuncio…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Button {
                    Task { await vm.parse() }
                } label: {
                    Label("Analizar anuncio", systemImage: "text.magnifyingglass")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!vm.canParse)
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.orange)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
