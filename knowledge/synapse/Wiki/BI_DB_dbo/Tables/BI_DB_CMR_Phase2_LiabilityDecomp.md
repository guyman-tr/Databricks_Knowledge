# BI_DB_dbo.BI_DB_CMR_Phase2_LiabilityDecomp

> 423,009-row daily client money liability decomposition for EU and ASIC regulatory jurisdictions (CySEC, BVI, NFA, None, ASIC, ASIC & GAML), segmented by Regulation × PlayerStatus. Pivots 9 liability metrics (Total, Negative, Closing, Withdrawable, Used Margin, In-Process Cashouts and their negative counterparts) into long format for the CMR Phase 2 Finance automation report. 1,218 distinct dates from 2022-01-01 to 2026-04-12. Source: BI_DB_Client_Balance_Aggregate_Level_New (IsCreditReportValidCB=1).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New` via `SP_CMR_Phase2_LiabilityDecomp` |
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

`BI_DB_CMR_Phase2_LiabilityDecomp` is the **daily client money liability breakdown** for the CMR Phase 2 Finance automation framework, covering EU and ASIC regulated jurisdictions. It answers: "How is client money liability composed today, and how is it distributed across regulatory regions and account statuses?"

Client money liability represents the amount eToro owes to customers — their aggregate balances that must be segregated and held safely in accordance with regulatory requirements. Decomposing this liability into components (total, withdrawable, in margin, in-process cashouts) and separating negative (deficit) positions from positive ones is required for regulatory reporting under CySEC, ASIC, and similar regimes.

The 9 metrics (in long-format pivot):

| ExcelOrder | Metric | Most Recent Total (2026-04-12) |
|------------|--------|-------------------------------|
| 1 | Total Liability | $9.17B |
| 2 | Negative Total Liability | −$5.96M |
| 3 | Closing Balace (typo) | $9.18B |
| 4 | Withdrawable Liability | $1.11B |
| 5 | Negative Withdrawable Liability | −$5.98M |
| 6 | Liability In Used Margin | $8.06B (dominant component) |
| 7 | NegativeLiabilityInUsedMargin | $26.9K (stored positive — see §3.4) |
| 8 | In Process Cashouts | $6.06M |
| 9 | NegativeInProcessCashout | $0 (zero on latest date) |

Segmented by 6 Regulation values (ASIC & GAML, CySEC, BVI, ASIC, NFA, None) and 9 PlayerStatus values (Trade & MIMO Blocked 54,882 rows; Normal 51,057 rows; etc.) with `IsCreditReportValidCB = 1` filter. Total: 423,009 rows across 1,218 distinct dates (2022-01-01 to 2026-04-12).

---

## 2. Business Logic

### 2.1 ETL Pattern — DELETE + INSERT from CBCAN

**What**: Idempotent daily refresh — 9-branch UNION ALL pivot from CBCAN filtered to EU/ASIC scope.
**Columns Involved**: All 8 columns
**Rules**:
1. Compute `@dateID = CAST(CONVERT(VARCHAR(8), @date, 112) AS INT)`
2. Build `#temp` (HEAP, ROUND_ROBIN): 9 UNION ALL branches, each reading CBCAN WHERE `DateID = @dateID`
3. Outer filter on `#temp`: `Regulation IN ('CySEC','BVI','NFA','None','ASIC','ASIC & GAML') AND IsCreditReportValidCB = 1`
4. `GROUP BY Date, DateID, ExcelOrder, Metric, Regulation, PlayerStatus → SUM(MetricValue)`
5. `DELETE FROM BI_DB_CMR_Phase2_LiabilityDecomp WHERE Date = @date`
6. `INSERT INTO ... SELECT * FROM #temp`

### 2.2 Metric Definitions — 9-Branch UNION ALL

**What**: Each branch hardcodes ExcelOrder and Metric string, then aggregates the corresponding CBCAN liability column.
**Columns Involved**: ExcelOrder, Metric, MetricValue
**Rules**:

| Branch | ExcelOrder | Metric (hardcoded) | Source Column (CBCAN) |
|--------|------------|---------------------|----------------------|
| 1 | 1 | 'Total Liability' | `ISNULL(SUM(TotalLiability), 0)` |
| 2 | 2 | 'Negative Total Liability' | `ISNULL(SUM(TotalNegativeLiability), 0)` |
| 3 | 3 | 'Closing Balace' | `ISNULL(SUM(ClosingBalance), 0)` |
| 4 | 4 | 'Withdrawable Liability' | `ISNULL(SUM(WithdrawableLiability), 0)` |
| 5 | 5 | 'Negative Withdrawable Liability' | `ISNULL(SUM(NegativeWithdrawableLiability), 0)` |
| 6 | 6 | 'Liability In Used Margin' | `ISNULL(SUM(LiabilityInUsedMargin), 0)` |
| 7 | 7 | 'NegativeLiabilityInUsedMargin' | `ISNULL(SUM(NegativeLiabilityInUsedMargin), 0)` |
| 8 | 8 | 'In Process Cashouts' | `ISNULL(SUM(InProcessCashout), 0)` |
| 9 | 9 | 'NegativeInProcessCashout' | `ISNULL(SUM(NegativeInProcessCashout), 0)` |

### 2.3 Regulation Scope — EU and ASIC Only

**What**: Outer WHERE on the #temp aggregation restricts to EU and ASIC jurisdictions.
**Columns Involved**: Regulation
**Rules**:
- Included: CySEC (EU), BVI (EU), NFA (EU/non-US), None (unclassified), ASIC (Australia), ASIC & GAML (Australia + GAML)
- Excluded: FCA, FinCEN, FinCEN+FINRA, eToroUS — covered by US-specific CMR Phase 2 tables

### 2.4 PlayerStatus Filter — All Statuses Included

**What**: The SP contains a commented-out PlayerStatus restriction, resulting in all 9 statuses being included.
**Columns Involved**: PlayerStatus
**Rules**:
```sql
-- AND PlayerStatus in ('Blocked', 'Blocked Upon Request', 'Pending Verification', 'Block Deposit & Trading')
```
All 9 observed statuses: Trade & MIMO Blocked, Blocked, Normal, Block Deposit & Trading, Blocked Upon Request, Pending Verification, Warning, Deposit Blocked, Copy Block.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN; CLUSTERED INDEX (DateID ASC). Moderate table (423K rows) — DateID filter aligns with clustered index for efficient single-date retrieval.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total liability by regulation for a date | `WHERE ExcelOrder = 1 AND DateID = @id GROUP BY Regulation` |
| Liability breakdown for one segment | `WHERE DateID = @id AND Regulation = 'CySEC' AND PlayerStatus = 'Normal' ORDER BY ExcelOrder` |
| Blocked account liability trend | `WHERE ExcelOrder = 1 AND PlayerStatus IN ('Blocked', 'Blocked Upon Request') AND DateID >= 20260101` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|----------------|---------|
| BI_DB_CMR_Phase2_ClientBalance | DateID | Compare EU/ASIC liability slice vs all-regulation balance |
| BI_DB_CMR_Phase2_CycleGap | DateID + Regulation | Reconcile liability decomposition against cycle gap signals |

### 3.4 Gotchas

- **'Closing Balace' typo**: ExcelOrder=3 metric is named 'Closing Balace' (missing 'n') — matches the typo in the source CBCAN column naming. Use `ExcelOrder = 3` rather than string matching.
- **NegativeLiabilityInUsedMargin (metric 7) is stored positive**: Live data shows MetricValue > 0 for this metric (e.g., $26.9K total on 2026-04-12), unlike metrics 2 and 5 which are stored as negative. The sign depends on how the CBCAN source column is defined — verify sign convention before arithmetic.
- **IsCreditReportValidCB already applied**: The SP pre-filters to `IsCreditReportValidCB = 1`; no additional filter needed when querying this table.
- **Sparse combinations**: Not all Regulation × PlayerStatus combinations have data every day (423K actual vs ~762K theoretical max). Zero-balance segments are dropped by the ISNULL+SUM pattern.
- **9 rows per (Date, Regulation, PlayerStatus) when populated**: Always filter by ExcelOrder to avoid cross-metric double-counting.

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
| 1 | Date | date | YES | Reporting date for this row. GROUP BY passthrough from `BI_DB_Client_Balance_Aggregate_Level_New.Date`. Matches the @date parameter passed to SP_CMR_Phase2_LiabilityDecomp. (Tier 2 — SP_CMR_Phase2_LiabilityDecomp) |
| 2 | DateID | int | YES | Integer date key YYYYMMDD. GROUP BY passthrough from CBCAN. CLUSTERED INDEX key; primary filter for single-date queries. (Tier 2 — SP_CMR_Phase2_LiabilityDecomp) |
| 3 | ExcelOrder | int | YES | Ordinal metric position (1–9) matching the liability section column order in the CMR Phase 2 Excel report. Hardcoded per UNION ALL branch in SP. (Tier 2 — SP_CMR_Phase2_LiabilityDecomp) |
| 4 | Metric | varchar(200) | YES | Named metric label. 9 distinct values: Total Liability, Negative Total Liability, Closing Balace (typo), Withdrawable Liability, Negative Withdrawable Liability, Liability In Used Margin, NegativeLiabilityInUsedMargin, In Process Cashouts, NegativeInProcessCashout. Hardcoded string per UNION ALL branch. (Tier 2 — SP_CMR_Phase2_LiabilityDecomp) |
| 5 | Regulation | varchar(200) | YES | Regulatory jurisdiction label. GROUP BY passthrough from CBCAN. Scoped to: CySEC, BVI, NFA, None, ASIC, ASIC & GAML. (Tier 2 — SP_CMR_Phase2_LiabilityDecomp) |
| 6 | PlayerStatus | varchar(200) | YES | Account status segment. GROUP BY passthrough from CBCAN. All 9 statuses included (PlayerStatus filter commented out in SP). Observed: Trade & MIMO Blocked, Blocked, Normal, Block Deposit & Trading, Blocked Upon Request, Pending Verification, Warning, Deposit Blocked, Copy Block. (Tier 2 — SP_CMR_Phase2_LiabilityDecomp) |
| 7 | MetricValue | decimal(38,8) | YES | Aggregate liability amount (USD) for the named metric on the reporting date for this Regulation × PlayerStatus segment. `ISNULL(SUM(corresponding_column), 0)` from CBCAN per metric branch. Dominant component: Liability In Used Margin (~$8.06B, 2026-04-12). Note: NegativeLiabilityInUsedMargin (ExcelOrder=7) is stored as a positive value. (Tier 2 — SP_CMR_Phase2_LiabilityDecomp) |
| 8 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|----------------|--------------|---------------|-----------|
| Date | BI_DB_Client_Balance_Aggregate_Level_New | Date | GROUP BY passthrough |
| DateID | BI_DB_Client_Balance_Aggregate_Level_New | DateID | GROUP BY passthrough (= @dateID filter) |
| ExcelOrder | SP_CMR_Phase2_LiabilityDecomp | — | Hardcoded ordinal 1–9 per UNION ALL branch |
| Metric | SP_CMR_Phase2_LiabilityDecomp | — | Hardcoded metric name string per UNION ALL branch |
| Regulation | BI_DB_Client_Balance_Aggregate_Level_New | Regulation | GROUP BY passthrough; outer WHERE IN ('CySEC','BVI','NFA','None','ASIC','ASIC & GAML') |
| PlayerStatus | BI_DB_Client_Balance_Aggregate_Level_New | PlayerStatus | GROUP BY passthrough; all statuses (filter commented out) |
| MetricValue | BI_DB_Client_Balance_Aggregate_Level_New | TotalLiability / TotalNegativeLiability / ClosingBalance / WithdrawableLiability / NegativeWithdrawableLiability / LiabilityInUsedMargin / NegativeLiabilityInUsedMargin / InProcessCashout / NegativeInProcessCashout (varies by branch) | ISNULL(SUM(column), 0) per metric |
| UpdateDate | SP_CMR_Phase2_LiabilityDecomp | — | GETDATE() at INSERT time |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New (P0, Done Batch 6)
  (filter: Regulation IN CySEC/BVI/NFA/None/ASIC/ASIC & GAML, IsCreditReportValidCB=1, DateID=@dateID)
  |-- SP_CMR_Phase2_LiabilityDecomp (@date, P15 Daily SB_Daily) --|
  |   9-branch UNION ALL pivot → #temp (HEAP, ROUND_ROBIN)
  |   GROUP BY Date, DateID, ExcelOrder, Metric, Regulation, PlayerStatus → SUM(MetricValue)
  |   DELETE WHERE Date=@date + INSERT
  v
BI_DB_dbo.BI_DB_CMR_Phase2_LiabilityDecomp (423,009 rows, 1,218 dates, 9 metrics × 6 Regs × 9 Statuses)
  |-- UC Target: _Not_Migrated --|
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|----------------|-------------|
| MetricValue (all) | BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | Sole source; all 9 metrics are ISNULL(SUM(col), 0) of CBCAN liability columns |

### 6.2 Referenced By

| Object | Relationship |
|--------|-------------|
| BI_DB_dbo.BI_DB_CMR_Phase2_ClientBalance | Sibling CMR Phase 2 — full balance cycle (broader regulation scope) |
| BI_DB_dbo.BI_DB_CMR_Phase2_CycleGap | Sibling CMR Phase 2 — ASIC/EU cycle reconciliation gap |

---

## 7. Sample Queries

### Total Liability by Regulation for Most Recent Date

```sql
SELECT Regulation, SUM(MetricValue) AS TotalLiability
FROM BI_DB_dbo.BI_DB_CMR_Phase2_LiabilityDecomp
WHERE DateID = (SELECT MAX(DateID) FROM BI_DB_dbo.BI_DB_CMR_Phase2_LiabilityDecomp)
  AND ExcelOrder = 1
GROUP BY Regulation
ORDER BY TotalLiability DESC;
```

### Full Liability Decomposition for One Segment

```sql
SELECT ExcelOrder, Metric, MetricValue
FROM BI_DB_dbo.BI_DB_CMR_Phase2_LiabilityDecomp
WHERE DateID = 20260412
  AND Regulation = 'CySEC'
  AND PlayerStatus = 'Normal'
ORDER BY ExcelOrder;
```

### Blocked Account Liability Trend

```sql
SELECT Date, Regulation, SUM(MetricValue) AS TotalLiability
FROM BI_DB_dbo.BI_DB_CMR_Phase2_LiabilityDecomp
WHERE ExcelOrder = 1
  AND PlayerStatus IN ('Blocked', 'Blocked Upon Request')
  AND DateID >= 20260101
GROUP BY Date, Regulation
ORDER BY Date, Regulation;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for BI_DB_CMR_Phase2_LiabilityDecomp. Domain knowledge inferred from SP code analysis and CMR Phase 2 sibling table context.

---

*Generated: 2026-04-23 | Quality: 9.0/10 | Phases: 11/14*
*Tiers: 0 T1, 7 T2, 0 T3, 0 T4, 0 T5, 1 Propagation | Elements: 8/8, Logic: 9/10, ETL: 9/10, Data: 9/10*
*Object: BI_DB_dbo.BI_DB_CMR_Phase2_LiabilityDecomp | Type: Table | Production Source: BI_DB_Client_Balance_Aggregate_Level_New via SP_CMR_Phase2_LiabilityDecomp*
