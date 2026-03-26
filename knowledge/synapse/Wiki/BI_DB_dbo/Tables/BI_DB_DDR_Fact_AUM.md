# BI_DB_dbo.BI_DB_DDR_Fact_AUM

> 7.4B-row DDR Assets Under Management fact table — daily per-customer snapshot of equity, invested amounts, NOP, PnL, and credit breakdowns across Trading Platform, CopyTrading, manual stocks/crypto, IBAN (eMoney), and Options (Apex), providing a unified AUM view for the Daily Data Report framework.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Fact — DDR daily AUM snapshot) |
| **Production Source** | Derived — multi-source aggregate via `SP_DDR_Fact_AUM` from `BI_DB_Client_Balance_CID_Level_New`, `V_Liabilities`, `eMoneyClientBalance`, `Function_AUM_OptionsPlatform` |
| **Refresh** | Daily — `DELETE WHERE DateID = @dateID` + `INSERT` per business date |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_DDR_Fact_AUM` is the **Assets Under Management fact table** for the DDR (Daily Data Report) framework. It stores one row per customer (`RealCID`) per calendar day, capturing the complete equity and balance picture across **all eToro platforms**: Trading Platform (TP), CopyTrading, manual stocks, manual crypto, IBAN/eMoney, and Options (Apex).

The table was created in July 2024 by Guy Manova to power the new DDR dashboard framework. It aggregates data from four distinct sources:
1. **`BI_DB_Client_Balance_CID_Level_New`** — core TP balance metrics (realized equity, liabilities, NOP, bonus, position PnL)
2. **`DWH_dbo.V_Liabilities`** — copy equity, manual stock/crypto equity breakdowns, credit, ActualNWA
3. **`eMoney_dbo.eMoneyClientBalance`** — IBAN balance (non-TP cash held in eMoney accounts)
4. **`Function_AUM_OptionsPlatform`** — Options platform equity from Apex buy-power summary

Sources are joined via `FULL OUTER JOIN` on CID so customers present on any platform are included. Zero-equity global rows are excluded. Historical data spans from 2007-10-01 to present, with ~7.4 billion rows across ~6.7M distinct CIDs.

**ETL**: `SP_DDR_Fact_AUM` runs daily at Priority 60 in the SB_Daily Service Broker process. It deletes and reinserts rows for a single `@dateID`.

---

## 2. Business Logic

### 2.1 Multi-Platform Equity Aggregation

**What**: Combines equity from four platforms into a unified per-CID daily snapshot.

**Columns Involved**: All 40 columns; key merge columns: `RealCID`, `DateID`

**Rules**:
- TP equity columns come from `BI_DB_Client_Balance_CID_Level_New` (aggregated by CID/DateID with SUM)
- Copy/stock/crypto breakdowns come from `V_Liabilities` (joined on CID + DateID)
- IBAN balance from `eMoneyClientBalance` (SUM of ClosingBalanceBO × USDApproxRate per CID)
- Options equity from `Function_AUM_OptionsPlatform` (latest available Apex date ≤ @dateID)
- FULL OUTER JOIN ensures customers with only IBAN or only Options balances are included

### 2.2 Global vs TP Metrics

**What**: "Global" columns aggregate across all platforms; "TP" columns are Trading Platform only.

**Columns Involved**: `RealizedEquityTP`, `RealizedEquityGlobal`, `TotalLiabilityTP`, `TotalLiabilityGlobal`, `TotalEquityTP`, `EquityGlobal`, `CreditTP`, `CreditGlobal`

**Rules**:
- `RealizedEquityGlobal = RealizedEquityTP + IBANBalance` (Options excluded — cannot differentiate invested vs PnL)
- `TotalLiabilityGlobal = TotalLiabilityTP + IBANBalance + OptionsTotalEquity`
- `EquityGlobal = TotalEquityTP + IBANBalance + OptionsTotalEquity`
- `CreditGlobal = CreditTP + IBANBalance + OptionsCashEquity` (uses cash component of options, not total)

### 2.3 Equity Compartments (Copy, Manual Stocks, Manual Crypto)

**What**: Breaks equity into copy-trade vs manual components for stocks and crypto.

**Columns Involved**: `CashInCopy`, `CopyInvestedAmount`, `EquityCopy`, `StockInvestedAmount`, `EquityStocksManual`, `InvestedAmountCryptoManual`, `EquityCryptoManual`

**Rules**:
- Copy equity = mirror cash + mirror positions + mirror stock orders + copy PnL
- Manual stock equity = total stock positions + stock orders + stock PnL − mirror stock positions − mirror stock PnL
- Manual crypto equity = manual crypto position amount + manual crypto PnL

### 2.4 Zero-Equity Exclusion

**What**: Rows with zero global equity are filtered out to prevent table inflation.

**Rules**:
- Primary filter: `WHERE NOT (EquityGlobal = 0)`
- Secondary UNION catches TP-zero customers with non-zero individual components (NOP, realized equity, etc.)
- Null RealCID rows are deleted post-insert

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, HASH(RealCID) with CLUSTERED COLUMNSTORE. Always filter on `DateID` and/or `RealCID` for optimal performance. Date-range queries without RealCID filter will scan the full columnstore segment.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total AUM for a date | `SELECT SUM(EquityGlobal) FROM BI_DB_DDR_Fact_AUM WHERE DateID = @dateID` |
| Customer balance breakdown | `WHERE RealCID = @cid AND DateID = @dateID` — one row per CID per day |
| AUM trend over time | `SELECT DateID, SUM(EquityGlobal) GROUP BY DateID` — filter date range |
| IBAN vs TP split | Compare `TotalEquityTP` vs `IBANBalance` vs `OptionsTotalEquity` per CID |
| Copy vs manual stock equity | Compare `EquityCopy` vs `EquityStocksManual` per CID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | RealCID | Customer attributes, country, regulation |
| DWH_dbo.Dim_Date | DateID | Calendar attributes (week, month, quarter) |
| BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status | RealCID + DateID | Customer segmentation flags for DDR |
| BI_DB_dbo.BI_DB_V_DDR_AUM | — | View on top of this table with DDR aggregation |

### 3.4 Gotchas

- **One row per CID per day** — no multi-row grain unlike DDR_Fact_PnL. Safe to use directly without GROUP BY.
- **Global vs TP naming**: `*TP` = Trading Platform only; `*Global` = TP + IBAN + Options. Options excluded from `RealizedEquityGlobal` because options cannot distinguish invested from PnL.
- **IBAN balance is USD-converted**: `SUM(ClosingBalanceBO × USDApproxRate)` — approximate FX rate, not spot.
- **Options date lag**: Options equity uses the latest available Apex date ≤ @dateID, which may lag by 1+ days.
- **Historical data starts 2007**: Pre-DDR data was backfilled; DDR framework created July 2024.
- **Null RealCID rows**: Deleted post-insert, but interim queries during ETL may encounter them.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 — upstream wiki (V_Liabilities) | (Tier 1 — V_Liabilities) |
| ★★★ | Tier 2 — Synapse SP code | (Tier 2 — SP_DDR_Fact_AUM) |
| ★★ | Tier 3 — live data | (Tier 3 — sampling) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Real customer ID. COALESCE(cb.CID, i.CID, ob.RealCID) across TP, IBAN, and Options sources. HASH distribution key. (Tier 2 — SP_DDR_Fact_AUM) |
| 2 | DateID | int | YES | Business date as YYYYMMDD integer. Delete/replace key for the daily load. CAST(CONVERT(VARCHAR(8), @date, 112) AS INT). (Tier 2 — SP_DDR_Fact_AUM) |
| 3 | Date | date | YES | Calendar date for the batch — equals parameter `@date` in SP_DDR_Fact_AUM. (Tier 2 — SP_DDR_Fact_AUM) |
| 4 | RealizedEquityTP | decimal(16,6) | YES | Trading Platform realized equity. SUM(realizedEquity) from BI_DB_Client_Balance_CID_Level_New per CID/DateID. (Tier 2 — SP_DDR_Fact_AUM) |
| 5 | TotalLiabilityTP | decimal(16,6) | YES | Trading Platform total liability. SUM(TotalLiability) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 — SP_DDR_Fact_AUM) |
| 6 | InProcessCashout | decimal(16,6) | YES | TP in-process cashout amount. SUM(InProcessCashout) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 — SP_DDR_Fact_AUM) |
| 7 | NOP | decimal(16,6) | YES | Net Open Position — total notional exposure. SUM(NOP) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 — SP_DDR_Fact_AUM) |
| 8 | NOPCrypto | decimal(16,6) | YES | NOP for crypto positions. SUM(NOPCrypto) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 — SP_DDR_Fact_AUM) |
| 9 | NOPCryptoCFD | decimal(16,6) | YES | NOP for crypto CFD positions. SUM(NOPCryptoCFD) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 — SP_DDR_Fact_AUM) |
| 10 | NOPStocks | decimal(16,6) | YES | NOP for stock positions. SUM(NOPStocks) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 — SP_DDR_Fact_AUM) |
| 11 | NOPStocksCFD | decimal(16,6) | YES | NOP for stock CFD positions. SUM(NOPStocksCFD) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 — SP_DDR_Fact_AUM) |
| 12 | TotalRealCryptoLoan | decimal(16,6) | YES | Real crypto loan amount. SUM(TotalRealCryptoLoan) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 — SP_DDR_Fact_AUM) |
| 13 | TotalPositionPNL | decimal(16,6) | YES | Total position PnL (renamed from PositionPNL). SUM(PositionPNL) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 — SP_DDR_Fact_AUM) |
| 14 | TotalInvestedAmount | decimal(16,6) | YES | Total invested amount (renamed from PositionAmount). SUM(PositionAmount) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 — SP_DDR_Fact_AUM) |
| 15 | TotalEquityTP | decimal(16,6) | YES | Trading Platform total equity. SUM(ISNULL(TotalLiability,0) + ISNULL(actualNWA,0)) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 — SP_DDR_Fact_AUM) |
| 16 | Bonus | decimal(16,6) | YES | Promotional bonus amount. SUM(Bonus) from BI_DB_Client_Balance_CID_Level_New. (Tier 2 — SP_DDR_Fact_AUM) |
| 17 | CashInCopy | decimal(16,6) | YES | Cash allocated to copy trades. From V_Liabilities.TotalMirrorCash — total mirror cash held by copiers. (Tier 1 — DWH_dbo.V_Liabilities) |
| 18 | CopyInvestedAmount | decimal(16,6) | YES | Invested amount in copy trades. From V_Liabilities.TotalMirrorPositionsAmount — total mirror position amount. (Tier 1 — DWH_dbo.V_Liabilities) |
| 19 | CopyStockOrders | decimal(16,6) | YES | Stock orders within copy trades. From V_Liabilities.TotalMirrorStockOrders (legacy — always 0 since 2019). (Tier 1 — DWH_dbo.V_Liabilities) |
| 20 | CopyPositionPnL | decimal(16,6) | YES | Unrealized PnL on copy positions. From V_Liabilities.CopyPositionPnL via Fact_CustomerUnrealized_PnL. (Tier 1 — DWH_dbo.V_Liabilities) |
| 21 | EquityCopy | decimal(16,6) | YES | Total copy equity. TotalMirrorCash + TotalMirrorPositionsAmount + TotalMirrorStockOrders + CopyPositionPnL from V_Liabilities. (Tier 2 — SP_DDR_Fact_AUM) |
| 22 | InvestedAmountCopy | decimal(16,6) | YES | Invested amount in copy (excl cash). TotalMirrorPositionsAmount + TotalMirrorStockOrders + CopyPositionPnL from V_Liabilities. (Tier 2 — SP_DDR_Fact_AUM) |
| 23 | StockInvestedAmount | decimal(16,6) | YES | Total stock position amount. From V_Liabilities.TotalStockPositionAmount via Fact_SnapshotEquity. (Tier 1 — DWH_dbo.V_Liabilities) |
| 24 | StockOrders | decimal(16,6) | YES | Total stock orders. From V_Liabilities.TotalStockOrders via Fact_SnapshotEquity (legacy — always 0 since 2019). (Tier 1 — DWH_dbo.V_Liabilities) |
| 25 | StocksPositionPnL | decimal(16,6) | YES | Unrealized PnL on stock positions. From V_Liabilities.StocksPositionPnL via Fact_CustomerUnrealized_PnL. (Tier 1 — DWH_dbo.V_Liabilities) |
| 26 | MirrorStockInvestedAmount | decimal(16,6) | YES | Stock position amount in copy trades. From V_Liabilities.TotalMirrorStockPositionAmount via Fact_SnapshotEquity. (Tier 1 — DWH_dbo.V_Liabilities) |
| 27 | MirrorStocksPositionPnL | decimal(16,6) | YES | Stock PnL in copy trades. From V_Liabilities.MirrorStocksPositionPnL via Fact_CustomerUnrealized_PnL. (Tier 1 — DWH_dbo.V_Liabilities) |
| 28 | EquityStocksManual | decimal(16,6) | YES | Manual (non-copy) stock equity. TotalStockPositionAmount + TotalStockOrders + StocksPositionPnL − TotalMirrorStockPositionAmount − MirrorStocksPositionPnL. (Tier 2 — SP_DDR_Fact_AUM) |
| 29 | InvestedAmountStocksManual | decimal(16,6) | YES | Manual stock invested amount (excl PnL). TotalStockPositionAmount + TotalStockOrders − TotalMirrorStockPositionAmount. (Tier 2 — SP_DDR_Fact_AUM) |
| 30 | InvestedAmountCryptoManual | decimal(16,6) | YES | Manual crypto invested amount. From V_Liabilities.TotalCryptoManualPosition (= TotalCryptoPositionAmount − TotalMirrorCryptoPositionAmount). (Tier 1 — DWH_dbo.V_Liabilities) |
| 31 | CryptoManualPositionPnL | decimal(16,6) | YES | Manual crypto unrealized PnL. From V_Liabilities.ManualCryptoPositionPnL via Fact_CustomerUnrealized_PnL. (Tier 1 — DWH_dbo.V_Liabilities) |
| 32 | EquityCryptoManual | decimal(16,6) | YES | Manual crypto total equity. TotalCryptoManualPosition + ManualCryptoPositionPnL from V_Liabilities. (Tier 2 — SP_DDR_Fact_AUM) |
| 33 | TotalRealCrypto | decimal(16,6) | YES | Total real (non-CFD) crypto position amount. From V_Liabilities.TotalRealCrypto via Fact_SnapshotEquity. (Tier 1 — DWH_dbo.V_Liabilities) |
| 34 | TotalRealStocks | decimal(16,6) | YES | Total real (non-CFD) stock position amount. From V_Liabilities.TotalRealStocks via Fact_SnapshotEquity. (Tier 1 — DWH_dbo.V_Liabilities) |
| 35 | CreditTP | decimal(16,6) | YES | Trading Platform credit (promotional). From V_Liabilities.Credit via Fact_SnapshotEquity. Renamed from Credit. (Tier 1 — DWH_dbo.V_Liabilities) |
| 36 | ActualNWA | decimal(16,6) | YES | Non-Withdrawable Amount — credit-capped net worth. From V_Liabilities.ActualNWA: CASE WHEN NetEquity > BonusCredit THEN BonusCredit WHEN NetEquity < 0 THEN 0 ELSE NetEquity END. (Tier 1 — DWH_dbo.V_Liabilities) |
| 37 | IBANBalance | decimal(16,6) | YES | IBAN (eMoney) balance in USD. SUM(ClosingBalanceBO × USDApproxRate) from eMoney_dbo.eMoneyClientBalance for the date. Excludes GCID=0 and NULL GCID. (Tier 2 — SP_DDR_Fact_AUM) |
| 38 | RealizedEquityGlobal | decimal(16,6) | YES | Global realized equity. RealizedEquityTP + IBANBalance. Options excluded because options cannot differentiate invested vs PnL. (Tier 2 — SP_DDR_Fact_AUM) |
| 39 | TotalLiabilityGlobal | decimal(16,6) | YES | Global total liability. TotalLiabilityTP + IBANBalance + OptionsTotalEquity. (Tier 2 — SP_DDR_Fact_AUM) |
| 40 | EquityGlobal | decimal(16,6) | YES | Global total equity across all platforms. TotalEquityTP + IBANBalance + OptionsTotalEquity. (Tier 2 — SP_DDR_Fact_AUM) |
| 41 | CreditGlobal | decimal(16,6) | YES | Global credit. CreditTP + IBANBalance + OptionsCashEquity. Uses options cash component (not total). (Tier 2 — SP_DDR_Fact_AUM) |
| 42 | UpdateDate | datetime | YES | ETL load timestamp — GETDATE() at insert time. (Tier 2 — SP_DDR_Fact_AUM) |
| 43 | OptionsTotalEquity | decimal(18,6) | YES | Options platform total equity from Apex buy-power summary. From Function_AUM_OptionsPlatform → External_Sodreconciliation_apex_EXT981_BuyPowerSummary.TotalEquity. Uses latest available Apex date ≤ @dateID. Excludes house accounts (4GS43999, 4GS00100-104). (Tier 2 — SP_DDR_Fact_AUM) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column Group | Production Source | Columns | Transform |
|---------------------|-------------------|---------|-----------|
| TP balance metrics (cols 4-16) | BI_DB_Client_Balance_CID_Level_New | realizedEquity, TotalLiability, InProcessCashout, NOP*, Bonus, PositionPNL, PositionAmount | SUM per CID/DateID |
| Copy/stock/crypto breakdown (cols 17-36) | DWH_dbo.V_Liabilities | TotalMirrorCash, TotalMirrorPositionsAmount, StocksPositionPnL, TotalRealCrypto, Credit, ActualNWA, etc. | Passthrough or computed |
| IBAN balance (col 37) | eMoney_dbo.eMoneyClientBalance | ClosingBalanceBO × USDApproxRate | SUM per CID |
| Options equity (col 43) | Function_AUM_OptionsPlatform → External_Sodreconciliation_apex_EXT981_BuyPowerSummary | TotalEquity | TVF with customer mapping |
| Global aggregates (cols 38-41) | Multi-source | TP + IBAN + Options components | ETL-computed formulas |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New (daily, P99)
  |
DWH_dbo.V_Liabilities (view on Fact_SnapshotEquity + Fact_CustomerUnrealized_PnL)
  |
eMoney_dbo.eMoneyClientBalance (daily eMoney balance)
  |
Function_AUM_OptionsPlatform(@dateID, 0) → External_Sodreconciliation_apex_EXT981_BuyPowerSummary
  |
  +-- FULL OUTER JOIN on CID --|
  v
SP_DDR_Fact_AUM(@date) [Priority 60, SB_Daily]
  |-- DELETE WHERE DateID = @dateID
  |-- INSERT from #final (excludes zero EquityGlobal + null RealCID)
  v
BI_DB_dbo.BI_DB_DDR_Fact_AUM (7.4B rows, 2007-present)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension — demographics, regulation, account type |
| DateID | DWH_dbo.Dim_Date | Calendar dimension — week, month, quarter, year |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.BI_DB_V_DDR_AUM | — | DDR view on top of this fact for aggregation functions |
| BI_DB_dbo.SP_MarketingCloudDaily | BI_DB_DDR_Fact_AUM | Marketing cloud daily push references AUM data |
| BI_DB_dbo.SP_RevenueForum | BI_DB_DDR_Fact_AUM | Revenue forum report references AUM data |
| BI_DB_dbo.SP_AML_KYC_Process | BI_DB_DDR_Fact_AUM | AML/KYC monitoring references customer AUM |

---

## 7. Sample Queries

### 7.1 Total platform AUM for a specific date

```sql
SELECT SUM(EquityGlobal) AS TotalAUM_Global,
       SUM(TotalEquityTP) AS TotalAUM_TP,
       SUM(IBANBalance) AS TotalAUM_IBAN,
       SUM(OptionsTotalEquity) AS TotalAUM_Options
FROM BI_DB_dbo.BI_DB_DDR_Fact_AUM
WHERE DateID = 20260309
```

### 7.2 Customer AUM breakdown across platforms

```sql
SELECT RealCID,
       TotalEquityTP AS TP_Equity,
       EquityCopy AS Copy_Equity,
       EquityStocksManual AS ManualStocks_Equity,
       EquityCryptoManual AS ManualCrypto_Equity,
       IBANBalance AS IBAN_Equity,
       OptionsTotalEquity AS Options_Equity,
       EquityGlobal AS Total_Global
FROM BI_DB_dbo.BI_DB_DDR_Fact_AUM
WHERE RealCID = @cid AND DateID = @dateID
```

### 7.3 AUM trend by month with customer count

```sql
SELECT DateID / 100 AS YearMonth,
       COUNT(DISTINCT RealCID) AS Customers,
       SUM(EquityGlobal) AS TotalAUM
FROM BI_DB_dbo.BI_DB_DDR_Fact_AUM
WHERE DateID BETWEEN 20260101 AND 20260309
  AND DateID % 100 = 1  -- first of month
GROUP BY DateID / 100
ORDER BY YearMonth
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. The DDR framework is primarily documented via SP headers and internal engineering documentation by Guy Manova.

---

*Generated: 2026-03-26 | Quality: 8.5/10 (★★★★☆) | Phases: 13/14*
*Tiers: 12 T1, 31 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_DDR_Fact_AUM | Type: Table | Production Source: SP_DDR_Fact_AUM (multi-source)*
