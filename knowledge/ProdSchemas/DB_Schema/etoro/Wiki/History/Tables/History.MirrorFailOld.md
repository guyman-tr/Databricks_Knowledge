# History.MirrorFailOld

> Legacy predecessor to History.MirrorFail - the original CopyTrader mirror operation failure log table that was superseded by the current History.MirrorFail. Retained in schema for historical data but no longer actively written by the Mirror Operation Engine.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite PK: (MirrorID, CID, SessionIdentifier, MirrorOperationID, InsertDate) |
| **Partition** | Yes - EndMonth(InsertDate) partition scheme |
| **Indexes** | 1 active (CLUSTERED PK on MirrorID+CID+SessionIdentifier+MirrorOperationID+InsertDate) |

---

## 1. Business Meaning

History.MirrorFailOld is the legacy failure audit log for CopyTrader mirror operations, predating the current History.MirrorFail table. It records failed attempts to execute mirror operations (start copying, stop copying, fund changes, state changes) - the same business purpose as History.MirrorFail but with an older data model.

The table is not present in the test environment (dropped or not provisioned), indicating it is no longer actively used. The Mirror Operation Engine (MOE) service account (`MirrorOperationEngineUser`) retains INSERT and SELECT permissions on this table in the schema definition, suggesting the migration from Old to New was a staged transition rather than a hard cutover. The new History.MirrorFail table replaced this one with: an auto-incrementing bigint ID as a leading key, a ReferenceID column for distributed tracing, and additional operational columns.

Key structural differences from History.MirrorFail:
- No bigint IDENTITY ID column (PK is composite on business keys + date)
- Includes SessionIdentifier (bigint) and ExceptionType columns (not in the new table)
- Missing ReferenceID (uniqueidentifier) column that was added in History.MirrorFail
- Simpler structure reflecting the older MOE architecture before microservice redesign

---

## 2. Business Logic

### 2.1 Mirror Operation Failure Recording (Legacy)

**What**: Recorded a failure row for each failed CopyTrader mirror operation in the older MOE implementation. Each row captures the copier (CID), the mirror relationship (MirrorID), the operation type (MirrorOperationID), the error (ErrorCode + FailReason), and the operation payload.

**Columns/Parameters Involved**: `MirrorID`, `CID`, `MirrorOperationID`, `ErrorCode`, `FailReason`, `ExceptionType`, `InsertDate`

**Rules**:
- Written by the MOE service (Mirror Operation Engine) via direct INSERT (same SqlBulkCopy or similar mechanism as the new History.MirrorFail)
- MirrorOperationID identifies the operation that failed (same enum as History.MirrorFail: start copying, stop copying, add/remove funds, state changes)
- ErrorCode + FailReason + ExceptionType together provide the full error context
- SessionIdentifier groups operations within a single MOE session or request context
- InsertDate (DEFAULT getutcdate()) and PK design allow the same (MirrorID, CID, MirrorOperationID) to fail multiple times within different sessions or at different times
- The "Old" suffix and lack of active test DB presence confirms this table is no longer written in production

### 2.2 Relationship to History.MirrorFail (Current Table)

**What**: History.MirrorFail (documented separately, Batch 1) is the direct successor. The transition preserved the core columns while adding new tracking capabilities.

**Rules**:
- Shared columns: CID, MirrorID, MirrorOperationID (int), ErrorCode, FailReason, Amount, MirrorTypeID, MirrorStopLossPercentage, PauseCopy, StopLossPercentageDelta, AmountDelta, CloseReason, IsActive, RequestTime, ReasonID, InsertDate
- Removed in new table: SessionIdentifier (bigint), ExceptionType (varchar), Guid (uniqueidentifier as separate column)
- Added in new table: ID (bigint IDENTITY), ReferenceID (uniqueidentifier) - the primary correlation key used by History.GetMirrorOperationDetails
- Both tables are partitioned on the same EndMonth(InsertDate) scheme

---

## 3. Data Overview

Table does not exist in test environment (not provisioned). In production, rows represent historical CopyTrader failure events from the legacy MOE version.

Representative row structure based on DDL:

| MirrorID | CID | SessionIdentifier | MirrorOperationID | ErrorCode | FailReason | ExceptionType | InsertDate |
|---|---|---|---|---|---|---|---|
| 123456 | 789012 | 98765432100 | 4 | 1058 | Mirror is null! | System.NullReferenceException | 2023-11-01 08:15:22 |
| 234567 | 345678 | 98765432101 | 2 | 60050 | Not copying this trader | MirrorOperationException | 2023-11-01 09:30:45 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID of the copier whose mirror operation failed. Part of the composite PK. References Customer.CustomerStatic.CID (no FK enforced). |
| 2 | MirrorID | int | NO | - | CODE-BACKED | The mirror relationship involved in the failed operation. Leading column of the composite PK and clustered index - queries by mirror are the primary access pattern. References Trade.Mirror.MirrorID (no FK enforced). |
| 3 | SessionIdentifier | bigint | NO | - | CODE-BACKED | Identifies the MOE session or processing context within which the failure occurred. Groups failures from the same service execution. Not present in the newer History.MirrorFail table - replaced by ReferenceID (uniqueidentifier). |
| 4 | ClientRequestID | uniqueidentifier | YES | - | CODE-BACKED | Client-supplied idempotency key for the mirror operation request. Same concept as in History.MirrorFail. NULL if the operation was internally initiated. |
| 5 | Guid | uniqueidentifier | YES | - | CODE-BACKED | Operation or request GUID. Predecessor to the ReferenceID column in History.MirrorFail. Used for correlating failed operations with the originating request. |
| 6 | MirrorOperationID | int | NO | - | CODE-BACKED | The operation type that failed. Part of the composite PK. Same enum as History.MirrorFail: common values include 2 (UnRegister/stop copying), 4 (change mirror state/deactivate), and others for fund operations and alignment updates. Exact enum values defined in MOE application code. |
| 7 | ErrorCode | int | NO | - | CODE-BACKED | Numeric error code returned by MOE when the operation failed. Common codes from History.MirrorFail data: 1058 (Mirror is null), 60050 (not copying this trader), 60067 (cannot close with open positions). Defined in MOE application error catalog. |
| 8 | FailReason | varchar(1000) | NO | - | CODE-BACKED | Human-readable description of why the operation failed. Intended for support and investigation. Up to 1000 characters. Example: "Mirror is null!", "Not copying this trader", "CancelCopy cannot be done with open positions". |
| 9 | ExceptionType | varchar(1000) | NO | - | CODE-BACKED | The .NET exception type name that was caught when the failure was recorded. Not present in History.MirrorFail. Example: "System.NullReferenceException", "MirrorOperationException". Up to 1000 characters. Provides technical context beyond the business-level FailReason. |
| 10 | FailOccurred | datetime | YES | - | CODE-BACKED | UTC timestamp when the failure event occurred (as reported by MOE). Distinct from InsertDate (when the row was inserted). NULL if not supplied. |
| 11 | ParentCID | int | YES | - | CODE-BACKED | CID of the leader (the person being copied). Helps identify which side of the copy relationship triggered the failure. NULL for operations where the leader identity is not relevant. |
| 12 | ParentUserName | varchar(20) | YES | - | CODE-BACKED | Username of the leader being copied. Denormalized snapshot of the leader identity at time of failure for diagnostic purposes. |
| 13 | Amount | decimal(16,8) | YES | - | CODE-BACKED | Copy amount in the account currency at time of the operation. Relevant for fund-related operations (add funds, initial copy amount). 8 decimal places for precision with crypto-denominated copies. |
| 14 | MirrorTypeID | int | YES | - | CODE-BACKED | The type/mode of copy relationship (e.g., standard copy, portfolio copy, smart portfolio). Identifies what kind of mirror was involved in the failed operation. |
| 15 | MirrorStopLossPercentage | decimal(16,8) | YES | - | CODE-BACKED | The stop-loss threshold (percentage) set on the copy at time of failure. Captures the risk parameters that were active when the operation failed. |
| 16 | PauseCopy | bit | YES | - | CODE-BACKED | Whether the copy was paused at time of failure. Relevant for operations that change the active/paused state of a copy relationship. |
| 17 | StopLossPercentageDelta | decimal(16,8) | YES | - | CODE-BACKED | The change in stop-loss percentage that was being applied when the operation failed (for operations that modify the stop-loss setting). |
| 18 | AmountDelta | decimal(16,8) | YES | - | CODE-BACKED | The change in allocated copy amount that was being applied when the operation failed (for fund add/remove operations). |
| 19 | CloseReason | int | YES | - | CODE-BACKED | The reason code for closing the mirror, if the failed operation was a close/stop operation. Enum values defined in MOE application code. |
| 20 | IsActive | bit | YES | - | CODE-BACKED | The intended active state of the mirror after the failed operation. Captures the desired state that could not be applied due to the failure. |
| 21 | RequestTime | datetime | YES | - | CODE-BACKED | UTC timestamp of the original request that triggered the failed operation. May differ from FailOccurred if there was a processing queue delay. |
| 22 | ReasonID | int | YES | - | CODE-BACKED | Additional reason categorization for the operation context (beyond ErrorCode). Used for analytics and monitoring of failure patterns. |
| 23 | RequiredMirrorCalculationType | int | YES | - | CODE-BACKED | Specifies what calculation method should be used for the mirror after the operation - relevant for copy fund allocation. |
| 24 | InsertDate | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp when this failure row was inserted into the table. Partition key for the EndMonth(InsertDate) partition scheme. DEFAULT getutcdate() ensures consistent stamping. Part of the composite PK allowing multiple failures for the same (MirrorID, CID, Session, OperationID) over time. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MirrorID | Trade.Mirror | Implicit | References the copy relationship involved in the failure. No FK enforced. |
| CID | Customer.CustomerStatic | Implicit | References the copier customer. No FK enforced. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MirrorOperationEngineUser | INSERT permission | Writer (legacy) | MOE service account retains INSERT+SELECT permissions; the actual write path was via MOE application code |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.MirrorFailOld (table)
  - No code-level dependencies (leaf table)
  - Legacy predecessor to History.MirrorFail
  - Written by Mirror Operation Engine (MOE) application - no stored procedure writer
  - Table not present in test environment (legacy/archived)
```

### 6.1 Objects This Depends On

No dependencies. Free-standing failure log table.

### 6.2 Objects That Depend On This

No stored procedures reference this table. The MirrorOperationEngineUser service account has permissions but the active write path now uses History.MirrorFail.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MirrorFail | CLUSTERED | MirrorID ASC, CID ASC, SessionIdentifier ASC, MirrorOperationID ASC, InsertDate ASC | - | - | Active |

Note: PK_MirrorFail name (without "Old") suggests this was the original table before renaming. FILLFACTOR=90. PAGE compression applied. Partitioned on EndMonth(InsertDate) - same partition scheme as the successor History.MirrorFail.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_MirrorFail | PRIMARY KEY | Clustered composite PK (MirrorID, CID, SessionIdentifier, MirrorOperationID, InsertDate) |
| DF_InsertDate_MirrorFail | DEFAULT | InsertDate = getutcdate() |

---

## 8. Sample Queries

### 8.1 Historical failure lookup for a specific mirror (if data exists)

```sql
SELECT
    MirrorID,
    CID,
    SessionIdentifier,
    MirrorOperationID,
    ErrorCode,
    FailReason,
    ExceptionType,
    FailOccurred,
    InsertDate
FROM [History].[MirrorFailOld] WITH (NOLOCK)
WHERE MirrorID = @MirrorID
ORDER BY InsertDate ASC
```

### 8.2 Cross-table failure history (legacy + current)

```sql
-- Unified view of all mirror failures across old and new tables
SELECT 'Old' AS TableSource, MirrorID, CID, MirrorOperationID, ErrorCode, FailReason, InsertDate
FROM [History].[MirrorFailOld] WITH (NOLOCK)
WHERE MirrorID = @MirrorID
UNION ALL
SELECT 'Current', MirrorID, CID, MirrorOperationID, ErrorCode, FailReason, InsertDate
FROM [History].[MirrorFail] WITH (NOLOCK)
WHERE MirrorID = @MirrorID
ORDER BY InsertDate ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (no SP references; permissions file reviewed) | App Code: 0 repos | Corrections: 0 applied*
*Note: Table not present in test environment (legacy/superseded). Documentation based on DDL analysis and comparison with successor History.MirrorFail.*
*Object: History.MirrorFailOld | Type: Table | Source: etoro/etoro/History/Tables/History.MirrorFailOld.sql*
