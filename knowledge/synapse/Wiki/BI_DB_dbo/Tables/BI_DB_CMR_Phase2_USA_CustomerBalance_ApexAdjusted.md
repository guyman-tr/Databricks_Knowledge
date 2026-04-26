# BI_DB_dbo.BI_DB_CMR_Phase2_USA_CustomerBalance_ApexAdjusted

> 46,000-row daily US customer balance cycle with Apex Clearing adjustments for FINRA regulatory reporting (CMR Phase 2). Pivots 40 metrics — including Apex-adjusted opening/closing balances, invested amount changes, P&L components, and four gap variants (Gap, GapTotal, GapFinra, GapNonFinra) — into long format for Finance's CMR automation Excel workbook. 1,149 distinct dates from 2022-01-01 to 2026-04-12; 40 rows per date. Source: BI_DB_Client_Balance_Aggregate_Level_New scoped to FinCEN/FinCEN+FINRA/eToroUS.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New` via `SP_CMR_Phase2_USA_CustomerBalance_ApexAdjusted` |
| **Refresh** | Daily (DELETE WHERE Date=@date + INSERT) |
| **OpsDB Priority** | 15 (SB_Daily, second-wave — depends on P0 CBCAN) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_CMR_Phase2_USA_CustomerBalance_ApexAdjusted` is the **US customer balance cycle sheet with Apex Clearing adjustments** for CMR Phase 2. It extends the global balance cycle (same structure as `BI_DB_CMR_Phase2_ClientBalance`) with Apex-specific adjustments required for FINRA-compliant reporting: real stock components held with Apex Clearing are separated from the cash/CFD balance cycle, and four gap metrics (Gap, GapTotal, GapFinra, GapNonFinra) isolate the FINRA vs non-FINRA reconciliation signals.

**Scope**: FinCEN, FinCEN+FINRA, and eToroUS regulations; `IsCreditReportValidCB = 1` only. Club <> 'Internal' filter is commented out in SP — all clubs included.

The 40 metrics in ExcelOrder sequence:

| ExcelOrder | Metric | Category |
|------------|--------|----------|
| 1 | OpeningBalanceAdjusted | Apex-adjusted opening (excl. real stocks for FinCEN+FINRA) |
| 2 | RealStockInvestedAmountChangeAdjusted | Net real stocks invested change (FinCEN+FINRA only) |
| 3–12 | Deposits, CompensationDeposit, UsedBonus, CompensationAdjusted, Compensation, CompensationPI, CompensationToAffiliate, NWAAdjustment, NegativeRefill, Cashouts | Standard inflows/outflows |
| 13–18 | TransferCoins, TransferCoinFees, CompensationCashouts, CashoutFee, Chargeback, Refund | Transfer and fee flows |
| 19–27 | ClientBalanceCommissionAdjusted, OvernightFee, DividendsPaid, LostDebt, ChargebackLoss, OtherNegatives, Foreclosure, CompensationPnLAdjustments, CompensationDormantFee | Commission, fees, losses |
| 28–30 | ClientBalanceRealizedPnLAdjusted, UnrealizedCommissionChangeAdjusted, UnrealizedPnLChangeAdjusted | Adjusted P&L components |
| 31–33 | NetTransfersNWA, NetTransfersUnrealizedPnL, NetTransfersLiability | Net transfers |
| 34 | ClosingBalanceAdjusted | Apex-adjusted closing (excl. real stocks for FinCEN+FINRA) |
| 35 | CycleCalculation | Transaction-flow-based balance (uses raw unadjusted columns) |
| 36 | ClosingBalanceCalculated | Balance-sheet-component estimate (EquityRealCrypto + EquityRealStocks + TotalCash + EquityCFD − TotalNegativeLiability + InProcessCashout − actualNWA + StockOrders) |
| 37 | Gap | ClosingBalance − CycleCalculation (unadjusted gap; $0 on 2026-04-12) |
| 38 | GapTotal | Gap + GapFinra ($89.5M on 2026-04-12) |
| 39 | GapFinra | SUM(RealStocksClosingBalance WHERE Regulation='FinCEN+FINRA') ($89.5M on 2026-04-12) |
| 40 | GapNonFinra | Gap excluding FINRA real stocks ($0 on 2026-04-12) |

Data spans 2022-01-01 to 2026-04-12 (1,149 distinct dates).

---

## 2. Business Logic

### 2.1 ETL Pattern — Two-Phase: Wide Staging then Long-Format Pivot

**What**: Two-phase processing: (1) wide Apex-adjusted staging in #temp, (2) 40-branch UNION ALL pivot to long format.
**Columns Involved**: All 6 columns
**Rules**:
1. Compute `@dateID = CAST(CONVERT(VARCHAR(8), @date, 112) AS INT)`
2. `CREATE TABLE #temp (HEAP, ROUND_ROBIN)`: SELECT from CBCAN WHERE `DateID = @dateID AND IsCreditReportValidCB = 1 AND Regulation IN ('FinCEN','FinCEN+FINRA','eToroUS')` — `Club <> 'Internal'` filter is commented out (all clubs included). GROUP BY all dimension keys. Pre-compute Apex-adjusted columns + Gap/GapFinra/GapNonFinra/ClosingBalanceCalculated
3. 40-branch UNION ALL pivot from #temp: each branch GROUPs BY Date, DateID, Regulation, IsCreditReportValidCB, Club and assigns hardcoded ExcelOrder + Metric
4. Outer `GROUP BY Date, DateID, ExcelOrder, Metric` — collapses Regulation/Club out of final output
5. `DELETE FROM BI_DB_CMR_Phase2_USA_CustomerBalance_ApexAdjusted WHERE Date = @date`
6. `INSERT INTO` from pivot SELECT

### 2.2 Apex Adjustments — FinCEN+FINRA Only

**What**: Five columns are pre-computed in #temp Phase 1 using CASE WHEN Regulation = 'FinCEN+FINRA' to subtract the Apex Clearing real-stocks component.
**Columns Involved**: MetricValue (ExcelOrders 1, 2, 6, 19, 28–30)
**Rules**:

| Adjusted Column | Formula (FinCEN+FINRA) | Passthrough (FinCEN / eToroUS) |
|-----------------|------------------------|-------------------------------|
| OpeningBalanceAdjusted | OpeningBalance − RealStocksOpeningBalance | OpeningBalance |
| ClosingBalanceAdjusted | ClosingBalance − RealStocksClosingBalance | ClosingBalance |
| CompensationAdjusted | Compensation − CompensationsApexUSStocks | Compensation |
| ClientBalanceCommissionAdjusted | ClientBalanceCommission − ClientBalanceCommissionRealStocks (only when FromRegulation ≠ Regulation) | ClientBalanceCommission |
| RealStockInvestedAmountChangeAdjusted | −1 × (TotalRealStocksEquityChange − UnrealizedPnLChangeStocksReal − ClientBalanceRealizedPnLRealStocks) | 0 |

### 2.3 Gap Metrics — Four Variants

**What**: Reconciliation signals computed in Phase 1 staging.
**Columns Involved**: MetricValue (ExcelOrders 37–40)
**Rules**:
- `Gap` (37): `ClosingBalance − CycleCalculation` (raw unadjusted; near zero = good reconciliation)
- `GapTotal` (38): `Gap + GapFinra`
- `GapFinra` (39): `SUM(CASE WHEN Regulation = 'FinCEN+FINRA' THEN RealStocksClosingBalance ELSE 0 END)` — the real stocks component held with Apex. On 2026-04-12: $89.5M
- `GapNonFinra` (40): same as Gap formula (redundant alias of Gap in current code)

### 2.4 ClosingBalanceCalculated (ExcelOrder 36)

**What**: Balance-sheet-component cross-check, independent of the transaction-flow CycleCalculation.
**Formula**: `EquityRealCrypto + EquityRealStocks + TotalCash + EquityCFD − TotalNegativeLiability + InProcessCashout − actualNWA + StockOrders`
On 2026-04-12: ClosingBalanceCalculated = CycleCalculation = $320.1M (CycleCalculation uses raw ClosingBalance in GAP formula; the two agree when all equity components are accounted for).

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN; CLUSTERED INDEX (DateID ASC). Small table (46K rows) — near-instantaneous full scans. DateID filter aligns with clustered index.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| US gap trend | `WHERE ExcelOrder IN (37,38,39,40) AND DateID >= 20260101 ORDER BY Date, ExcelOrder` |
| Full US balance cycle for a date | `WHERE DateID = @id ORDER BY ExcelOrder` |
| Opening-to-closing reconciliation | `MAX(CASE WHEN ExcelOrder = N THEN MetricValue END)` pivot across ExcelOrders 1, 34, 35, 36, 37 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|----------------|---------|
| BI_DB_CMR_Phase2_FinraGap | DateID | Compare Apex-adjusted US gap vs dedicated FINRA real stocks gap (ExcelOrder 39 ↔ FinraGap ExcelOrder 7) |
| BI_DB_CMR_Phase2_ClientBalance | DateID | Global vs US-only balance cycle comparison |

### 3.4 Gotchas

- **No Regulation/Club/PlayerStatus in output**: The pivot Phase 2 aggregates all segments into a single row per metric. The table gives totals across FinCEN + FinCEN+FINRA + eToroUS; to segment by regulation, use CBCAN directly.
- **GapNonFinra ≈ Gap**: In practice, GapNonFinra uses the same computation as Gap (unadjusted ClosingBalance − CycleCalculation) — the naming implies "Gap excluding FINRA real stocks," but the SP formula doesn't subtract GapFinra. Verify interpretation with Finance.
- **Duplicate date 2025-01-13**: Live data shows 80 rows for 2025-01-13 (expected 40). This indicates a double-load for that date. ETL logs should be checked; affected metrics should be aggregated with SUM/40 care.
- **IsCreditReportValidCB = 1 pre-applied**: No additional filter needed when querying.
- **Club <> 'Internal' commented out**: All clubs (including Internal) are included in the output. This differs from FinraGap which filters Club <> 'Internal'.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code analysis (source-to-target trace) |
| Tier 3 | Inferred from column name, type, and context |
| Tier 4 | Best-available knowledge, limited confidence |
| Tier 5 | Glossary/documentation only |
| Propagation | ETL metadata column (UpdateDate, InsertDate, etc.) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Reporting date for this row. GROUP BY passthrough from `BI_DB_Client_Balance_Aggregate_Level_New.Date` via #temp staging. Matches the @date parameter passed to SP_CMR_Phase2_USA_CustomerBalance_ApexAdjusted. (Tier 2 — SP_CMR_Phase2_USA_CustomerBalance_ApexAdjusted) |
| 2 | DateID | int | YES | Integer date key YYYYMMDD. GROUP BY passthrough from CBCAN. CLUSTERED INDEX key; primary filter for single-date queries. (Tier 2 — SP_CMR_Phase2_USA_CustomerBalance_ApexAdjusted) |
| 3 | ExcelOrder | int | YES | Ordinal metric position (1–40) matching the US/FINRA Apex-adjusted section column order in the CMR Phase 2 Excel report. Hardcoded per UNION ALL branch in SP Phase 2. (Tier 2 — SP_CMR_Phase2_USA_CustomerBalance_ApexAdjusted) |
| 4 | Metric | varchar(200) | YES | Named metric label. 40 distinct values from OpeningBalanceAdjusted (1) through GapNonFinra (40). Hardcoded string per UNION ALL branch. (Tier 2 — SP_CMR_Phase2_USA_CustomerBalance_ApexAdjusted) |
| 5 | MetricValue | decimal(38,8) | YES | Aggregate USD monetary value for the named metric on the reporting date, scoped to FinCEN/FinCEN+FINRA/eToroUS, IsCreditReportValidCB=1 (all clubs). SUM of Apex-adjusted column from #temp — Apex adjustments apply CASE WHEN Regulation='FinCEN+FINRA'. Gap metrics (ExcelOrder 37–40) are composite formulas. Opening/Closing balance on 2026-04-12: $236.4M/$230.5M (adjusted); GapFinra: $89.5M. (Tier 2 — SP_CMR_Phase2_USA_CustomerBalance_ApexAdjusted) |
| 6 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|----------------|--------------|---------------|-----------|
| Date | BI_DB_Client_Balance_Aggregate_Level_New | Date | GROUP BY passthrough via #temp |
| DateID | BI_DB_Client_Balance_Aggregate_Level_New | DateID | GROUP BY passthrough (= @dateID filter) |
| ExcelOrder | SP_CMR_Phase2_USA_CustomerBalance_ApexAdjusted | — | Hardcoded ordinal 1–40 per UNION ALL branch |
| Metric | SP_CMR_Phase2_USA_CustomerBalance_ApexAdjusted | — | Hardcoded metric name string per UNION ALL branch |
| MetricValue | BI_DB_Client_Balance_Aggregate_Level_New | OpeningBalance/ClosingBalance/Deposits/Compensation/… (varies per branch; 5 columns Apex-adjusted in #temp Phase 1) | ISNULL(SUM(adjusted_col), 0) per metric; Gap/GapFinra/GapNonFinra/ClosingBalanceCalculated are composite formulas |
| UpdateDate | SP_CMR_Phase2_USA_CustomerBalance_ApexAdjusted | — | GETDATE() at INSERT time |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New (P0, Done Batch 6)
  (filter: Regulation IN FinCEN/FinCEN+FINRA/eToroUS, IsCreditReportValidCB=1, DateID=@dateID)
  |-- SP_CMR_Phase2_USA_CustomerBalance_ApexAdjusted (@date, P15 Daily SB_Daily) --|
  |   Phase 1: #temp (HEAP, ROUND_ROBIN) — wide staging with Apex adjustments
  |     CASE WHEN Regulation='FinCEN+FINRA' THEN adjusted ELSE raw END for 5 columns
  |     + Gap, GapFinra, GapNonFinra, ClosingBalanceCalculated, CycleCalculation computed
  |   Phase 2: 40-branch UNION ALL pivot from #temp
  |     GROUP BY Date, DateID, ExcelOrder, Metric → SUM(MetricValue)
  |   DELETE WHERE Date=@date + INSERT
  v
BI_DB_dbo.BI_DB_CMR_Phase2_USA_CustomerBalance_ApexAdjusted (46,000 rows, 1,149 dates, 40 metrics/date)
  |-- UC Target: _Not_Migrated --|
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|----------------|-------------|
| MetricValue (all) | BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | Sole source; all 40 metrics are ISNULL(SUM(Apex-adjusted column), 0) from CBCAN scoped to US regulations |

### 6.2 Referenced By

| Object | Relationship |
|--------|-------------|
| BI_DB_dbo.BI_DB_CMR_Phase2_FinraGap | Sibling CMR Phase 2 — FINRA real stocks balance cycle (ExcelOrder 39 GapFinra maps to FinraGap metric 7) |
| BI_DB_dbo.BI_DB_CMR_Phase2_Finra_NonCash_Comps | Sibling CMR Phase 2 — CID-level FINRA non-cash corporate action events |
| BI_DB_dbo.BI_DB_CMR_Phase2_ClientBalance | Sibling CMR Phase 2 — global balance cycle (all regulations) |

---

## 7. Sample Queries

### Daily US Gap Trend (All 4 Variants)

```sql
SELECT Date,
  MAX(CASE WHEN ExcelOrder = 37 THEN MetricValue END) AS Gap,
  MAX(CASE WHEN ExcelOrder = 38 THEN MetricValue END) AS GapTotal,
  MAX(CASE WHEN ExcelOrder = 39 THEN MetricValue END) AS GapFinra,
  MAX(CASE WHEN ExcelOrder = 40 THEN MetricValue END) AS GapNonFinra
FROM BI_DB_dbo.BI_DB_CMR_Phase2_USA_CustomerBalance_ApexAdjusted
WHERE DateID >= 20260101
GROUP BY Date
ORDER BY Date;
```

### Full US Apex-Adjusted Balance Cycle for Most Recent Date

```sql
SELECT ExcelOrder, Metric, MetricValue
FROM BI_DB_dbo.BI_DB_CMR_Phase2_USA_CustomerBalance_ApexAdjusted
WHERE DateID = (SELECT MAX(DateID) FROM BI_DB_dbo.BI_DB_CMR_Phase2_USA_CustomerBalance_ApexAdjusted)
ORDER BY ExcelOrder;
```

### Opening vs Adjusted Closing vs Calculated Closing

```sql
SELECT Date,
  MAX(CASE WHEN ExcelOrder = 1  THEN MetricValue END) AS OpeningAdj,
  MAX(CASE WHEN ExcelOrder = 34 THEN MetricValue END) AS ClosingAdj,
  MAX(CASE WHEN ExcelOrder = 35 THEN MetricValue END) AS CycleCalc,
  MAX(CASE WHEN ExcelOrder = 36 THEN MetricValue END) AS ClosingCalc,
  MAX(CASE WHEN ExcelOrder = 39 THEN MetricValue END) AS GapFinra
FROM BI_DB_dbo.BI_DB_CMR_Phase2_USA_CustomerBalance_ApexAdjusted
WHERE DateID >= 20260101
GROUP BY Date
ORDER BY Date;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for BI_DB_CMR_Phase2_USA_CustomerBalance_ApexAdjusted. Domain knowledge inferred from SP code analysis, CMR Phase 2 sibling table context, and live data sampling.

---

*Generated: 2026-04-23 | Quality: 9.0/10 | Phases: 11/14*
*Tiers: 0 T1, 5 T2, 0 T3, 0 T4, 0 T5, 1 Propagation | Elements: 6/6, Logic: 9/10, ETL: 9/10, Data: 9/10*
*Object: BI_DB_dbo.BI_DB_CMR_Phase2_USA_CustomerBalance_ApexAdjusted | Type: Table | Production Source: BI_DB_Client_Balance_Aggregate_Level_New via SP_CMR_Phase2_USA_CustomerBalance_ApexAdjusted*
