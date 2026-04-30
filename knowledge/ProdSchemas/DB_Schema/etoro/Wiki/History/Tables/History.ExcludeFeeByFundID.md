# History.ExcludeFeeByFundID

> Temporal system-versioned history table storing all past versions of the overnight/weekend fee exemption list - recording every change to which customer accounts (typically Smart Portfolio fund accounts) are excluded from position carry fees.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; rows identified by (CID) + SysStartTime + SysEndTime |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

This table is the **SQL Server temporal history store** for `Trade.ExcludeFeeByFundID`. SQL Server automatically moves rows here whenever a fee exemption entry is updated or deleted.

`Trade.ExcludeFeeByFundID` is a **fee exemption whitelist** - each row holds a single customer account (`CID`) that is excluded from overnight fee and weekend (end-of-week) fee charges. These are typically eToro Smart Portfolio or investment fund accounts whose CIDs are registered as "fund IDs" for fee purposes.

**How the exclusion works** (from `Trade.GetPositionsForFeeBulkGeneral` and `Trade.GetPositionsForFeeProcess`):

The fee processing SPs apply a **two-level exclusion**:
1. **Direct**: Positions where `CID IN (SELECT CID FROM Trade.ExcludeFeeByFundID)` are not charged - the fund account's own positions are fee-exempt.
2. **Cascade**: The SP also collects all position IDs belonging to excluded CIDs into `#excludePositionBySmartPortfolioCID`, then excludes positions where `ParentPositionID IN` that set - meaning positions that were copied FROM an excluded fund account (i.e., the fund's copiers' positions that derive from fund positions) are also excluded.

This dual exclusion ensures that when eToro's own Smart Portfolio allocations are in fee-excluded accounts, neither the fund's direct positions nor the downstream copied positions triggered by those fund trades incur carry fees.

The table currently has **0 rows** in both `Trade.ExcludeFeeByFundID` and `History.ExcludeFeeByFundID` in this staging environment.

---

## 2. Business Logic

### 2.1 Temporal Versioning - How History Is Recorded

**What**: SQL Server automatically populates this table via system-versioning whenever a fee-exemption row is updated or deleted.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `CID`

**Rules**:
- When a row is **updated**: SQL Server moves the old version here with `SysEndTime` = the moment of update.
- When a row is **deleted**: SQL Server moves the row here with `SysEndTime` = deletion timestamp.
- Active rows in `Trade.ExcludeFeeByFundID` have `SysEndTime = '9999-12-31...'` and are NOT in this history table.
- CLUSTERED index on `(SysEndTime, SysStartTime)` enables efficient `FOR SYSTEM_TIME AS OF` temporal queries.

### 2.2 INSERT Trigger Creates Zero-Duration History Rows

**What**: `Tr_T_ExcludeFeeByFundID_INSERT` fires a no-op UPDATE after every INSERT into `Trade.ExcludeFeeByFundID`, generating a zero-duration history row for each newly added exemption.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `CID`

**Rules**:
- After INSERT, trigger executes: `UPDATE A SET A.CID = A.CID` (no-op self-update joined on CID).
- SQL Server temporal treats this as an UPDATE, moving the just-inserted row to history with `SysStartTime = SysEndTime = T` (zero-duration).
- This ensures every CID that was ever added to the exemption list has a history record even if immediately removed.
- Zero-duration rows (SysStartTime = SysEndTime) are INSERT artifacts; rows with SysStartTime < SysEndTime represent actual exemption periods.

### 2.3 Fee Exemption Application in Fee Processing

**What**: Three fee calculation SPs check this table to skip fee charges for exempt accounts.

**Rules** (from `Trade.GetPositionsForFeeBulkGeneral`, `Trade.GetPositionsForFeeBulkGeneral_Aus`, `Trade.GetPositionsForFeeProcess`):
- **Overnight fee** (CreditTypeID=14, Description='Over night fee'): Not charged if CID is in exemption list.
- **Weekend fee** (CreditTypeID=14, Description='Weekend fee'): Not charged if CID is in exemption list.
- **Cascade exclusion**: The SP creates a temp table `#excludePositionBySmartPortfolioCID` containing ALL active positions owned by exempted CIDs. Then the final fee charge set also excludes positions where `ParentPositionID IN #excludePositionBySmartPortfolioCID` - this removes copy-child positions that were initiated by fund account trades.
- The fee calculations still run to completion (FeeInDollars is computed) but the final INSERT to `Trade.SYN_FeeNightProcess` / fee queue filters these positions out.

**Diagram**:
```
Fee processing run (nightly/weekly):
  Trade.GetPositionsForFeeProcess / GetPositionsForFeeBulkGeneral

  Step 1: Build excluded positions from fund accounts
    SELECT PositionID INTO #excludePositionBySmartPortfolioCID
    FROM Trade.Position WHERE CID IN (SELECT CID FROM Trade.ExcludeFeeByFundID)

  Step 2: Final fee charge set excludes:
    - CID directly in ExcludeFeeByFundID (fund's own positions)
    - ParentPositionID in #excludePositionBySmartPortfolioCID (fund's copiers' positions)

  Result: Fund accounts and their copy-derived positions pay no overnight/weekend fees
```

### 2.4 Audit Attribution via DbLoginName

**What**: `DbLoginName` captures who modified the exemption list.

**Columns/Parameters Involved**: `DbLoginName`

**Rules**:
- `DbLoginName = suser_name()` - computed column on source, captures the SQL Server login that performed the DML.
- No `AppLoginName` column exists on this table (unlike other temporal tables such as `Trade.ExcludeFeeByFundID` only tracks the DB-level login).
- No SP writers found in SSDT - exemptions are managed via direct DML (SSMS or an admin tool).

---

## 3. Data Overview

The table currently contains **0 rows** (staging environment - no fund CIDs registered). A representative history row would look like:

| CID | DbLoginName | SysStartTime | SysEndTime | Meaning |
|---|---|---|---|---|
| 12345 | TRAD\admin | 2024-01-15 09:00 | 2024-01-15 09:00 | Zero-duration INSERT artifact - fund CID 12345 was added to the exemption list |
| 12345 | TRAD\admin | 2024-01-15 09:00 | 2025-06-01 12:30 | Fund CID 12345 was fee-exempt from Jan 2024 to Jun 2025, then removed from the list |

All history rows have the same `DbLoginName` for INSERT artifacts (SysStartTime=SysEndTime) as for the subsequent active period, since both are generated from the same or subsequent DML by the same login.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer account identifier of the fee-exempt account. PK in source table (Trade.ExcludeFeeByFundID, PK_CIDFee, FILLFACTOR=90). Typically a Smart Portfolio / fund account CID. One CID = one exemption entry; a single fund account registers once and all its positions (and their copy-children) are exempt from overnight and weekend fees. |
| 2 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | SQL Server login that performed the DML on Trade.ExcludeFeeByFundID, captured via `suser_name()` computed column on source. Identifies the DBA or admin who added or removed the exemption. NULL if suser_name() unavailable. |
| 3 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this exemption version became active in Trade.ExcludeFeeByFundID. Managed by SQL Server temporal system-versioning. Equal to SysEndTime for INSERT-triggered zero-duration rows. |
| 4 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this version was superseded (exemption updated or CID removed). Clustered index leading column. Equal to SysStartTime for INSERT-triggered zero-duration rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | Implicit | The customer account that is fee-exempt (FK on source: PK_CIDFee constraint on CID) |
| (all columns) | Trade.ExcludeFeeByFundID | Temporal | This row is a historical version of the source table row with matching CID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ExcludeFeeByFundID | (all columns) | Temporal (SYSTEM_VERSIONING) | Source table - SQL Server writes superseded rows here |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ExcludeFeeByFundID (table)
- Temporal history leaf node - no code-level dependencies
- Populated automatically from Trade.ExcludeFeeByFundID (table)
- INSERT trigger on source (Tr_T_ExcludeFeeByFundID_INSERT) creates additional zero-duration history rows

Trade.ExcludeFeeByFundID is READ by:
- Trade.GetPositionsForFeeBulkGeneral (fee processing SP - general)
- Trade.GetPositionsForFeeBulkGeneral_Aus (fee processing SP - Australia)
- Trade.GetPositionsForFeeProcess (fee processing SP - newer version)
```

### 6.1 Objects This Depends On

No dependencies. Temporal history table populated automatically by SQL Server.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ExcludeFeeByFundID | Table | Source table - SQL Server writes old row versions here automatically on UPDATE/DELETE; INSERT trigger also generates zero-duration rows |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_ExcludeFeeByFundID | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

**Filegroup**: [MAIN] - matches source table, different from [HISTORY] used by large audit tables.
**Storage**: DATA_COMPRESSION = PAGE (table-level and index-level).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| None | - | Temporal history tables cannot have PK, UNIQUE, FK, or CHECK constraints in SQL Server |

---

## 8. Sample Queries

### 8.1 Full exemption history for a specific CID
```sql
-- Historical periods
SELECT 'History' AS Source, CID, DbLoginName, SysStartTime, SysEndTime,
       DATEDIFF(DAY, SysStartTime, SysEndTime) AS DurationDays
FROM [History].[ExcludeFeeByFundID]
WHERE CID = 12345
  AND SysStartTime < SysEndTime  -- exclude zero-duration INSERT artifacts
UNION ALL
-- Current active exemption (if any)
SELECT 'Current' AS Source, CID, DbLoginName, SysStartTime, SysEndTime, NULL
FROM [Trade].[ExcludeFeeByFundID]
WHERE CID = 12345
ORDER BY SysStartTime
```

### 8.2 Which CIDs were exempt on a specific date
```sql
SELECT CID, DbLoginName, SysStartTime, SysEndTime
FROM [History].[ExcludeFeeByFundID]
WHERE '2024-06-01' BETWEEN SysStartTime AND SysEndTime
  AND SysStartTime < SysEndTime  -- exclude zero-duration INSERT artifacts
ORDER BY CID
```

### 8.3 Audit - all exemption changes ordered by time
```sql
SELECT CID, DbLoginName, SysStartTime, SysEndTime,
       CASE WHEN SysStartTime = SysEndTime THEN 'INSERT artifact'
            WHEN SysEndTime < '9999-12-31' THEN 'Removed/Updated'
            ELSE 'Active' END AS EventType
FROM [History].[ExcludeFeeByFundID]
WHERE SysStartTime < SysEndTime  -- exclude INSERT artifacts
ORDER BY SysStartTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Note: Table has 0 rows in staging - business logic inferred from Trade.GetPositionsForFeeBulkGeneral and Trade.GetPositionsForFeeProcess*
*Object: History.ExcludeFeeByFundID | Type: Table | Source: etoro/etoro/History/Tables/History.ExcludeFeeByFundID.sql*
