# Review Needed: BI_DB_dbo.BI_DB_InstrumentsAlerts

> Sidecar to `BI_DB_InstrumentsAlerts.md`. Items requiring domain expert validation.

---

## SP Authorship — Missing Header
`SP_InstrumentsAlerts` has no author or change history block. This is the only BI_DB_dbo SP reviewed in this batch without attribution. Confirm ownership for escalation purposes.

---

## Data Modeling Concerns

### InstrumentID Mixed Usage
For `FirstAction='Copy'` rows, `InstrumentID` contains `Dim_Customer.RealCID` (a customer ID), not an instrument ID. This breaks the FK relationship with `Dim_Instrument.InstrumentID`. Queries that JOIN on `InstrumentID` must be aware of this mixed usage:
```sql
-- Correct pattern: join only for non-Copy rows
WHERE FirstAction <> 'Copy'
```
Confirm whether downstream consumers of this table handle this correctly.

### Blank Exchange (~17% of rows)
~17% of rows have `Exchange = ''` (blank string, not NULL). Confirm whether this is expected for Copy instruments, Copy Fund, and certain CFD types, or whether it represents missing Dim_Instrument data that should be back-filled.

---

## Business Logic Questions

### Tier=0 for Copy Fund
The SP CASE expression uses `ELSE 0` for Copy Fund rows. This means Copy Fund instruments have Tier=0 (below Tier 1). Confirm that 0 is intentional (a distinct tier, not an error) and that downstream alert thresholds handle Tier=0 correctly.

### Crypto Weekend Calendar
The Crypto pipeline uses all calendar days in its rolling window (no `IsWeekend='N'` filter), while non-Crypto uses weekdays only. Confirm this is the intended comparison baseline — a crypto instrument's `avg7d_past` covers 7 calendar days, while a stock's `avg7d_past` covers 7 business days, making the two incomparable by raw number.

### Rolling Window Boundary NULLs
For newly-onboarded instruments (fewer than 7/14/30 historical rows), `avg7d_past`, `avg14d_past`, `avg30d_past` will be NULL (insufficient lookback). Confirm that downstream alert logic handles NULLs correctly and does not treat them as zero or suppress them.

---

## Not Migrated to UC

Before UC migration:
- `BI_DB_dbo.BI_DB_First5Actions` — confirm UC path for upstream table
- `FULL OUTER JOIN ON 1=1` (Cartesian scaffold pattern) — confirm Databricks SQL supports this pattern in the same way for the rolling window computation

---

*Generated: 2026-04-22 | Batch 27 | Reviewer: pending*
