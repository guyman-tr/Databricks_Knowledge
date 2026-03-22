# Dealing_dbo.Dealing_SAXORecon_Trades

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_SAXORecon_Trades |
| **Type** | Table |
| **ETL SP** | `Dealing_dbo.SP_SAXO_Recon` |
| **Refresh** | Daily (SB_Daily, Priority 0) |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on `[Date]` |
| **Rows** | ~1.0M |
| **Date Range** | 2021-02-01 → 2026-03-10 (active) |
| **PII** | none |

---

## 1. Business Meaning

Intraday trades reconciliation between SAXO Bank and eToro for **Real Stocks and Employee accounts**. Each row represents one instrument × HedgeServer × AccountNumber on a given date, comparing SAXO's executed trade volume against eToro's internal hedge allocation and aggregate client-side trades for that day.

Where `Dealing_SAXORecon_EODHoldings` captures end-of-day open **positions**, this table captures intraday **trade flow** — what was bought and sold during the day. The same SP (`SP_SAXO_Recon`) writes both tables in the same execution. SAXO LP files used here are the `ShareTradesExecuted` variants (not `ShareOpenPositions`). The difference columns (`SAXO-eToro_AmountUSD`, `SAXO-Clients_AmountUSD`) serve as the primary diagnostic for trade-level hedge discrepancies.

Note: `Total_Commission` records SAXO commission in local currency; `Total_Commission_Dollar` records the USD-converted equivalent. These were added in May 2023 (Adar, 18/05/2023 restructuring).

---

## 2. Business Logic

- **SAXO side**: `Dealing_staging.LP_SAXO_SaxoBank_9121766_ShareTradesExecuted` (Stocks-Real) and `LP_SAXO_SaxoBank_6914282_ShareTradesExecuted` + `LP_SAXO_SaxoBank_6914282_CFDTradesExecuted` (Employee accounts). Aggregated by ISINCode × BuySell × AccountNumber with GBX currency normalization.
- **eToro side**: Computed from `#etoroAllocation` — derived from `Dealing_staging.etoro_Hedge_Netting` trade allocations during the `@StartTrade`/`@EndTrade` window. Units = `ABS(eToroUnits)`, aggregated by instrument/HS/LiquidityAccount.
- **Client side**: From `DWH_dbo.Dim_Position` — positions opened (`OpenOccurred`) or closed (`CloseOccurred`) within the trade cutoff window, `SUM((2*IsBuy-1)*AmountInUnitsDecimal)` for valid customers.
- **Join logic**: Full outer join between eToro and SAXO sides on ISINCode × Buy/Sell × AccountNumber × Currency (GBX→GBP normalization applied).
- **Commission**: `Total_Commission_Local` = SAXO commission in instrument currency from LP file. `Total_Commission_Dollar` = USD-converted via `InstrumentToAccountRate`.
- **FX**: `SAXO_FX_Rate` = `InstrumentToAccountRate` from SAXO LP file. `eToro_FX_Rate` = `FXratetoUSD` from eToro allocation.
- **Key difference columns**: `SAXO-eToro_AmountUSD` = SAXO_AmountUSD − eToro_AmountUSD; `SAXO-Clients_AmountUSD` = SAXO_AmountUSD − Clients_AmountUSD.

---

## 3. Relationships

| Direction | Table | Join Key | Notes |
|-----------|-------|----------|-------|
| Source | `Dealing_staging.LP_SAXO_SaxoBank_9121766_ShareTradesExecuted` | `ReportDateID` | SAXO Real Stocks trade LP file |
| Source | `Dealing_staging.LP_SAXO_SaxoBank_6914282_ShareTradesExecuted` | `ReportDateID` | SAXO Employee Shares trade LP file |
| Source | `Dealing_staging.LP_SAXO_SaxoBank_6914282_CFDTradesExecuted` | `ReportDateID` | SAXO Employee CFD trade LP file |
| Source | `Dealing_staging.etoro_Hedge_Netting` | `InstrumentID, HedgeServerID, LiquidityAccountID` | eToro trade allocations |
| Source | `DWH_dbo.Dim_Position` | `InstrumentID, HedgeServerID, CID` | Client trades at date cutoff |
| Source | `DWH_dbo.Dim_Instrument` | `InstrumentID` | Instrument metadata |
| Source | `DWH_dbo.Fact_CurrencyPriceWithSplit` | `InstrumentID, OccurredDateID` | FX conversion rates |
| Source | `Dealing_staging.External_Fivetran_dealing_active_hs_mappings` | `hs_dealing_desk, liquidity_account_id` | Fivetran HS→LA→Account mapping |
| Related | `Dealing_dbo.Dealing_SAXORecon_EODHoldings` | `Date, HedgeServerID` | EOD holdings companion from same SP |

---

## 4. Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | date | YES | Reconciliation date. Same as @Date SP parameter. Clustered index. (Tier 2 — SP_SAXO_Recon) |
| `InstrumentID` | int | YES | eToro instrument ID. NULL for SAXO-only rows. ISNULL(eToro, Client) fallback. (Tier 2 — SP_SAXO_Recon) |
| `InstrumentDisplayName` | varchar(100) | YES | Instrument display name. ISNULL(eToro, SAXO LP description). (Tier 2 — SP_SAXO_Recon) |
| `ISINCode` | varchar(30) | YES | ISIN code. Primary join key between eToro and SAXO sides. (Tier 2 — SP_SAXO_Recon) |
| `Buy/Sell` | varchar(50) | YES | Trade direction: 'Buy' or 'Sell'. Derived from eToro IsBuy flag or SAXO BuySell field. Special-character column. (Tier 2 — SP_SAXO_Recon) |
| `CurrencyPrimary` | varchar(50) | YES | Instrument's primary trading currency. GBX normalized to GBP. (Tier 2 — SP_SAXO_Recon) |
| `SAXO_Units` | decimal(16,6) | YES | Units traded on SAXO LP for this instrument on this date. `ABS(TradedAmount)` from ShareTradesExecuted LP file. (Tier 2 — SP_SAXO_Recon) |
| `eToro_Units` | decimal(16,6) | YES | eToro internal hedge allocation units traded. `ABS(eToroUnits)` from etoro_Hedge_Netting trade allocation. (Tier 2 — SP_SAXO_Recon) |
| `Clients_Units` | decimal(16,6) | YES | Client-side net traded units from Dim_Position. `SUM((2*IsBuy-1)*AmountInUnitsDecimal)` for positions opened/closed during date window. (Tier 2 — SP_SAXO_Recon) |
| `SAXO-eToro_Units` | decimal(16,6) | YES | Discrepancy: SAXO_Units − eToro_Units. Special-character column. (Tier 2 — SP_SAXO_Recon) |
| `SAXO-Clients_Units` | decimal(16,6) | YES | Discrepancy: SAXO_Units − Clients_Units. Special-character column. (Tier 2 — SP_SAXO_Recon) |
| `SAXO_Rate` | decimal(16,6) | YES | SAXO LP execution price (from `Price` field in TradesExecuted file). (Tier 2 — SP_SAXO_Recon) |
| `eToro_Rate` | decimal(16,6) | YES | eToro average execution rate for the day. `eToro_AvgRate` from trade allocation. (Tier 2 — SP_SAXO_Recon) |
| `SAXO-eToro_Rate` | decimal(16,6) | YES | Rate discrepancy: SAXO_Rate − eToro_Rate. Special-character column. (Tier 2 — SP_SAXO_Recon) |
| `SAXO_LocalAmount` | money | YES | SAXO trade value in local currency. `ABS(TradedAmount) × Price` from LP file. (Tier 2 — SP_SAXO_Recon) |
| `eToro_LocalAmount` | money | YES | eToro trade value in local currency. `ABS(eToroLocalAmount)` from trade allocation. (Tier 2 — SP_SAXO_Recon) |
| `SAXO-eToro_LocalAmount` | money | YES | Local currency value discrepancy: SAXO_LocalAmount − eToro_LocalAmount. Special-character column. (Tier 2 — SP_SAXO_Recon) |
| `SAXO_AmountUSD` | money | YES | SAXO trade value in USD. `SAXO_LocalAmount × InstrumentToAccountRate` from LP file. (Tier 2 — SP_SAXO_Recon) |
| `eToro_AmountUSD` | money | YES | eToro trade value in USD. `ABS(eToroUSDAmount)` from trade allocation (no typo — unlike EODHoldings). (Tier 2 — SP_SAXO_Recon) |
| `Clients_AmountUSD` | money | YES | Client-side aggregate trade USD value. `-SUM((2*IsBuy-1)*Volume)` from Dim_Position for positions traded in date window. (Tier 2 — SP_SAXO_Recon) |
| `SAXO-eToro_AmountUSD` | money | YES | USD value discrepancy: SAXO_AmountUSD − eToro_AmountUSD. Primary reconciliation metric for trade-side. Special-character column. (Tier 2 — SP_SAXO_Recon) |
| `SAXO-Clients_AmountUSD` | money | YES | USD value discrepancy: SAXO_AmountUSD − Clients_AmountUSD. Secondary metric. Special-character column. (Tier 2 — SP_SAXO_Recon) |
| `SAXO_FX_Rate` | decimal(16,6) | YES | FX rate to USD from SAXO LP file (`InstrumentToAccountRate`). (Tier 2 — SP_SAXO_Recon) |
| `eToro_FX_Rate` | decimal(16,6) | YES | FX rate to USD from eToro trade allocation (`FXratetoUSD`). (Tier 2 — SP_SAXO_Recon) |
| `UpdateDate` | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |
| `Total_Commission` | decimal(16,6) | YES | SAXO commission in local currency for this instrument/date. Added May 2023 restructuring. (Tier 2 — SP_SAXO_Recon) |
| `HedgeServerID` | int | YES | HedgeServer identifier. Values: 35 (Stocks-Real), 128 (Employee). From Fivetran mapping. (Tier 2 — SP_SAXO_Recon) |
| `AccountNumber` | varchar(150) | YES | SAXO LP account number (e.g., '204400INETALM'). From Fivetran `lp_accounts` field. (Tier 2 — SP_SAXO_Recon) |
| `Total_Commission_Dollar` | decimal(16,6) | YES | SAXO commission in USD. `Total_Commission_Local × InstrumentToAccountRate`. Added May 2023 restructuring. (Tier 2 — SP_SAXO_Recon) |
| `Exchange` | varchar(100) | YES | Stock exchange name. ISNULL(eToro Dim_Instrument.Exchange, SAXO ExchangeDescription). (Tier 2 — SP_SAXO_Recon) |
| `Symbol` | varchar(20) | YES | Instrument ticker symbol (e.g., 'AAPL'). ISNULL(eToro, Client). (Tier 2 — SP_SAXO_Recon) |

---

## 5. Data Quality Notes

- **Trade-flow vs position**: This table captures intraday trades, not EOD holdings — a zero row here does not mean no position exists. Use `Dealing_SAXORecon_EODHoldings` for position-level reconciliation.
- **No `eToro_AmounUSD` typo here**: Unlike `Dealing_SAXORecon_EODHoldings`, this table's column is correctly named `eToro_AmountUSD`.
- **Special-character columns**: `[Buy/Sell]`, `[SAXO-eToro_Units]`, `[SAXO-Clients_Units]`, `[SAXO-eToro_Rate]`, `[SAXO-eToro_LocalAmount]`, `[SAXO-eToro_AmountUSD]`, `[SAXO-Clients_AmountUSD]` require bracket quoting.
- **GBX/GBP normalization**: Join logic normalizes GBX→GBP for currency matching between eToro and SAXO sides (added July 2024).
- **Commission added May 2023**: `Total_Commission` and `Total_Commission_Dollar` were added in the same restructuring that removed the Hedging table logic.
- **Fivetran dependency**: Same as EODHoldings — HS/LA mapping from `External_Fivetran_dealing_active_hs_mappings` (SR-282189, Nov 2024).

---

## 6. Usage Notes

```sql
-- Latest date available
SELECT MAX([Date]) FROM Dealing_dbo.Dealing_SAXORecon_Trades;

-- Large USD trade discrepancies
SELECT [Date], InstrumentDisplayName, HedgeServerID,
       [SAXO-eToro_AmountUSD], SAXO_Units, eToro_Units
FROM Dealing_dbo.Dealing_SAXORecon_Trades
WHERE [Date] = '2026-03-10'
  AND ABS([SAXO-eToro_AmountUSD]) > 5000
ORDER BY ABS([SAXO-eToro_AmountUSD]) DESC;
```

**Performance**: ROUND_ROBIN distribution — always filter on `[Date]` (clustered index).

---

## 7. Known Issues

- Special-character column names require bracket quoting throughout.
- No `Reality-Supposed` / `Reality-Client` columns — use `[SAXO-eToro_AmountUSD]` and `[SAXO-Clients_AmountUSD]` as equivalents for trade-day analysis.

---

## 8. Sources & Confidence

| Source | Phase | Confidence |
|--------|-------|------------|
| SSDT DDL (`Dealing_dbo.Dealing_SAXORecon_Trades.sql`) | P1 | High |
| SP Logic (`Dealing_dbo.SP_SAXO_Recon.sql`) | P9 | High |
| Live data sample (Synapse MCP) | P2 | High |
| OpsDB orchestration | P9B | High |
| Atlassian knowledge scan | P10 | Not available (−3 quality) |

**Quality Score: 7.5/10** — Active table with clear ETL logic. Deducted: no Atlassian scan (−1), special-character columns add query complexity (−0.5), SAXO LP file dependency introduces external risk (−0.5), no upstream wiki (−0.5).
