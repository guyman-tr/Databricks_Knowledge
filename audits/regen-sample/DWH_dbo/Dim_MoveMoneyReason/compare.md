# Compare — `DWH_dbo.Dim_MoveMoneyReason`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +1.5; slop 1 -> 0 (delta -1))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 7.05 | 8.55 | 1.5 |
| Slop hits (`Tier 4 ... inferred`) | 1 | 0 | -1 |
| Element rows | 3 | 3 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 2 | 2 | +0 |
| T2 count | 0 | 1 | +1 |
| T3 count | 1 | 0 | -1 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 9 |
| completeness | 10 | 8 |
| data_evidence | 7 | 5 |
| shape_fidelity | 9 | 7 |
| tier_accuracy | 6 | 10 |
| upstream_fidelity | 3 | 10 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `1` | 0.19 | 1 | 1 | Internal money movement reason identifier. DWH values: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 4=Airdrop (DWH-only label). Production has additional IDs 5=InternalTransfer Trade, 6=InternalTransfer,  | Unique identifier for the money movement reason: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 5=InternalTransfer Trade, 6=InternalTransfer, 7=Not In Use, 8=Recurring Deposit, 9=Recurring Investment. Gap a |
| `2` | 0.239 | 1 | 1 | Human-readable money movement reason label. DWH labels: Adjustment, Bonus Abuser, Staking, Airdrop. Column name intentionally matches table name (denormalized pattern per upstream wiki). Used in finan | Human-readable reason label. Note: column name matches table name (denormalized pattern). Displayed in account statements, credit history, and BackOffice audit screens. (Tier 1 — Dictionary.MoveMoneyR |
| `3` | 0.437 | 3 | 2 | Last update timestamp for the row. IDs 1-3: 2022-03-27 (initial load batch); ID 4: 2022-11-13 (added 8 months later). Suggests manual DBA inserts; not populated by an automated pipeline. Not present i | ETL-added timestamp recording when each row was last loaded or refreshed by the generic dictionary pipeline. Not present in the production source table. (Tier 2 — Generic Pipeline ETL) |

## Top issues — regen wiki (per judge)

- [medium] `Footer` — Missing phases-completed list in footer. Golden shape expects explicit P1/P2/P3 completion indicators.
- [low] `Section 1` — No explicit min/max date range for UpdateDate. States '2022' generically instead of precise range.
- [low] `Section 2.1` — Lists '4 = Airdrop' as DWH value while Element description (correctly verbatim from upstream) says 'Gap at ID 4'. The tension is explained in Section 2.2 but could be clearer in 2.1.
- [low] `Section 4 — MoveMoneyReasonID` — Production source has NOT NULL constraint on MoveMoneyReasonID but DWH DDL is NULL. Element correctly shows YES but a note about the nullability difference would help analysts.
