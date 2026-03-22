# Dealing_dbo.Dealing_SAXORecon_Hedging

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_SAXORecon_Hedging |
| **Type** | Table |
| **ETL SP** | Unknown — **no SP found in SSDT** |
| **Refresh** | ⛔ ORPHANED — no writer SP in SSDT repo |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on `[Date]` |
| **Rows** | ~42.7K |
| **Date Range** | 2022-01-03 → 2023-05-17 (**STALE ~3 years**) |
| **PII** | none |

---

## 1. Business Meaning

A hedging-specific reconciliation view for SAXO — comparing eToro's hedge position changes to SAXO's reported position for a given day. The design captures daily delta from the previous day (`DiffFromPreviousDay`) and the intraday cumulative delta (`DiffFromToday`), as well as a hedging adequacy flag (`HedgingDiff`). The column `Over_Under` indicates whether eToro is over-hedged or under-hedged relative to SAXO's expected position.

**This table is effectively decommissioned.** No stored procedure in the SSDT repo writes to it. Data stopped on 2023-05-17. The last SP change history in `SP_SAXO_Recon.sql` mentions the SP was restructured in May 2023 (Adar, 18/05/2023: "Change the code — etoro and client side from DUCO, Add Total_Commission_Dollar & Exchange in Trades table") — this restructuring likely removed the hedging comparison logic. The hedging monitoring functionality may have been absorbed into `Dealing_SAXORecon_EODHoldings` via the `SAXO-eToro_Units` / `Reality-Supposed` columns.

---

## 2. Business Logic

- **Original intent**: Per-instrument daily hedging delta. `DiffFromPreviousDay` = today's eToro hedge units minus yesterday's. `DiffFromToday` = SAXO reported trades vs eToro executed. `HedgingDiff` = 'OK'/'Over'/'Under' string indicator.
- **`Over_Under`**: Likely 'Over-hedged' or 'Under-hedged' — eToro holds more/less than required vs SAXO.
- **No writer SP**: Cannot reconstruct logic from SSDT — the writer was removed from the codebase. Last data: 2023-05-17.

---

## 3. Relationships

| Direction | Table | Join Key | Notes |
|-----------|-------|----------|-------|
| Related | `Dealing_dbo.Dealing_SAXORecon_EODHoldings` | `Date, InstrumentID, HedgeServerID` | Active replacement for hedging monitoring |

---

## 4. Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | date | YES | Reconciliation date. Clustered index. Data stopped 2023-05-17. |
| `InstrumentID` | int | YES | eToro instrument ID. (Tier 4 — inferred from table context) |
| `InstrumentDisplayName` | varchar(100) | YES | Instrument display name. (Tier 4 — inferred) |
| `ISINCode` | varchar(30) | YES | ISIN code used to join SAXO LP data with eToro instrument. (Tier 4 — inferred) |
| `CurrencyPrimary` | varchar(50) | YES | Instrument's primary trading currency. (Tier 4 — inferred) |
| `HedgeServerID` | int | YES | HedgeServer identifier for the SAXO account. (Tier 4 — inferred) |
| `Buy/Sell` | varchar(50) | YES | Position direction: 'Buy' or 'Sell'. Special-character column. (Tier 4 — inferred) |
| `Over_Under` | varchar(50) | YES | Hedge adequacy indicator — likely 'Over-hedged' / 'Under-hedged'. eToro position vs required hedge level. (Tier 4 — inferred) |
| `DiffFromPreviousDay` | decimal(16,6) | YES | Change in eToro hedge units from the previous trading day. (Tier 4 — inferred from column name) |
| `DiffFromToday` | decimal(16,6) | YES | Intraday cumulative delta between SAXO traded units and eToro executed units. (Tier 4 — inferred) |
| `HedgingDiff` | varchar(20) | YES | Hedging adequacy flag — likely 'OK', 'Over', 'Under' or similar string classification. (Tier 4 — inferred from column name) |
| `UpdateDate` | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

---

## 5. Data Quality Notes

- ⛔ **ORPHANED TABLE**: No SP writes to this table in the SSDT codebase. Data stopped May 2023 (~3 years stale at time of documentation).
- Do NOT rely on this table for current hedging analysis. Use `Dealing_SAXORecon_EODHoldings.[SAXO-eToro_Units]` and `[Reality-Supposed]` instead.
- Special-character column `[Buy/Sell]` requires bracket quoting.

---

## 6. Usage Notes

This table is stale and should not be used for current analysis. For current SAXO hedging reconciliation, use `Dealing_SAXORecon_EODHoldings`.

---

## 7. Known Issues

- No writer SP found in SSDT — decommissioned as of May 2023.
- All tier assignments are Tier 4 (inferred) due to missing SP code.

---

## 8. Sources & Confidence

| Source | Phase | Confidence |
|--------|-------|------------|
| SSDT DDL (`Dealing_dbo.Dealing_SAXORecon_Hedging.sql`) | P1 | High |
| SP scan (no SP found) | P8 | High |
| Live data sample (Synapse MCP) | P2 | High |
| Atlassian knowledge scan | P10 | Not available |

**Quality Score: 4.5/10** — Orphaned table. No writer SP — all column descriptions are Tier 4 inference. Deducted: no SP (−3), stale data (−1), no Atlassian (−1), all inferred descriptions (−0.5).
