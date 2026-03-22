# DWH_dbo.V_Liabilities

> Daily customer liabilities view combining equity snapshots (`Fact_SnapshotEquity`) with unrealized PnL (`Fact_CustomerUnrealized_PnL`) to compute **ActualNWA** (credit-capped net worth), **Liabilities** (customer obligations to the platform), **WA_Liabilities** (credit-covered portion), and asset-class breakdowns — the central view for regulatory balance reporting, dormant fee calculations, AML monitoring, and client balance dashboards.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | View |
| **Source Tables** | Fact_SnapshotEquity (a), V_M2M_Date_DateRange (b), Fact_CustomerUnrealized_PnL (c), Fact_Guru_Copiers (gc — dead join) |
| **Key Identifier** | CID + DateID |
| **Output Columns** | 75 (T1: 63, T2: 12) |
| **UC Table** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities` |
| **Data Scope** | All dates **before today** (`DateKey < CAST(CONVERT(VARCHAR(MAX),GETDATE(),112) AS INT)`) |
| **Generated** | 2026-03-22 |

---

## 1. Business Meaning

`V_Liabilities` is the platform's primary view for computing what eToro owes each customer (liabilities) and how much of the customer's balance is "real" vs promotional credit.

**Core formula** — let `NetEquity = TotalPositionsAmount + TotalCash + TotalStockOrders + PositionPnL`:
- **ActualNWA** (Non-Withdrawable Amount): The portion of NetEquity covered by BonusCredit. Clamped to `[0, BonusCredit]`. If the customer's NetEquity exceeds their BonusCredit, ActualNWA = BonusCredit. If NetEquity goes negative, ActualNWA = 0.
- **Liabilities**: InProcessCashouts + the portion of NetEquity **above** BonusCredit. This is what eToro owes the customer — real money, not promotional credit.
- **Balance**: Liabilities + ActualNWA = RealizedEquity + PositionPnL (Confluence: "Summary of V-Liabilities")

**Business context** (from Confluence):
- "If clients lose money, their Actual NWA will reflect only what's left. A client has $1000, loses $200 → Actual NWA = $800. When they profit back to $2000 → Actual NWA = $1000 and Liabilities show $1000 bonus credit."
- The view excludes today's date because end-of-day snapshots (FSE + FCUPNL) must both be loaded before the view is meaningful.

**Key consumers**: SP_DDR_Fact_AUM, SP_Client_Balance_New, SP_Client_Balance_Breakdown, SP_Q_AML_EDD_US_Report, SP_Q_AML_FSA_Report, SP_AML_PI_Abuse, SP_AML_BI_Alerts_New_Singapore, SP_CIDFirstDates, SP_CID_DailyPanel_FullData, SP_CID_MonthlyPanel_FullData, SP_MarketingCloudDaily, SP_Copyfunds_SignificantAllocation, SP_Fact_RegulationTransfer, SP_TIN_Gap, SP_BI_DB_W8_Users_Status, SP_BI_DB_CO_Cluster_Daily, SP_IR_Dashboard_Monitor_Checks, SP_OPS_MultipleAccounts, SP_Q_QSR_New.

---

## 2. Business Logic

### 2.1 Join Structure

```
Fact_SnapshotEquity a                   -- daily equity snapshot per CID
  JOIN V_M2M_Date_DateRange b           -- expands DateRangeID → one row per calendar day (DateKey)
    ON a.DateRangeID = b.DateRangeID
  LEFT JOIN Fact_CustomerUnrealized_PnL c  -- daily PnL snapshot per CID
    ON a.CID = c.CID AND b.DateKey = c.DateModified
  LEFT JOIN Fact_Guru_Copiers gc        -- DEAD JOIN: no columns selected (Boris Slutski, 2021-01-11)
    ON a.CID = gc.CID AND b.DateKey = gc.DateID
WHERE b.DateKey < today
```

### 2.2 Computed Column Formulas

All computed columns use a common intermediate value:

```
NetEquity = ISNULL(TotalPositionsAmount, 0) + ISNULL(TotalCash, 0)
          + ISNULL(TotalStockOrders, 0) + ISNULL(PositionPnL, 0)
```

Note: `TotalStockOrders` is a legacy column hardcoded to 0 since 2019 (see Fact_SnapshotEquity wiki). Its presence in the formula is a historical artifact — it does not affect computation.

| Column | Formula |
|--------|---------|
| **ActualNWA** | `CASE WHEN NetEquity > BonusCredit THEN BonusCredit WHEN NetEquity < 0 THEN 0 ELSE NetEquity END` |
| **Liabilities** | `InProcessCashouts + CASE WHEN NetEquity - BonusCredit > 0 THEN NetEquity - BonusCredit WHEN NetEquity < 0 THEN NetEquity ELSE 0 END` |
| **WA_Liabilities** | `MIN(Liabilities_excl_cashouts, Credit)` — the portion of liabilities coverable by credit |
| **Liabilities_InUsedMargin** | `MAX(Liabilities_excl_cashouts - Credit, 0)` — liabilities exceeding available credit |
| **LiabilitiesStockReal** | `ISNULL(PositionPnLStocksReal, 0) + ISNULL(TotalRealStocks, 0)` |
| **LiabilitiesCryptoReal** | `ISNULL(PositionPnLCryptoReal, 0) + ISNULL(TotalRealCrypto, 0)` |
| **LiabilitiesCrypto_TRS** | `ISNULL(CryptoPositionPnL_TRS, 0) + ISNULL(Total_TRSCrypto, 0)` |
| **LiabilitiesFuturesReal** | `ISNULL(PositionPnLFuturesReal, 0) + ISNULL(TotalRealFutures, 0)` |
| **TotalStockManualPosition** | `TotalStockPositionAmount + TotalStockOrders - TotalMirrorStockPositionAmount` |
| **ManualStockPositionPnL** | `StocksPositionPnL - MirrorStocksPositionPnL` |
| **TotalCryptoManualPosition** | `TotalCryptoPositionAmount - TotalMirrorCryptoPositionAmount` |
| **TotalCryptoManualPosition_TRS** | `TotalCryptoPositionAmount_TRS - TotalMirrorCryptoPositionAmount_TRS` |

---

## 3. Source Objects

| Object | Schema | Alias | Role |
|--------|--------|-------|------|
| Fact_SnapshotEquity | DWH_dbo | a | Equity balances, cash, positions, AUM, credit |
| V_M2M_Date_DateRange | DWH_dbo | b | Expands DateRangeID to per-day rows (DateKey, FullDate) |
| Fact_CustomerUnrealized_PnL | DWH_dbo | c | Unrealized PnL, NOP, notional, commissions, risk |
| Fact_Guru_Copiers | DWH_dbo | gc | **Dead join** — no columns selected. LEFT JOIN preserved from 2021, can be removed. |

---

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | CID | Fact_SnapshotEquity.CID | Direct | T1 |
| 2 | DateID | V_M2M_Date_DateRange.DateKey | Direct (alias DateKey → DateID) | T1 |
| 3 | FullDate | V_M2M_Date_DateRange.FullDate | Direct | T1 |
| 4 | RealizedEquity | Fact_SnapshotEquity.RealizedEquity | Direct | T1 |
| 5 | TotalPositionsAmount | Fact_SnapshotEquity.TotalPositionsAmount | Direct | T1 |
| 6 | TotalCash | Fact_SnapshotEquity.TotalCash | Direct | T1 |
| 7 | InProcessCashouts | Fact_SnapshotEquity.InProcessCashouts | Direct | T1 |
| 8 | TotalMirrorPositionsAmount | Fact_SnapshotEquity.TotalMirrorPositionsAmount | Direct | T1 |
| 9 | TotalMirrorCash | Fact_SnapshotEquity.TotalMirrorCash | Direct | T1 |
| 10 | TotalStockOrders | Fact_SnapshotEquity.TotalStockOrders | Direct (legacy — always 0 since 2019) | T1 |
| 11 | TotalMirrorStockOrders | Fact_SnapshotEquity.TotalMirrorStockOrders | Direct (legacy — always 0 since 2019) | T1 |
| 12 | Credit | Fact_SnapshotEquity.Credit | Direct | T1 |
| 13 | AUM | Fact_SnapshotEquity.AUM | Direct | T1 |
| 14 | BonusCredit | Fact_SnapshotEquity.BonusCredit | Direct | T1 |
| 15 | TotalStockPositionAmount | Fact_SnapshotEquity.TotalStockPositionAmount | Direct | T1 |
| 16 | TotalMirrorStockPositionAmount | Fact_SnapshotEquity.TotalMirrorStockPositionAmount | Direct | T1 |
| 17 | PositionPnL | Fact_CustomerUnrealized_PnL.PositionPnL | Direct | T1 |
| 18 | CopyPositionPnL | Fact_CustomerUnrealized_PnL.CopyPositionPnL | Direct | T1 |
| 19 | StandardDeviation | Fact_CustomerUnrealized_PnL.StandardDeviation | Direct | T1 |
| 20 | CommissionOnOpen | Fact_CustomerUnrealized_PnL.CommissionOnOpen | Direct | T1 |
| 21 | ActualNWA | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | CASE WHEN NetEquity > BonusCredit THEN BonusCredit WHEN NetEquity < 0 THEN 0 ELSE NetEquity END. NetEquity = ISNULL(TotalPositionsAmount,0) + ISNULL(TotalCash,0) + ISNULL(TotalStockOrders,0) + ISNULL(PositionPnL,0) | T2 |
| 22 | Liabilities | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | ISNULL(InProcessCashouts,0) + CASE WHEN NetEquity - BonusCredit > 0 THEN NetEquity - BonusCredit WHEN NetEquity < 0 THEN NetEquity ELSE 0 END | T2 |
| 23 | WA_Liabilities | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | MIN(Liabilities_excl_cashouts, Credit) — credit-capped liabilities | T2 |
| 24 | Liabilities_InUsedMargin | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | MAX(Liabilities_excl_cashouts - Credit, 0) — liabilities beyond credit | T2 |
| 25 | StocksPositionPnL | Fact_CustomerUnrealized_PnL.StocksPositionPnL | Direct | T1 |
| 26 | TotalStockManualPosition | Fact_SnapshotEquity | TotalStockPositionAmount + TotalStockOrders - TotalMirrorStockPositionAmount | T2 |
| 27 | ManualStockPositionPnL | Fact_CustomerUnrealized_PnL | StocksPositionPnL - MirrorStocksPositionPnL | T2 |
| 28 | MirrorStocksPositionPnL | Fact_CustomerUnrealized_PnL.MirrorStocksPositionPnL | Direct | T1 |
| 29 | CryptoPositionPnL | Fact_CustomerUnrealized_PnL.CryptoPositionPnL | Direct | T1 |
| 30 | ManualCryptoPositionPnL | Fact_CustomerUnrealized_PnL.ManualCryptoPositionPnL | Direct | T1 |
| 31 | CopyCryptoPositionPnL | Fact_CustomerUnrealized_PnL.CopyCryptoPositionPnL | Direct | T1 |
| 32 | TotalCryptoPositionAmount | Fact_SnapshotEquity.TotalCryptoPositionAmount | Direct | T1 |
| 33 | TotalCryptoManualPosition | Fact_SnapshotEquity | TotalCryptoPositionAmount - TotalMirrorCryptoPositionAmount | T2 |
| 34 | CopyFundAUM | Fact_SnapshotEquity.CopyFundAUM | Direct | T1 |
| 35 | CopyFundPnL | Fact_CustomerUnrealized_PnL.CopyFundPnL | Direct | T1 |
| 36 | NOP | Fact_CustomerUnrealized_PnL.NOP | Direct | T1 |
| 37 | Notional | Fact_CustomerUnrealized_PnL.Notional | Direct | T1 |
| 38 | NOP_Crypto | Fact_CustomerUnrealized_PnL.NOP_Crypto | Direct | T1 |
| 39 | Notional_Crypto | Fact_CustomerUnrealized_PnL.Notional_Crypto | Direct | T1 |
| 40 | NOP_CFD | Fact_CustomerUnrealized_PnL.NOP_CFD | Direct | T1 |
| 41 | Notional_CFD | Fact_CustomerUnrealized_PnL.Notional_CFD | Direct | T1 |
| 42 | NOP_Crypto_CFD | Fact_CustomerUnrealized_PnL.NOP_Crypto_CFD | Direct | T1 |
| 43 | Notional_Crypto_CFD | Fact_CustomerUnrealized_PnL.Notional_Crypto_CFD | Direct | T1 |
| 44 | PositionPnLStocksReal | Fact_CustomerUnrealized_PnL.PositionPnLStocksReal | Direct | T1 |
| 45 | PositionPnLCryptoReal | Fact_CustomerUnrealized_PnL.PositionPnLCryptoReal | Direct | T1 |
| 46 | TotalRealStocks | Fact_SnapshotEquity.TotalRealStocks | Direct | T1 |
| 47 | TotalRealCrypto | Fact_SnapshotEquity.TotalRealCrypto | Direct | T1 |
| 48 | LiabilitiesStockReal | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | ISNULL(PositionPnLStocksReal, 0) + ISNULL(TotalRealStocks, 0) | T2 |
| 49 | LiabilitiesCryptoReal | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | ISNULL(PositionPnLCryptoReal, 0) + ISNULL(TotalRealCrypto, 0) | T2 |
| 50 | CommissionByUnitsCrypto_TRS | Fact_CustomerUnrealized_PnL.CommissionByUnitsCrypto_TRS | Direct | T1 |
| 51 | CopyCryptoPositionPnL_TRS | Fact_CustomerUnrealized_PnL.CopyCryptoPositionPnL_TRS | Direct | T1 |
| 52 | CryptoPositionPnL_TRS | Fact_CustomerUnrealized_PnL.CryptoPositionPnL_TRS | Direct | T1 |
| 53 | FullCommissionByUnitsCrypto_TRS | Fact_CustomerUnrealized_PnL.FullCommissionByUnitsCrypto_TRS | Direct | T1 |
| 54 | ManualCryptoPositionPnL_TRS | Fact_CustomerUnrealized_PnL.ManualCryptoPositionPnL_TRS | Direct | T1 |
| 55 | NOP_Crypto_TRS | Fact_CustomerUnrealized_PnL.NOP_Crypto_TRS | Direct | T1 |
| 56 | Notional_Crypto_TRS | Fact_CustomerUnrealized_PnL.Notional_Crypto_TRS | Direct | T1 |
| 57 | Total_TRSCrypto | Fact_SnapshotEquity.Total_TRSCrypto | Direct | T1 |
| 58 | TotalCryptoPositionAmount_TRS | Fact_SnapshotEquity.TotalCryptoPositionAmount_TRS | Direct | T1 |
| 59 | TotalCryptoManualPosition_TRS | Fact_SnapshotEquity | TotalCryptoPositionAmount_TRS - TotalMirrorCryptoPositionAmount_TRS | T2 |
| 60 | LiabilitiesCrypto_TRS | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | ISNULL(CryptoPositionPnL_TRS, 0) + ISNULL(Total_TRSCrypto, 0) | T2 |
| 61 | MirrorRealFuturesPositionPnL | Fact_CustomerUnrealized_PnL.MirrorRealFuturesPositionPnL | Direct | T1 |
| 62 | ManualRealFuturesPositionPnL | Fact_CustomerUnrealized_PnL.ManualRealFuturesPositionPnL | Direct | T1 |
| 63 | NOP_FuturesReal | Fact_CustomerUnrealized_PnL.NOP_FuturesReal | Direct | T1 |
| 64 | Notional_FuturesReal | Fact_CustomerUnrealized_PnL.Notional_FuturesReal | Direct | T1 |
| 65 | PositionPnLFuturesReal | Fact_CustomerUnrealized_PnL.PositionPnLFuturesReal | Direct | T1 |
| 66 | FullCommissionByUnitsFuturesReal | Fact_CustomerUnrealized_PnL.FullCommissionByUnitsFuturesReal | Direct | T1 |
| 67 | CommissionByUnitsFuturesReal | Fact_CustomerUnrealized_PnL.CommissionByUnitsFuturesReal | Direct | T1 |
| 68 | TotalMirrorRealFuturesPositionAmount | Fact_SnapshotEquity.TotalMirrorRealFuturesPositionAmount | Direct | T1 |
| 69 | TotalRealFutures | Fact_SnapshotEquity.TotalRealFutures | Direct | T1 |
| 70 | TotalFuturesProviderMargin | Fact_SnapshotEquity.TotalFuturesProviderMargin | Direct | T1 |
| 71 | LiabilitiesFuturesReal | Fact_SnapshotEquity, Fact_CustomerUnrealized_PnL | ISNULL(PositionPnLFuturesReal, 0) + ISNULL(TotalRealFutures, 0) | T2 |
| 72 | NOP_StocksMargin | Fact_CustomerUnrealized_PnL.NOP_StocksMargin | Direct | T1 |
| 73 | PositionPnLStocksMargin | Fact_CustomerUnrealized_PnL.PositionPnLStocksMargin | Direct | T1 |
| 74 | TotalStocksMargin | Fact_SnapshotEquity.TotalStocksMargin | Direct | T1 |
| 75 | TotalStockMarginLoanValue | Fact_SnapshotEquity.TotalStockMarginLoanValue | Direct | T1 |

---

## 5. Query Advisory

- **Always filter by DateID** — the view contains the full history of daily snapshots. Unfiltered queries are expensive.
- **Balance formula**: `Liabilities + ActualNWA` or equivalently `ISNULL(RealizedEquity,0) + ISNULL(PositionPnL,0)` (Confluence)
- **TotalCash decomposition**: `TotalCash = Credit + TotalMirrorCash` (Confluence)
- **Today's data is excluded** — the WHERE clause filters `DateKey < today`. This is by design; use yesterday's date.
- **LEFT JOIN to FCUPNL**: PnL columns will be NULL for CIDs with no open positions on a given date. Use ISNULL when aggregating.

---

## 6. Relationships

### 6.1 Upstream Sources

| Source | Join Key | Columns Contributed |
|--------|----------|-------------------|
| Fact_SnapshotEquity | CID + DateRangeID → V_M2M_Date_DateRange | Equity, cash, positions, credit, AUM, asset-class amounts (32 columns) |
| Fact_CustomerUnrealized_PnL | CID + DateModified = DateKey | PnL, NOP, notional, commissions, risk (31 columns) |
| V_M2M_Date_DateRange | DateRangeID | DateKey (→ DateID), FullDate |

### 6.2 Downstream Consumers (20+ SPs)

| SP | Schema | Usage Pattern |
|----|--------|---------------|
| SP_DDR_Fact_AUM | BI_DB_dbo | AUM dashboard aggregation |
| SP_Client_Balance_New | BI_DB_dbo | Customer balance reporting |
| SP_Client_Balance_Breakdown | BI_DB_dbo | Detailed balance decomposition |
| SP_Q_AML_EDD_US_Report | BI_DB_dbo | AML enhanced due diligence (US) |
| SP_Q_AML_FSA_Report | BI_DB_dbo | AML FSA regulatory report |
| SP_AML_PI_Abuse | BI_DB_dbo | Popular Investor abuse detection |
| SP_AML_BI_Alerts_New_Singapore | BI_DB_dbo | AML alerts (Singapore) |
| SP_Fact_RegulationTransfer | DWH_dbo | Regulation transfer processing |
| SP_Fact_CustomerUnrealized_PnL | DWH_dbo | Uses equity from FSE for risk weights |
| SP_CIDFirstDates | BI_DB_dbo | First date tracking per CID |
| SP_MarketingCloudDaily | BI_DB_dbo | Marketing data feed |
| SP_Copyfunds_SignificantAllocation | BI_DB_dbo | Copy fund allocation analysis |
| SP_Q_QSR_New | BI_DB_dbo | QSR regulatory report |
| SP_TIN_Gap | BI_DB_dbo | TIN gap analysis |
| SP_CID_DailyPanel_FullData | BI_DB_dbo | Daily customer panel |
| SP_CID_MonthlyPanel_FullData | BI_DB_dbo | Monthly customer panel |
| SP_BI_DB_CO_Cluster_Daily | BI_DB_dbo | Cashout clustering |
| SP_BI_DB_W8_Users_Status | BI_DB_dbo | W8 tax form status |
| SP_IR_Dashboard_Monitor_Checks | BI_DB_dbo | IR dashboard monitoring |
| SP_OPS_MultipleAccounts | BI_DB_dbo | Multiple account detection |
| SP_M_Affiliates_FraudMonitoring | BI_DB_dbo | Affiliate fraud monitoring |

---

## 7. Sample Queries

```sql
-- Customer balance for yesterday
SELECT CID, DateID,
       Liabilities + ActualNWA AS Balance,
       Liabilities, ActualNWA, Credit,
       RealizedEquity, PositionPnL
FROM DWH_dbo.V_Liabilities
WHERE DateID = CAST(CONVERT(CHAR(8), GETDATE()-1, 112) AS INT)
  AND CID = 12345;

-- Platform total liabilities trend (last 7 days)
SELECT DateID,
       SUM(Liabilities) AS TotalLiabilities,
       SUM(ActualNWA) AS TotalNWA,
       SUM(Liabilities) + SUM(ActualNWA) AS TotalBalance,
       COUNT(DISTINCT CID) AS Customers
FROM DWH_dbo.V_Liabilities
WHERE DateID >= CAST(CONVERT(CHAR(8), GETDATE()-8, 112) AS INT)
GROUP BY DateID
ORDER BY DateID;
```

---

## 8. Atlassian Knowledge Sources

| Source | Key Information |
|--------|-----------------|
| Summary of V-Liabilities (Confluence/BI) | Authoritative business definitions: Balance = Liabilities + ActualNWA = RealizedEquity + PositionPnL. BonusCredit examples. TotalCash = Credit + TotalMirrorCash. |
| BI Dictionary (Confluence/BI) | "V_Liabilities: a view that summarizes or exposes customer liabilities, such as negative balances, equity, Position PnL, etc." |
| DDR Tables (Confluence) | "BI_DB_DDR_Fact_AUM is the same as V_Liabilities table (daily snapshot per user)" — notes equivalence for equity/AUM |
| Azure Data Platform Projects (Confluence/BDP) | Lists V_Liabilities as a Gold-tier replicated asset |
| PNL flow (Confluence/BDP) | V_Liabilities as downstream consumer of PnL pipeline |
| Dormant Fee (Confluence/REGTECH) | Uses V_Liabilities.Liabilities and Credit for dormant fee eligibility |
| Credit Line COs (Confluence/OTS) | NWA / Credit Line rules: "Credit Line × 3 = AAA; Equity - AAA = what can be CO" |

---
*Generated: 2026-03-22 | Quality: 9.2/10*
*Tiers: 63 T1, 12 T2, 0 T3, 0 T4 | Phases: 1,5,7,8,10,11*
