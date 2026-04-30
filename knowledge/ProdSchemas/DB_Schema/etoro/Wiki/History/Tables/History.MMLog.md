# History.MMLog

> Money Management failure log for copy-trading position synchronization - each row records a specific MM failure event (disconnected parent, max stop loss reached, max unit size exceeded, etc.) to prevent recovery processes from repeatedly attempting to fix known-failed positions.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (int, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (CLUSTERED PK on ID, NC on FailTypeID INCLUDE PositionID) |

---

## 1. Business Meaning

This table is the **Money Management (MM) failure event log** for eToro's copy-trading (Mirror Trading) system. When the MM subsystem encounters a failure while attempting to synchronize a child position to its parent (e.g., a copied position can't be opened to its target size, a position reaches its max stop loss, or a position loses its parent connection), it logs the failure here.

The primary role of this table is **recovery suppression**: several recovery views query MMLog to determine which positions have known MM failures and should be SKIPPED by the MM recovery process. Without this check, the recovery process would repeatedly attempt to fix the same broken positions.

**Written by**: `History.LogMMNotification` - a simple INSERT SP called by the hedging/copy-trading layer.

**Read by**:
- `Trade.ClosePositionsGetRecoveryItemsDemo` - excludes positions with FailTypeID=8 from close recovery
- `Trade.GetRealEditOWMMRecovery` - excludes positions with FailTypeID=9 from CloseOnEndOfWeek (OW) edit recovery
- `Trade.GetRealEditSLMMRecovery` / `Trade.GetRealEditSLMMRecovery_Org` - excludes positions with FailTypeID=9 from stop loss (SL) edit recovery
- `Trade.GetRecoveryItemsDemo` - marks positions as `MaxSLReached=1` when FailTypeID=9 exists

**FailType dictionary** (from `Dictionary.FailType`, 17 values):

| FailTypeID | Name | Used in MMLog |
|---|---|---|
| 1 | Request To Open | Possible |
| 2 | Request To Close | Possible |
| 3 | Open | Possible |
| 4 | Close | Possible |
| 5 | Edit | Possible |
| 6 | External Error | Possible |
| 7 | Internal Error | Possible |
| 8 | MM object disconnected from its parent | YES - recovery exclusion in views |
| 9 | MM Max StopLoss | YES - recovery exclusion, MaxSLReached flag |
| 10 | Min Position Amount | Possible |
| 11 | Mirror edit StopLoss insufficient funds | Possible |
| 12 | Max position amount in units | YES - observed in data (staging) |
| 13 | Max Take Profit reached | Possible |
| 14 | PositionRedeemCancelFail | Possible |
| 15 | PositionRedeemPendingFail | Possible |
| 16 | PositionRedeemCloseFail | Possible |
| 17 | Detach | Possible |

The table has **8 rows** in staging - all FailTypeID=12 from October 2023.

---

## 2. Business Logic

### 2.1 MM Failure Logging Pattern

**What**: The MM system calls `History.LogMMNotification` to record a failure for a position.

**Columns/Parameters Involved**: All columns

**Rules** (from `History.LogMMNotification`):
- `Occurred` = GETUTCDATE() at insert time (SP does not accept a timestamp parameter).
- `PositionID = 0`: The failure is not tied to a specific child position (e.g., FailTypeID=12 rows in staging where the child was never successfully opened). In this case, `ParentPositionID` identifies the parent.
- `PositionID > 0`: The failure is tied to a specific position (e.g., FailTypeID=8 or 9 where an existing position failed).
- `MirrorID` is populated when the failure is related to a copy-trading Mirror (Smart Portfolio).
- `OrderID` defaults to 0 when not specified.
- Multiple rows can exist for the same PositionID with the same or different FailTypeIDs.

### 2.2 Recovery Exclusion Pattern

**What**: Recovery views use MMLog as a "don't retry" list.

**Columns/Parameters Involved**: `PositionID`, `FailTypeID`

**Rules** (from recovery views):
- `FailTypeID = 8 (MM object disconnected from its parent)`:
  - Excludes the position from **close recovery** (`Trade.ClosePositionsGetRecoveryItemsDemo`, `Trade.GetRecoveryItemsDemo`).
  - Rationale: A disconnected MM position cannot be closed via the normal MM path.
- `FailTypeID = 9 (MM Max StopLoss)`:
  - Excludes the position from **SL edit recovery** (`Trade.GetRealEditSLMMRecovery`): `NOT EXISTS (SELECT 1 FROM History.MMLog WHERE PositionID = TGP.PositionID AND FailTypeID = 9)`.
  - Excludes from **OW (Over-Weekend) edit recovery** (`Trade.GetRealEditOWMMRecovery`).
  - Marks the position as `MaxSLReached = 1` in `Trade.GetRecoveryItemsDemo`.
  - Rationale: A position at max stop loss should not have its SL edited further.
- **Deduplication**: MMLog rows are never deleted - once logged, a position stays excluded from recovery indefinitely. If the failure is resolved, the application logic must bypass this check explicitly.

### 2.3 FailTypeID=12 - Max Position Amount in Units (Staging Data)

**What**: The 8 staging rows illustrate a specific copy-trading failure pattern.

**Rules** (from actual data, Oct 2023):
- `PositionID = 0`: No child position was opened (the open attempt failed before position creation).
- `ParentPositionID` populated: The parent (Mirror) position that triggered the copy.
- `MirrorID` populated: The Smart Portfolio / Mirror these positions belong to.
- `Details` format: `"Max child position AmountInUnits reached! ParentPositionID: {X} Target: LotCount {T} AmountInUnits {T}, Actual: LotCount {A} AmountInUnits {A}"`.
- The "Actual" size (e.g., 890 units) is less than the "Target" size (e.g., 1526 or 2290 units) because a maximum unit size cap was enforced.
- All 8 rows relate to MirrorID 1831540 and 1831541, ParentPositionIDs 2149997601/2149997604/2149997607/2149997610 - a specific Smart Portfolio's positions that repeatedly hit the max unit cap over two successive processing attempts.

---

## 3. Data Overview

| ID | PositionID | FailTypeID | Occurred | MirrorID | ParentPositionID | Details Summary |
|---|---|---|---|---|---|---|
| 37759887 | 0 | 12 | 2023-10-11 14:40 | 1831540 | 2149997601 | Max units: target 1526.7, actual 890 |
| 37759888 | 0 | 12 | 2023-10-11 14:40 | 1831540 | 2149997604 | Max units: target 1526.7, actual 890 |
| 37759889 | 0 | 12 | 2023-10-11 14:40 | 1831540 | 2149997607 | Max units: target 1526.7, actual 890 |
| 37759890 | 0 | 12 | 2023-10-11 14:40 | 1831540 | 2149997610 | Max units: target 987.6, actual 890 |
| 37759891-37759894 | 0 | 12 | 2023-10-11 15:10 | 1831541 | Same 4 parents | Repeated failures ~30 min later, larger targets |

IDs jump from nothing to 37,759,887 - this is the highest seen ID in staging, meaning the production system had processed ~37.7M MM notifications at the time this staging data was imported.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY | VERIFIED | Surrogate PK (IDENTITY(1,1), NOT FOR REPLICATION). CLUSTERED - append-only log pattern with sequential ID as physical order. IDs starting at 37.7M in staging suggest production has 37.7M+ MM failure events in history. |
| 2 | PositionID | bigint | NO | - | VERIFIED | The child position that failed. `0` when the failure occurred before a position was created (e.g., FailTypeID=12 - max unit size prevented position opening). When > 0, identifies a specific position in Trade.PositionTbl or History.Position_Active. Changed to bigint in Nov 2021 (per SP change log). |
| 3 | FailTypeID | int | NO | - | VERIFIED | The type of MM failure. FK to Dictionary.FailType (17 values). Recovery views specifically check FailTypeID=8 (disconnected from parent) and FailTypeID=9 (max stop loss). FailTypeID=12 (max position amount in units) is seen in staging data. NC index on this column with INCLUDE PositionID for fast recovery exclusion lookups. |
| 4 | Occurred | datetime | NO | GETUTCDATE() | VERIFIED | UTC timestamp when the failure was logged (set to GETUTCDATE() in LogMMNotification SP). Not passed as a parameter - always the actual time of the INSERT. |
| 5 | Details | varchar(250) | YES | - | VERIFIED | Free-text failure message from the MM system. For FailTypeID=12: "Max child position AmountInUnits reached! ParentPositionID: {X} Target: LotCount {T} AmountInUnits {T}, Actual: LotCount {A} AmountInUnits {A}". NULL for failures with no descriptive message. |
| 6 | ParentPositionID | bigint | YES | - | VERIFIED | The parent position ID when the failure is in a copy-trading context. For FailTypeID=12 with PositionID=0, this identifies which parent position triggered the failed copy attempt. bigint to match PositionID precision. |
| 7 | MirrorID | int | YES | - | VERIFIED | The Smart Portfolio / Mirror ID when the failure is in a copy-trading context. Links to Trade.Mirror. For the staging data, all 8 rows are tied to two specific MirrorIDs (1831540, 1831541). |
| 8 | OrderID | int | NO | 0 | VERIFIED | The order ID associated with the failure, if any. Defaults to 0 (per DF_HistoryMMLog constraint). Most failures don't involve a specific order. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FailTypeID | Dictionary.FailType | Implicit (explicit FK not on table) | The MM failure category (17 values) |
| PositionID | Trade.PositionTbl / History.Position_Active | Implicit | The failing child position (0 = pre-creation failure) |
| ParentPositionID | Trade.PositionTbl / History.Position_Active | Implicit | The parent position in copy-trading context |
| MirrorID | Trade.Mirror | Implicit | The Smart Portfolio this failure belongs to |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.LogMMNotification | PositionID, FailTypeID | Writer | Inserts MM failure records |
| Trade.ClosePositionsGetRecoveryItemsDemo | MMLog | Reader | Excludes positions with FailTypeID=8 from close recovery |
| Trade.GetRealEditOWMMRecovery | MMLog | Reader | Excludes positions with FailTypeID=9 from OW edit recovery |
| Trade.GetRealEditSLMMRecovery | MMLog | Reader | Excludes positions with FailTypeID=9 from SL edit recovery |
| Trade.GetRealEditSLMMRecovery_Org | MMLog | Reader | Same as above (original version) |
| Trade.GetRecoveryItemsDemo | MMLog | Reader | Marks FailTypeID=9 as MaxSLReached; excludes FailTypeID=8 from close recovery |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.MMLog (table)
- Append-only failure log
- Written by History.LogMMNotification (SP)
- Read by: Trade recovery views (Trade.ClosePositionsGetRecoveryItemsDemo,
  Trade.GetRealEditOWMMRecovery, Trade.GetRealEditSLMMRecovery,
  Trade.GetRealEditSLMMRecovery_Org, Trade.GetRecoveryItemsDemo)
```

### 6.1 Objects This Depends On

No structural dependencies (FKs not enforced on this table).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.LogMMNotification | Stored Procedure | Writer - inserts MM failure events |
| Trade.ClosePositionsGetRecoveryItemsDemo | View | Reader - FailTypeID=8 exclusion |
| Trade.GetRealEditOWMMRecovery | View | Reader - FailTypeID=9 exclusion |
| Trade.GetRealEditSLMMRecovery | View | Reader - FailTypeID=9 exclusion |
| Trade.GetRealEditSLMMRecovery_Org | View | Reader - FailTypeID=9 exclusion |
| Trade.GetRecoveryItemsDemo | View | Reader - FailTypeID=8 and 9 checks |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryMMLog | CLUSTERED (PK) | ID ASC | - | - | Active |
| MMLog_FailTypeID | NONCLUSTERED | FailTypeID ASC | PositionID | - | Active |

**Note**: The NC index on FailTypeID INCLUDE PositionID is on [MAIN] filegroup while the CLUSTERED PK is on [PRIMARY]. The INCLUDE on PositionID means the recovery view's `WHERE PositionID = X AND FailTypeID = Y` query can be satisfied from the NC index without a key lookup.

**Filegroup**: Table on [PRIMARY], NC index on [MAIN]. PAGE compression on both.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryMMLog | PRIMARY KEY (CLUSTERED) | Uniqueness on ID |
| DF_HistoryMMLog_Occurred | DEFAULT | Occurred = getutcdate() |
| DF_HistoryMMLog | DEFAULT | OrderID = 0 |

---

## 8. Sample Queries

### 8.1 Recent MM failures by type
```sql
SELECT ft.Name AS FailTypeName, COUNT(*) AS FailureCount,
       MIN(mm.Occurred) AS FirstOccurrence,
       MAX(mm.Occurred) AS LastOccurrence
FROM [History].[MMLog] mm
JOIN [Dictionary].[FailType] ft ON mm.FailTypeID = ft.FailTypeID
WHERE mm.Occurred >= DATEADD(day, -30, GETUTCDATE())
GROUP BY mm.FailTypeID, ft.Name
ORDER BY FailureCount DESC
```

### 8.2 Positions blocked from SL recovery (FailTypeID=9)
```sql
SELECT mm.PositionID, mm.MirrorID, mm.Occurred, mm.Details
FROM [History].[MMLog] mm
WHERE mm.FailTypeID = 9  -- MM Max StopLoss
ORDER BY mm.Occurred DESC
```

### 8.3 Copy-trading unit cap failures for a specific mirror
```sql
SELECT mm.ID, mm.ParentPositionID, mm.MirrorID, mm.Occurred, mm.Details
FROM [History].[MMLog] mm
WHERE mm.FailTypeID = 12  -- Max position amount in units
  AND mm.MirrorID = 1831540
ORDER BY mm.Occurred
```

### 8.4 Check if a position is excluded from recovery
```sql
-- Returns 1 if position has FailTypeID=8 (excluded from close recovery)
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM [History].[MMLog] WHERE PositionID = 12345 AND FailTypeID = 8
) THEN 1 ELSE 0 END AS IsExcludedFromCloseRecovery,
CASE WHEN EXISTS (
    SELECT 1 FROM [History].[MMLog] WHERE PositionID = 12345 AND FailTypeID = 9
) THEN 1 ELSE 0 END AS IsExcludedFromSLEditRecovery
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.MMLog | Type: Table | Source: etoro/etoro/History/Tables/History.MMLog.sql*
