# BI_DB_dbo.BI_DB_CMR_Phase2_Finra_NonCash_Comps

> 18,683-row CID-grain log of Apex Clearing non-cash corporate action compensations for US FinCEN+FINRA-regulated customers. Captures 19 event types (Merger, Spinoff, Stock Dividend, Cash in Lieu, ADR fee, etc.) for 7,338 distinct customers across 239 event-dates (2022-01-31 to 2026-04-07 — sparse, only dates with events). Source: Fact_CustomerAction (ActionTypeID=36, 27 CompensationReasonIDs) filtered to RegulationID=8 via Fact_SnapshotCustomer. Used in CMR Phase 2 Finance automation reconciliation.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `DWH_dbo.Fact_CustomerAction` (ActionTypeID=36) via `SP_CMR_Phase2_Finra_NonCash_Comps` |
| **Refresh** | Daily (DELETE WHERE Date=@date + INSERT) |
| **OpsDB Priority** | 15 (SB_Daily, second-wave — depends on DWH P0 Fact_CustomerAction) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_CMR_Phase2_Finra_NonCash_Comps` is the **CID-level log of Apex Clearing non-cash corporate action compensations** for US FINRA-regulated customers, used in the CMR Phase 2 Finance automation framework. It answers: "Which customers received which type of corporate action event today, and for how much?"

Non-cash compensations are balance adjustments from corporate actions on real stock holdings — events that alter a customer's balance but are not standard cash deposits, cashouts, or bonus allocations. These events must be separately tracked for FINRA regulatory reporting.

The 19 distinct `CompensationReason` values (>15, see SP filter for full ID set):

| Category | Reasons |
|----------|---------|
| Dividends | Dividend, Dividend Adjustment, Dividend on merger, Stock Dividend, Dividend Reinvestments (DRS) |
| Corporate Restructuring | Merger, Spinoff, Exchange, Name Change, Liquidation, Tender |
| Capital Events | Return Of Capital, REORG Cash, REORG Security, Reverse split |
| Fees | ADR fee, Reorg fee |
| Fractional/Promo | Cash in Lieu, Promotion |

**Cash in Lieu** dominates by row count (14,195 rows, 76%) but is near-zero in total amount ($8.09 — fractional share compensation). **Merger** ($165.6K) and **Spinoff** ($103.8K) are the highest-value categories. Fee-type reasons (ADR fee, Liquidation, Reorg fee, DRS) have negative amounts.

Data is **sparse** — only 239 distinct dates have events (not every day). Date range: 2022-01-31 to 2026-04-07.

---

## 2. Business Logic

### 2.1 ETL Pattern — DELETE + INSERT from DWH Fact Tables

**What**: Idempotent daily refresh — deletes any existing row for @date and inserts from a 4-table JOIN.
**Columns Involved**: All 6 columns
**Rules**:
1. `DELETE FROM BI_DB_CMR_Phase2_Finra_NonCash_Comps WHERE Date = @date`
2. `INSERT` from Fact_CustomerAction JOIN Fact_SnapshotCustomer (via Dim_Range) JOIN Dim_CompensationReason
3. Filter: ActionTypeID=36, CompensationReasonID IN (45,60,62-72,75,76,78,79,81-89,92), RegulationID=8 (FinCEN+FINRA), DateID=@dateID
4. GROUP BY RealCID, DateID, CompensationReason → SUM(Amount)

### 2.2 ActionTypeID = 36 — Non-Cash Compensations

**What**: ActionTypeID=36 in Fact_CustomerAction represents compensation events — credit adjustments from corporate actions on Apex-held real stocks.
**Columns Involved**: Amount, CompensationReason
**Rules**:
- 27 specific CompensationReasonIDs are included (Apex corporate action subset)
- Amount can be negative for fee-type events (ADR fee, Reorg fee, Liquidation, DRS)
- Cash in Lieu = fractional share cash settlement (high count, near-zero amount per event)

### 2.3 RegulationID = 8 Filter — FinCEN+FINRA Scope

**What**: The Fact_SnapshotCustomer join with RegulationID=8 restricts to US FINRA-regulated customers only.
**Columns Involved**: RealCID (implicitly scoped)
**Rules**:
- Join uses Dim_Range (DateRangeID → FromDateID/ToDateID) to find the snapshot row valid for the event date
- No Regulation column stored in the output — scope is baked into the population

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN; CLUSTERED INDEX (DateID ASC). Very small table (18K rows) — DateID index useful for single-date queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Totals by reason for a date | `WHERE DateID = @id GROUP BY CompensationReason ORDER BY SUM(Amount) DESC` |
| Merger/Spinoff history | `WHERE CompensationReason IN ('Merger','Spinoff') ORDER BY Date` |
| High-value events | `GROUP BY Date ORDER BY SUM(Amount) DESC` with date filter |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|----------------|---------|
| DWH_dbo.Dim_Customer | `ON dc.RealCID = t.RealCID` | Customer demographics, country |
| BI_DB_CMR_Phase2_FinraGap | DateID | Aggregate cross-check — ExcelOrder 9 (Compensation) should reconcile |

### 3.4 Gotchas

- **Sparse dates**: Only 239 dates have data (2022-2026). A date with no corporate action events has no rows — this is expected, not missing data.
- **Cash in Lieu dominates row count but not amount**: 76% of rows are Cash in Lieu with total ~$8 — treat separately from high-value events when computing averages.
- **Negative amounts**: ADR fee, Reorg fee, Liquidation, and DRS can have negative Amount — do not assume all values are credits.
- **Amount is SUM**: One row per (RealCID, Date, CompensationReason) — if a customer had two Spinoff events on the same date, they appear as one summed row.

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
| 1 | RealCID | int | YES | Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. DWH note: filtered to FinCEN+FINRA-regulated customers (RegulationID=8 via Fact_SnapshotCustomer join). (Tier 1 — Customer.CustomerStatic) |
| 2 | DateID | int | YES | Date of the action as integer YYYYMMDD. Derived from `Occurred`. Part of nonclustered indexes. Passthrough from Fact_CustomerAction.DateID. (Tier 2 — SP_CMR_Phase2_Finra_NonCash_Comps) |
| 3 | Date | date | YES | Calendar date of the compensation event. Derived as CAST(Fact_CustomerAction.Occurred AS DATE). (Tier 2 — SP_CMR_Phase2_Finra_NonCash_Comps) |
| 4 | CompensationReason | varchar(200) | YES | Human-readable reason label used in BackOffice UI and reports. E.g., "Satisfaction Bonus", "Cash Dividend", "Dormant Fee". Passed through unchanged from production. DWH note: filtered to ActionTypeID=36 (non-cash corporate actions) and CompensationReasonIDs 45,60,62-72,75,76,78,79,81-89,92. 19 distinct values observed (Merger, Spinoff, Cash in Lieu, Stock Dividend, ADR fee, etc.). (Tier 1 — BackOffice.CompensationReason) |
| 5 | Amount | decimal(38,8) | YES | Sum of non-cash corporate action compensation amounts (USD) for this customer, date, and reason. Aggregated from Fact_CustomerAction.Amount for ActionTypeID=36 events. Can be negative for fee-type reasons (ADR fee, Reorg fee, Liquidation, DRS). (Tier 2 — SP_CMR_Phase2_Finra_NonCash_Comps) |
| 6 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|----------------|--------------|---------------|-----------|
| RealCID | Fact_CustomerAction | RealCID | Passthrough (GROUP BY key) |
| DateID | Fact_CustomerAction | DateID | Passthrough (= @dateID filter, GROUP BY key) |
| Date | Fact_CustomerAction | Occurred | CAST(Occurred AS DATE) |
| CompensationReason | Dim_CompensationReason | Name | JOIN on fca.CompensationReasonID = dcr.CompensationReasonID |
| Amount | Fact_CustomerAction | Amount | SUM(Amount) per (RealCID, DateID, CompensationReason) |
| UpdateDate | SP_CMR_Phase2_Finra_NonCash_Comps | — | GETDATE() at INSERT time |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_CustomerAction (P0, ~11B rows)
  (filter: ActionTypeID=36, CompensationReasonID IN(45,60,62..92), DateID=@dateID)
  |
  JOIN DWH_dbo.Fact_SnapshotCustomer ON RealCID + Dim_Range date range
  (filter: RegulationID=8 = FinCEN+FINRA)
  |
  JOIN DWH_dbo.Dim_CompensationReason ON CompensationReasonID → Name
  |-- SP_CMR_Phase2_Finra_NonCash_Comps (@date, P15 Daily SB_Daily) --|
  |   GROUP BY RealCID, DateID, CompensationReason → SUM(Amount)
  |   DELETE WHERE Date=@date + INSERT
  v
BI_DB_dbo.BI_DB_CMR_Phase2_Finra_NonCash_Comps (18,683 rows, 239 event-dates)
  |-- UC Target: _Not_Migrated --|
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|----------------|-------------|
| RealCID | DWH_dbo.Fact_CustomerAction | Source table for all compensation events |
| CompensationReason | DWH_dbo.Dim_CompensationReason | Reason code → name lookup |
| (RealCID filter) | DWH_dbo.Fact_SnapshotCustomer | Regulation scoping (RegulationID=8) |

### 6.2 Referenced By

| Object | Relationship |
|--------|-------------|
| BI_DB_dbo.BI_DB_CMR_Phase2_FinraGap | Sibling CMR Phase 2 — FINRA aggregate gap (ExcelOrder 9/10/11 includes compensation) |
| BI_DB_dbo.BI_DB_CMR_Phase2_USA_CustomerBalance_ApexAdjusted | Sibling CMR Phase 2 — US balance with Apex adjustments |

---

## 7. Sample Queries

### Non-Cash Compensation Totals by Reason for Most Recent Date

```sql
SELECT CompensationReason, SUM(Amount) AS TotalAmount, COUNT(DISTINCT RealCID) AS CustomerCount
FROM BI_DB_dbo.BI_DB_CMR_Phase2_Finra_NonCash_Comps
WHERE DateID = (SELECT MAX(DateID) FROM BI_DB_dbo.BI_DB_CMR_Phase2_Finra_NonCash_Comps)
GROUP BY CompensationReason
ORDER BY TotalAmount DESC;
```

### Merger and Spinoff History (High-Value Events)

```sql
SELECT Date, CompensationReason, SUM(Amount) AS TotalAmount, COUNT(DISTINCT RealCID) AS Recipients
FROM BI_DB_dbo.BI_DB_CMR_Phase2_Finra_NonCash_Comps
WHERE CompensationReason IN ('Merger','Spinoff','Exchange','REORG Security')
  AND DateID >= 20260101
GROUP BY Date, CompensationReason
ORDER BY Date DESC, TotalAmount DESC;
```

### Customers Receiving Corporate Action Events in a Date Range

```sql
SELECT RealCID, Date, CompensationReason, Amount
FROM BI_DB_dbo.BI_DB_CMR_Phase2_Finra_NonCash_Comps
WHERE DateID BETWEEN 20260401 AND 20260412
ORDER BY Amount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for BI_DB_CMR_Phase2_Finra_NonCash_Comps. Domain knowledge inferred from SP code analysis, CMR Phase 2 context, and DWH Fact_CustomerAction and Dim_CompensationReason wikis.

---

*Generated: 2026-04-23 | Quality: 9.2/10 | Phases: 11/14*
*Tiers: 2 T1, 3 T2, 0 T3, 0 T4, 0 T5, 1 Propagation | Elements: 6/6, Logic: 9/10, ETL: 9/10, Data: 9/10*
*Object: BI_DB_dbo.BI_DB_CMR_Phase2_Finra_NonCash_Comps | Type: Table | Production Source: Fact_CustomerAction (ActionTypeID=36) via SP_CMR_Phase2_Finra_NonCash_Comps*
