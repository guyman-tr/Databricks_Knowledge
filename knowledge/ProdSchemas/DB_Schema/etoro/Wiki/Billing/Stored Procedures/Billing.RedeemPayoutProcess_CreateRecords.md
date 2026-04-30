# Billing.RedeemPayoutProcess_CreateRecords

> Back-office approval step for stock redemptions: creates or updates RedeemPayoutProcess records for approved redeems and advances them from "BO Approved" (status 3) to "InProcess" (status 4).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns result set of created/updated process records |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a back-office operator approves a batch of customer redemption requests, `Billing.RedeemPayoutProcess_CreateRecords` is the transactional write that registers the approval and starts the processing workflow. It handles two cases: redeems that already have a process record (re-approval scenario) and new redeems that need a process record created for the first time.

The procedure advances redeems from status 3 (BO Approved/waiting) to status 4 (InProcess) and either creates or updates their `Billing.RedeemPayoutProcess` entry with the approving manager's ID and a correlation ID for tracking the batch. It returns the full set of records that were moved into processing so the calling service can initiate the downstream position-closing workflow.

---

## 2. Business Logic

### 2.1 Upsert with Dual Path (Existing vs New)

**What**: Handles both re-approvals of existing process records and first-time approvals with atomic guarantees.

**Columns/Parameters Involved**: `RedeemStatusID`, `ManagerID`, `BoCorrelationID`, `InClosePositionProcess`

**Rules**:
- **Existing path**: For redeems with RedeemStatusID=3 that ALREADY have a RedeemPayoutProcess row, updates ManagerID and BoCorrelationID. Advances Billing.Redeem.RedeemStatusID from 3 to 4.
- **New path**: For redeems with RedeemStatusID=3 that do NOT have a process row, INSERTs a new RedeemPayoutProcess row. Advances Billing.Redeem.RedeemStatusID from 3 to 4.
- Both paths output their results into temp tables (#OutputExist, #Output) and the return SELECT unions them.
- Runs in a TRY/CATCH transaction. ROLLBACK on single-transaction failure; COMMIT on nested transaction.

**Diagram**:
```
Input: @Ids (list of RedeemIDs at status 3)
         |
         +-- Existing process row?
         |       YES --> UPDATE RedeemPayoutProcess (ManagerID, BoCorrelationID)
         |               UPDATE Billing.Redeem (RedeemStatusID 3 -> 4, ManagerID)
         |
         +-- No process row?
                 YES --> INSERT RedeemPayoutProcess (RedeemID, ManagerID, BoCorrelationID)
                         UPDATE Billing.Redeem (RedeemStatusID 3 -> 4, ManagerID)
         |
         v
    SELECT all processed records (ProcessID, RedeemID, PositionID, CID, Units, InstrumentID)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Ids | BackOffice.IDs (table type) | NO | - | CODE-BACKED | Table-valued parameter containing RedeemIDs (NOT ProcessIDs) to approve. Only redeems with RedeemStatusID=3 in this list will be processed. |
| 2 | @ManagerID | INT | NO | - | CODE-BACKED | Back-office operator ID who is approving this batch. Written to Billing.RedeemPayoutProcess.ManagerID and Billing.Redeem.ManagerID. |
| 3 | @CorrelationID | VARCHAR(36) | NO | - | CODE-BACKED | Batch correlation GUID written to Billing.RedeemPayoutProcess.BoCorrelationID. Used to group this approval batch for tracking and audit. |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | ProcessID | INT | NO | - | CODE-BACKED | Billing.RedeemPayoutProcess.RedeemPayoutProcessID of the created/updated record. |
| 5 | RedeemID | INT | NO | - | CODE-BACKED | Billing.Redeem.RedeemID that was approved. |
| 6 | PositionID | BIGINT | NO | - | CODE-BACKED | Trading position being redeemed, from Billing.Redeem. Used by the caller to initiate position closing. |
| 7 | CID | INT | NO | - | CODE-BACKED | Customer ID of the redeem owner. |
| 8 | Units | DECIMAL(16,8) | NO | - | CODE-BACKED | Number of units to redeem. Used by position-closing service. |
| 9 | InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument being redeemed. Used by position-closing service to determine settlement type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Ids | Billing.RedeemPayoutProcess | INSERT or UPDATE | Creates or updates the payout process record |
| @Ids | Billing.Redeem | UPDATE | Advances RedeemStatusID from 3 to 4, sets ManagerID |

### 5.2 Referenced By (other objects point to this)

No SQL callers found. Called by the back-office approval service when an operator approves a batch of redemptions.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.RedeemPayoutProcess_CreateRecords (procedure)
├── Billing.RedeemPayoutProcess (table)
└── Billing.Redeem (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.RedeemPayoutProcess | Table | Upsert target for process records |
| Billing.Redeem | Table | Status update (3->4) and ManagerID write |
| BackOffice.IDs | User Defined Type | Input parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application (BO approval service) | External caller | Calls this when a manager approves a batch of redemptions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RedeemStatusID=3 filter | Business filter | Only processes redeems that are in BO-approved state (status 3). Ignores other statuses in the input list. |
| TRY/CATCH transaction | Atomicity | Rolls back on error within a single transaction. For nested transactions, commits to preserve outer transaction. |

---

## 8. Sample Queries

### 8.1 Approve a batch of redeems

```sql
DECLARE @Ids BackOffice.IDs
INSERT INTO @Ids (ID) VALUES (501), (502), (503)
EXEC Billing.RedeemPayoutProcess_CreateRecords
    @Ids = @Ids,
    @ManagerID = 12345,
    @CorrelationID = 'b2c3d4e5-2345-6789-bcde-f01234567890'
```

### 8.2 View redeems awaiting BO approval (status 3)

```sql
SELECT r.RedeemID, r.CID, r.PositionID, r.Units, r.AmountOnRequest, r.RedeemTypeID, r.RequestDate
FROM Billing.Redeem r WITH (NOLOCK)
WHERE r.RedeemStatusID = 3
ORDER BY r.RedeemTypeID DESC, r.RequestDate ASC
```

### 8.3 Check process records created by a specific BO correlation batch

```sql
SELECT rpp.RedeemPayoutProcessID, rpp.RedeemID, rpp.ManagerID, rpp.BoCorrelationID,
       r.RedeemStatusID, r.PositionID, r.CID
FROM Billing.RedeemPayoutProcess rpp WITH (NOLOCK)
JOIN Billing.Redeem r WITH (NOLOCK) ON rpp.RedeemID = r.RedeemID
WHERE rpp.BoCorrelationID = 'b2c3d4e5-2345-6789-bcde-f01234567890'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.4/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: skipped | Corrections: 0 applied*
*Object: Billing.RedeemPayoutProcess_CreateRecords | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.RedeemPayoutProcess_CreateRecords.sql*
