# Dealing_dbo.Dealing_SAXORecon_EODHoldings

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_SAXORecon_EODHoldings |
| **Type** | Table |
| **ETL SP** | `Dealing_dbo.SP_SAXO_Recon` |
| **Refresh** | Daily (SB_Daily, Priority 0) |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on `[Date]` |
| **Rows** | ~1.86M |
| **Date Range** | 2021-02-01 → 2026-03-10 (active) |
| **PII** | none |

---

## 1. Business Meaning

End-of-day (EOD) holdings reconciliation between SAXO Bank and eToro for **Real Stocks and Employee accounts**. Each row represents one instrument × HedgeServer × AccountNumber on a given date, showing SAXO's reported position alongside eToro's internal hedge netting position and the aggregate client-side exposure. The three-way comparison (`SAXO_Units` vs `eToro_Units` vs `Clients_Units`) and derived difference columns (`SAXO-eToro_Units`, `SAXO-Clients_Units`, `Reality-Supposed`, `Reality-Client`) are the primary tool for the Dealing desk to detect and investigate position discrepancies with the SAXO liquidity provider.

SAXO is eToro's LP for real stock execution — account numbers like `204400INETALM`, `204400INET4` map to specific SAXO sub-accounts. The SP uses a Fivetran-maintained mapping table (`Dealing_staging.External_Fivetran_dealing_active_hs_mappings`) to determine which HedgeServer IDs and LiquidityAccountIDs correspond to SAXO `activity IN ('Stocks - Real', 'Employees')`. The eToro-side holdings come from the temporal `etoro_Hedge_Netting` tables (current + history). The client-side comes from `Dim_Position` filtered to open positions at the trade cutoff (22:00 CET, i.e., -2h UTC offset).

Note: `eToro_AmounUSD` has a **typo** (missing 't') preserved from the original DDL.

---

## 2. Business Logic

- **SAXO side**: `Dealing_staging.LP_SAXO_SaxoBank_9121766_ShareOpenPositions` (Stocks - Real) or `LP_SAXO_SaxoBank_6914282_CFDOpenPositions` / `LP_SAXO_SaxoBank_6914282_ShareOpenPositions` (Employee accounts). These are LP files delivered by SAXO and loaded via Fivetran/staging.
- **eToro side**: Point-in-time reconstruction from `etoro_Hedge_Netting` (current) UNION `etoro_History_Netting_History` (historical). Positions are netted as `SUM((2*IsBuy-1)*Units)` per InstrumentID × HedgeServerID × LiquidityAccountID using the most recent snapshot before the cutoff (`ROW_NUMBER() OVER ... ORDER BY SysEndTime DESC WHERE RN=1`).
- **Client side**: Live position sum from `DWH_dbo.Dim_Position` — `SUM((2*IsBuy-1)*ABS(AmountInUnitsDecimal))` for valid customers, open positions at the cutoff.
- **Currency conversion**: Multi-step FX via `Fact_CurrencyPriceWithSplit` with ConvertRate fields. GBX (pence) instruments: LocalAmount divided by 100 (`CASE WHEN SellCurrency='GBX' THEN eToroLocalAmount/100`).
- **Boundaries**: `UpperBoundary` = HedgeRiskLimitUSD and `LowerBoundary` = -OpenThresholdUSD from `Dealing_staging.External_Etoro_Hedge_InstrumentBoundaries`; `illiquid/liquid` = 'illiquid' when LowerBoundary = -1000.
- **Staleness guard**: `@Date` is adjusted to the latest available `ReportingDate` from the SAXO LP file if the requested date has no LP data.
- **Key difference columns**: `Reality-Supposed` = SAXO_AmountUSD − eToro_AmountUSD; `Reality-Client` = SAXO_AmountUSD − Clients_AmountUSD.

---

## 3. Relationships

| Direction | Table | Join Key | Notes |
|-----------|-------|----------|-------|
| Source | `Dealing_staging.LP_SAXO_SaxoBank_9121766_ShareOpenPositions` | `ReportDateID` | SAXO Real Stocks LP EOD file |
| Source | `Dealing_staging.LP_SAXO_SaxoBank_6914282_CFDOpenPositions` | `ReportDateID` | SAXO Employee CFD LP file |
| Source | `Dealing_staging.LP_SAXO_SaxoBank_6914282_ShareOpenPositions` | `ReportDateID` | SAXO Employee Shares LP file |
| Source | `Dealing_staging.etoro_Hedge_Netting` | `InstrumentID, HedgeServerID, LiquidityAccountID` | eToro current hedge positions |
| Source | `Dealing_staging.etoro_History_Netting_History` | `InstrumentID, HedgeServerID` | eToro historical hedge (temporal) |
| Source | `DWH_dbo.Dim_Position` | `InstrumentID, HedgeServerID, CID` | Client-side positions at cutoff |
| Source | `DWH_dbo.Dim_Instrument` | `InstrumentID` | Instrument metadata |
| Source | `DWH_dbo.Fact_CurrencyPriceWithSplit` | `InstrumentID, OccurredDateID` | FX conversion rates |
| Source | `Dealing_staging.External_Fivetran_dealing_active_hs_mappings` | `hs_dealing_desk, liquidity_account_id` | Fivetran HS→LA→Account mapping |
| Source | `Dealing_staging.External_Etoro_Hedge_InstrumentBoundaries` | `InstrumentID, HedgeServerID` | Risk boundaries |
| Related | `Dealing_dbo.Dealing_SAXORecon_Trades` | `Date, HedgeServerID` | Trade-level companion from same SP |

---

## 4. Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | date | YES | Reconciliation date. Adjusted to latest available SAXO LP file date if requested date has no data. Clustered index. |
| `InstrumentID` | int | YES | eToro instrument ID. NULL for SAXO-only rows (instruments eToro has no mapping for). (Tier 2 — SP_SAXO_Recon) |
| `InstrumentDisplayName` | varchar(100) | YES | Instrument display name. ISNULL(eToro, SAXO) — eToro name preferred, falls back to SAXO LP description. (Tier 2 — SP_SAXO_Recon) |
| `ISINCode` | varchar(30) | YES | ISIN code. Used as the primary JOIN key between eToro and SAXO sides. (Tier 2 — SP_SAXO_Recon) |
| `Buy/Sell` | varchar(50) | YES | Position direction: 'Buy' or 'Sell'. Derived from eToro IsBuy flag or SAXO BuySell field. Special-character column name requires bracket quoting. (Tier 2 — SP_SAXO_Recon) |
| `CurrencyPrimary` | varchar(50) | YES | Instrument's primary trading currency. GBX converted to GBP in eToro side. (Tier 2 — SP_SAXO_Recon) |
| `SAXO_Units` | decimal(16,6) | YES | Units reported by SAXO LP at EOD. Negative for Sell positions. Aggregated across SAXO sub-accounts. (Tier 2 — SP_SAXO_Recon) |
| `eToro_Units` | decimal(16,6) | YES | eToro's internal hedge netting position in units. Computed as `SUM((2*IsBuy-1)*Units)` from Netting tables at EOD cutoff. (Tier 2 — SP_SAXO_Recon) |
| `Clients_Units` | decimal(16,6) | YES | Aggregate client-side net units from `Dim_Position`. `SUM((2*IsBuy-1)*ABS(AmountInUnitsDecimal))` for open positions at cutoff. (Tier 2 — SP_SAXO_Recon) |
| `SAXO-eToro_Units` | decimal(16,6) | YES | Discrepancy: SAXO_Units − eToro_Units. Non-zero indicates hedge imbalance between eToro's books and SAXO's records. Special-character column. (Tier 2 — SP_SAXO_Recon) |
| `SAXO-Clients_Units` | decimal(16,6) | YES | Discrepancy: SAXO_Units − Clients_Units. Measures how much SAXO holds vs what clients own. Special-character column. (Tier 2 — SP_SAXO_Recon) |
| `SAXO_LocalAmount` | money | YES | SAXO position value in the instrument's local currency. `Amount × EODRate × FigureSize` from SAXO LP file. (Tier 2 — SP_SAXO_Recon) |
| `eToro_LocalAmount` | money | YES | eToro position value in local currency. `SUM((2*IsBuy-1)*Units*Bid_or_Ask)`. GBX adjusted by /100. (Tier 2 — SP_SAXO_Recon) |
| `SAXO_AmountUSD` | money | YES | SAXO position value converted to USD. `SAXO_LocalAmount × InstrumentToAccountRate` from SAXO LP file. (Tier 2 — SP_SAXO_Recon) |
| `eToro_AmounUSD` | money | YES | **Typo column name** (missing 't'). eToro position USD value. `SUM((2*IsBuy-1)*Units*rate*ConvertRate)`. (Tier 2 — SP_SAXO_Recon) |
| `Clients_AmountUSD` | money | YES | Client-side aggregate position USD value. `SUM((2*IsBuy-1)*ABS(AmountInUnitsDecimal)*bid_or_ask*ConvertRate)`. (Tier 2 — SP_SAXO_Recon) |
| `Reality-Supposed` | money | YES | SAXO_AmountUSD − eToro_AmountUSD. Primary reconciliation metric: eToro's hedging vs what SAXO actually holds. Special-character column. (Tier 2 — SP_SAXO_Recon) |
| `Reality-Client` | money | YES | SAXO_AmountUSD − Clients_AmountUSD. Secondary metric: SAXO holdings vs aggregate client exposure. Special-character column. (Tier 2 — SP_SAXO_Recon) |
| `eToro_Rate` | decimal(16,6) | YES | eToro's mid-price at EOD: `(Bid+Ask)/2` from `Fact_CurrencyPriceWithSplit`. (Tier 2 — SP_SAXO_Recon) |
| `SAXO_Rate` | decimal(16,6) | YES | SAXO's EOD rate from LP file. `CASE WHEN InstrumentCurrency='GBP' THEN EODRate/100 ELSE EODRate END` (GBX adjustment). (Tier 2 — SP_SAXO_Recon) |
| `eToro-SAXO_Rate` | decimal(16,6) | YES | eToro_Rate − SAXO_Rate. Rate discrepancy used to explain value differences. Special-character column. (Tier 2 — SP_SAXO_Recon) |
| `FX_Rate` | decimal(16,6) | YES | USD conversion rate used. ISNULL(eToro FXratetoUSD, SAXO InstrumentToAccountRate). (Tier 2 — SP_SAXO_Recon) |
| `UpdateDate` | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |
| `HedgeServerID` | int | YES | HedgeServer identifier. Predominant values: 35 (most rows, Stocks-Real), 128 (Employee accounts). Cross-references `Dealing_staging.External_Fivetran_dealing_active_hs_mappings`. (Tier 2 — SP_SAXO_Recon) |
| `UnrealisedValueAccount` | money | YES | Unrealised P&L value from SAXO LP file (`UnrealisedValueAccount` / `UnrealisedPLAccount`). Used for internal SAXO position health monitoring. (Tier 2 — SAXO LP file) |
| `UpperBoundary` | int | YES | Risk limit in USD (HedgeRiskLimitUSD). Above this, the instrument triggers risk alerts. From `External_Etoro_Hedge_InstrumentBoundaries`. (Tier 2 — SP_SAXO_Recon) |
| `LowerBoundary` | int | YES | Lower threshold in USD (-OpenThresholdUSD). Equal to -1000 for illiquid instruments. (Tier 2 — SP_SAXO_Recon) |
| `illiquid/liquid` | varchar(30) | YES | 'illiquid' when LowerBoundary = -1000 (OpenThreshold = 1000); 'liquid' otherwise. Special-character column. (Tier 2 — SP_SAXO_Recon) |
| `AccountNumber` | varchar(50) | YES | SAXO LP account number (e.g., '204400INETALM', '204400INET4'). From Fivetran mapping `lp_accounts` field. Identifies which SAXO sub-account holds the position. (Tier 2 — SP_SAXO_Recon) |
| `Exchange` | varchar(80) | YES | Stock exchange name (e.g., 'NASDAQ', 'NYSE'). ISNULL(eToro Dim_Instrument.Exchange, SAXO ExchangeDescription). (Tier 2 — SP_SAXO_Recon) |
| `MaxTradeDate` | int | YES | Maximum trade date in YYYYMMDD integer format. Latest SAXO LP TradeDate for this instrument/account. Indicates when last trade occurred. (Tier 2 — SAXO LP file) |
| `LastExecutionTime` | datetime | YES | Last execution timestamp from CopyFromLake.etoro_Hedge_ExecutionLog for this instrument × HS. (Tier 2 — SP_SAXO_Recon) |
| `Symbol` | varchar(20) | YES | Instrument ticker symbol (e.g., 'AAPL'). Added Feb 2025 (SR-301154). ISNULL(eToro, SAXO). (Tier 2 — SP_SAXO_Recon) |

---

## 5. Data Quality Notes

- **NULL InstrumentID rows**: SAXO-only instruments with no eToro mapping appear with NULL InstrumentID and no eToro/client data. These are "orphan SAXO positions".
- **GBX/GBP conversion**: UK stocks traded in pence (GBX) are normalized to GBP in eToro local amount (`/100`). SAXO rate also adjusted (`EODRate/100`) for GBP instruments.
- **eToro_AmounUSD typo**: The column `eToro_AmounUSD` (missing 't') is preserved from original DDL. Do NOT correct — downstream queries use this name.
- **Special-character columns**: `Buy/Sell`, `SAXO-eToro_Units`, `SAXO-Clients_Units`, `eToro-SAXO_Rate`, `illiquid/liquid` require bracket quoting in queries: `[Buy/Sell]`, `[SAXO-eToro_Units]`, etc.
- **Date staleness guard**: SP auto-adjusts `@Date` to `MAX(ReportingDate)` from SAXO LP file. If SAXO hasn't delivered a file for a given day, the previous day's data is used.
- **Fivetran dependency**: HedgeServer mapping requires `Dealing_staging.External_Fivetran_dealing_active_hs_mappings` to be current. SR-282189 (Nov 2024) changed from hardcoded HS/LA to Fivetran-based lookup.

---

## 6. Usage Notes

```sql
-- Latest date available
SELECT MAX([Date]) FROM Dealing_dbo.Dealing_SAXORecon_EODHoldings;

-- Active discrepancies (SAXO vs eToro > $1000)
SELECT [Date], InstrumentDisplayName, HedgeServerID,
       [Reality-Supposed], [SAXO-eToro_Units], [illiquid/liquid]
FROM Dealing_dbo.Dealing_SAXORecon_EODHoldings
WHERE [Date] = '2026-03-10'
  AND ABS([Reality-Supposed]) > 1000
ORDER BY ABS([Reality-Supposed]) DESC;

-- Filter out SAXO-only rows (no eToro mapping)
WHERE InstrumentID IS NOT NULL
```

**Performance**: ROUND_ROBIN distribution — queries scanning large date ranges may be slow. Always filter on `[Date]` (clustered index). Avoid cross-node aggregations by filtering to specific accounts/instruments first.

---

## 7. Known Issues

- `eToro_AmounUSD` column has a typo (missing 't') — preserved from original DDL, do not rename.
- Special-character column names (`Buy/Sell`, `SAXO-eToro_Units`, etc.) require bracket quoting.
- Date staleness guard may cause the SP to silently write prior-day data if SAXO LP file delivery is delayed.

---

## 8. Sources & Confidence

| Source | Phase | Confidence |
|--------|-------|------------|
| SSDT DDL (`Dealing_dbo.Dealing_SAXORecon_EODHoldings.sql`) | P1 | High |
| SP Logic (`Dealing_dbo.SP_SAXO_Recon.sql`) | P9 | High |
| Live data sample (Synapse MCP) | P2 | High |
| OpsDB orchestration | P9B | High |
| Atlassian knowledge scan | P10 | Not available (−3 quality) |

**Quality Score: 7.5/10** — Active table with well-understood ETL. Deducted: no Atlassian scan (−1), no upstream wiki for production lineage (−0.5), special-character columns add query complexity (−0.5), SAXO LP file dependency introduces external risk (−0.5).
