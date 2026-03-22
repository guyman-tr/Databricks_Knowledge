# Dealing_dbo.Dealing_ApexRecon_Hedging

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_ApexRecon_Hedging |
| **Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on `Date` |
| **Columns** | 10 |
| **Primary Source** | `Dealing_dbo.Dealing_ApexRecon_Holdings` (same-day and previous-day) |
| **ETL SP** | `Dealing_dbo.SP_Apex_Recon` (same SP as Holdings) |
| **Refresh** | Daily per @Date (delete+insert) |
| **PII** | None — instrument-level only |
| **Tags** | dealing, apex, reconciliation, hedging, over-hedge, under-hedge, real-stocks |

---

## 1. Business Meaning

`Dealing_ApexRecon_Hedging` is a **daily hedging discrepancy report** derived from `Dealing_ApexRecon_Holdings`. It flags instruments where eToro's hedge position at Apex (Apex_Units) significantly deviates from the client net open position (Client_NOP_Units), indicating over-hedging or under-hedging.

**Over-hedged** (`Over_Under = 'Over'`): Apex holds more shares than clients need — eToro is carrying excess hedge. Threshold: `Apex_Units - Client_NOP_Units ≥ 1` AND dollar value of excess ≥ $50,000.

**Under-hedged** (`Over_Under = 'Under'`): Apex holds fewer shares than clients need — eToro has unhedged client exposure. Threshold: `Apex_Units - Client_NOP_Units ≤ -1` AND dollar value ≤ -$5,000 AND total portfolio under-hedge exposure < -$100,000.

**HedgingDiff** (`'Yes'/'No'`): Compares today's hedging gap to yesterday's. `'Yes'` = gap unchanged (no trades corrected it); `'No'` = gap changed. NULL when not flagged. Used to track whether a hedging error is persistent.

**DiffFromPreviousDay**: The hedging gap from the previous trading day (PreviousDay.Apex_Units - PreviousDay.Client_NOP_Units), used to compute HedgingDiff.

**SP Author**: Sarah Benchitrit (2021-03-07); same SP as Holdings.

---

## 2. Business Logic

### ETL Pattern — Daily Delete + Insert per Date

Within `SP_Apex_Recon(@Date)` — Hedging section (runs after Holdings INSERT):

1. **`#PreviousDay`**: Reads `Dealing_ApexRecon_Holdings` for the previous trading day (`@PreviousDay` = @Date-1 skipping weekends). Computes `DiffFromPreviousDay = ISNULL(Apex_Units,0) - ISNULL(Client_NOP_Units,0)` per Symbol×HedgeServer×AccountNumber.

2. **`#Over_Under`**: Reads today's `Dealing_ApexRecon_Holdings` (just inserted). Computes `DiffFromToday = Apex_Units - Client_NOP_Units` and applies thresholds:
   - `'Over'`: diff ≥ 1 AND `(Etoro_Amount/Etoro_Units) × diff ≥ 50,000`
   - `'Under'`: diff ≤ -1 AND `(Etoro_Amount/Etoro_Units) × diff ≤ -5,000` AND portfolio-level total under-position < -$100,000

3. **INSERT**: LEFT JOINs `#Over_Under` to `#PreviousDay` on Symbol×HedgeServer. Computes:
   - `HedgingDiff = CASE WHEN PreviousDay.diff - Today.diff = 0 THEN 'Yes' ELSE 'No' END` (only when Over_Under is set)

---

## 3. Relationships

| Related Table | Join Key | Relationship |
|---------------|----------|--------------|
| `Dealing_dbo.Dealing_ApexRecon_Holdings` | `Date, Symbol, HedgeServerID` | Source for today's and previous day's hedging gap |
| `Dealing_staging.External_Fivetran_dealing_active_hs_mappings` | `hs_dealing_desk, lp_accounts` | HS↔LP account mapping (for AccountNumber in #PreviousDay) |
| `Dealing_dbo.Dealing_ApexRecon_TradeActivity` | `Date, InstrumentID` | Related trade-level recon (same SP) |

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — SP_Apex_Recon)` |
| ★★ | Tier 3 — live data / structure | `(Tier 3 — live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Reporting date. Clustered index key. (Tier 2 — SP_Apex_Recon) |
| 2 | Symbol | varchar(20) | YES | Apex ticker symbol (e.g., 'HROW', 'MLI'). From Dealing_ApexRecon_Holdings. (Tier 2 — SP_Apex_Recon) |
| 3 | InstrumentID | int | YES | Instrument identifier. FK to DWH_dbo.Dim_Instrument. (Tier 2 — SP_Apex_Recon) |
| 4 | InstrumentDisplayName | varchar(100) | YES | User-facing instrument name. (Tier 2 — SP_Apex_Recon) |
| 5 | ISINCode | varchar(50) | YES | ISIN from Holdings table. (Tier 2 — SP_Apex_Recon) |
| 6 | HedgeServerID | int | YES | HS identifier. See Dealing_ApexRecon_Holdings for classification. (Tier 2 — SP_Apex_Recon) |
| 7 | Over_Under | varchar(20) | YES | `'Over'` = eToro over-hedged (Apex holds excess shares, diff ≥ +1 with value ≥ $50K). `'Under'` = eToro under-hedged (Apex holds fewer shares than needed, diff ≤ -1 with value ≤ -$5K, portfolio under < -$100K). NULL = no significant hedging discrepancy. (Tier 2 — SP_Apex_Recon) |
| 8 | DiffFromPreviousDay | decimal(16,6) | YES | Previous trading day's hedging gap: `ISNULL(Apex_Units,0) - ISNULL(Client_NOP_Units,0)` from Dealing_ApexRecon_Holdings for @PreviousDay. NULL when no previous day data exists. (Tier 2 — SP_Apex_Recon) |
| 9 | HedgingDiff | varchar(20) | YES | `'Yes'` = today's gap equals yesterday's gap (no correction occurred). `'No'` = gap changed (trades were executed). NULL when `Over_Under IS NULL`. Used to identify persistent vs. newly-corrected discrepancies. (Tier 2 — SP_Apex_Recon) |
| 10 | UpdateDate | datetime | YES | ETL metadata: `GETDATE()` at SP run time. (Tier 2 — SP_Apex_Recon) |

---

## 5. Usage Notes

**Reading Over_Under**: NULL rows (most rows) are within acceptable tolerance. Focus on `WHERE Over_Under IS NOT NULL` for action items. Over-hedged positions need to be liquidated; under-hedged positions need to be purchased.

**HedgingDiff='Yes' with persistent Over_Under**: Indicates a hedging error that was not corrected from previous day — escalate to dealing desk. `HedgingDiff='No'` means a correction was made but may not be complete yet.

**Threshold asymmetry**: Over threshold is $50K (high, to avoid noise from small positions); Under threshold is $5K individual + $100K portfolio (lower, because unhedged client exposure is a more immediate risk).

**Previous day calculation**: `@PreviousDay` skips weekends: Sunday→Thursday-2 days, Monday→Friday-3 days, Tuesday-Saturday→day-1.

**Live data note**: Live sample shows rows with NULL Over_Under and NULL HedgingDiff — these are the majority of rows (instruments within acceptable range). Only instruments breaching the thresholds get Over_Under values.

---

## 6. Governance

| Property | Value |
|----------|-------|
| **Source** | Dealing_ApexRecon_Holdings (same-day and previous-day) |
| **Refresh** | Daily per date via `SP_Apex_Recon(@Date)` |
| **SP Author** | Sarah Benchitrit (2021-03-07); last modified 2025-09-29 |
| **PII** | None |
| **Compliance** | LP hedging reconciliation — operational risk management for real stock custody |

---

## 7. Quality Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Structure | 5/5 | Full DDL analyzed |
| Live Data | 4/5 | Active to 2026-03-09; Over_Under NULL in recent sample (no discrepancies) — normal |
| SP Logic | 4/5 | Hedging section of SP_Apex_Recon fully traced |
| Upstream Wiki | 2/5 | Dealing_ApexRecon_Holdings documented (this batch); Dealing_Duco_EODRecon not yet |
| Business Context | 2/5 | Atlassian MCP unavailable; Over/under thresholds and hedging purpose inferred from SP |
| **Total** | **7.4/10** | |

---

*Generated: 2026-03-21 | Batch 4 | Schema: Dealing_dbo*
