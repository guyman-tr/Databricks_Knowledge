# BI_DB_dbo.LTV_FromDB_ToBigQuery

> 88K-row BigQuery export table containing customer LTV predictions for depositors with a first deposit in the last 90 days and positive Revenue8Y_LTV_New. Refreshed daily by SP_LTV_FromDB_ToBigQuery (P0, SB_Daily) via TRUNCATE + INSERT from BI_DB_LTV_BI_Actual. Used by the marketing/growth analytics team for near-term depositor lifetime value targeting in Google BigQuery.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_LTV_BI_Actual (intra-schema, documented) |
| **Refresh** | Daily; SP_LTV_FromDB_ToBigQuery, Priority 0, SB_Daily (TRUNCATE + INSERT) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Row Count** | ~88,340 (varies with 90-day FTD volume) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — not yet migrated to Unity Catalog |

---

## 1. Business Meaning

`LTV_FromDB_ToBigQuery` is a lightweight export table that feeds customer Lifetime Value (LTV) data to Google BigQuery for marketing and growth analytics consumption. It is a narrow 4-column subset of the canonical LTV store (`BI_DB_LTV_BI_Actual`, ~5.84M rows) filtered to only include depositors who made their first deposit within the last 90 days AND have a positive 8-year revenue prediction.

Each row represents one customer who recently deposited and has a non-zero LTV forecast. The 88K rows (as of 2026-04-12) represent approximately 1.5% of the full BI_DB_LTV_BI_Actual population — the recent-depositor, positive-LTV segment that marketing uses for acquisition attribution, campaign ROI estimation, and lookalike audience generation in Google Ads via BigQuery.

The SP was created by Eti Rozolio in April 2022. It runs daily at Priority 0 in the SB_Daily process, performing a TRUNCATE + INSERT with a parameterized date (`@date`) that controls the 90-day lookback window.

---

## 2. Business Logic

### 2.1 90-Day First Deposit Window

**What**: Only customers whose first deposit occurred within the last 90 days are included.
**Columns Involved**: FirstDepositDate
**Rules**:
- Filter: `FirstDepositDate >= DATEADD(DAY, -90, @date)` where @date is the SP execution date
- This creates a sliding window of recent depositors — older depositors are excluded even if their LTV is high
- Purpose: marketing needs recent-FTD customers for attribution and targeting, not the full 18-year history

### 2.2 Positive LTV Gate

**What**: Only customers with positive LTV predictions are exported.
**Columns Involved**: Revenue8Y_LTV_New
**Rules**:
- Filter: `Revenue8Y_LTV_New > 0`
- Customers with zero or negative predicted LTV are excluded (inactive accounts, refund-heavy customers)
- This ensures BigQuery receives only actionable positive-value customer records

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP. Small table (~88K rows). Full scan is fast. No optimization needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current export to BigQuery | `SELECT * FROM LTV_FromDB_ToBigQuery` (small enough for full scan) |
| High-value recent depositors | `WHERE Revenue8Y_LTV_New > 5000 ORDER BY Revenue8Y_LTV_New DESC` |
| Daily deposit cohort LTV | `GROUP BY CAST(FirstDepositDate AS DATE)` |
| Compare to full LTV store | `JOIN BI_DB_LTV_BI_Actual ON CID = CID` to see excluded customers |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_LTV_BI_Actual | CID = CID | Access full LTV model outputs (1Y/3Y/8Y, VolFix, GroupLevel) |
| DWH_dbo.Dim_Customer | CID = RealCID | Resolve customer demographics, regulation, country |
| BI_DB_dbo.BI_DB_CIDFirstDates | CID = CID | Access registration date, first action dates, channel |

### 3.4 Gotchas

- **Not a complete LTV table**: This is a filtered export subset. Use BI_DB_LTV_BI_Actual for the full customer LTV population.
- **TRUNCATE + INSERT means momentary empty**: During SP execution, the table is briefly empty. Queries during this window return 0 rows.
- **Revenue8Y_LTV_New > 0 filter**: Zero-LTV customers are intentionally excluded. If you need them, query BI_DB_LTV_BI_Actual directly.
- **UpdateDate is execution timestamp**: All rows share the same UpdateDate (GETDATE() at SP run time), not a per-row modification time.
- **Data type mismatch**: Revenue8Y_LTV_New is `numeric(38,6)` here but `money` in BI_DB_LTV_BI_Actual — implicit conversion occurs.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available — limited confidence |
| Tier 5 | ETL infrastructure / canonical |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. Unique within eToro DB. Passthrough from BI_DB_LTV_BI_Actual. (Tier 1 — Customer.CustomerStatic) |
| 2 | FirstDepositDate | datetime | YES | Date of customer's first deposit. Filtered to last 90 days from SP execution date. Passthrough from BI_DB_LTV_BI_Actual. (Tier 2 — BI_DB_CIDFirstDates context + data evidence) |
| 3 | Revenue8Y_LTV_New | numeric(38,6) | YES | 8-year cumulative broker revenue prediction, new methodology (2023+). Individual prediction only — may be low for inactive customers. Filtered to > 0. Passthrough from BI_DB_LTV_BI_Actual. (Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki) |
| 4 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_LTV_FromDB_ToBigQuery. Set to GETDATE() at execution time. All rows share the same value per load. (Tier 5 — SP_LTV_FromDB_ToBigQuery) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| CID | BI_DB_LTV_BI_Actual | CID | Passthrough |
| FirstDepositDate | BI_DB_LTV_BI_Actual | FirstDepositDate | Passthrough (filtered: >= @date - 90 days) |
| Revenue8Y_LTV_New | BI_DB_LTV_BI_Actual | Revenue8Y_LTV_New | Passthrough (filtered: > 0) |
| UpdateDate | SP_LTV_FromDB_ToBigQuery | GETDATE() | ETL-computed |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_LTV_BI_Actual (~5.84M rows, canonical LTV store)
  |-- SP_LTV_FromDB_ToBigQuery @date ---|
  |   TRUNCATE + INSERT
  |   WHERE FirstDepositDate >= @date-90 AND Revenue8Y_LTV_New > 0
  v
BI_DB_dbo.LTV_FromDB_ToBigQuery (~88K rows)
  |-- External export process ---|
  v
Google BigQuery (marketing/growth analytics)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | FK to customer dimension (via RealCID) |
| (source table) | BI_DB_dbo.BI_DB_LTV_BI_Actual | Sole data source — canonical LTV store |

### 6.2 Referenced By (other objects point to this)

No known Synapse consumers. Data is exported externally to Google BigQuery.

---

## 7. Sample Queries

### 7.1 Top 20 Highest-LTV Recent Depositors

```sql
SELECT CID, FirstDepositDate, Revenue8Y_LTV_New
FROM [BI_DB_dbo].[LTV_FromDB_ToBigQuery]
ORDER BY Revenue8Y_LTV_New DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
```

### 7.2 Daily FTD Cohort Average LTV

```sql
SELECT CAST(FirstDepositDate AS DATE) AS FTD_Date,
       COUNT(*) AS customers,
       AVG(Revenue8Y_LTV_New) AS avg_ltv,
       SUM(Revenue8Y_LTV_New) AS total_ltv
FROM [BI_DB_dbo].[LTV_FromDB_ToBigQuery]
GROUP BY CAST(FirstDepositDate AS DATE)
ORDER BY FTD_Date DESC
```

---

## 8. Atlassian Knowledge Sources

No specific Confluence or Jira sources found for this table. See BI_DB_LTV_BI_Actual wiki for the upstream LTV model documentation.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 1 T1, 2 T2, 0 T3, 0 T4, 1 T5 | Elements: 4/4, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.LTV_FromDB_ToBigQuery | Type: Table | Production Source: BI_DB_LTV_BI_Actual*
