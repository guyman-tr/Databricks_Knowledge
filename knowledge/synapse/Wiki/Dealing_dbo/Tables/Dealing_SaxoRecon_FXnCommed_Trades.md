# Dealing_dbo.Dealing_SaxoRecon_FXnCommed_Trades

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_SaxoRecon_FXnCommed_Trades |
| **Type** | Table |
| **ETL SP** | Unknown — **no SP found in SSDT** |
| **Refresh** | ⛔ ORPHANED — no writer SP in SSDT repo |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on `[Date]` |
| **Rows** | ~4.2K |
| **Date Range** | 2022-01-02 → 2023-12-05 (**STALE ~15 months**) |
| **PII** | none |

---

## 1. Business Meaning

A FX and Commodities trade-level reconciliation table — the trade-side companion to `Dealing_SaxoRecon_FXnCommed_EODHoldings`. Each row represents one instrument × HedgeServer × Side (Buy/Sell) on a given date, comparing SAXO's executed FX trade volume against eToro's internal hedge allocation and client trades for the day.

**This table is decommissioned.** No stored procedure in the SSDT repo writes to it. Data stopped on 2023-12-05. The `SP_SAXO_Recon_FXnCommed` SP was restructured at some point and the Trades INSERT was removed — only the EOD holdings logic remains active. Compare with `Dealing_SaxoRecon_FXnCommed_EODHoldings` which is still actively written daily.

Notable DDL differences vs the active Stocks trades table:
- `Side` column (no special characters) instead of `[Buy/Sell]`
- No `LiquidityAccountID`, `Account_Number`, `Symbol` columns
- No `eToro_LocalAmount` or `SAXO-eToro_LocalAmount`
- Has `Commission` (not `Total_Commission` + `Total_Commission_Dollar`)

---

## 2. Business Logic

- **Original intent**: Per-instrument daily FX hedge trade comparison. SAXO side from `LP_SAXO_SaxoBank_6914282_FXTradesExecuted` (inferred). eToro side from `etoro_Hedge_Netting` trade allocations. Client side from `Dim_Position` for FX/Commed HS set.
- **No writer SP**: Cannot reconstruct logic from SSDT — the Trades INSERT was removed when the SP was restructured. Last data: 2023-12-05.
- **`Commission`**: SAXO commission amount (local or USD — cannot confirm without SP code).

---

## 3. Relationships

| Direction | Table | Join Key | Notes |
|-----------|-------|----------|-------|
| Related | `Dealing_dbo.Dealing_SaxoRecon_FXnCommed_EODHoldings` | `Date, HedgeServerID` | Active EOD holdings companion |

---

## 4. Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | date | YES | Reconciliation date. Clustered index. Data stopped 2023-12-05. |
| `InstrumentID` | int | YES | eToro instrument ID. (Tier 4 — inferred) |
| `InstrumentDisplayName` | nvarchar(100) | YES | Instrument display name. (Tier 4 — inferred) |
| `ISINCode` | nvarchar(30) | YES | ISIN code. Join key between eToro and SAXO sides. (Tier 4 — inferred) |
| `Side` | varchar(100) | YES | Trade direction: likely 'Buy' or 'Sell'. No special characters (unlike the Stocks Recon `[Buy/Sell]` column). (Tier 4 — inferred) |
| `HedgeServerID` | int | YES | HedgeServer identifier for FX/Commodities account. (Tier 4 — inferred) |
| `SAXO_Units` | decimal(16,6) | YES | Units executed by SAXO LP for this instrument on this date. (Tier 4 — inferred) |
| `eToro_Units` | decimal(16,6) | YES | eToro internal FX hedge trade units. (Tier 4 — inferred) |
| `Clients_Units` | decimal(16,6) | YES | Client-side net traded FX units. (Tier 4 — inferred) |
| `SAXO-eToro_Units` | decimal(16,6) | YES | Discrepancy: SAXO_Units − eToro_Units. Special-character column. (Tier 4 — inferred) |
| `SAXO-Clients_Units` | decimal(16,6) | YES | Discrepancy: SAXO_Units − Clients_Units. Special-character column. (Tier 4 — inferred) |
| `SAXO_Rate` | decimal(16,6) | YES | SAXO LP execution price. (Tier 4 — inferred) |
| `eToro_Rate` | decimal(16,6) | YES | eToro average execution rate. (Tier 4 — inferred) |
| `SAXO-eToro_Rate` | decimal(16,6) | YES | Rate discrepancy: SAXO_Rate − eToro_Rate. Special-character column. (Tier 4 — inferred) |
| `SAXO_LocalAmount` | money | YES | SAXO trade value in local currency. (Tier 4 — inferred) |
| `SAXO_AmountUSD` | money | YES | SAXO trade value in USD. (Tier 4 — inferred) |
| `eToro_AmountUSD` | money | YES | eToro trade value in USD. (Tier 4 — inferred) |
| `Clients_AmountUSD` | money | YES | Client-side aggregate trade USD value. (Tier 4 — inferred) |
| `SAXO-eToro_AmountUSD` | money | YES | USD discrepancy: SAXO_AmountUSD − eToro_AmountUSD. Primary reconciliation metric. Special-character column. (Tier 4 — inferred) |
| `SAXO-Clients_AmountUSD` | money | YES | USD discrepancy: SAXO_AmountUSD − Clients_AmountUSD. Secondary metric. Special-character column. (Tier 4 — inferred) |
| `Commission` | money | YES | SAXO commission amount (currency unconfirmed — no SP code). (Tier 4 — inferred) |
| `UpdateDate` | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

---

## 5. Data Quality Notes

- ⛔ **ORPHANED TABLE**: No SP writes to this table in the SSDT codebase. Data stopped December 2023 (~15 months stale at time of documentation).
- Do NOT use for current FX trade analysis. Use `Dealing_SaxoRecon_FXnCommed_EODHoldings` for current FX/Commodities reconciliation.
- `Side` column has no special characters (unlike `[Buy/Sell]` in the Stocks trades table) — likely a design improvement before the SP was decommissioned.
- Special-character columns `[SAXO-eToro_Units]`, `[SAXO-Clients_Units]`, `[SAXO-eToro_Rate]`, `[SAXO-eToro_AmountUSD]`, `[SAXO-Clients_AmountUSD]` still require bracket quoting.
- All column descriptions are Tier 4 (inferred) due to missing SP code.

---

## 6. Usage Notes

This table is stale and should not be used for current analysis. For current FX/Commodities SAXO reconciliation, use `Dealing_SaxoRecon_FXnCommed_EODHoldings`.

---

## 7. Known Issues

- No writer SP found in SSDT — decommissioned as of December 2023.
- All tier assignments are Tier 4 (inferred) due to missing SP code.

---

## 8. Sources & Confidence

| Source | Phase | Confidence |
|--------|-------|------------|
| SSDT DDL (`Dealing_dbo.Dealing_SaxoRecon_FXnCommed_Trades.sql`) | P1 | High |
| SP scan (no SP found) | P8 | High |
| Live data sample (Synapse MCP) | P2 | High |
| Atlassian knowledge scan | P10 | Not available |

**Quality Score: 4.0/10** — Orphaned table. No writer SP — all column descriptions are Tier 4 inference. Deducted: no SP (−3), stale data (−1), no Atlassian (−1), all inferred descriptions (−1).
