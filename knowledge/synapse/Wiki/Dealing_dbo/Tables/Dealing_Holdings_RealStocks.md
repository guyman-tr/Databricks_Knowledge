# Dealing_dbo.Dealing_Holdings_RealStocks

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_Holdings_RealStocks |
| **Type** | Table |
| **ETL SP** | `Dealing_dbo.SP_Holdings_RealStocks` |
| **Refresh** | Daily (SB_Daily, Priority 0) |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on `[Date]` |
| **Rows** | ~12.2M |
| **Date Range** | 2021-10-01 → 2026-03-10 (active) |
| **PII** | none |

---

## 1. Business Meaning

Daily EOD holdings snapshot for **BNY Mellon reporting** — the total net position (in units and USD value) held by eToro for each instrument across all Real Stocks and CFD hedge servers. Each row represents one instrument × settlement type (`IsSettled`) on a given date.

`IsSettled='Real'` captures positions from Real hedge servers (HS 3, 9, 102, 128, 112, 125, 126) — these are the actual stock holdings settled via BNY Mellon. `IsSettled='CFD'` captures CFD-style hedge servers (HS 2, 101, 129) — contracts for difference positions.

The table is used by the Dealing desk to report total holdings to BNY Mellon (the custodian for eToro's real stock positions). `Units` represents the net position (positive = long, negative = short). `Amount_USD` is the USD market value at EOD prices.

---

## 2. Business Logic

- **Position reconstruction**: Point-in-time snapshot using temporal netting tables. `etoro_Hedge_Netting` (current) UNION `etoro_History_Netting_History` (historical). Filter: `UpdateTime < @Date+1` (current) or `SysEndTime ≥ @Date+1 AND SysStartTime < @Date+1` (historical).
- **HS classification**: HedgeServerID IN (3,9,102,128,112,125,126) → `IsSettled='Real'`; IN (2,101,129) → `IsSettled='CFD'`.
- **NOP computation**: `SUM((2*IsBuy-1)*Units)` per instrument × IsSettled. Positive = net long.
- **EOD pricing**: `Fact_CurrencyPriceWithSplit.Bid` for Buy positions, `.Ask` for Sell positions at `OccurredDateID=@DateID`.
- **USD conversion**: Multi-step FX chain:
  - If SellCurrencyID=1 (USD): ConversionRate=1
  - If BuyCurrencyID=1: `1 / (Bid or Ask)`
  - If neither is USD: `COALESCE(1/r1.Bid_or_Ask, r2.Bid_or_Ask, 1)` (cross-currency)
- **Amount_USD**: `SUM((2*IsBuy-1) × Units × EOD_Price × ConversionRate)`.
- **DELETE+INSERT by Date**: Accumulating table.

---

## 3. Relationships

| Direction | Table | Join Key | Notes |
|-----------|-------|----------|-------|
| Source | `Dealing_staging.etoro_Hedge_Netting` | `InstrumentID, HedgeServerID` | Current hedge netting positions |
| Source | `Dealing_staging.etoro_History_Netting_History` | `InstrumentID, HedgeServerID` | Historical hedge netting (temporal) |
| Source | `DWH_dbo.Dim_Instrument` | `InstrumentID` | Instrument metadata (ISIN, display name) |
| Source | `DWH_dbo.Fact_CurrencyPriceWithSplit` | `InstrumentID, OccurredDateID` | EOD prices and FX rates |

---

## 4. Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | date | YES | Date of the holdings snapshot. Clustered index. (Tier 2 — SP_Holdings_RealStocks) |
| `InstrumentID` | int | YES | eToro instrument ID. (Tier 2 — SP_Holdings_RealStocks) |
| `InstrumentDisplayName` | varchar(100) | YES | Instrument display name from Dim_Instrument. (Tier 2 — SP_Holdings_RealStocks) |
| `ISIN` | varchar(50) | YES | ISIN code from Dim_Instrument (stored as `ISINCode` in source, renamed to `ISIN` here). (Tier 2 — SP_Holdings_RealStocks) |
| `Units` | decimal(16,6) | YES | Net position in units: `SUM((2*IsBuy-1)*Units)`. Positive=long, negative=short. Aggregated across all HS in the IsSettled group. (Tier 2 — SP_Holdings_RealStocks) |
| `Amount_USD` | decimal(16,6) | YES | Net position USD market value: `SUM((2*IsBuy-1)*Units*EOD_Price*ConversionRate)`. EOD price from Fact_CurrencyPriceWithSplit (Bid for Buy, Ask for Sell). (Tier 2 — SP_Holdings_RealStocks) |
| `UpdateDate` | datetime | YES | ETL metadata: `GETDATE()` at SP execution time. |
| `IsSettled` | varchar(50) | YES | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |

---

## 5. Data Quality Notes

- **BNY Mellon report**: Primary use case is reporting total holdings to BNY Mellon custodian. `IsSettled='Real'` rows are the custodian-relevant ones.
- **Temporal reconstruction**: Uses `etoro_Hedge_Netting` + `etoro_History_Netting_History` union to ensure correct EOD snapshot. The time boundary is `< @Date+1` (i.e., up to but not including midnight of the next day).
- **HS set hardcoded**: HedgeServer IDs (3,9,102,128,112,125,126 for Real; 2,101,129 for CFD) are hardcoded. If new hedge servers are added, the SP must be updated.
- **Amount_USD uses Bid/Ask EOD prices**: Unlike SAXO recon which uses LP rates, this table uses eToro's internal Fact_CurrencyPriceWithSplit prices. May differ from SAXO/broker prices.
- **ISIN column name**: The DDL column is named `ISIN` (not `ISINCode` like most other tables). Note when joining.

---

## 6. Usage Notes

```sql
-- Latest date available
SELECT MAX([Date]) FROM Dealing_dbo.Dealing_Holdings_RealStocks;

-- Total BNY Mellon Real holdings by date
SELECT [Date], SUM(Amount_USD) AS Total_Amount_USD, COUNT(DISTINCT InstrumentID) AS Instruments
FROM Dealing_dbo.Dealing_Holdings_RealStocks
WHERE IsSettled = 'Real'
  AND [Date] = '2026-03-10'
GROUP BY [Date];

-- Top 20 instruments by USD value
SELECT InstrumentDisplayName, ISIN, Units, Amount_USD
FROM Dealing_dbo.Dealing_Holdings_RealStocks
WHERE [Date] = '2026-03-10'
  AND IsSettled = 'Real'
ORDER BY ABS(Amount_USD) DESC;
```

---

## 7. Known Issues

- HedgeServer IDs are hardcoded — requires SP update if new HS accounts are added.
- ISIN column named `ISIN` (not `ISINCode`) — inconsistent with other Dealing schema tables.

---

## 8. Sources & Confidence

| Source | Phase | Confidence |
|--------|-------|------------|
| SSDT DDL (`Dealing_dbo.Dealing_Holdings_RealStocks.sql`) | P1 | High |
| SP Logic (`Dealing_dbo.SP_Holdings_RealStocks.sql`) | P9 | High |
| Live data sample (Synapse MCP) | P2 | High |
| OpsDB orchestration | P9B | High |
| Atlassian knowledge scan | P10 | Not available (−3 quality) |

**Quality Score: 8.0/10** — Active table with straightforward, fully-documented ETL. Deducted: no Atlassian scan (−1), hardcoded HS set (−0.5), ISIN column naming inconsistency (−0.5).
