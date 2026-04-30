# Billing.UpdateTransferStatus

> Advances a transfer's lifecycle status with terminal-state protection: updates TransferStatusID unless the transfer has already reached Received(10), in which case it throws an error to prevent accidental reopening.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Void (no return value, throws on terminal state violation) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.UpdateTransferStatus is the sole procedure responsible for advancing a transfer through its lifecycle states. It is the most business-critical modifier in the Billing schema because it implements the terminal-state guard: once a transfer reaches status 10 (Received), its status can never be changed again.

Without this guard, a successfully completed transfer could accidentally be reverted to a pending or failed state, causing financial reconciliation issues and potentially double-processing of funds. The THROW statement acts as a hard business rule enforcement at the database level.

The procedure is called by the MoneyTransfer application service each time the transfer's state changes (e.g., New -> Init, Init -> Pending, Pending -> Sent, Sent -> Received, or any failure branch). The status values are defined in Dictionary.TransferStatus: 0=New, 1=Init, 2=Pending, 4=Technical, 7=Cancel, 8=Fail, 9=Sent, 10=Received.

---

## 2. Business Logic

### 2.1 Terminal State Guard (Received = Immutable)

**What**: Prevents status changes on transfers that have already reached the Received(10) terminal success state.

**Columns/Parameters Involved**: `TransferStatusID`, `ReferenceID`

**Rules**:
- First checks: `SELECT @RowCount = COUNT(*) FROM Billing.Transfers WHERE ReferenceID = @RefGuid AND TransferStatusID = 10`
- If @RowCount = 1 (transfer IS in Received state): `THROW 50000, 'Update failed or affected more than one row.', 1` - the update is blocked
- If @RowCount <> 1 (transfer is NOT in Received state): proceeds with the UPDATE
- The error message "Update failed or affected more than one row" is slightly misleading - the actual business meaning is "Cannot update a Received transfer"
- This logic means: only Received(10) is protected. Other terminal states (Cancel=7, Fail=8) CAN be updated (e.g., for retry scenarios)
- Uses SET NOCOUNT ON for performance
- Trigger auto-updates ModificationDate on successful UPDATE

**Diagram**:
```
UpdateTransferStatus(@RefGuid, @StatusID)
    |
    v
Is transfer currently Received(10)?
    |
    +-- YES --> THROW 50000 (blocked - terminal state)
    |
    +-- NO  --> UPDATE TransferStatusID = @StatusID
                    |
                    v
              ModificationDate auto-updated by trigger
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RefGuid | UNIQUEIDENTIFIER | NO | - | VERIFIED | Internal business key of the transfer to update. Maps to Billing.Transfers.ReferenceID (UNIQUE CLUSTERED). |
| 2 | @StatusID | INT | NO | - | VERIFIED | New status value to set. Must be a valid TransferStatusID: 0=New, 1=Init, 2=Pending, 4=Technical, 7=Cancel, 8=Fail, 9=Sent, 10=Received. See [Transfer Status](../../_glossary.md#transfer-status). No validation against Dictionary.TransferStatus - any integer is accepted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT + UPDATE target | Billing.Transfers | Read + Write | Checks current status then updates TransferStatusID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateTransferStatus (procedure)
  └── Billing.Transfers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Transfers | Table | SELECT (terminal state check) + UPDATE (status change) |

### 6.2 Objects That Depend On This

No dependents found in the database.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Advance transfer to Pending
```sql
EXEC Billing.UpdateTransferStatus
    @RefGuid = '023BE1D7-45AF-4710-9369-323E647A4EE4',
    @StatusID = 2  -- Pending
```

### 8.2 Mark transfer as Received (terminal)
```sql
EXEC Billing.UpdateTransferStatus
    @RefGuid = '023BE1D7-45AF-4710-9369-323E647A4EE4',
    @StatusID = 10  -- Received (after this, no further updates allowed)
```

### 8.3 Check current status before updating
```sql
SELECT TransferID, ReferenceID, TransferStatusID,
    CASE WHEN TransferStatusID = 10 THEN 'LOCKED (Received)' ELSE 'Updatable' END AS UpdateStatus
FROM Billing.Transfers WITH (NOLOCK)
WHERE ReferenceID = '023BE1D7-45AF-4710-9369-323E647A4EE4'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.UpdateTransferStatus | Type: Stored Procedure | Source: MoneyTransfer/Billing/Stored Procedures/Billing.UpdateTransferStatus.sql*
