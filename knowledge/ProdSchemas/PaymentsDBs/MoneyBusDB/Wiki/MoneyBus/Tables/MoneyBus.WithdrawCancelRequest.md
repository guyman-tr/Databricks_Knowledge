# MoneyBus.WithdrawCancelRequest

> Records cancellation requests for withdrawals, tracking who or what initiated the cancellation (user, back-office, or system abort) with an audit trail of comments and timestamps.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, IDENTITY, NONCLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (PK nonclustered + unique clustered on WithdrawID) |

---

## 1. Business Meaning

MoneyBus.WithdrawCancelRequest records every cancellation request made against a withdrawal. When a withdrawal needs to be canceled - whether by the user themselves, a back-office operator, or the system's automated abort workflow - a record is created here linking the cancellation to the original withdrawal with details about who initiated it and why.

This table exists to provide a complete audit trail for withdrawal cancellations, which is critical for compliance and dispute resolution. The unique constraint on WithdrawID ensures that each withdrawal can only have one active cancellation request, preventing duplicate cancel processing. The table separates the cancellation metadata from the main Withdrawals table to keep the core table clean while still maintaining full traceability.

Data flows in exclusively through WithdrawCancelRequestAdd, which inserts a cancellation record with the source, optional manager ID, and comments. WithdrawCancelRequestGet reads the cancellation details for a given withdrawal. The vast majority (~88%) of cancellations are system-initiated aborts with "cancel by abort" comments, while ~12% are user-initiated.

---

## 2. Business Logic

### 2.1 Cancellation Source Classification

**What**: Each cancellation is classified by its initiator, enabling analytics on cancellation patterns and audit compliance.

**Columns/Parameters Involved**: `CancellationSource`, `ManagerID`, `Comments`

**Rules**:
- CancellationSource=3 (Abort): ~88% of records. System-automated abort workflow. ManagerID is always NULL. Comments typically "cancel by abort". Triggered when a withdrawal fails at any pipeline step and the system initiates rollback.
- CancellationSource=1 (User): ~12% of records. User self-service cancellation. ManagerID is NULL (users don't have manager IDs). Comments may contain user-provided reason.
- CancellationSource=2 (BackOffice): 0% in current data, but available for manual back-office intervention. When used, ManagerID would identify the operator.
- No records exist for CancellationSource=0 (None) - this value serves as a null-safe default in other contexts.

### 2.2 One-to-One Withdrawal Binding

**What**: Each withdrawal can have at most one cancellation request, enforced by a unique clustered index on WithdrawID.

**Columns/Parameters Involved**: `WithdrawID`

**Rules**:
- The unique constraint on WithdrawID prevents duplicate cancellation requests for the same withdrawal
- The clustered index is on WithdrawID (not ID), optimizing lookups by withdrawal ID which is the primary access pattern
- This design means re-cancellation attempts for the same withdrawal will fail with a constraint violation

---

## 3. Data Overview

| ID | WithdrawID | ManagerID | CancellationSource | Comments | Created | Meaning |
|---|---|---|---|---|---|---|
| 36833 | 773494 | NULL | 3 (Abort) | cancel by abort | 2026-04-15 13:05:29 | System-initiated abort - the withdrawal pipeline failed and the system automatically canceled it to release held funds |
| 36832 | 773480 | NULL | 3 (Abort) | cancel by abort | 2026-04-15 13:02:58 | Same pattern - automated abort after pipeline failure. This withdrawal had "Account suspended" error |
| 36830 | 773355 | NULL | 3 (Abort) | cancel by abort | 2026-04-15 12:25:34 | Automated abort - the associated withdrawal (773355) had "Account suspended" error |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate key. NONCLUSTERED PK (not the clustered key - that's WithdrawID for access pattern optimization). |
| 2 | WithdrawID | bigint | NO | - | CODE-BACKED | FK to MoneyBus.Withdrawals.ID. Identifies which withdrawal this cancellation applies to. Unique clustered index ensures one cancellation per withdrawal and optimizes the primary lookup pattern. |
| 3 | ManagerID | int | YES | - | CODE-BACKED | ID of the back-office manager who initiated the cancellation. Only populated for CancellationSource=2 (BackOffice). NULL for user-initiated and system abort cancellations. Currently NULL in all production data. |
| 4 | CancellationSource | int | NO | - | CODE-BACKED | Who/what initiated the cancellation: 0=None, 1=User, 2=BackOffice, 3=Abort. See [Withdraw Cancellation Source](../../_glossary.md#withdraw-cancellation-source). (Dictionary.WithdrawCancellationSources). ~88% Abort, ~12% User. |
| 5 | Comments | varchar(200) | YES | - | CODE-BACKED | Free-text reason for the cancellation. For system aborts: "cancel by abort". For user cancellations: user-provided reason text. For back-office: operator's explanation. |
| 6 | Created | datetime | NO | SYSUTCDATETIME() | CODE-BACKED | UTC timestamp when the cancellation request was created. Default uses SYSUTCDATETIME() (higher precision than GETDATE()). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID | MoneyBus.Withdrawals | Implicit FK (Unique) | One-to-one link to the withdrawal being canceled |
| CancellationSource | Dictionary.WithdrawCancellationSources | Implicit Lookup | Classifies the cancellation initiator |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MoneyBus.WithdrawCancelRequestAdd | (whole table) | Writer | Creates cancellation records |
| MoneyBus.WithdrawCancelRequestGet | (whole table) | Reader | Retrieves cancellation by WithdrawID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.WithdrawCancelRequest (table)
└── MoneyBus.Withdrawals (table) [via WithdrawID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.Withdrawals | Table | WithdrawID references Withdrawals.ID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.WithdrawCancelRequestAdd | Stored Procedure | Writer - inserts cancellation records |
| MoneyBus.WithdrawCancelRequestGet | Stored Procedure | Reader - retrieves by WithdrawID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_WithdrawCancelRequest | NONCLUSTERED PK | ID ASC | - | - | Active |
| UQ_WithdrawCancelRequest_WithdrawID | CLUSTERED UNIQUE | WithdrawID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_WithdrawCancelRequest | PRIMARY KEY | Nonclustered on ID - surrogate key for identity |
| UQ_WithdrawCancelRequest_WithdrawID | UNIQUE CLUSTERED | WithdrawID - enforces one cancel per withdrawal and provides clustered access by withdrawal ID |
| DF_WithdrawCancelRequest_Created | DEFAULT | SYSUTCDATETIME() for Created - UTC precision timestamp |

---

## 8. Sample Queries

### 8.1 Get cancellation details for a withdrawal
```sql
SELECT wcr.*, wcs.Name AS CancellationSourceName
FROM MoneyBus.WithdrawCancelRequest wcr WITH (NOLOCK)
JOIN Dictionary.WithdrawCancellationSources wcs WITH (NOLOCK) ON wcs.ID = wcr.CancellationSource
WHERE wcr.WithdrawID = @WithdrawID;
```

### 8.2 Find all user-initiated cancellations in a time range
```sql
SELECT wcr.WithdrawID, wcr.Comments, wcr.Created, w.Amount, w.CurrencyID
FROM MoneyBus.WithdrawCancelRequest wcr WITH (NOLOCK)
JOIN MoneyBus.Withdrawals w WITH (NOLOCK) ON w.ID = wcr.WithdrawID
WHERE wcr.CancellationSource = 1
  AND wcr.Created >= @StartDate AND wcr.Created < @EndDate
ORDER BY wcr.Created DESC;
```

### 8.3 Cancellation source distribution
```sql
SELECT wcs.Name AS Source, COUNT(*) AS CancelCount
FROM MoneyBus.WithdrawCancelRequest wcr WITH (NOLOCK)
JOIN Dictionary.WithdrawCancellationSources wcs WITH (NOLOCK) ON wcs.ID = wcr.CancellationSource
GROUP BY wcs.Name
ORDER BY CancelCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.WithdrawCancelRequest | Type: Table | Source: MoneyBusDB/MoneyBus/Tables/MoneyBus.WithdrawCancelRequest.sql*
