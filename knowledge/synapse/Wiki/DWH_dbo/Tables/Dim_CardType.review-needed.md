# Review Sidecar — DWH_dbo.Dim_CardType

## Unverified Columns (Tier 4)

_None._

## Open Questions

### Structural
1. **Column name typo** — `CarTypeName` is missing the "d". Should this be corrected to `CardTypeName`, or do downstream consumers depend on the current name?
2. **Frozen status** — No active ETL exists. If new card types are needed (e.g., Apple Pay, Google Pay cards), how would they be added?
3. **Amex duplication** — Both "Amex" (ID 4) and "American Express" (ID 7) exist as separate inactive entries. Were these ever used differently?

---

*Generated: 2026-03-18*
