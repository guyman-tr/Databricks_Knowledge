# Compare — `Dealing_dbo.Dealing_SaxoRecon_FXnCommed_Trades`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +1.95; slop 20 -> 0 (delta -20))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 7.0 | 8.95 | 1.95 |
| Slop hits (`Tier 4 ... inferred`) | 20 | 0 | -20 |
| Element rows | 0 | 22 | +22 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 0 | 0 | +0 |
| T3 count | 0 | 22 | +22 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 8 | 9 |
| completeness | 4 | 10 |
| data_evidence | 6 | 8 |
| shape_fidelity | 5 | 9 |
| tier_accuracy | 10 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `1` | 0.0 | None | 3 |  | Reconciliation date for this trade comparison row. Clustered index key. Range: 2022-01-02 to 2023-12-05. All 4,226 rows are non-NULL. (Tier 3 — DDL + data sample; no writer SP in SSDT) |
| `2` | 0.0 | None | 3 |  | eToro internal instrument identifier. FK to `DWH_dbo.Dim_Instrument`. 15 distinct values observed (e.g., 40=Platinum, 19=Silver, 18=Gold, 2=GBP/USD, 1=EUR/USD, 7=AUD/USD). 2 NULL rows. (Tier 3 — DDL + |
| `3` | 0.0 | None | 3 |  | Human-readable instrument display name. Values include: Platinum, Silver, Gold, GBP/USD, EUR/USD, AUD/USD, USD/CHF, Natural Gas, Oil, and minor FX pairs. (Tier 3 — DDL + data sample; no writer SP in S |
| `4` | 0.0 | None | 3 |  | International Securities Identification Number. Used as a join key between SAXO and eToro sides. NULL for ~35% of rows (1,468/4,226) — FX currency pairs do not have ISIN codes. (Tier 3 — DDL + data sa |
| `5` | 0.0 | None | 3 |  | Trade direction. Two distinct values: 'Buy' (1,868 rows) and 'Sell' (2,358 rows). Unlike the sibling Stocks recon table, this column uses plain text rather than `[Buy/Sell]` bracket notation. (Tier 3  |
| `6` | 0.0 | None | 3 |  | Dealing desk / hedge server identifier for FX and commodities routing. Three distinct values: 7 (3,235 rows, primary), 8 (932 rows), 23 (59 rows, added Jan 2022). Maps to LP account via Fivetran `Exte |
| `7` | 0.0 | None | 3 |  | Number of units executed by SAXO Bank LP for this instrument/date/side. Represents the liquidity provider's reported trade volume. Can be 0 when SAXO has no corresponding position. (Tier 3 — DDL + dat |
| `8` | 0.0 | None | 3 |  | Number of units from eToro's internal FX/commodities hedge allocation for this instrument/date/side. Represents eToro's view of the hedged volume. Can be 0 when eToro has no corresponding allocation.  |
| `9` | 0.0 | None | 3 |  | Aggregate client-side net traded units for this instrument/date/side. Represents the sum of retail client positions that drive the hedge requirement. (Tier 3 — DDL + data sample + sibling SP pattern;  |
| `10` | 0.0 | None | 3 |  | Unit discrepancy: `SAXO_Units − eToro_Units`. Non-zero values indicate a mismatch between SAXO LP execution and eToro hedge allocation. Special-character column requiring bracket quoting. (Tier 3 — DD |

## Top issues — regen wiki (per judge)

- [medium] `All 22 columns` — 100% Tier 3 — every column description is inferred from DDL + data + sibling SP pattern. No writer SP code or upstream wiki available. Inherent to orphaned status but means all descriptions are unconfirmed.
- [low] `Commission` — Currency is unconfirmed — wiki says 'likely USD given the column context' which is a guess. Review-needed sidecar correctly flags this.
- [low] `Clients_Units, Clients_AmountUSD` — Client-side data source is speculative ('DWH_dbo.Dim_Position or risk matrix — inferred'). The sibling SP's EOD section uses Dealing_Duco_EODRecon but the Trades section may have used a different source.
- [low] `SAXO-eToro_Units, SAXO-Clients_Units, SAXO-eToro_Rate, SAXO-eToro_AmountUSD, SAXO-Clients_AmountUSD` — Differential formulas (e.g., SAXO_Units − eToro_Units) are inferred from sibling SP pattern and data values, not confirmed from actual SP code.
- [low] `Section 8` — Three Atlassian links are tangentially related (general trade reporting, SAXO connectivity, SOD recon) but none is specific to this table. Acknowledged by the writer.
