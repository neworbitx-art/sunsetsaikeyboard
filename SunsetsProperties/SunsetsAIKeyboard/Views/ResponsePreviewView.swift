import SwiftUI

struct ResponsePreviewView: View {
    let text: String
    let propertyTitle: String
    let onInsert: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            previewContent
            Divider()
            actionBar
        }
        .background(Color(.systemGroupedBackground))
    }

    private var headerBar: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.callout.weight(.medium))
                    Text("Volver")
                        .font(.callout)
                }
            }
            .foregroundStyle(Color.accentColor)

            Spacer()

            Text("Vista previa")
                .font(.callout.weight(.semibold))

            Spacer()

            // Balance spacer
            Text("Volver")
                .font(.callout)
                .foregroundStyle(.clear)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var previewContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Para: \(propertyTitle)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(text)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .padding(12)
        }
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Text("Volver")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button(action: onInsert) {
                Text("Insertar")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
    }
}
