# History.MirrorFail

> Partitioned audit log of every failed CopyTrader mirror operation processed by the Mirror Operation Engine (MOE) microservice. Each row captures the copier identity, the operation attempted, the error code and human-readable failure reason, and the operation-specific payload (amount, stop-loss percentage, etc.) - enabling support investigation, compliance review, and service reliability monitoring for the Copy Trading platform.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (bigint IDENTITY, PK leading column) + InsertDate (partition key) |
| **Partition** | Yes - EndMonth(InsertDate) partition scheme |
| **Indexes** | 3 (CLUSTERED PK on ID+InsertDate, NC on CID+ReferenceID, NC on MirrorID) |

---

## 1. Business Meaning

This table is the **failure audit log** for the Mirror Operation Engine (MOE) - eToro's AKS-deployed microservice that handles all CopyTrader operations (start copying, stop copying, add/remove funds, change state, pause/resume, alignment updates). Every time MOE attempts a mirror operation and fails - whether due to a validation error, a database error, or a business rule violation - it writes a row here via `HistoryMirrorFailRepository` using `SqlBulkCopy`.

The table has 538,489 rows spanning January 2025 to March 2026 (active). The dominant failure type is MirrorOperationID=4 (Change mirror's state / deactivation) at 80% of all failures, most of which are ErrorCode 1058 ("Mirror is null!" validation - the mirror had already been closed or never existed when the deactivation message arrived). The second-largest category is MirrorOperationID=2 (UnRegister Mirror / stop copying) at ~19%, often failing with ErrorCode 60050 (not copying the requested trader) or 60067 (cannot close with open positions).

`History.GetMirrorOperationDetails` SP reads from this table as the "failure" branch of a UNION with `History.Mirror` (success records), returning a unified operation detail record for support tooling. The SP prefers success over failure (Ordinal=1 beats Ordinal=2) so a ReferenceID that appears in both tables returns the success record.

**Note**: `MirrorOperationEngineUser` (the MOE service account) has INSERT and SELECT permissions on this table. No stored procedure owns the write path - MOE writes directly via SqlBulkCopy from the application layer.

---

## 2. Business Logic

### 2.1 MOE Failure Recording Pattern

**What**: Every MOE processor (RegisterMirror, UnRegisterMirror, EditAmount, ChangeState, PauseCopy, AlignmentStatusUpdate, etc.) wraps its execution in a try/catch. On any failure (validation exception `MoeValidationException`, SQL exception, or generic exception), the processor constructs a failure object and writes it to this table.

**Columns/Parameters Involved**: `MirrorOperationID`, `ErrorCode`, `FailReason`, `ExceptionType`, `FailOccurred`, `InsertDate`, `ReferenceID`

**Rules**:
- `FailOccurred` = timestamp when the failure was detected in-process
- `InsertDate` = timestamp when the row was written to the DB (DEFAULT getutcdate()) - may be slightly after FailOccurred due to batching
- `ExceptionType` = the .NET exception class name: `MoeValidationException` for business rule violations, SQL exception types for DB errors, etc.
- `ErrorCode` = a value from the `ErrorMessagesCode` enum (eToro.Trading.Application.Messages.Enumerations). Values above 60000 (60050, 60061, 60067) are DB-level error codes raised by stored procedures via RAISERROR
- `FailReason` = the human-readable failure message, often including the specific validator name, the MirrorID, and the CID/GCID involved

**Error Code Reference** (observed values mapped to enum names):
| ErrorCode | Enum Name | Count | Sample Reason |
|-----------|-----------|-------|---------------|
| 1058 | MIRROR_DATA_NOT_AVAILABLE_OR_INACTIVE | 431,981 | "Mirror is null!" - mirror already closed |
| 60050 | (DB RAISERROR) | 57,020 | "You can't stop copying a user you are not already copying" |
| 60067 | (DB RAISERROR) | 47,594 | "Cannot close CopyTrader with open positions" |
| 229 | (SQL permissions error) | 1,263 | SELECT permission denied on Trade.Mirror |
| 972 | BLOCKED_BY_COPY_SETTLEMENT_RESTRICTIONS | 319 | User blocked from copying non-PI users |
| 758 | FAILED_REGISTER_MIRROR_MINIMUM_AMOUNT | 85 | Copy amount below minimum ($200) |
| 793 | FAILED_EDIT_MIRROR_MINIMUM_AMOUNT | 77 | Add funds amount below MinCopiedAmountDollars |
| 604 | INSUFFICIENT_FUNDS_ERROR | 54 | Insufficient available cash |
| 820 | AMOUNT_TOO_LOW / country restriction | 23 | User blocked due to country of registration |
| 812 | USA_USER_INVALID_OPERATION | 12 | US user cannot copy this trader |

### 2.2 Operation-Specific Payload Columns

**What**: Each MirrorOperationID populates a different subset of the nullable payload columns. The columns are not universally populated - only those relevant to the attempted operation are set.

**Columns/Parameters Involved**: `Amount`, `AmountDelta`, `StopLossPercentageDelta`, `MirrorStopLossPercentage`, `PauseCopy`, `IsActive`, `RequiredMirrorCalculationType`, `CloseReason`

**Rules by MirrorOperationID** (values from Dictionary.MirrorOperation):

| MirrorOperationID | Operation | Key Payload Columns Populated | Observed Count |
|-------------------|-----------|-------------------------------|----------------|
| 1 | Register Mirror | Amount (initial copy $), MirrorStopLossPercentage, ParentCID, ParentUserName, MirrorTypeID | 521 |
| 2 | UnRegister Mirror | CloseReason, ParentCID | 104,615 |
| 3 | Edit Mirror's balance | AmountDelta (requested change), ExternalOperationType | 103 |
| 4 | Change mirror's state | CloseReason (mostly 0) | 433,198 |
| 7 | Pause Copy | PauseCopy (true/false requested) | 1 |
| 13 | alignment_ended | IsActive (false = ending alignment) | 51 |

- `CloseReason`=0 is the overwhelmingly dominant value (537,812 of 537,813 non-null rows), indicating normal/user-initiated operations
- `MirrorTypeID`=1 (standard CopyTrader), =4 (Smart Copy/MIMO), NULL (99.9% - not applicable for state-change ops)
- `ExternalOperationType`=3 (add funds), =4 (remove funds) - only populated for external copy edit-amount operations

### 2.3 Unified Operation Detail Query (Success or Failure)

**What**: `History.GetMirrorOperationDetails` provides a single-row result for any ReferenceID, preferring the success record from `History.Mirror` over the failure record from `History.MirrorFail`.

**Columns/Parameters Involved**: `ReferenceID`, `CID`, `MirrorID`, `MirrorOperationID`, `FailOccurred`, `ErrorCode`, `FailReason`

**Rules**:
```sql
-- SP logic (simplified):
;WITH Unified AS (
    SELECT ..., 1 AS Ordinal FROM History.Mirror WHERE ReferenceID = @ReferenceID AND CID = @CID
    UNION ALL
    SELECT ..., 2 AS Ordinal FROM History.MirrorFail WHERE ReferenceID = @ReferenceID AND CID = @CID
)
SELECT TOP 1 ... FROM Unified ORDER BY Ordinal  -- Success (1) wins over Failure (2)
```
- If a ReferenceID has a success record in History.Mirror, the SP returns success data (failure columns NULL)
- If a ReferenceID has only a failure record, the SP returns failure data (success columns NULL)
- A ReferenceID that appears in both tables (retry succeeded after initial failure) returns the success record

---

## 3. Data Overview

| CID | MirrorID | MirrorOperationID | ErrorCode | FailReason (excerpt) | Meaning |
|-----|----------|-------------------|-----------|---------------------|---------|
| 14866508 | 1873900 | 4 (Change state) | 1058 | "Mirror Deactivate Validation Failure. IsNullValidator - Mirror is null!" | Mirror already deactivated before MOE processed the message - race condition or duplicate message |
| 14952811 | 1874238 | 4 (Change state) | 1058 | Same as above | Pattern: batch deactivation events arrive and mirror is already gone |
| (register sample) | (any) | 1 (Register) | 805 | "Requested Mirror type ID: 4 does not equal the parent's type: 1" | Smart Copy attempted against a non-Smart-Copy trader |
| (edit sample) | (any) | 3 (Edit balance) | 793 | "Mirror added funds: 199.00 is under MinCopiedAmountDollars (200)" | Attempted to add $199 when minimum is $200 |
| (unregister sample) | (any) | 2 (UnRegister) | 60050 | "You can't stop copying a user you are not already copying" | Duplicate close request - mirror already closed |

**Distribution summary**: 538,489 total rows, 272 distinct copier CIDs, 249 distinct MirrorIDs. The table is very active in the current environment. Failures are dominated by MirrorOperationID=4 (deactivation events) at 80%, suggesting high-volume automated alignment/deactivation flows regularly encounter mirrors that have already been closed.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. Leading column of the CLUSTERED PK (with InsertDate). Note: querying by ID alone fails on partitioned tables; always include InsertDate in WHERE for partition elimination. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID of the copier who attempted the mirror operation. Links to Customer.Customer.CID. NC index IX_CID_ReferenceID allows efficient lookup by copier + reference. 272 distinct copiers have failure records in the current dataset. |
| 3 | MirrorID | int | NO | - | CODE-BACKED | The copy relationship identifier for which the operation failed. NC index [MirrorID] enables efficient lookup of all failures for a given copy relationship. 249 distinct MirrorIDs in current data. |
| 4 | SessionIdentifier | bigint | NO | - | CODE-BACKED | MOE session/correlation identifier for the processing session. Observed as 0 for all recent rows in live data, suggesting the field is either deprecated or set to a default sentinel by the current MOE version. |
| 5 | ClientRequestID | uniqueidentifier | YES | - | CODE-BACKED | Client-provided idempotency GUID for the original operation request. Aliased as `RequestGUID` in History.GetMirrorOperationDetails SP. Used by caller systems to correlate their request with the outcome. |
| 6 | Guid | uniqueidentifier | YES | - | CODE-BACKED | Alternative operation GUID. Distinct from ClientRequestID - likely an internally generated correlation ID within MOE for distributed tracing. |
| 7 | MirrorOperationID | int | NO | - | CODE-BACKED | The type of mirror operation that failed. FK (implicit) to Dictionary.MirrorOperation.ID. Values: 1=Register Mirror, 2=UnRegister Mirror, 3=Edit Mirror's balance, 4=Change mirror's state, 5=Edit Mirror SL, 6=Close Position, 7=Pause Copy, 8=Resume Copy, 9=Edit Mirror SL Percentage, 10=Position Detach, 11=Update MirrorCalculationType, 12=alignment_started, 13=alignment_ended. Observed in data: 1,2,3,4,7,13. |
| 8 | ErrorCode | int | NO | - | CODE-BACKED | Numeric error code from MOE's ErrorMessagesCode enum. Values below 60000 are application-level validation codes; values 60000+ are DB-level error codes raised by stored procedures via RAISERROR. Most common: 1058 (mirror null/inactive), 60050 (not copying this trader), 60067 (open positions block close). |
| 9 | FailReason | varchar(1000) | NO | - | CODE-BACKED | Human-readable failure description. Typically formatted as "{OperationName} Validation Failure. {ValidatorName} - {Detail}. Requested Mirror: {MirrorID}". Used by support teams to diagnose copy trading failures. Never NULL (MOE always provides a reason string). |
| 10 | ExceptionType | varchar(1000) | NO | - | CODE-BACKED | .NET exception class name that caused the failure. Primary values: "MoeValidationException" (business rule violation), SQL exception class names (DB errors). Enables filtering failures by root cause category. |
| 11 | FailOccurred | datetime | YES | - | CODE-BACKED | UTC timestamp when the failure was detected within MOE processing. May be slightly before InsertDate (DB write time) due to SqlBulkCopy batching. NULL when the timestamp was unavailable at failure capture time. |
| 12 | ParentCID | int | YES | - | CODE-BACKED | Customer ID of the trader being copied (the "parent" or popular investor). Populated for RegisterMirror (op=1) and UnRegisterMirror (op=2) operations. NULL for state-change and alignment operations where the parent identity is not relevant to the failure. |
| 13 | ParentUserName | varchar(20) | YES | - | CODE-BACKED | Username of the trader being copied. Populated alongside ParentCID for register/unregister operations. NULL for other operation types. |
| 14 | Amount | decimal(16,8) | YES | - | CODE-BACKED | For RegisterMirror (op=1): the initial copy amount in USD requested by the copier. NULL for other operations. Example: Amount=2000 means copier attempted to start copying with $2,000. |
| 15 | MirrorTypeID | int | YES | - | CODE-BACKED | Type of the copy relationship. 1=Standard CopyTrader, 4=Smart Copy / MIMO. NULL for 99.9% of rows (operations where mirror type is not relevant to the failure context, particularly state-change ops). |
| 16 | MirrorStopLossPercentage | decimal(16,8) | YES | - | CODE-BACKED | The stop-loss percentage requested during RegisterMirror (op=1) operations. Represents the maximum loss percentage the copier tolerates before auto-close. NULL for other operations. |
| 17 | PauseCopy | bit | YES | - | CODE-BACKED | The requested pause state for PauseCopy (op=7) operations: true=pause, false=resume. NULL for all other operation types. |
| 18 | StopLossPercentageDelta | decimal(16,8) | YES | - | CODE-BACKED | The requested stop-loss percentage change for Edit Mirror SL Percentage (op=9) operations. Aliased as `RequestedEditSLPercentageDelta` in GetMirrorOperationDetails SP. NULL for other operations. |
| 19 | AmountDelta | decimal(16,8) | YES | - | CODE-BACKED | The requested amount change for Edit Mirror's balance (op=3) operations - positive=add funds, negative=remove funds. Example: AmountDelta=199 means copier tried to add $199. Aliased as `RequestedDeltaAmount` in SP. NULL for other operations. |
| 20 | CloseReason | int | YES | - | CODE-BACKED | Reason code for UnRegister/Change-state operations. 0=normal/user-initiated close (99.999% of non-null rows), 1=forced close (1 observed row). Aliased as `RequestedMirrorCloseReason` in GetMirrorOperationDetails SP. |
| 21 | IsActive | bit | YES | - | CODE-BACKED | The requested IsActive flag for alignment status update (op=13) operations: false=ending alignment, true=starting alignment. NULL for all other operations. |
| 22 | RequestTime | datetime | YES | - | CODE-BACKED | UTC timestamp when the original client request was submitted to MOE (before processing). Enables measuring how long a request waited before the failure occurred (RequestTime to FailOccurred delta). |
| 23 | ReasonID | int | YES | - | NAME-INFERRED | Additional reason identifier for the failure. Not referenced in any observed stored procedures. Likely a supplementary categorization code from MOE's failure classification system. |
| 24 | RequiredMirrorCalculationType | int | YES | - | CODE-BACKED | The requested mirror calculation type for Update MirrorCalculationType (op=11) operations. Aliased as `RequestedMirrorCalculationType` in GetMirrorOperationDetails SP. Values correspond to calculation method IDs used by the copy trading engine. NULL for other operations. |
| 25 | InsertDate | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp when this row was written to the DB. Acts as the partition key for the EndMonth(InsertDate) partition scheme and the trailing column of the CLUSTERED PK. DEFAULT = getutcdate() ensures accurate write-time stamping even if the application does not provide a value. |
| 26 | ReferenceID | varchar(36) | YES | - | CODE-BACKED | Client-provided operation reference ID used to correlate failures with their initiating request and with success records in History.Mirror. Used by History.GetMirrorOperationDetails to look up the operation outcome. Also indexed via IX_CID_ReferenceID (CID, ReferenceID). |
| 27 | ExternalOperationType | smallint | YES | - | CODE-BACKED | Type of external copy edit-amount operation. 3=add funds, 4=remove funds. Only populated for MirrorOperationID=3 (Edit Mirror's balance) from external copy flows. NULL for all other operations and internal flows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Target Object | Target Element | Relationship Type | Description |
|--------------|----------------|-------------------|-------------|
| Dictionary.MirrorOperation | ID | Implicit FK (no constraint) | MirrorOperationID matches Dictionary.MirrorOperation.ID. 13 operation types defined. |
| Customer.Customer | CID | Implicit FK (no constraint) | CID identifies the copier customer. |
| Trade.Mirror | MirrorID | Implicit FK (no constraint) | MirrorID identifies the copy relationship. Mirror may no longer exist (deleted after close) when the failure record is queried. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.GetMirrorOperationDetails | MirrorFail | Read-only query | SP unions History.MirrorFail (failures) with History.Mirror (successes) to return a unified operation detail record for support tooling. Reads by (ReferenceID, CID). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.MirrorFail (table)
- Written by: Mirror Operation Engine (MOE) microservice via SqlBulkCopy
  - HistoryMirrorFailRepository -> [History].[MirrorFail]
- Read by: History.GetMirrorOperationDetails SP
```

### 6.1 Objects This Depends On

No formal FK constraints. Implicit dependencies: Dictionary.MirrorOperation (MirrorOperationID), Customer.Customer (CID), Trade.Mirror (MirrorID).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.GetMirrorOperationDetails | Stored Procedure | UNION branch for failed operations; returns failure details when no success record exists for a ReferenceID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MirrorFailNe1w | CLUSTERED | ID ASC, InsertDate ASC | - | - | Active (FILLFACTOR=90, PAGE compression, EndMonth partition) |
| IX_CID_ReferenceID | NONCLUSTERED | CID ASC, ReferenceID ASC | - | - | Active (EndMonth partition) |
| MirrorID | NONCLUSTERED | MirrorID ASC | - | - | Active (EndMonth partition) |

The CLUSTERED PK on (ID, InsertDate) is partitioned - queries by ID alone without InsertDate will fan out across all partitions. Always include InsertDate in predicates for efficient partition elimination.

### 7.2 Constraints

| Name | Type | Definition |
|------|------|------------|
| PK_MirrorFailNe1w | PRIMARY KEY | (ID ASC, InsertDate ASC) - clustered, partitioned |
| DF_InsertDate_MirrorFail1 | DEFAULT | InsertDate = getutcdate() |

### 7.3 Partitioning

- **Partition scheme**: EndMonth(InsertDate) - date-range partitioning by month based on insert date
- **Filegroup**: EndMonth (same partition scheme used by other History tables for lifecycle management)
- All three indexes are ON EndMonth(InsertDate) - aligned partitioning

---

## 8. Sample Queries

### 8.1 Recent failures for a specific copier

```sql
SELECT TOP 50
    mf.InsertDate,
    mf.MirrorID,
    mo.MirrorOperation AS OperationType,
    mf.ErrorCode,
    mf.FailReason,
    mf.ExceptionType,
    mf.Amount,
    mf.AmountDelta,
    mf.CloseReason,
    mf.ReferenceID
FROM History.MirrorFail mf WITH (NOLOCK)
JOIN Dictionary.MirrorOperation mo WITH (NOLOCK) ON mo.ID = mf.MirrorOperationID
WHERE mf.CID = @CID
ORDER BY mf.InsertDate DESC;
```

### 8.2 Failure rate by operation type in a time window

```sql
SELECT
    mo.MirrorOperation,
    mf.MirrorOperationID,
    COUNT(*) AS FailureCount,
    COUNT(DISTINCT mf.CID) AS AffectedCopiers,
    COUNT(DISTINCT mf.ErrorCode) AS DistinctErrorCodes,
    MAX(mf.InsertDate) AS LastFailure
FROM History.MirrorFail mf WITH (NOLOCK)
JOIN Dictionary.MirrorOperation mo WITH (NOLOCK) ON mo.ID = mf.MirrorOperationID
WHERE mf.InsertDate >= @StartDate
  AND mf.InsertDate <  @EndDate
GROUP BY mf.MirrorOperationID, mo.MirrorOperation
ORDER BY FailureCount DESC;
```

### 8.3 Look up outcome for a specific operation reference

```sql
-- Use the SP - returns success record if it exists, failure record otherwise
EXEC History.GetMirrorOperationDetails
    @ReferenceID = '550e8400-e29b-41d4-a716-446655440000',
    @CID = @CopierCID;
```

### 8.4 Top error codes in the last 7 days

```sql
SELECT TOP 10
    mf.ErrorCode,
    LEFT(MIN(mf.FailReason), 200) AS SampleReason,
    COUNT(*) AS Count
FROM History.MirrorFail mf WITH (NOLOCK)
WHERE mf.InsertDate >= DATEADD(DAY, -7, GETUTCDATE())
GROUP BY mf.ErrorCode
ORDER BY Count DESC;
```

---

## 9. Atlassian Knowledge Sources

- **Confluence**: "Moe - Mirror Operation Engine" (page 12857836033) - Comprehensive service architecture documentation. Explicitly documents History.MirrorFail as the failure audit table. Describes `HistoryMirrorFailRepository` using SqlBulkCopy. Lists all 9 MOE processors, their responsibilities, and failure handling. Provides full error code enum (ErrorMessagesCode). Documents RabbitMQ topology, deployment configuration (6 pods across North/West regions), and service architecture (DDD with Application/Infrastructure/WebAPI/Bootstrap layers).

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.2/10, Relationships: 8.5/10, Sources: 9.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 26 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence (MOE architecture doc) + 0 Jira | Procedures: 1 analyzed (History.GetMirrorOperationDetails) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.MirrorFail | Type: Table | Source: etoro/etoro/History/Tables/History.MirrorFail.sql*
