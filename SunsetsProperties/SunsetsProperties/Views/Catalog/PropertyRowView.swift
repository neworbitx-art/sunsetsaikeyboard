import SwiftUI

struct PropertyRowView: View {
    let property: Property

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(property.displayTitle.isEmpty ? property.internalCode : property.displayTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer()
                if property.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                        .accessibilityLabel("Favorita")
                }
            }

            HStack(spacing: 4) {
                Text(property.internalCode)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("·")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(property.locationSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 6) {
                StatusBadge(status: property.status)
                OperationBadge(operation: property.operationType)
                Spacer()
                Text(AppFormatters.currency(property.price, code: property.currency))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        "\(property.displayTitle.isEmpty ? property.internalCode : property.displayTitle), \(property.status.label), \(property.operationType.label), \(AppFormatters.currency(property.price, code: property.currency)), \(property.locationSummary)"
    }
}
