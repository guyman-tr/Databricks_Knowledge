# Compare — `DWH_dbo.Dim_ContractType`

**Bucket**: `slop`

**Verdict**: **EQUIVALENT**  (score delta +0.25; slop 1 -> 0 (delta -1))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 8.2 | 8.45 | 0.25 |
| Slop hits (`Tier 4 ... inferred`) | 1 | 0 | -1 |
| Element rows | 4 | 4 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 3 | 0 | -3 |
| T3 count | 1 | 4 | +3 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 9 |
| completeness | 8 | 8 |
| data_evidence | 7 | 7 |
| shape_fidelity | 9 | 9 |
| tier_accuracy | 9 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `1` | 0.17 | 2 | 3 | Affiliate commission model identifier. Values: 0=N/A (unknown/fallback), 1=CPR (Cost Per Registration), 2=CPA (Cost Per Acquisition), 3=Rev (Revenue Share), 4=Hyb (Hybrid), 5=Other, 6=eCost, 7=ZeroCos | Primary key identifying the affiliate contract type. Integer enum: 0=N/A, 1=CPR, 2=CPA, 3=Rev, 4=Hyb, 5=Other, 6=eCost, 7=ZeroCost, 8=CPL. Referenced by Dim_Affiliate.ContractType. (Tier 3 — DDL + liv |
| `3` | 0.352 | 2 | 3 | Migration load timestamp. All 9 rows are NULL - this column was populated as varchar(50) in the DWH_Migration staging DDL but the values were not carried over (or were NULL in the legacy DWH SQL Serve | Row insertion timestamp. Currently NULL across all 9 rows — never populated by migration or ETL. (Tier 3 — DDL + live data, no upstream wiki) |
| `2` | 0.373 | 3 | 3 | Abbreviated commission model name: N/A, CPR, CPA, Rev, Hyb, Other, eCost, ZeroCost, CPL. Short abbreviations used as display labels in affiliate reporting. No description column exists - analyst refer | Short abbreviation for the contract type. 9 distinct values: N/A, CPR, CPA, Rev, Hyb, Other, eCost, ZeroCost, CPL. Resolved in SP_Marketing_Cube via JOIN to Dim_Affiliate. (Tier 3 — DDL + live data, n |
| `4` | 0.457 | 2 | 3 | Last update timestamp. All 9 rows are NULL - same as InsertDate, no values were populated during migration. Table is effectively static since initial load. (Tier 2 - DWH_Migration.Dim_ContractType DDL | Row last-update timestamp. Currently NULL across all 9 rows — never populated by migration or ETL. (Tier 3 — DDL + live data, no upstream wiki) |

## Top issues — regen wiki (per judge)

- [low] `Section 2.2` — CPR mapping described as → 8 which conflicts with Dim_ContractType ID 1 = CPR. Correctly flagged in review-needed sidecar but could be more prominent in Section 3.4 Gotchas.
- [low] `Footer / Shape` — Phase Gate Checklist not rendered as an explicit section in the wiki body; only referenced as 'Phases: 13/14' in footer.
- [low] `Section 2.2` — SP_Dim_Affiliate CASE logic documented but SP source was not in the upstream bundle — claims are unverifiable from bundle alone.
- [low] `ContractTypeID` — Column is nullable per DDL despite serving as logical PK. Not called out as a gotcha in Section 3.4.
- [low] `Property table` — Production Source marked 'Unknown (dormant)' — honest but leaves a gap. Review-needed sidecar correctly escalates.
