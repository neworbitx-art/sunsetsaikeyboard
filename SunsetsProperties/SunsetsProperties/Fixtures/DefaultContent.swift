import Foundation

enum DefaultContent {

    // Rental requirements template (from docs/DEFAULT_CONTENT.md).
    // Applied to new and imported rent properties only when requirements is empty.
    static let rentRequirements: [String] = [
        "Titular y fiador guatemaltecos",
        "Ingresos mínimos comprobables equivalentes al doble de la renta",
        "DPI de titular y fiador",
        "Antecedentes penales y policíacos del titular",
        "Antecedentes crediticios de INFORNET del titular y fiador",
        "Constancia laboral y de ingresos del titular y fiador",
        "Estados de cuenta de los últimos tres meses del titular y fiador",
        "Contrato mínimo por un año; el costo del contrato lo paga el inquilino",
        "Constancia RENAS",
        "Referencias de arrendadores anteriores, si aplica"
    ]

    // Base financing note for sale properties (from docs/DEFAULT_CONTENT.md).
    // Applied when financingNotesText is empty; seller financing is set to unavailable.
    static let saleDefaultNote: String =
        "Permítame comentarle que la propiedad no cuenta con financiamiento propio, pero puede gestionarse un crédito con la entidad financiera de su preferencia. Nosotros le asesoramos y apoyamos sin costo adicional durante todo el proceso.\n\nLos bancos del sistema suelen solicitar que el comprador aporte un enganche del 20% al 30%, y financian el 70% u 80% del valor determinado por el avalúo de la propiedad."

    // FHA paragraph appended to saleDefaultNote when fhaEligibility == .eligible.
    // Removed (and only this paragraph) when eligibility later changes to ineligible.
    static let saleDefaultNoteFHAAppend: String =
        "También puede gestionar su crédito bancario con el respaldo del FHA. En este caso, el enganche puede ser desde el 5%."
}
