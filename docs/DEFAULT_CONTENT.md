# Default Content — Sunsets AI

Este archivo documenta el contenido predeterminado que se carga en la aplicación en la primera instalación o al restaurar datos de demostración.

---

## Requisitos de arrendamiento predeterminados (`RENT_DEFAULT_REQUIREMENTS`)

Los siguientes requisitos se aplican como plantilla base para propiedades en renta, salvo que la propiedad especifique condiciones distintas.

- Titular y fiador guatemaltecos
- Ingresos mínimos comprobables equivalentes al doble de la renta
- DPI de titular y fiador
- Antecedentes penales y policíacos del titular
- Antecedentes crediticios de INFORNET del titular y fiador
- Constancia laboral y de ingresos del titular y fiador
- Estados de cuenta de los últimos tres meses del titular y fiador
- Contrato mínimo por un año; el costo del contrato lo paga el inquilino
- Constancia RENAS
- Referencias de arrendadores anteriores, si aplica

---

## Nota de financiamiento para ventas (`SALE_DEFAULT_NOTE`)

Texto predeterminado para propiedades en venta cuando no se cuenta con financiamiento propio del vendedor.

> Permítame comentarle que la propiedad no cuenta con financiamiento propio, pero puede gestionarse un crédito con la entidad financiera de su preferencia. Nosotros le asesoramos y apoyamos sin costo adicional durante todo el proceso.
>
> Los bancos del sistema suelen solicitar que el comprador aporte un enganche del 20% al 30%, y financian el 70% u 80% del valor determinado por el avalúo de la propiedad.

---

## Complemento FHA para ventas (`SALE_FHA_APPEND`)

Texto que se agrega al `SALE_DEFAULT_NOTE` cuando la propiedad tiene elegibilidad FHA confirmada (`fhaEligibility == .eligible`).

> También puede gestionar su crédito bancario con el respaldo del FHA. En este caso, el enganche puede ser desde el 5%.

---

## Uso en código

| Constante | Usado en |
|-----------|----------|
| `RENT_DEFAULT_REQUIREMENTS` | `TemplateEngine` — categoría `.requirements` cuando `property.requirements` está vacío |
| `SALE_DEFAULT_NOTE` | `TemplateEngine` — categoría `.purchaseInfo` cuando `sellerFinancingStatus == .unavailable` o `.unknown` |
| `SALE_FHA_APPEND` | `TemplateEngine` — se concatena al `SALE_DEFAULT_NOTE` cuando `fhaEligibility == .eligible` |

---

## Notas

- Este contenido está en español guatemalteco (`es-GT`), registro profesional neutro.
- No se usa en propiedades con tipo de operación exclusivamente `.rent` para las notas de financiamiento.
- El texto FHA nunca se muestra cuando `fhaEligibility == .notEligible` o `.unknown`.
- Cualquier cambio a este contenido predeterminado debe reflejarse también en `SeedData.swift` y en los tests correspondientes de `TemplateEngine`.
