# BI_DB_dbo.BI_DB_PI_StatusPanel

> 11K-row accumulating table tracking the most recent PI tier upgrade, downgrade, and removal events for each customer who has ever been a Popular Investor. Daily UPDATE+INSERT (upsert pattern) via SP_PI_StatusPanel. Source: Fact_SnapshotCustomer GuruStatusID change detection via LAG() window function.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer + Dim_GuruStatus via `SP_PI_StatusPanel` |
| **Refresh** | Daily (UPDATE existing + INSERT new — accumulating, not truncate) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | Katy F (2017-06-01), rewritten by Ben Einav (2024-05-10) |
| **Row Count** | ~11,031 (as of 2026-04-13) |

---

## 1. Business Meaning

`BI_DB_PI_StatusPanel` tracks the most recent PI tier change events for each customer. Unlike most BI_DB tables that use TRUNCATE+INSERT, this table uses an **accumulating pattern**: existing rows are UPDATEd with new event data, and new CIDs are INSERTed. This means the table grows over time as more customers enter the PI program.

For each customer who has been in the PI program within the last year, the table records:
- **Last Downgrade**: Most recent tier reduction (e.g., Champion → Cadet), excluding downgrades TO GuruStatusID=1 (Certified)
- **Last Upgrade**: Most recent tier promotion (e.g., No → Cadet, Cadet → Champion), excluding upgrades TO GuruStatusID=1
- **Last Removed**: Most recent date the customer was demoted to GuruStatusID=0 (No / removed from PI program)

Change detection uses `LAG(GuruStatusID) OVER (PARTITION BY CID ORDER BY DateRangeID)` on Fact_SnapshotCustomer to identify where GuruStatusID changed between consecutive snapshot periods.

As of 2026-04-13: 11,031 PI accounts tracked. Data accumulates from 2024-05-10 (SP creation date) onward. Recent events show mostly Cadet upgrades (No → Cadet).

---

## 2. Business Logic

### 2.1 Upgrade Detection

**What**: Identifies the most recent tier promotion for each PI.
**Columns Involved**: `LastUpgradeID`, `LastUpgradeTo`, `LastUpgradeFromID`, `LastUpgradeFrom`, `LastUpgradeDate`
**Rules**:
- Upgrade = GuruStatusID > PrevGuruStatusID (current tier higher than previous)
- Excludes upgrades where target GuruStatusID = 1 (Certified is treated as non-PI)
- Only the most recent upgrade is kept (ROW_NUMBER DESC, rn=1)

### 2.2 Downgrade Detection

**What**: Identifies the most recent tier demotion for each PI.
**Columns Involved**: `LastDowngradeID`, `LastDowngradeTo`, `LastDowngradeFromID`, `LastDowngradeFrom`, `LastDowngradeDate`
**Rules**:
- Downgrade = GuruStatusID < PrevGuruStatusID (current tier lower than previous)
- Excludes downgrades where target GuruStatusID = 1 (Certified)
- Only the most recent downgrade is kept (ROW_NUMBER DESC, rn=1)

### 2.3 Removal Detection

**What**: Identifies the most recent date the PI was removed from the program.
**Columns Involved**: `LastRemovedDate`
**Rules**:
- Removed = GuruStatusID < PrevGuruStatusID AND GuruStatusID = 0 (demoted to "No")
- MAX date across all removal events for each CID

### 2.4 Accumulating Upsert Pattern

**What**: The table accumulates over time — existing rows are updated, new CIDs are inserted.
**Rules**:
- Only CIDs with recent events (downgrade/upgrade/removal date >= @date parameter) are processed
- Existing CIDs: UPDATE all columns
- New CIDs: INSERT
- This means rows persist even if the PI is currently inactive

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on CID ASC — efficient for CID lookups.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Recently demoted PIs | `WHERE LastDowngradeDate >= DATEADD(DAY, -30, GETDATE())` |
| PIs removed from program | `WHERE LastRemovedDate IS NOT NULL ORDER BY LastRemovedDate DESC` |
| PI tier promotion history | `WHERE LastUpgradeTo IS NOT NULL ORDER BY LastUpgradeDate DESC` |
| PIs with both upgrade and downgrade | `WHERE LastUpgradeDate IS NOT NULL AND LastDowngradeDate IS NOT NULL` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `CID = RealCID` | Full customer profile |
| DWH_dbo.Dim_GuruStatus | `LastDowngradeID = GuruStatusID` or `LastUpgradeID = GuruStatusID` | Tier details |

### 3.4 Gotchas

- **Not truncated daily**: This table accumulates — it UPDATE+INSERTs, not TRUNCATE. Historical rows persist
- **GuruStatusID=1 excluded**: Upgrades/downgrades TO Certified (ID=1) are excluded from both upgrade and downgrade tracking
- **Multiple event types per CID**: A CID can have both a LastUpgrade and LastDowngrade — they are independent events
- **LastRemovedDate can coexist with LastUpgradeDate**: A PI can be removed then re-admitted later
- **Column count**: DDL has 13 columns (including UpdateDate), not 14 as batch assignment stated

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID. Mapped from Fact_SnapshotCustomer.RealCID. Clustered index key. (Tier 1 — Customer.CustomerStatic) |
| 2 | LastDowngradeID | int | YES | GuruStatusID of the most recent downgrade target tier. NULL if no downgrade recorded. Values: 0=No, 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite. (Tier 1 — Dictionary.GuruStatus) |
| 3 | LastDowngradeTo | varchar(100) | YES | Human-readable name of the downgrade target tier. From Dim_GuruStatus.GuruStatusName. (Tier 1 — Dictionary.GuruStatus) |
| 4 | LastDowngradeFromID | int | YES | GuruStatusID of the tier BEFORE the downgrade. NULL if no downgrade recorded. (Tier 1 — Dictionary.GuruStatus) |
| 5 | LastDowngradeFrom | varchar(100) | YES | Human-readable name of the tier before downgrade. From Dim_GuruStatus.GuruStatusName. (Tier 1 — Dictionary.GuruStatus) |
| 6 | LastDowngradeDate | date | YES | Date of the most recent downgrade event. Derived from Dim_Range.FromDateID. NULL if no downgrade. (Tier 2 — SP_PI_StatusPanel) |
| 7 | LastUpgradeID | int | YES | GuruStatusID of the most recent upgrade target tier. NULL if no upgrade recorded. (Tier 1 — Dictionary.GuruStatus) |
| 8 | LastUpgradeTo | varchar(100) | YES | Human-readable name of the upgrade target tier. From Dim_GuruStatus.GuruStatusName. (Tier 1 — Dictionary.GuruStatus) |
| 9 | LastUpgradeFromID | int | YES | GuruStatusID of the tier BEFORE the upgrade. NULL if no upgrade recorded. (Tier 1 — Dictionary.GuruStatus) |
| 10 | LastUpgradeFrom | varchar(100) | YES | Human-readable name of the tier before upgrade. From Dim_GuruStatus.GuruStatusName. (Tier 1 — Dictionary.GuruStatus) |
| 11 | LastUpgradeDate | date | YES | Date of the most recent upgrade event. Derived from Dim_Range.FromDateID. NULL if no upgrade. (Tier 2 — SP_PI_StatusPanel) |
| 12 | LastRemovedDate | date | YES | Date of the most recent removal from the PI program (downgrade to GuruStatusID=0). NULL if never removed. (Tier 2 — SP_PI_StatusPanel) |
| 13 | UpdateDate | datetime | YES | ETL execution timestamp. GETDATE() at SP execution time. (Tier 2 — SP_PI_StatusPanel) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID | Customer.CustomerStatic | CID | passthrough via Fact_SnapshotCustomer.RealCID |
| LastDowngradeID/To/FromID/From | Dictionary.GuruStatus | GuruStatusID/Name | dim-lookup via Dim_GuruStatus |
| LastUpgradeID/To/FromID/From | Dictionary.GuruStatus | GuruStatusID/Name | dim-lookup via Dim_GuruStatus |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (GuruStatusID != 0, last year)
  + DWH_dbo.Dim_Range (date range for FromDateID)
  + DWH_dbo.Dim_GuruStatus (tier names)
  |
  |-- SP_PI_StatusPanel @date (daily UPDATE + INSERT)
  |   Step 1: Find PI population (GuruStatusID != 0 in last year)
  |   Step 2: Detect status changes via LAG(GuruStatusID) on Fact_SnapshotCustomer
  |   Step 3: Resolve tier names from Dim_GuruStatus
  |   Step 4: Find last downgrade (GuruStatusID < Prev, exclude ID=1, ROW_NUMBER rn=1)
  |   Step 5: Find last upgrade (GuruStatusID > Prev, exclude ID=1, ROW_NUMBER rn=1)
  |   Step 6: Find last removal (downgrade to GuruStatusID=0, MAX date)
  |   Step 7: Filter to recent events (>= @date)
  |   Step 8: UPDATE existing CIDs, INSERT new CIDs
  v
BI_DB_dbo.BI_DB_PI_StatusPanel (11K rows, ROUND_ROBIN CI(CID))
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer dimension |
| LastDowngradeID/LastUpgradeID | DWH_dbo.Dim_GuruStatus | PI tier classification |

### 6.2 Referenced By (other objects point to this)

No known consumers in the current wiki inventory.

---

## 7. Sample Queries

### 7.1 Recent PI Downgrades

```sql
SELECT CID, LastDowngradeFrom, LastDowngradeTo, LastDowngradeDate
FROM BI_DB_dbo.BI_DB_PI_StatusPanel
WHERE LastDowngradeDate >= DATEADD(DAY, -30, GETDATE())
ORDER BY LastDowngradeDate DESC
```

### 7.2 PIs Removed and Later Re-Admitted

```sql
SELECT CID, LastRemovedDate, LastUpgradeTo, LastUpgradeDate
FROM BI_DB_dbo.BI_DB_PI_StatusPanel
WHERE LastRemovedDate IS NOT NULL AND LastUpgradeDate > LastRemovedDate
ORDER BY LastUpgradeDate DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable due to permissions).

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 9 T1, 4 T2, 0 T3, 0 T4, 0 T5 | Elements: 13/13, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_PI_StatusPanel | Type: Table | Production Source: Fact_SnapshotCustomer + Dim_GuruStatus via SP_PI_StatusPanel*
