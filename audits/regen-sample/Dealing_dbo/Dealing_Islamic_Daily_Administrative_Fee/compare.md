# Compare — `Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee`

**Bucket**: `good`

**Verdict**: **BETTER**  (score delta +5.1; slop 0 -> 0 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 4.2 | 9.3 | 5.1 |
| Slop hits (`Tier 4 ... inferred`) | 0 | 0 | +0 |
| Element rows | 0 | 42 | +42 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 23 | +23 |
| T2 count | 0 | 19 | +19 |
| T3 count | 0 | 0 | +0 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 7 | 10 |
| completeness | 4 | 10 |
| data_evidence | 7 | 7 |
| shape_fidelity | 5 | 8 |
| tier_accuracy | 3 | 10 |
| upstream_fidelity | 2 | 9 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `1` | 0.0 | None | 2 |  | The fee calculation date — the @Date input parameter to SP_Islamic_Administrative_Fee. One row per position per date. (Tier 2 — SP_Islamic_Administrative_Fee) |
| `2` | 0.0 | None | 2 |  | Integer representation of Date in YYYYMMDD format. ETL-computed: CAST(CONVERT(VARCHAR(8), @Date, 112) AS INT). (Tier 2 — SP_Islamic_Administrative_Fee) |
| `3` | 0.0 | None | 1 |  | Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. Passthrough from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| `4` | 0.0 | None | 1 |  | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer. (Tier 1 — Cus |
| `5` | 0.0 | None | 1 |  | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. Passthrough from Dim_Customer. (Tier 1 — Cus |
| `6` | 0.0 | None | 1 |  | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| `7` | 0.0 | None | 1 |  | ETL-computed date int (YYYYMMDD) derived from OpenOccurred. E.g., 20260310. Used for date-range filtering. NOT a FK to Dim_Date by default. Passthrough from Dim_Position. (Tier 1 — Dim_Position) |
| `8` | 0.0 | None | 1 |  | ETL-computed date int (YYYYMMDD) derived from CloseOccurred. 0=still open, 19000101=ETL transient state, YYYYMMDD=closed. **Partition column.** Always include in WHERE clause. Passthrough from Dim_Pos |
| `9` | 0.0 | None | 1 |  | When position was persisted (mapped from Occurred in production). Default getutcdate(). Passthrough from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| `10` | 0.0 | None | 2 |  | Adjusted open date for fee calculation: if position opened after 22:00 GMT, shifted to the next calendar day; otherwise same as OpenOccurred date. (Tier 2 — SP_Islamic_Administrative_Fee) |

## Top issues — regen wiki (per judge)

- [medium] `NewCloseOccurred (#12)` — Tagged Tier 2 (SP_Islamic_Administrative_Fee) but SP code shows `dp.CloseOccurred AS NewCloseOccurred` — a literal alias passthrough from Dim_Position. With Dim_Position wiki available, this should be Tier 1 — Trade.PositionTbl. The description itself acknowledges 'Currently identical to CloseOccurred (no transformation applied).'
- [medium] `IsSettled (#26)` — Tagged Tier 2 (SP_Islamic_Administrative_Fee) but SP code shows `dp.IsSettled` — direct passthrough from Dim_Position. Upstream wiki exists and documents this column (as Tier 5 — Expert Review). Per tier rules, passthrough with upstream wiki present should be Tier 1, not Tier 2.
- [low] `OpenDateID (#7), CloseDateID (#8)` — Tagged 'Tier 1 — Dim_Position' but the dim-lookup passthrough rule says NOT to use 'Tier 1 via Dim_X'. These are ETL-computed in Dim_Position (Tier 2 in the upstream wiki). The origin attribution is inconsistent with other columns that correctly trace to production origins (e.g., Trade.PositionTbl).
- [low] `Section 8 / Footer` — No explicit Phase Gate Checklist with P2/P3 checkboxes. Footer shows 'Phases: 11/14' but there is no way to verify which phases were completed or skipped. Data claims appear genuine but lack formal verification.
- [low] `InstrumentTypeID (#14) — Group C` — Placed in 'Group C: Fee Timing' but InstrumentTypeID is an instrument attribute (asset class identifier), not a fee timing column. Should logically be in 'Group D: Instrument Details' alongside InstrumentType, InstrumentName, etc.
