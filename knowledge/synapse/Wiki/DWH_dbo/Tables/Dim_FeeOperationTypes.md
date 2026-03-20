# DWH_dbo.Dim_FeeOperationTypes

> Fee operation type dimension - maps integer codes to labels classifying fee calculation scope as Open (entry fee), Close (exit fee), or All (applies to both).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.FeeOperationTypes |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (FeeOperationTypeID ASC) |
| | |
| **UC Target** | _Pending - resolved during write-objects_ |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_FeeOperationTypes` is a dictionary with only 3 distinct values (1=Open, 2=Close, 3=All), classifying whether a fee applies at position open, at position close, or at both events. This dimension is used in the HistoryCosts fee calculation system to determine when a cost is charged.

**CRITICAL DATA QUALITY ISSUE**: This table has a known ETL bug. The `SP_Dictionaries_DL_To_Synapse` script performs an INSERT without a preceding TRUNCATE for this table (all other dictionary tables use TRUNCATE+INSERT). As a result, the 3 distinct rows are duplicated on every SP run. As of 2026-03-19, the table contains **897 total rows** (approximately 299 accumulated daily loads). Any query to this table MUST use `SELECT DISTINCT` or deduplicate before joining.

The data originates from `etoro.Dictionary.FeeOperationTypes` on the production etoroDB-REAL server via `DWH_staging.etoro_Dictionary_FeeOperationTypes`. No upstream wiki exists for this table.

`FeeOperationTypeID` passes through unchanged from staging. `Name` is renamed to `FeeOperationTypeName`. `UpdateDate = GETDATE()` (NOT NULL constraint).

---

## 2. Business Logic

### 2.1 Fee Timing Classification

**What**: The three fee operation types classify when a fee/cost is applied in the position lifecycle.

**Columns Involved**: `FeeOperationTypeID`, `FeeOperationTypeName`

**Rules**:
- 1 = Open: Fee is charged when a position is opened (entry fee)
- 2 = Close: Fee is charged when a position is closed (exit fee)
- 3 = All: Fee applies to both open and close operations

**Diagram**:
```
Position lifecycle:
  [Open] ---> [Active] ---> [Close]
    ^                          ^
    |                          |
FeeOperationTypeID=1    FeeOperationTypeID=2
   (Open fee)              (Close fee)
    |                          |
    +----FeeOperationTypeID=3--+
              (All fee)
```

### 2.2 ETL Bug - Row Accumulation

**What**: SP_Dictionaries_DL_To_Synapse inserts without truncating, accumulating duplicates.

**Columns Involved**: All columns

**Rules**:
- The SP INSERT block for Dim_FeeOperationTypes has no preceding TRUNCATE (unlike all other dict tables)
- Each daily SP run appends 3 more rows
- 897 rows as of 2026-03-19 = approximately 299 daily runs since the bug was introduced
- The 3 distinct values (1=Open, 2=Close, 3=All) are correct but duplicated ~299 times

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, ROUND_ROBIN distributed (anomaly - same as Dim_CalculationType and Dim_ExecutionOperationType). With 897 rows (due to bug), joins from large tables will have data movement. Once the bug is fixed and the table returns to 3 rows, REPLICATE would be more appropriate.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, small table despite the bug. Broadcast join automatic.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode FeeOperationTypeID | `LEFT JOIN (SELECT DISTINCT FeeOperationTypeID, FeeOperationTypeName FROM DWH_dbo.Dim_FeeOperationTypes) AS fee ON ...` |
| Safe dedup join | Always use `SELECT DISTINCT` or a CTE to deduplicate before joining |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_History_Cost (pending) | ON FeeOperationTypeID | Classify costs by fee timing |

### 3.4 Gotchas

- **DO NOT JOIN directly**: The table has 897 rows instead of 3. A direct JOIN will multiply your result set by ~299x. Always `SELECT DISTINCT FeeOperationTypeID, FeeOperationTypeName FROM Dim_FeeOperationTypes` before joining.
- **Bug is in the ETL SP**: The fix requires adding `TRUNCATE TABLE [DWH_dbo].[Dim_FeeOperationTypes]` before the INSERT in `SP_Dictionaries_DL_To_Synapse` (around line 1404). After the fix, a manual truncate is needed to remove accumulated rows.
- **ROUND_ROBIN anomaly**: Same as Dim_ExecutionOperationType - REPLICATE would be appropriate for a 3-row table.
- **UpdateDate NOT NULL**: Unusual constraint for a dictionary table; consistent with Dim_ExecutionOperationType (both from HistoryCosts section of SP_Dictionaries, though this one is from etoro).

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| *** | Tier 2 | Synapse SP code (SP_Dictionaries_DL_To_Synapse) |
| ** | Tier 3 | Live data / DDL structure |
| * | Tier 4 | Inferred [UNVERIFIED] |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FeeOperationTypeID | int | YES | Fee timing phase: 1=Open (at position entry), 2=Close (at position exit), 3=All (both phases). Referenced by Trade.FixPerLotConfigurations, Trade.FeeInPercentageConfigurations, and fee validation procedures. (Tier 1 — Dictionary.FeeOperationTypes) |
| 2 | FeeOperationTypeName | nvarchar(max) | YES | Human-readable phase label: 'Open', 'Close', 'All'. Used in trading engine configuration and admin UIs. (Tier 1 — Dictionary.FeeOperationTypes) |
| 3 | UpdateDate | datetime | NO | ETL load timestamp. Set to GETDATE() on each SP run. NOT NULL constraint (unusual for DWH dict tables). Because there is no TRUNCATE, this column stores the time of each accumulated run, not just the last run. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| FeeOperationTypeID | etoro.Dictionary.FeeOperationTypes | FeeOperationTypeID | passthrough |
| FeeOperationTypeName | etoro.Dictionary.FeeOperationTypes | Name | rename: Name -> FeeOperationTypeName |
| UpdateDate | - | - | ETL-computed: GETDATE() at SP execution time |

### 5.2 ETL Pipeline

```
etoro.Dictionary.FeeOperationTypes -> Generic Pipeline -> DWH_staging.etoro_Dictionary_FeeOperationTypes -> SP_Dictionaries_DL_To_Synapse (INSERT ONLY - NO TRUNCATE BUG) -> DWH_dbo.Dim_FeeOperationTypes
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.FeeOperationTypes | Fee operation type dictionary on etoroDB-REAL |
| Lake | Bronze/etoro/Dictionary/FeeOperationTypes/ | Daily Generic Pipeline export |
| Staging | DWH_staging.etoro_Dictionary_FeeOperationTypes | Raw import |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | INSERT ONLY (missing TRUNCATE - DATA QUALITY BUG). Adds UpdateDate=GETDATE(). |
| Target | DWH_dbo.Dim_FeeOperationTypes | 3 distinct values, 897 total rows (accumulated). ROUND_ROBIN anomaly. |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| N/A | - | No foreign key references. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_History_Cost (pending) | FeeOperationTypeID (expected) | Fee operation type for cost records |

---

## 7. Sample Queries

### 7.1 Get distinct fee operation types (safe dedup)

```sql
SELECT DISTINCT FeeOperationTypeID, FeeOperationTypeName
FROM DWH_dbo.Dim_FeeOperationTypes
ORDER BY FeeOperationTypeID
```

### 7.2 Safe join template (avoids row multiplication bug)

```sql
WITH FeeDim AS (
    SELECT DISTINCT FeeOperationTypeID, FeeOperationTypeName
    FROM DWH_dbo.Dim_FeeOperationTypes
)
SELECT
    hc.CostID,
    fd.FeeOperationTypeName
FROM DWH_dbo.Fact_History_Cost hc
LEFT JOIN FeeDim fd ON hc.FeeOperationTypeID = fd.FeeOperationTypeID
```

### 7.3 Diagnose the accumulation bug

```sql
SELECT
    FeeOperationTypeID,
    COUNT(*) AS RowCount,
    MIN(UpdateDate) AS EarliestRun,
    MAX(UpdateDate) AS LatestRun
FROM DWH_dbo.Dim_FeeOperationTypes
GROUP BY FeeOperationTypeID
ORDER BY FeeOperationTypeID
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|-------------------------|
| [Fees](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/1137475986/Fees) | Confluence | Enumerates major eToro fee categories (conversion, withdrawal, etc.)—customer-facing vocabulary for fee events that may be tagged by operation phase (cash movement vs trading). |
| [Conversion Fee](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/1137344864/Conversion+Fee) | Confluence | Conversion fees can apply on deposit, withdrawal, open/close, dividends—illustrates **when** fees apply in the client lifecycle (Open/Close/All semantics at a business level). |
| [Withdrawal fees and conversion fees](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/11699453953/Withdrawal+fees+and+conversion+fees) | Confluence | Withdrawal fee and FX conversion rules by account currency—supports interpreting fee timing on cash-out vs in-account trading. |

---

*Generated: 2026-03-19 | Quality: 7.2/10 (****) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 7/10*
*Object: DWH_dbo.Dim_FeeOperationTypes | Type: Table | Production Source: etoro.Dictionary.FeeOperationTypes*
