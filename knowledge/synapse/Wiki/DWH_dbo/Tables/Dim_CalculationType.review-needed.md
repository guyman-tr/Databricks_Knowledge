# Review Sidecar — DWH_dbo.Dim_CalculationType

## Unverified Columns (Tier 4)

_None — all columns are Tier 2 (self-evident from data)._

## Open Questions

### Structural
1. **Distribution strategy** — Table uses ROUND_ROBIN distribution despite being a small 8-row dimension. REPLICATE would be more performant for JOINs. Is this intentional?
2. **HistoryCosts source** — The source database (`HistoryCosts`) has no generic pipeline mapping. What is the ingestion mechanism for `DWH_staging.HistoryCosts_Dictionary_CalculationType`?
3. **Consumer coverage** — Which fact tables use CalculationTypeId? Likely cost-related facts in the HistoryCosts domain.

---

*Generated: 2026-03-18*
