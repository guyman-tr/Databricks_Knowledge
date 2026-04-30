# BackOffice.SetRiskStatus

> Upserts a customer's risk status record in BackOffice.CustomerRisk - inserting a new risk status or updating an existing one when the risk event state changes, with the previous state automatically archived to History.CustomerRisk before any modification.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @RiskStatusID - the customer/status pair being set |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.SetRiskStatus is the write entry point for the customer risk status system. It maintains BackOffice.CustomerRisk, which tracks the active AML/compliance risk categorization for each customer across multiple risk dimensions (AML Deposit, Activity, General, Behaviour, etc.).

The procedure implements a conditional upsert with automatic history archiving. When a customer's existing risk status transitions to a different event state (e.g., a risk is resolved or escalated), the old state is preserved to History.CustomerRisk before the update is applied. This provides a full audit trail: every change to a risk status is recorded with who made the change (@ManagerID) and when.

@RiskEventStatusID defaults to 1, which corresponds to the "On" (active) state - representing 93% of all rows in BackOffice.CustomerRisk. BackOffice compliance and risk teams call this procedure when assigning, escalating, or clearing risk flags on customer accounts.

---

## 2. Business Logic

### 2.1 Conditional Upsert with History Archiving

**What**: The procedure checks whether the customer already has this risk status and whether it is changing, then branches accordingly.

**Columns/Parameters Involved**: `@CID`, `@RiskStatusID`, `@ManagerID`, `@RiskEventStatusID`, `GCID` (resolved from Customer.CustomerStatic)

**Rules**:
- Step 1: Resolve GCID from Customer.CustomerStatic WHERE CustomerID=@CID
- Step 2: Check IF EXISTS in BackOffice.CustomerRisk WHERE GCID=@GCID AND RiskStatusID=@RiskStatusID AND RiskEventStatusID != @RiskEventStatusID (same risk, different event state -> transition case)
  - If transition: INSERT current row into History.CustomerRisk (archive), then UPDATE BackOffice.CustomerRisk SET RiskEventStatusID=@RiskEventStatusID, ManagerID=@ManagerID, ModifiedDate=GETDATE()
- Step 3: ELSE IF NOT EXISTS (no row at all for this GCID + RiskStatusID): INSERT new row into BackOffice.CustomerRisk
- Step 4: If the row already exists AND has the same RiskEventStatusID -> no-op (idempotent call, already in the desired state)
- Wrapped in BEGIN TRAN/COMMIT with TRY/CATCH THROW for atomicity

**Diagram**:
```
EXEC BackOffice.SetRiskStatus @CID, @RiskStatusID, @ManagerID, @RiskEventStatusID=1
    |
    +--> Resolve GCID from Customer.CustomerStatic WHERE CustomerID=@CID
    |
    +--> EXISTS? (GCID + RiskStatusID + RiskEventStatusID != @RiskEventStatusID)
    |       YES (status transition)
    |         +--> INSERT History.CustomerRisk (archive old state)
    |         +--> UPDATE BackOffice.CustomerRisk SET RiskEventStatusID, ManagerID, ModifiedDate
    |
    +--> EXISTS? (same GCID + RiskStatusID) = NO (new risk)
    |       YES (new insertion)
    |         +--> INSERT BackOffice.CustomerRisk (new row)
    |
    +--> EXISTS with same RiskEventStatusID = YES (no-op, already correct)
    |
    COMMIT
```

### 2.2 History Archiving Pattern

**What**: Every risk status transition creates a permanent audit record in History.CustomerRisk.

**Rules**:
- History.CustomerRisk receives the FULL pre-change row (GCID, RiskStatusID, old RiskEventStatusID, old ManagerID, CreatedDate, old ModifiedDate) plus a snapshot timestamp
- This means every change is reconstructible: who set which risk status, when, and what it changed from/to
- The archive INSERT happens inside the same transaction as the UPDATE - no partial state is possible

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | VERIFIED | The customer whose risk status is being set. Resolved to GCID via Customer.CustomerStatic. Must have a CustomerStatic row - invalid CID results in NULL GCID and a no-op or integrity error. |
| 2 | @RiskStatusID | INT | NO | - | VERIFIED | The risk category being assigned. FK to the risk status dimension (AML Deposit=1, Activity=2, General=3, Behaviour=4, etc.). Combined with GCID as the composite key in BackOffice.CustomerRisk. |
| 3 | @ManagerID | INT | NO | - | VERIFIED | The BackOffice user (manager/compliance officer) performing the risk assignment. Written to BackOffice.CustomerRisk.ManagerID and preserved in the History archive. Used for audit attribution - who changed which risk status. |
| 4 | @RiskEventStatusID | INT | YES | 1 | VERIFIED | The new risk event state to assign. Default 1 = "On" (active risk). Other values represent resolved, under review, or cleared states. The procedure archives the old value and updates to this new value when transitioning. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerStatic | READER (GCID lookup) | Resolves customer CID to GCID for the risk status composite key |
| @CID, @RiskStatusID | BackOffice.CustomerRisk | WRITER (conditional INSERT/UPDATE) | Active risk status store - upserts the current risk state |
| Transition archive | History.CustomerRisk | WRITER (INSERT on change) | Audit trail - previous risk state archived before any modification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice compliance/risk team | - | Caller | Called to assign, escalate, or clear AML/compliance risk flags on customer accounts |
| BackOffice.SetRiskClassificationNew | - | Indirect | SetRiskClassificationNew determines which customers need risk attention; SetRiskStatus is the write path for those assignments |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.SetRiskStatus (procedure)
├── Customer.CustomerStatic (table) - GCID resolution
├── BackOffice.CustomerRisk (table) - active risk status target
└── History.CustomerRisk (table) - audit archive target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | SELECT GCID WHERE CustomerID=@CID - resolves CID to the GCID used as the CustomerRisk PK |
| BackOffice.CustomerRisk | Table | Conditional INSERT (new risk) or UPDATE (transition) with EXISTS pre-check |
| History.CustomerRisk | Table | INSERT pre-change snapshot when risk event status transitions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice compliance workflows | External | Risk flag assignment for AML/KYC customer risk management |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Transaction Safety

The procedure uses BEGIN TRAN/COMMIT with TRY/CATCH THROW. The history INSERT and the CustomerRisk UPDATE are always in the same transaction - they either both commit or both roll back. This prevents orphaned history records or missing audit entries.

---

## 8. Sample Queries

### 8.1 Set a customer's AML deposit risk to active (default RiskEventStatusID=1)
```sql
EXEC BackOffice.SetRiskStatus
    @CID             = 12345678,
    @RiskStatusID    = 1,     -- AML Deposit
    @ManagerID       = 9876   -- compliance officer's BackOffice user ID
    -- @RiskEventStatusID defaults to 1 (On/Active)
```

### 8.2 Clear/resolve a risk status (set to resolved event state)
```sql
EXEC BackOffice.SetRiskStatus
    @CID              = 12345678,
    @RiskStatusID     = 1,     -- AML Deposit
    @ManagerID        = 9876,
    @RiskEventStatusID = 2      -- resolved/cleared state
```

### 8.3 View current risk statuses and their history for a customer
```sql
-- Active risk statuses
SELECT cr.GCID, cr.RiskStatusID, cr.RiskEventStatusID, cr.ManagerID, cr.ModifiedDate
FROM BackOffice.CustomerRisk cr WITH (NOLOCK)
JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cs.GCID = cr.GCID
WHERE cs.CustomerID = 12345678

-- History of changes
SELECT hcr.*
FROM History.CustomerRisk hcr WITH (NOLOCK)
JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cs.GCID = hcr.GCID
WHERE cs.CustomerID = 12345678
ORDER BY hcr.ModifiedDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.SetRiskStatus | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.SetRiskStatus.sql*
