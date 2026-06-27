import SwiftUI

struct StatusBadge: View {
    let status: PropertyStatus

    var body: some View {
        Text(status.label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch status {
        case .available: return .green
        case .reserved:  return .orange
        case .rented:    return .blue
        case .sold:      return .purple
        case .inactive:  return .secondary
        }
    }
}

struct OperationBadge: View {
    let operation: OperationType

    var body: some View {
        Text(operation.label)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.accentColor.opacity(0.12))
            .foregroundStyle(Color.accentColor)
            .clipShape(Capsule())
    }
}
