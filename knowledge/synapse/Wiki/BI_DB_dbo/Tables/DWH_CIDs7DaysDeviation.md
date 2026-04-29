# BI_DB_dbo.DWH_CIDs7DaysDeviation

> 4.8B-row daily 7-day rolling portfolio deviation table storing the average standard deviation of unrealized PnL for every customer — computed from DWH_dbo.Fact_CustomerUnrealized_PnL over a trailing 7-day window, covering Jan 2013 to present. Used as the risk score input for copy-trading block decisions. Refreshed daily by SP_DWH_CIDs7DaysDeviation via DELETE+INSERT by FullDate. Not migrated to Unity Catalog.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed by `BI_DB_dbo.SP_DWH_CIDs7DaysDeviation` from DWH_dbo.Fact_CustomerUnrealized_PnL |
| **Refresh** | Daily — DELETE WHERE FullDate=@start + INSERT. Accumulating by date. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP (PK on CID, FullDate — NOT ENFORCED) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

This table calculates the **7-day rolling average portfolio deviation** for every eToro customer. The deviation measures how volatile a customer's unrealized PnL has been over the past 7 days — higher deviation = more volatile trading behavior = higher risk.

The 4.8B rows cover daily snapshots from Jan 2013 to Apr 2026 (one row per customer per day). The Deviation value is the AVG of daily StandardDeviation values from Fact_CustomerUnrealized_PnL over a 7-day window (current day minus 6 through current day).

This table is a critical input for the **copy-trading risk management system**. SP_WeeklyCopyBlock reads from this table and applies a 10-bucket risk score (1-10) based on deviation thresholds to determine whether Popular Investors should be blocked from being copied.

---

## 2. Business Logic

### 2.1 7-Day Rolling Average

**What**: Smooths daily portfolio deviation into a weekly rolling average.
**Columns Involved**: Deviation, FullDate, CID
**Rules**:
- Window: DATEADD(day, -6, FullDate) to FullDate (7 calendar days)
- Calculation: AVG(Fact_CustomerUnrealized_PnL.StandardDeviation) across all days in the window
- Uses Dim_Date self-join for efficient date range calculation

### 2.2 Risk Score Mapping (consumed by SP_WeeklyCopyBlock)

**What**: Downstream consumption converts Deviation to a 1-10 risk score.
**Columns Involved**: Deviation
**Rules** (from SP_WeeklyCopyBlock — for reference):
- 1: Deviation < 0.00034
- 2: < 0.00068
- 3: < 0.00204
- 4: < 0.00340
- 5: < 0.00544
- 6: < 0.00816
- 7: < 0.01361
- 8: < 0.02722
- 9: < 0.04763
- 10: >= 0.04763
- 0: NULL/no data

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP with NOT ENFORCED PK on (CID, FullDate). **This is the largest table in BI_DB_dbo at 4.8B rows**. ALWAYS filter by FullDate for any query.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Risk for a customer today | `WHERE CID = X AND FullDate = @today` |
| High-risk customers on a date | `WHERE FullDate = @date AND Deviation >= 0.04763` (risk score 10) |
| Customer deviation trend | `WHERE CID = X AND FullDate BETWEEN @start AND @end ORDER BY FullDate` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Customer profile |
| BI_DB_dbo.BI_DB_WeeklyCopyBlock | CID + FullDate | Risk score at block start/end |

### 3.4 Gotchas

- **4.8B rows**: NEVER run unfiltered queries. Always include FullDate in WHERE clause.
- **Deviation = 0**: Can mean no trading activity in the 7-day window (all StandardDeviation values were 0).
- **Extreme outliers**: Max deviation ~994, far beyond the 10-bucket threshold of 0.04763. These are likely accounts with extreme position sizing.
- **NOT ENFORCED PK**: The (CID, FullDate) uniqueness constraint exists for optimizer hints but is not enforced at write time.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code analysis — high confidence |
| Tier 5 | ETL infrastructure column — canonical description |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FullDate | date | NO | Snapshot date. The target date for the 7-day rolling window calculation. PK component (NOT ENFORCED). Used as DELETE+INSERT key. (Tier 2 — SP_DWH_CIDs7DaysDeviation) |
| 2 | CID | int | NO | Customer ID. FK to Dim_Customer.RealCID. One row per customer per day. PK component (NOT ENFORCED). (Tier 2 — SP_DWH_CIDs7DaysDeviation) |
| 3 | Deviation | float | YES | 7-day rolling average of portfolio standard deviation. AVG(Fact_CustomerUnrealized_PnL.StandardDeviation) from (FullDate-6) to FullDate. Higher values indicate more volatile trading. Consumed by SP_WeeklyCopyBlock for risk score bucketing (1-10 scale). (Tier 2 — SP_DWH_CIDs7DaysDeviation) |
| 4 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_DWH_CIDs7DaysDeviation. (Tier 5 — ETL infrastructure) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| FullDate | Dim_Date | FullDate | passthrough |
| CID | Fact_CustomerUnrealized_PnL | CID | passthrough |
| Deviation | Fact_CustomerUnrealized_PnL | StandardDeviation | AVG over 7-day rolling window |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_CustomerUnrealized_PnL (daily PnL standard deviation)
DWH_dbo.Dim_Date (date range self-join for 7-day window)
  |
  |-- SP_DWH_CIDs7DaysDeviation @start (daily)
  |   AVG(StandardDeviation) WHERE date in [day-6, day]
  |   DELETE WHERE FullDate=@start + INSERT
  v
BI_DB_dbo.DWH_CIDs7DaysDeviation (4.8B rows, accumulating daily)
  |
  |-- SP_WeeklyCopyBlock (downstream consumer, weekly)
  v
BI_DB_dbo.BI_DB_WeeklyCopyBlock (risk score bucketing)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| BI_DB_dbo.BI_DB_WeeklyCopyBlock | Reader | Risk score calculation at block start/end dates |

---

## 7. Sample Queries

### 7.1 High-Risk Customers Today

```sql
SELECT CID, Deviation
FROM BI_DB_dbo.DWH_CIDs7DaysDeviation
WHERE FullDate = CAST(GETDATE()-1 AS DATE)
  AND Deviation >= 0.04763  -- Risk score 10
ORDER BY Deviation DESC
```

---

## 8. Atlassian Knowledge Sources

No direct Confluence/Jira pages found. Context: feeds the copy-trading risk management system.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 3 T2, 0 T3, 0 T4, 1 T5 | Elements: 4/4, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.DWH_CIDs7DaysDeviation | Type: Table | Production Source: SP_DWH_CIDs7DaysDeviation (from Fact_CustomerUnrealized_PnL)*
