# BI_DB_dbo.BI_DB_QMMF_Report_Finance

> ~399M-row daily financial metrics table for QMMF-accepted customers (UserInteractionActionId=14). Populated by `SP_QMMF_Report` via DELETE+INSERT per DateID. Contains 556K distinct GCIDs from 2023-11-01 to present, tracking unrealized CFD equity and credit balances for customers who completed the QMMF compliance flow.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo.V_Liabilities via `SP_QMMF_Report` |
| **Refresh** | Daily (DELETE+INSERT per DateID) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Row Count** | ~398,955,254 (daily snapshots, 20231101–20260412) |

---

## 1. Business Meaning

`BI_DB_QMMF_Report_Finance` provides daily financial metrics for customers who accepted the QMMF (Qualifying Money Market Funds) compliance flow. Each row represents one customer (GCID) on one date, capturing their unrealized CFD equity and credit balance.

The table is restricted to customers with UserInteractionActionId=14 (acceptance) from the QMMF interaction base (#QMMF temp table in `SP_QMMF_Report`). For each such customer, the SP computes:
- **UnrealizedEquity CFD**: Sum of non-settled position equity (Amount + PositionPnL where IsSettled=0) from BI_DB_PositionPnL at the @DateID
- **Credit**: Sum of credit balances from V_Liabilities at the @DateID

This companion table to `BI_DB_QMMF_Report` allows compliance and finance teams to monitor the financial exposure of QMMF-accepting customers over time.

---

## 2. Business Logic

### 2.1 CFD Unrealized Equity

**What**: Sum of unrealized equity for non-settled (CFD) positions.
**Columns Involved**: `UnrealizedEquity CFD`
**Rules**:
- SUM(Amount + PositionPnL) from BI_DB_PositionPnL WHERE IsSettled=0 at @DateID
- ISNULL defaults to 0 for customers with no CFD positions
- Only includes CFD (non-settled) positions, excludes real/settled positions

### 2.2 Credit Balance

**What**: Sum of credit balances from liabilities.
**Columns Involved**: `Credit`
**Rules**:
- SUM(Credit) from V_Liabilities at @DateID
- ISNULL defaults to 0 for customers with no liabilities record

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — no preferred join key. ~399M rows. **Large table** — always filter on `DateID` or `Date`.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Latest day's metrics | `WHERE DateID = (SELECT MAX(DateID) FROM BI_DB_QMMF_Report_Finance)` |
| Total CFD exposure of QMMF customers | `SELECT DateID, SUM([UnrealizedEquity CFD]) FROM ... GROUP BY DateID` |
| Customers with high credit | `WHERE Credit > 10000 AND DateID = @latest` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_QMMF_Report | `GCID = GCID` | Full interaction details for the customer |
| DWH_dbo.Dim_Customer | `GCID = GCID` | Full customer profile |

### 3.4 Gotchas

- **Large table (~399M rows)**: Always filter by DateID/Date.
- **Column name contains space**: `[UnrealizedEquity CFD]` — must use square brackets in queries.
- **Only QMMF-accepted customers**: UserInteractionActionId=14 filter in SP — not all QMMF interactors are included.
- **GCID not CID**: Uses Global CID. Join to Dim_Customer.GCID for RealCID.
- **Credit can be negative**: Observed negative Credit values in sample data (e.g., -11.37).
- **Zero values are meaningful**: 0 means ISNULL defaulted — customer has no CFD positions or no liabilities record, not that their balance is exactly zero.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | Propagation column (ETL infrastructure) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | NO | Global Customer ID. Identifies the QMMF-accepted customer. Only customers with UserInteractionActionId=14 from the ComplianceStateDB QMMF flow appear. (Tier 2 — SP_QMMF_Report, ComplianceStateDB) |
| 2 | DateID | int | NO | Date as YYYYMMDD integer (e.g., 20260412). Partition key for DELETE+INSERT. (Tier 2 — SP_QMMF_Report) |
| 3 | Date | date | NO | Calendar date corresponding to DateID. (Tier 2 — SP_QMMF_Report) |
| 4 | UnrealizedEquity CFD | float | NO | Sum of unrealized equity for non-settled (CFD) positions: SUM(Amount + PositionPnL) from BI_DB_PositionPnL WHERE IsSettled=0 at DateID. ISNULL → 0. (Tier 2 — SP_QMMF_Report, BI_DB_PositionPnL) |
| 5 | Credit | float | NO | Sum of credit balances from V_Liabilities at DateID. Can be negative. ISNULL → 0. (Tier 2 — SP_QMMF_Report, V_Liabilities) |
| 6 | UpdateDate | date | YES | SP execution date (@Date parameter). (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| GCID | ComplianceStateDB.Compliance.CustomerInteractions | GCID | passthrough (UserInteractionActionId=14 filter) |
| DateID | (computed) | — | @DateID = CAST(CONVERT(CHAR(8), @Date, 112) AS INT) |
| Date | (computed) | — | @Date SP parameter |
| UnrealizedEquity CFD | BI_DB_PositionPnL | Amount, PositionPnL | SUM(Amount+PositionPnL) WHERE IsSettled=0 |
| Credit | V_Liabilities | Credit | SUM(Credit) |
| UpdateDate | (computed) | — | @Date parameter |

### 5.2 ETL Pipeline

```
ComplianceStateDB.Compliance.CustomerInteractions (QMMF accepted, ActionId=14)
  |-- External tables in BI_DB_dbo --|
  v
BI_DB_dbo.External_ComplianceStateDB_Compliance_* (GCID base)
  |
  |-- SP_QMMF_Report (daily DELETE+INSERT by DateID)
  |   Step 1: Filter QMMF interactions for UserInteractionActionId=14
  |   Step 2: Resolve GCID → RealCID via Dim_Customer
  |   Step 3: Compute unrealized CFD equity from BI_DB_PositionPnL (IsSettled=0)
  |   Step 4: Compute credit from V_Liabilities
  |   Step 5: DELETE + INSERT by DateID
  v
BI_DB_dbo.BI_DB_QMMF_Report_Finance (~399M rows, ROUND_ROBIN HEAP)
  |-- No UC target (Not_Migrated) --|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID | DWH_dbo.Dim_Customer (GCID) | Customer dimension |
| UnrealizedEquity CFD | BI_DB_dbo.BI_DB_PositionPnL | CFD position equity source |
| Credit | DWH_dbo.V_Liabilities | Credit balance source |

### 6.2 Referenced By (other objects point to this)

| Consuming Object | Relationship |
|-----------------|-------------|
| BI_DB_dbo.BI_DB_QMMF_Report | Sibling table — same SP, interaction-level detail |

---

## 7. Sample Queries

### 7.1 Daily Total CFD Exposure

```sql
SELECT
    DateID,
    COUNT(DISTINCT GCID) AS Customers,
    SUM([UnrealizedEquity CFD]) AS Total_CFD_Equity,
    SUM(Credit) AS Total_Credit
FROM BI_DB_dbo.BI_DB_QMMF_Report_Finance
WHERE DateID >= 20260101
GROUP BY DateID
ORDER BY DateID
```

### 7.2 High-Exposure QMMF Customers

```sql
SELECT
    f.GCID,
    f.[UnrealizedEquity CFD],
    f.Credit,
    r.Club,
    r.StateAdditionalData
FROM BI_DB_dbo.BI_DB_QMMF_Report_Finance f
JOIN BI_DB_dbo.BI_DB_QMMF_Report r ON f.GCID = r.GCID
WHERE f.DateID = (SELECT MAX(DateID) FROM BI_DB_dbo.BI_DB_QMMF_Report_Finance)
  AND f.[UnrealizedEquity CFD] > 50000
ORDER BY f.[UnrealizedEquity CFD] DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found specific to this table.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 5 T2, 0 T3, 0 T4, 1 T5 | Elements: 6/6, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_QMMF_Report_Finance | Type: Table | Production Source: BI_DB_PositionPnL + V_Liabilities via SP_QMMF_Report*
