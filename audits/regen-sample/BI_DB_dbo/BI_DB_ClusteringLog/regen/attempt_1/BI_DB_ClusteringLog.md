# BI_DB_dbo.BI_DB_ClusteringLog

> 202.9M-row customer behavioral clustering log tracking daily cluster assignments for every CID from 2019-01-01 to present. Each row records the ML-assigned cluster label (one of 6 behavioral segments) for a customer on a given date. Loaded externally by a Python/ML pipeline via the `BI_DB_python` staging schema. Consumed downstream by `SP_CID_DailyCluster` to build the SCD-style `BI_DB_CID_DailyCluster` table.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Python/ML clustering pipeline → BI_DB_python.BI_DB_ClusteringLog (staging) → BI_DB_dbo.BI_DB_ClusteringLog |
| **Refresh** | Daily — Python pipeline writes new clustering assignments per CID per date |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_ClusteringLog` is a 202.9M-row daily log of customer behavioral cluster assignments. A Python/ML pipeline classifies each customer (CID) into one of six behavioral clusters based on their trading, investing, and crypto activity patterns. The six clusters are:

- **Crypto** — primarily crypto traders
- **Equities Crypto** — mixed equities and crypto activity
- **Equities Investors** — primarily equities investors (buy-and-hold)
- **Equities Traders** — primarily equities traders (short-term)
- **Diversified Traders** — traders active across multiple asset classes
- **Leveraged Traders** — traders using leverage-heavy instruments

Each row represents one CID on one date, recording the cluster assignment for that day. The table spans from 2019-01-01 to present (2026-04-25 at last sample) with daily granularity.

The table is a raw log — it does not track cluster transitions (that is the role of the downstream `BI_DB_CID_DailyCluster` SCD table built by `SP_CID_DailyCluster`). The Python pipeline writes to the staging schema `BI_DB_python.BI_DB_ClusteringLog` (which has an identical schema but uses a CLUSTERED INDEX on DateID), and the data is then promoted to `BI_DB_dbo.BI_DB_ClusteringLog`.

No Synapse stored procedure writes to this table; all inserts originate from the external Python/ML pipeline.

---

## 2. Business Logic

### 2.1 Cluster Assignment

**What**: Each CID receives a behavioral cluster label daily based on ML classification of their trading activity.
**Columns Involved**: CID, ClusterDesc, Date, DateID
**Rules**:
- Exactly one of 6 cluster labels is assigned per CID per date: Crypto, Equities Crypto, Equities Investors, Equities Traders, Diversified Traders, Leveraged Traders
- The assignment is computed externally by a Python/ML pipeline (not in Synapse SQL)
- A CID may appear on multiple dates, each with the same or different cluster

### 2.2 Dynamic Reclassification (Downstream)

**What**: `SP_CID_DailyCluster` applies a secondary reclassification rule when consuming this table.
**Columns Involved**: ClusterDesc (read by SP)
**Rules**:
- If `ClusterDesc = 'Diversified Traders'` AND `CryptoRatio >= 0.4` (from `BI_DB_ClusteringDailyPrepData`), the dynamic cluster is overridden to `'Equities Crypto'`
- This reclassification happens in the downstream SP, NOT in this table

### 2.3 DateID Convention

**What**: DateID is the integer representation of the date in YYYYMMDD format.
**Columns Involved**: Date, DateID
**Rules**:
- DateID = CAST(CONVERT(CHAR(8), Date, 112) AS INT) — e.g., 2024-05-20 → 20240520
- Both Date and DateID represent the same calendar day; DateID is the join key used by SP_CID_DailyCluster

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with HEAP storage. No clustered index on the BI_DB_dbo copy (the staging BI_DB_python copy has a CLUSTERED INDEX on DateID). Queries filtering by DateID or Date will benefit from adding explicit WHERE clauses to limit scan scope on this 202.9M-row table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| What cluster is a customer in today? | `SELECT * FROM BI_DB_dbo.BI_DB_ClusteringLog WHERE CID = @CID AND DateID = @Today ORDER BY DateID DESC` |
| How have cluster sizes changed over time? | `SELECT DateID, ClusterDesc, COUNT(*) FROM BI_DB_dbo.BI_DB_ClusteringLog WHERE DateID >= 20260101 GROUP BY DateID, ClusterDesc ORDER BY DateID` |
| When did a customer's cluster change? | Use `BI_DB_CID_DailyCluster` instead — it tracks transitions as an SCD |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| BI_DB_CID_DailyCluster | CID, DateID range | Downstream SCD built from this log |
| BI_DB_ClusteringDailyPrepData | CID + CalculationDateID = DateID | Ratio data used for dynamic reclassification |
| DWH_dbo.Dim_Date | DateKey = DateID | Calendar attributes (month, day-of-week, fiscal period) |

### 3.4 Gotchas

- **HEAP on 202.9M rows**: Full table scans are expensive. Always filter by DateID.
- **No uniqueness constraint**: A CID may theoretically appear multiple times for the same DateID (the SP uses GROUP BY when reading).
- **Staging vs. production schema**: `BI_DB_python.BI_DB_ClusteringLog` has the same data but with a CLUSTERED INDEX on DateID — prefer it for ad-hoc queries if accessible.
- **Dynamic reclassification is NOT stored here**: The `Equities Crypto` override for Diversified Traders with high CryptoRatio only appears in `BI_DB_CID_DailyCluster.ClusterDynamic`, not in this table's ClusterDesc.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki — highest confidence |
| Tier 2 | Derived from SP code or ETL logic |
| Tier 3 | Inferred from DDL, sample data, and downstream SP usage — no upstream wiki available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID. Identifies the customer whose behavioral cluster is recorded. Used as the join key to `BI_DB_CID_DailyCluster` and `BI_DB_ClusteringDailyPrepData`. Read by `SP_CID_DailyCluster` to build the daily cluster SCD. (Tier 3 — no upstream wiki; grounded in DDL + SP_CID_DailyCluster usage at line 166) |
| 2 | ClusterDesc | varchar(255) | YES | ML-assigned behavioral cluster label. One of 6 values: `Crypto`, `Equities Crypto`, `Equities Investors`, `Equities Traders`, `Diversified Traders`, `Leveraged Traders`. Assigned by the external Python/ML clustering pipeline. SP_CID_DailyCluster reads this as `ClusterDetail` and may dynamically reclassify `Diversified Traders` to `Equities Crypto` when CryptoRatio >= 0.4. (Tier 3 — no upstream wiki; grounded in DDL + sample data + SP_CID_DailyCluster line 170) |
| 3 | Date | date | YES | Calendar date of the clustering assignment. Represents the day on which the Python/ML pipeline evaluated the customer's behavior and assigned the cluster. (Tier 3 — no upstream wiki; grounded in DDL + sample data date range 2019-01-01 to 2026-04-25) |
| 4 | DateID | int | YES | Integer date key in YYYYMMDD format (e.g., 20240520). Derived from `Date` as `CAST(CONVERT(CHAR(8), Date, 112) AS INT)`. Used by SP_CID_DailyCluster as the primary filter key (`WHERE DateID = @LoadDateID`). (Tier 3 — no upstream wiki; grounded in DDL + sample data + SP_CID_DailyCluster line 174) |
| 5 | UpdateDate | datetime | YES | Timestamp of when this clustering record was last written or updated by the Python/ML pipeline. Sample values show updates typically occur 1-2 days after the assignment date. (Tier 3 — no upstream wiki; grounded in DDL + sample data showing lag pattern) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| CID | Python/ML pipeline | CID | Passthrough via BI_DB_python staging |
| ClusterDesc | Python/ML pipeline | ClusterDesc | ML-assigned label, passthrough |
| Date | Python/ML pipeline | Date | Passthrough |
| DateID | Python/ML pipeline | DateID | YYYYMMDD integer, passthrough |
| UpdateDate | Python/ML pipeline | UpdateDate | Pipeline write timestamp, passthrough |

### 5.2 ETL Pipeline

```
Python/ML Clustering Pipeline (external)
  |-- Writes daily cluster assignments per CID ---|
  v
BI_DB_python.BI_DB_ClusteringLog (staging, CLUSTERED INDEX on DateID)
  |-- Promoted / copied to production schema ---|
  v
BI_DB_dbo.BI_DB_ClusteringLog (202.9M rows, HEAP)
  |-- SP_CID_DailyCluster @Date (daily, reads + joins with BI_DB_ClusteringDailyPrepData) ---|
  v
BI_DB_dbo.BI_DB_CID_DailyCluster (SCD-style cluster transition table)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| CID | DWH_dbo.Dim_Customer | Customer dimension — CID is the customer identifier |
| DateID | DWH_dbo.Dim_Date | Date dimension — DateID is the YYYYMMDD integer key |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---|---|---|
| CID, ClusterDesc, Date, DateID | BI_DB_dbo.SP_CID_DailyCluster | Reader SP — consumes this table to build BI_DB_CID_DailyCluster |
| CID | BI_DB_dbo.BI_DB_ClusteringDailyPrepData | Sibling table joined on CID for ratio enrichment in SP_CID_DailyCluster |

---

## 7. Sample Queries

### 7.1 Current Cluster for a Specific Customer

```sql
SELECT CID, ClusterDesc, Date, DateID, UpdateDate
FROM BI_DB_dbo.BI_DB_ClusteringLog
WHERE CID = 22359150
  AND DateID >= 20260401
ORDER BY DateID DESC;
```

### 7.2 Daily Cluster Distribution (Recent Month)

```sql
SELECT DateID, ClusterDesc, COUNT(*) AS cid_count
FROM BI_DB_dbo.BI_DB_ClusteringLog
WHERE DateID >= 20260401
GROUP BY DateID, ClusterDesc
ORDER BY DateID, ClusterDesc;
```

### 7.3 Customers Who Changed Cluster in the Last Week

```sql
SELECT a.CID, a.ClusterDesc AS prev_cluster, b.ClusterDesc AS new_cluster,
       a.DateID AS prev_date, b.DateID AS new_date
FROM BI_DB_dbo.BI_DB_ClusteringLog a
JOIN BI_DB_dbo.BI_DB_ClusteringLog b
  ON a.CID = b.CID
  AND b.DateID = a.DateID + 1
WHERE a.DateID >= 20260420
  AND a.ClusterDesc <> b.ClusterDesc;
```

---

## 8. Atlassian Knowledge Sources

No direct Confluence or Jira documentation found for `BI_DB_ClusteringLog`. The clustering pipeline is part of the BI-Customer team's Python/ML workloads on Databricks.

---

*Generated: 2026-04-30 | Quality: 7.0/10 | Phases: 11/14*
*Tiers: 0 T1, 0 T2, 5 T3, 0 T4, 0 T5 | Elements: 5/5, Logic: 6/10, Lineage: 7/10*
*Object: BI_DB_dbo.BI_DB_ClusteringLog | Type: Table | Production Source: Python/ML pipeline (external)*
