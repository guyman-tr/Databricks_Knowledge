# BI_DB_dbo.BI_DB_GuruRatios

> 50-row utility table storing the recursive copier-tree amplification ratio for the top 50 Popular Investors (PIs) by copy AUM. Each row represents one PI and the total multiplier effect across all levels of copiers (children, grandchildren, etc.) — i.e., how many units are opened across the entire copy tree for every unit the PI opens. Refreshed on-demand via SP_Guru_Ratio_Populate; data is based on a 10-day-lagged snapshot.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | SP_Guru_Ratio_Populate → SP_GuruRatio (recursive copier-tree walker) |
| **Refresh** | On-demand (TRUNCATE + repopulate); currently disabled for investigation |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (RealCID ASC) |
| **UC Target** | `_Not_Migrated` |
| **Row Count** | 50 (fixed — top 50 PIs by copy AUM) |

---

## 1. Business Meaning

`BI_DB_GuruRatios` captures the **amplification ratio** for Popular Investors on the eToro platform. The ratio measures the total capital multiplier across the entire copy-trading hierarchy: for every $1 the PI allocates to a position, the ratio tells you how many dollars are moved across all copiers (direct copiers, their copiers, etc.).

The SP comment states: *"finding the ratio of all levels of copiers for PIs (including sons, grandsons, etc.) to see how many units open for every position unit open for PI."*

The table is populated by `SP_Guru_Ratio_Populate`, which:
1. TRUNCATEs the table
2. Selects the top 50 ParentCIDs from `etoroGeneral_History_GuruCopiers` by descending `SUM(Cash + Investment)` (i.e., total copy AUM)
3. Calls `SP_GuruRatio` for each PI, which recursively walks the copier tree using a 10-day-lagged snapshot
4. After all ratios are computed, enriches `UserName` from `Dim_Customer`

**Note**: Both SP_GuruRatio and SP_Guru_Ratio_Populate contain the comment `-- Disabled for investigation`, and the last `UpdateDate` in the data is 2024-06-06, indicating the process has been paused since then.

---

## 2. Business Logic

### 2.1 Recursive Copier-Tree Ratio Computation

**What**: For a given PI, the SP walks the copy hierarchy level by level, computing a cumulative ratio at each level and summing across all levels.

**Columns Involved**: Ratio, RealCID

**Rules**:
- At each level, per-copier ratio = `(ISNULL(Cash, 0) + ISNULL(Investment, 0)) / NULLIF(RealizedEquity, 0) * parent_ratio`
- `Cash + Investment` = RealizedAUM of the copier relationship (from `etoroGeneral_History_GuruCopiers`)
- `RealizedEquity` = the parent's equity (from `V_Liabilities` at the snapshot date)
- The total ratio = sum of all per-copier ratios across all levels
- Copiers who are themselves PIs (`PlayerLevelID = 4`) are excluded from the tree via `Dim_Customer` filter

### 2.2 Top-50 Selection

**What**: Only the top 50 PIs by total copy AUM are included.

**Columns Involved**: RealCID

**Rules**:
- `TOP 50 ParentCID` ordered by `SUM(ISNULL(Cash, 0) + ISNULL(Investment, 0)) DESC`
- Source: `etoroGeneral_History_GuruCopiers` at `partition_date = GETDATE() - 10`
- Table is TRUNCATEd before each run — no historical accumulation

### 2.3 UserName Enrichment

**What**: After ratio computation, UserName is populated from Dim_Customer.

**Columns Involved**: UserName

**Rules**:
- `UPDATE R SET R.UserName = C.UserName FROM BI_DB_GuruRatios R LEFT JOIN Dim_Customer C ON R.RealCID = C.RealCID`
- LEFT JOIN ensures rows are not lost if Dim_Customer has no match (UserName would be NULL)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN — appropriate for 50-row table; no skew concerns
- **Index**: CLUSTERED INDEX on RealCID — efficient for point lookups by PI

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Which PI has the highest amplification? | `SELECT TOP 1 * FROM BI_DB_dbo.BI_DB_GuruRatios ORDER BY Ratio DESC` |
| What is the average ratio across top PIs? | `SELECT AVG(Ratio) FROM BI_DB_dbo.BI_DB_GuruRatios` |
| Join with customer details | `JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID = gr.RealCID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Dim_Customer | Dim_Customer.RealCID = BI_DB_GuruRatios.RealCID | Full customer profile for PI |
| V_Liabilities | V_Liabilities.CID = BI_DB_GuruRatios.RealCID | Current equity/AUM for PI |

### 3.4 Gotchas

- **Stale data**: The table was last updated 2024-06-06; the SP is marked `-- Disabled for investigation`
- **Only top 50**: This is NOT a complete PI list — only the 50 largest by copy AUM
- **10-day lag**: Ratios are computed from a snapshot 10 days in the past (`GETDATE() - 10`)
- **No history**: Each run TRUNCATEs the table — no time series of ratios is preserved
- **Ratio > 1 is normal**: A ratio of 332 means $332 moves across the tree for every $1 the PI allocates

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream documented source |
| Tier 2 | ETL-computed or derived in SP code |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. In this table, identifies the Popular Investor whose copier-tree ratio is computed. (Tier 1 — Customer.CustomerStatic) |
| 2 | Ratio | decimal(16,8) | YES | Recursive copier-tree amplification ratio: total capital multiplier across all copier levels for this PI. Computed as the sum of `(RealizedAUM / RealizedEquity) * parent_ratio` at each level of the copy hierarchy, where RealizedAUM = `ISNULL(Cash, 0) + ISNULL(Investment, 0)` from copier relationships and RealizedEquity from V_Liabilities. Excludes copiers who are themselves PIs (PlayerLevelID = 4). (Tier 2 — V_Liabilities / etoroGeneral_History_GuruCopiers) |
| 3 | UserName | nvarchar(150) | YES | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 4 | UpdateDate | datetime | YES | ETL timestamp — `GETDATE()` at the time SP_GuruRatio inserts the row. (Tier 2 — SP_GuruRatio) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|--------------|-----------|
| RealCID | etoroGeneral_History_GuruCopiers | ParentCID | Top 50 by copy AUM, passed as @cid |
| Ratio | V_Liabilities + etoroGeneral_History_GuruCopiers | RealizedEquity, Cash, Investment | Recursive ratio sum across copier tree levels |
| UserName | Customer.CustomerStatic (via Dim_Customer) | UserName | Direct lookup |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
etoroGeneral_History_GuruCopiers (general schema, partition_date = T-10)
  + DWH_dbo.V_Liabilities (RealizedEquity at T-10)
  + DWH_dbo.Dim_Customer (PlayerLevelID filter + UserName enrichment)
  |
  |-- SP_Guru_Ratio_Populate (orchestrator: TRUNCATE → top 50 loop → UserName UPDATE)
  |     |-- SP_GuruRatio @cid (called per PI: recursive copier-tree walk)
  v
BI_DB_dbo.BI_DB_GuruRatios (50 rows)
  |
  [Not migrated to UC]
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer.RealCID | Customer dimension for PI details |
| (implicit) | DWH_dbo.V_Liabilities | RealizedEquity used in ratio denominator |
| (implicit) | general.etoroGeneral_History_GuruCopiers | Copier hierarchy and copy AUM |

### 6.2 Referenced By (other objects point to this)

No downstream consumers found in the SSDT codebase.

---

## 7. Sample Queries

### 7.1 Top PIs by Amplification Ratio

```sql
SELECT RealCID, UserName, Ratio, UpdateDate
FROM BI_DB_dbo.BI_DB_GuruRatios
ORDER BY Ratio DESC;
```

### 7.2 Join with Customer Profile

```sql
SELECT gr.RealCID, gr.UserName, gr.Ratio,
       dc.CountryID, dc.RegulationID, dc.GuruStatusID
FROM BI_DB_dbo.BI_DB_GuruRatios gr
JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID = gr.RealCID;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-29 | Quality: 8.5/10 | Phases: 1-11 (excl. 10 Jira)*
*Tiers: 2 T1, 2 T2, 0 T3, 0 T4 | Elements: 4/4, Logic: 8/10*
*Object: BI_DB_dbo.BI_DB_GuruRatios | Type: Table | Production Source: SP_Guru_Ratio_Populate*
