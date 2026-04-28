# Compare — `Dealing_dbo.Dealing_CME_Reporting`

**Bucket**: `random`

**Verdict**: **BETTER**  (score delta +4.35; slop 0 -> 0 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 4.3 | 8.65 | 4.35 |
| Slop hits (`Tier 4 ... inferred`) | 0 | 0 | +0 |
| Element rows | 5 | 5 | +0 |
| Untagged count | 5 | 0 | -5 |
| T1 count | 0 | 0 | +0 |
| T2 count | 0 | 5 | +5 |
| T3 count | 0 | 0 | +0 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 7 | 10 |
| completeness | 4 | 8 |
| data_evidence | 5 | 8 |
| shape_fidelity | 6 | 7 |
| tier_accuracy | 3 | 10 |
| upstream_fidelity | 3 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| ``Date`` | 0.0 | None | None | SP-computed via DATEADD from input @Date parameter. Clustered index key. |  |
| ``InstrumentDisplayName`` | 0.0 | None | None | From DWH_dbo.Dim_Instrument.InstrumentDisplayName; CASE normalizes crude oil variants. |  |
| ``CID_Count`` | 0.0 | None | None | COUNT(DISTINCT CID) from DWH_dbo.Dim_Position; valid customers only. |  |
| ``Monthly_Volume`` | 0.0 | None | None | SUM(Volume) + SUM(VolumeOnClose) from DWH_dbo.Dim_Position. |  |
| ``UpdateDate`` | 0.0 | None | None | ETL metadata (blacklist canonical). |  |
| `1` | 0.0 | None | 2 |  | Last calendar day of the reporting month. ETL-computed: @EndOfMonth derived from @Date parameter via DATEADD(MONTH, DATEDIFF(MONTH, 0, @FirstOfMonth), -1). E.g., 2026-03-31 for the March 2026 report.  |
| `2` | 0.0 | None | 2 |  | User-facing instrument display name from Dim_Instrument.InstrumentDisplayName. CASE-transformed: all instruments where LOWER(name) LIKE '%crude oil%' are consolidated into 'Crude Oil Future'; all othe |
| `3` | 0.0 | None | 2 |  | Count of distinct valid customers (IsValidCustomer=1) who opened or closed positions on this instrument during the reporting month. Computed as COUNT(DISTINCT CID) across a UNION ALL of open-side and  |
| `4` | 0.0 | None | 2 |  | Total trading volume for the instrument during the reporting month. Computed as SUM(CAST(Volume AS bigint)) where Volume = Dim_Position.Volume for open-side positions and Dim_Position.VolumeOnClose fo |
| `5` | 0.0 | None | 2 |  | ETL load timestamp. Set to GETDATE() at insert time by SP_M_CME_Reporting. Does NOT reflect a business event date. (Tier 2 -- SP_M_CME_Reporting) |

## Top issues — regen wiki (per judge)

- [low] `Section 4 — Tier Legend` — Tier legend omits star ratings and only lists Tier 2. Golden shape expects multi-tier legend with stars even when only one tier is represented.
- [low] `Footer` — No formal Phase Gate Checklist with P1/P2/P3 checkboxes. Footer says 'Phases: 11/14' without specifying which phases were skipped.
- [low] `InstrumentDisplayName` — 46 distinct values claimed but no representative sample listed. Small enough cardinality to warrant top-10 inline examples.
- [low] `Section 6.1 — References To` — DWH_dbo.Dim_Customer is omitted from the References To table despite being a JOIN dependency for the IsValidCustomer filter in SP_M_CME_Reporting.
- [low] `Section 3.3 — Common JOINs` — Only Dim_Instrument listed. Missing note about joining to date/calendar dimension for monthly trend analysis.
