# Dealing_dbo.Dealing_SaxoRecon_FXnCommed_EODHoldings

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_SaxoRecon_FXnCommed_EODHoldings |
| **Type** | Table |
| **ETL SP** | `Dealing_dbo.SP_SAXO_Recon_FXnCommed` |
| **Refresh** | Daily (SB_Daily, Priority 0) |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on `[Date]` |
| **Rows** | ~195.7K |
| **Date Range** | 2024-04-12 → 2026-03-10 (active, data from April 2024) |
| **PII** | none |

---

## 1. Business Meaning

End-of-day (EOD) holdings reconciliation between SAXO Bank and eToro for **FX (Currencies) and Commodities accounts**. Analogous to `Dealing_SAXORecon_EODHoldings` but focused on the FX/Commodities desk rather than Real Stocks. Each row represents one instrument × HedgeServer × LiquidityAccount on a given date, comparing SAXO's reported FX position against eToro's internal hedge netting and aggregate client exposure.

The SAXO LP file used is `LP_SAXO_SaxoBank_6914282_FXOpenPositions` (FX positions, account 6914282). The Fivetran mapping filters to `activity IN ('Currencies', 'Commodities')`. The key discrepancy columns are `SAXO-eToro_AmountUSD` and `SAXO-Clients_AmountUSD`.

Note: `SAXO_LocalAmount` is computed as `-1 × QuotedValue` from the SAXO LP file (sign convention for FX quoted value). `SAXO_AmountUSD` is `-1 × Amount × EODRate × InstrumentToAccountRate`. Data only starts from April 2024 — this table is relatively new. The companion `Dealing_SaxoRecon_FXnCommed_Trades` table is orphaned (no active writer SP).

---

## 2. Business Logic

- **SAXO side**: `Dealing_staging.LP_SAXO_SaxoBank_6914282_FXOpenPositions`. SAXO_Units = `Amount`; SAXO_LocalAmount = `-QuotedValue`; SAXO_AmountUSD = `-Amount × EODRate × InstrumentToAccountRate`. Aggregated by ISINCode × BuySell × AccountNumber.
- **eToro side**: Point-in-time reconstruction from `etoro_Hedge_Netting` (current) UNION `etoro_History_Netting_History` (historical) for FX/Commodities HS IDs. Filtered by `SysStartTime < @EndTrade`, `ROW_NUMBER()` to get latest snapshot. Rates from `Fact_CurrencyPriceWithSplit` (InstrumentTypeID=1 for FX). USD conversion: multi-step via `#ConversionRate` using Bid/Ask chain.
- **Client side**: `DWH_dbo.Dim_Position` for valid customers with HedgeServerID in the Fivetran-filtered FX/Commodities HS set. Open positions at cutoff.
- **Fivetran filter**: `activity IN ('Currencies', 'Commodities')` from `External_Fivetran_dealing_active_hs_mappings` (latest active record by update_date ≤ @Date).
- **Account names**: `Dealing_staging.etoro_Trade_LiquidityAccounts` used to resolve LiquidityAccountID → LiquidityAccountName for the `Account_Number` field.
- **Key difference columns**: `SAXO-eToro_AmountUSD` = SAXO_AmountUSD − eToro_AmountUSD; `SAXO-Clients_AmountUSD` = SAXO_AmountUSD − Clients_AmountUSD.

---

## 3. Relationships

| Direction | Table | Join Key | Notes |
|-----------|-------|----------|-------|
| Source | `Dealing_staging.LP_SAXO_SaxoBank_6914282_FXOpenPositions` | `ReportingDate` | SAXO FX/Commed LP EOD file |
| Source | `Dealing_staging.etoro_Hedge_Netting` | `InstrumentID, HedgeServerID, LiquidityAccountID` | eToro current FX/Commed hedge positions |
| Source | `Dealing_staging.etoro_History_Netting_History` | `InstrumentID, HedgeServerID` | eToro historical FX/Commed hedge (temporal) |
| Source | `DWH_dbo.Dim_Position` | `InstrumentID, HedgeServerID, CID` | Client-side positions at cutoff |
| Source | `DWH_dbo.Dim_Instrument` | `InstrumentID` | Instrument metadata (InstrumentTypeID=1 for FX) |
| Source | `DWH_dbo.Fact_CurrencyPriceWithSplit` | `InstrumentID, OccurredDateID` | FX rates for eToro-side valuation |
| Source | `Dealing_staging.External_Fivetran_dealing_active_hs_mappings` | `hs_dealing_desk, liquidity_account_id` | Fivetran HS→LA mapping (Currencies/Commodities activity) |
| Source | `Dealing_staging.etoro_Trade_LiquidityAccounts` | `LiquidityAccountID` | Account name resolution |
| Related | `Dealing_dbo.Dealing_SaxoRecon_FXnCommed_Trades` | `Date, HedgeServerID` | Orphaned trades companion table (no active writer) |

---

## 4. Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | date | YES | Reconciliation date. Clustered index. Data starts 2024-04-12. (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `LiquidityAccountID` | int | YES | eToro liquidity account ID for this FX/Commed account. From Fivetran mapping. (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `HedgeServerID` | int | YES | HedgeServer identifier for the FX/Commodities account. From Fivetran mapping (Currencies/Commodities activity). (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `Account_Number` | varchar(50) | YES | SAXO LP account number or LiquidityAccountName. From Fivetran `lp_accounts` / etoro_Trade_LiquidityAccounts. (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `InstrumentID` | int | YES | eToro instrument ID. NULL for SAXO-only rows. (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `InstrumentDisplayName` | varchar(100) | YES | Instrument display name. ISNULL(eToro, SAXO LP description). (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `Symbol` | varchar(250) | YES | Instrument ticker symbol (e.g., 'EURUSD'). From Dim_Instrument. (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `ISINCode` | varchar(30) | YES | ISIN code. Used as join key between eToro and SAXO sides. (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `CurrencyPrimary` | varchar(50) | YES | Instrument's primary currency. From Dim_Instrument SellCurrency or SAXO InstrumentCurrency. (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `Exchange` | varchar(80) | YES | Exchange name. ISNULL(eToro Exchange, SAXO ExchangeDescription). (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `SAXO_Units` | decimal(16,6) | YES | Units reported by SAXO LP at EOD. `Amount` from FXOpenPositions LP file. Aggregated per ISINCode×BuySell×AccountNumber. (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `eToro_Units` | decimal(16,6) | YES | eToro's internal FX/Commed hedge netting position in units at EOD cutoff. `SUM((2*IsBuy-1)*Units)` from Netting tables. (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `Clients_Units` | decimal(16,6) | YES | Aggregate client-side net units from `Dim_Position` for FX/Commed HS set. (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `SAXO-eToro_Units` | decimal(16,6) | YES | Discrepancy: SAXO_Units − eToro_Units. Special-character column. (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `SAXO-Clients_Units` | decimal(16,6) | YES | Discrepancy: SAXO_Units − Clients_Units. Special-character column. (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `SAXO_LocalAmount` | money | YES | SAXO position value in local currency. `-1 × QuotedValue` from LP file (FX sign convention). (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `eToro_LocalAmount` | money | YES | eToro position value in local currency. From netting computation with Bid/Ask rates. (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `SAXO-eToro_LocalAmount` | money | YES | Local currency value discrepancy: SAXO_LocalAmount − eToro_LocalAmount. Special-character column. (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `SAXO_AmountUSD` | money | YES | SAXO position USD value. `-1 × Amount × EODRate × InstrumentToAccountRate`. (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `eToro_AmountUSD` | money | YES | eToro position USD value. Multi-step FX conversion via #ConversionRate (Bid/Ask chain). (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `Clients_AmountUSD` | money | YES | Client-side aggregate position USD value via Fact_CurrencyPriceWithSplit. (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `SAXO-eToro_AmountUSD` | money | YES | SAXO_AmountUSD − eToro_AmountUSD. Primary reconciliation metric. Special-character column. (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `SAXO-Clients_AmountUSD` | money | YES | SAXO_AmountUSD − Clients_AmountUSD. Secondary metric. Special-character column. (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `SAXO_Rate` | decimal(16,6) | YES | SAXO's EOD rate from LP file (`EODRate`). Aggregated as MAX per ISINCode group. (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `eToro_Rate` | decimal(16,6) | YES | eToro mid-price at EOD. `(Bid+Ask)/2` from `Fact_CurrencyPriceWithSplit`. (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `SAXO-eToro_Rate` | decimal(16,6) | YES | Rate discrepancy: SAXO_Rate − eToro_Rate. Special-character column. (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `SAXO_FXRate` | decimal(16,6) | YES | FX rate to USD from SAXO LP file (`InstrumentToAccountRate`). Aggregated as MAX. (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `eToro_FXRate` | decimal(16,6) | YES | FX rate to USD used for eToro-side USD conversion. From #ConversionRate Bid/Ask chain. (Tier 2 — SP_SAXO_Recon_FXnCommed) |
| `UpdateDate` | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

---

## 5. Data Quality Notes

- **Data only from April 2024**: Table was introduced relatively recently — only ~2 years of history vs 5 years for the Stocks recon tables.
- **FX sign convention**: `SAXO_LocalAmount` = `-QuotedValue` and `SAXO_AmountUSD` = `-Amount × EODRate × InstrumentToAccountRate`. The negation reflects FX LP reporting conventions. Be aware when comparing absolute values.
- **Special-character columns**: `[SAXO-eToro_Units]`, `[SAXO-Clients_Units]`, `[SAXO-eToro_LocalAmount]`, `[SAXO-eToro_AmountUSD]`, `[SAXO-Clients_AmountUSD]`, `[SAXO-eToro_Rate]` require bracket quoting.
- **No `Reality-Supposed` / `Reality-Client`**: Use `[SAXO-eToro_AmountUSD]` / `[SAXO-Clients_AmountUSD]` as the primary discrepancy metrics (unlike the Stocks table which uses the `Reality-*` naming).
- **eToro_FXRate vs SAXO_FXRate**: FX instruments have complex multi-step USD conversion. The eToro-side uses a chain of Bid/Ask rates; SAXO uses `InstrumentToAccountRate` directly from the LP file.
- **Companion Trades table orphaned**: `Dealing_SaxoRecon_FXnCommed_Trades` has no active writer SP — only EOD holdings are currently reconciled for FX/Commodities.

---

## 6. Usage Notes

```sql
-- Latest date available
SELECT MAX([Date]) FROM Dealing_dbo.Dealing_SaxoRecon_FXnCommed_EODHoldings;

-- Active discrepancies (SAXO vs eToro > $10K)
SELECT [Date], InstrumentDisplayName, HedgeServerID, LiquidityAccountID,
       [SAXO-eToro_AmountUSD], SAXO_Units, eToro_Units
FROM Dealing_dbo.Dealing_SaxoRecon_FXnCommed_EODHoldings
WHERE [Date] = '2026-03-10'
  AND ABS([SAXO-eToro_AmountUSD]) > 10000
ORDER BY ABS([SAXO-eToro_AmountUSD]) DESC;
```

**Performance**: ROUND_ROBIN distribution — always filter on `[Date]` (clustered index).

---

## 7. Known Issues

- FX sign convention: `SAXO_LocalAmount` and `SAXO_AmountUSD` use `-1 × LP values`. Verify sign expectations before building reports.
- Special-character column names require bracket quoting throughout.
- No historical data before April 2024.

---

## 8. Sources & Confidence

| Source | Phase | Confidence |
|--------|-------|------------|
| SSDT DDL (`Dealing_dbo.Dealing_SaxoRecon_FXnCommed_EODHoldings.sql`) | P1 | High |
| SP Logic (`Dealing_dbo.SP_SAXO_Recon_FXnCommed.sql`) | P9 | High |
| Live data sample (Synapse MCP) | P2 | High |
| OpsDB orchestration | P9B | High |
| Atlassian knowledge scan | P10 | Not available (−3 quality) |

**Quality Score: 7.0/10** — Active table with clear ETL logic. Deducted: no Atlassian scan (−1), limited history since April 2024 only (−0.5), FX sign convention complexity (−0.5), special-character columns (−0.5), companion Trades table orphaned (−0.5).
