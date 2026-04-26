# BI_DB_dbo.BI_DB_CMR_Phase2_FinraGap

> 17,193-row daily FINRA real stocks balance cycle reconciliation table for US FinCEN+FINRA-regulated customers holding Apex Clearing real stocks. Pivots 11 metrics (opening balance, invested amount change, Apex compensations, realized P&L, unrealized P&L, closing balance, gap, dividends, compensation types) into long format per day, 2022-01-01 to 2026-04-12 (1,563 dates). FinraGapBreakdownTotal (ExcelOrder 7) is the key daily reconciliation signal for FINRA regulatory reporting.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New` via `SP_CMR_Automation_Phase2_FinraGap` |
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

`BI_DB_CMR_Phase2_FinraGap` is the **daily FINRA real stocks balance cycle summary** for the CMR (Capital Management Reconciliation) Phase 2 Finance automation framework. It covers only US customers regulated under **FinCEN+FINRA** who hold real stocks through Apex Clearing, and tracks the opening/closing balance of those stock positions alongside all movements that should explain any change.

The 11 metrics form the FINRA real stocks balance equation:

| ExcelOrder | Metric | Role |
|------------|--------|------|
| 1 | RealStocksOpeningBalance | Starting position value ($1.98M–$96M range observed) |
| 2 | RealStocksInvestedAmountChangeExcAirdrops | Net capital deployed (buy/sell activity, excluding Apex airdrops) |
| 3 | CompensationsApexUSStocks(-) | Apex compensation deducted from net invested change (negated) |
| 4 | ClientBalanceRealizedPnLRealStocks | Realized gain/loss on real stock positions closed |
| 5 | UnrealizedPnLChangeStocksReal | Change in mark-to-market value of open real stock positions |
| 6 | RealStocksClosingBalance | Ending position value |
| 7 | FinraGapBreakdownTotal | Reconciliation gap — sum of items 1-6; observed range -5.26 to 18.12 (near-zero = fully reconciled) |
| 8 | DividendsPaid | Cash dividends paid on real stock holdings |
| 9 | Compensation | Total Apex compensation credits |
| 10 | CompensationAdjusted | Compensation excluding Apex US stock airdrop component |
| 11 | ApexAirdrops | Apex airdrop-type compensation component |

**FinraGapBreakdownTotal** (metric 7) is the key alert signal: a non-zero value flags unreconciled real stocks balance movements that Finance must investigate for FINRA regulatory reporting. Gap observed range: -5.26 to 18.12 USD (very tight, indicating good reconciliation). Filter: `Regulation='FinCEN+FINRA'`, `IsCreditReportValidCB=1`, `Club<>'Internal'`.

---

## 2. Business Logic

### 2.1 Vertical Pivot — 11 UNION ALL Branches from CBCAN

**What**: Each of the 11 UNION ALL branches in SP_CMR_Automation_Phase2_FinraGap reads from `BI_DB_Client_Balance_Aggregate_Level_New` (CBCAN) for a single date, applies the FinCEN+FINRA filter, and SUM-aggregates one or more CBCAN columns into a single MetricValue row.
**Columns Involved**: ExcelOrder, Metric, MetricValue
**Rules**:
- Branch 1: `SUM(RealStocksOpeningBalance)`
- Branch 2: `SUM(-1*(TotalRealStocksEquityChange - UnrealizedPnLChangeStocksReal - ClientBalanceRealizedPnLRealStocks)) + SUM(CompensationsApexUSStocks)`
- Branch 3: `-1 * SUM(CompensationsApexUSStocks)`
- Branch 4: `SUM(ClientBalanceRealizedPnLRealStocks)`
- Branch 5: `SUM(UnrealizedPnLChangeStocksReal)`
- Branch 6: `SUM(RealStocksClosingBalance)`
- Branch 7: Gap formula (see 2.2)
- Branch 8: `SUM(DividendsPaid)`
- Branch 9: `SUM(Compensation)`
- Branch 10: `SUM(Compensation - CompensationsApexUSStocks)`
- Branch 11: `SUM(CompensationsApexUSStocks)`

### 2.2 FinraGapBreakdownTotal Formula

**What**: ExcelOrder 7 is a balance-sheet identity check: Opening + Flows = Closing; any residual is the gap.
**Columns Involved**: MetricValue WHERE ExcelOrder=7
**Rules**:
```
GapValue = −1 × (
  SUM(RealStocksOpeningBalance)
  − (−1 × (TotalRealStocksEquityChange − UnrealizedPnLChangeStocksReal − ClientBalanceRealizedPnLRealStocks))
  + SUM(ClientBalanceRealizedPnLRealStocks)
  + SUM(UnrealizedPnLChangeStocksReal)
  + 0  -- dividends not included in this version
  − SUM(RealStocksClosingBalance)
)
```
- Near-zero = fully reconciled real stocks cycle
- Non-zero (>$5) = Finance investigation required

### 2.3 Scope Filters

**What**: Applied in the source query before aggregation.
**Columns Involved**: Regulation, IsCreditReportValidCB, Club (from CBCAN — not stored in this table)
**Rules**:
- Regulation: outer filter IN ('eToroUS','FinCEN','FinCEN+FINRA') AND effective scope 'FinCEN+FINRA'
- IsCreditReportValidCB = 1 — credit-valid accounts only
- Club <> 'Internal' — excludes internal/test accounts

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution; CLUSTERED INDEX on DateID. Small table (17K rows) — full scans are negligible. DateID filter aligns with the clustered index for efficient single-date retrieval.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily gap trend | `WHERE ExcelOrder = 7 AND DateID >= 20260101 ORDER BY Date` |
| Full balance cycle for a date | `WHERE DateID = @targetDateID ORDER BY ExcelOrder` |
| Balance vs prior day | Self-join on ExcelOrder 1 (Opening) = prior day ExcelOrder 6 (Closing) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|----------------|---------|
| BI_DB_CMR_Phase2_ClientBalance | DateID | Compare FINRA-specific gap vs all-regulation balance cycle |
| BI_DB_CMR_Phase2_Finra_NonCash_Comps | DateID | Reconcile non-cash corporate actions against ExcelOrder 8/9/10/11 |

### 3.4 Gotchas

- **No segmentation columns in output**: All regulation/IsCreditReportValidCB/Club filters are applied inside the SP; the table has only 6 columns, no Regulation or Club dimension.
- **11 rows per date exactly**: If querying a range, always GROUP BY or filter by ExcelOrder to avoid double-counting.
- **FinraGapBreakdownTotal includes 0 for dividends**: Note `+ 0 -- dividends adjusted separately` in SP code; DividendsPaid (branch 8) is a separate metric, not used in the gap formula.
- **SP named with 'Automation'**: `SP_CMR_Automation_Phase2_FinraGap` — sibling SPs for other CMR Phase 2 tables drop 'Automation' from the name (SP_CMR_Phase2_*).

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
| 1 | Date | date | YES | Reporting date for this row. Passthrough from `BI_DB_Client_Balance_Aggregate_Level_New.Date` (GROUP BY key). Matches the @date parameter passed to SP_CMR_Automation_Phase2_FinraGap. (Tier 2 — SP_CMR_Automation_Phase2_FinraGap) |
| 2 | DateID | int | YES | Integer date key YYYYMMDD. Passthrough from CBCAN. Used as CLUSTERED INDEX key; primary filter for single-date queries. (Tier 2 — SP_CMR_Automation_Phase2_FinraGap) |
| 3 | ExcelOrder | int | YES | Ordinal metric position (1–11) matching the FINRA real stocks section column order in the CMR Phase 2 Excel report. Hardcoded per UNION ALL branch in SP. (Tier 2 — SP_CMR_Automation_Phase2_FinraGap) |
| 4 | Metric | varchar(200) | YES | Named metric label. 11 distinct values: RealStocksOpeningBalance, RealStocksInvestedAmountChangeExcAirdrops, CompensationsApexUSStocks(-), ClientBalanceRealizedPnLRealStocks, UnrealizedPnLChangeStocksReal, RealStocksClosingBalance, FinraGapBreakdownTotal, DividendsPaid, Compensation, CompensationAdjusted, ApexAirdrops. Hardcoded string per UNION ALL branch. (Tier 2 — SP_CMR_Automation_Phase2_FinraGap) |
| 5 | MetricValue | decimal(38,8) | YES | Aggregate USD monetary value for the named metric on the reporting date. SUM of one or more real-stocks columns from BI_DB_Client_Balance_Aggregate_Level_New scoped to Regulation='FinCEN+FINRA', IsCreditReportValidCB=1, Club<>'Internal'. ExcelOrder 7 is a composite gap formula; all others are direct SUM aggregations. (Tier 2 — SP_CMR_Automation_Phase2_FinraGap) |
| 6 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|----------------|--------------|---------------|-----------|
| Date | BI_DB_Client_Balance_Aggregate_Level_New | Date | GROUP BY passthrough |
| DateID | BI_DB_Client_Balance_Aggregate_Level_New | DateID | GROUP BY passthrough |
| ExcelOrder | SP_CMR_Automation_Phase2_FinraGap | — | Hardcoded ordinal per UNION ALL branch |
| Metric | SP_CMR_Automation_Phase2_FinraGap | — | Hardcoded metric name string per UNION ALL branch |
| MetricValue | BI_DB_Client_Balance_Aggregate_Level_New | RealStocksOpeningBalance / TotalRealStocksEquityChange / UnrealizedPnLChangeStocksReal / ClientBalanceRealizedPnLRealStocks / RealStocksClosingBalance / CompensationsApexUSStocks / DividendsPaid / Compensation (varies by branch) | SUM aggregation with optional sign inversion per metric |
| UpdateDate | SP_CMR_Automation_Phase2_FinraGap | — | GETDATE() at INSERT time |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New (P0, Done Batch 6)
  (filter: Regulation='FinCEN+FINRA', IsCreditReportValidCB=1, Club<>'Internal', DateID=@dateID)
  |-- SP_CMR_Automation_Phase2_FinraGap (@date, P15 Daily SB_Daily) --|
  |   11-branch UNION ALL pivot → #finragap temp table
  |   DELETE WHERE Date=@date + INSERT
  v
BI_DB_dbo.BI_DB_CMR_Phase2_FinraGap (17,193 rows, 1,563 dates)
  |-- UC Target: _Not_Migrated --|
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|----------------|-------------|
| MetricValue (all) | BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | Sole source; all 11 metrics are SUMs of CBCAN real-stocks columns scoped to FinCEN+FINRA |

### 6.2 Referenced By

| Object | Relationship |
|--------|-------------|
| BI_DB_dbo.BI_DB_CMR_Phase2_Finra_NonCash_Comps | Sibling CMR Phase 2 FINRA table — CID-level non-cash compensations |
| BI_DB_dbo.BI_DB_CMR_Phase2_USA_CustomerBalance_ApexAdjusted | Sibling CMR Phase 2 — US Apex-adjusted balance cycle |
| BI_DB_dbo.BI_DB_CMR_Phase2_ClientBalance | Parent CMR Phase 2 — global balance cycle (all regulations, includes FinCEN+FINRA rows) |

---

## 7. Sample Queries

### Daily FINRA Gap Trend

```sql
SELECT Date, MetricValue AS FinraGap
FROM BI_DB_dbo.BI_DB_CMR_Phase2_FinraGap
WHERE ExcelOrder = 7
  AND DateID >= 20260101
ORDER BY Date;
```

### Full FINRA Balance Cycle for Most Recent Date

```sql
SELECT ExcelOrder, Metric, MetricValue
FROM BI_DB_dbo.BI_DB_CMR_Phase2_FinraGap
WHERE DateID = (SELECT MAX(DateID) FROM BI_DB_dbo.BI_DB_CMR_Phase2_FinraGap)
ORDER BY ExcelOrder;
```

### Opening vs Prior Day Closing (Gap Sanity Check)

```sql
SELECT t.Date, t.MetricValue AS Opening, prev.MetricValue AS PriorClosing,
       t.MetricValue - prev.MetricValue AS Diff
FROM BI_DB_dbo.BI_DB_CMR_Phase2_FinraGap t
JOIN BI_DB_dbo.BI_DB_CMR_Phase2_FinraGap prev
  ON t.DateID > prev.DateID
  AND prev.ExcelOrder = 6
WHERE t.ExcelOrder = 1
  AND t.DateID >= 20260101
ORDER BY t.Date;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for BI_DB_CMR_Phase2_FinraGap. Domain knowledge inferred from SP code analysis and CMR Phase 2 sibling table context.

---

*Generated: 2026-04-23 | Quality: 9.1/10 | Phases: 11/14*
*Tiers: 0 T1, 5 T2, 0 T3, 0 T4, 0 T5, 1 Propagation | Elements: 6/6, Logic: 9/10, ETL: 9/10, Data: 9/10*
*Object: BI_DB_dbo.BI_DB_CMR_Phase2_FinraGap | Type: Table | Production Source: BI_DB_Client_Balance_Aggregate_Level_New via SP_CMR_Automation_Phase2_FinraGap*
