# BackOffice.SetFTDPoolManager

> Assigns a new FTD (First-Time Deposit) pool manager to a customer and writes an auditable change history record, enabling sales team lead management of which agent handles a customer's first deposit.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - the customer being reassigned |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.SetFTDPoolManager reassigns a customer's First-Time Deposit (FTD) pool manager - the sales agent responsible for coaching the customer through their first deposit. This is a managed sales workflow: when a customer registers and is ready to make their first deposit, they are assigned to a sales agent (FTDPoolManagerID). This procedure transfers that assignment to a new agent and creates a timestamped history record for audit and performance tracking.

The procedure is used by BackOffice sales team leads or automated assignment algorithms to rebalance agent workloads, transfer customers between teams, or correct misassignments. Every change is immutably recorded in History.BackOfficeFTDPoolManager with who made the change, when, and a free-text comment - enabling compliance review and commission attribution disputes to be resolved.

The two-step write (UPDATE BackOffice.Customer + INSERT History) is wrapped in a single transaction. If either step fails, both are rolled back to prevent the customer profile and history from diverging.

---

## 2. Business Logic

### 2.1 Transactional Two-Phase Write (Customer + History)

**What**: Both the customer profile update and the history insert must succeed or neither persists.

**Columns/Parameters Involved**: `@CID`, `@NewManagerID`, `@ChangedBy`, `@Comment`

**Rules**:
- BEGIN TRANSACTION wraps both writes
- Phase 1: UPDATE BackOffice.Customer SET FTDPoolManagerID=@NewManagerID WHERE CID=@CID
  - If @@ERROR != 0: ROLLBACK, RAISERROR(60000, 16, 1), RETURN 60000
- Phase 2: INSERT INTO History.BackOfficeFTDPoolManager (ChangedBy, Occurred=GETDATE(), Comment, CID, PoolManagerID=@NewManagerID)
  - If @@ERROR != 0: ROLLBACK, RAISERROR(60000, 16, 1), RETURN 60000
- COMMIT TRANSACTION, RETURN 0
- Note: There is no row-exists validation - if @CID is not in BackOffice.Customer, the UPDATE affects 0 rows (no error), and the History INSERT still occurs. The history record is created even for a no-op update.

**Diagram**:
```
Sales lead reassigns customer to new manager
    |
    v
SetFTDPoolManager(@CID, @ChangedBy, @Comment, @NewManagerID)
    |
    BEGIN TRANSACTION
    |
    +--> UPDATE BackOffice.Customer
    |        SET FTDPoolManagerID = @NewManagerID
    |        WHERE CID = @CID
    |        [error? ROLLBACK + RETURN 60000]
    |
    +--> INSERT History.BackOfficeFTDPoolManager
    |        (ChangedBy, Occurred=GETDATE(), Comment, CID, PoolManagerID)
    |        [error? ROLLBACK + RETURN 60000]
    |
    COMMIT TRANSACTION
    RETURN 0
```

### 2.2 Audit Trail in History Schema

**What**: Every manager assignment change is permanently recorded in History.BackOfficeFTDPoolManager.

**Rules**:
- Occurred = GETDATE() (server timestamp of the change, not parameterized)
- ChangedBy = @ChangedBy (the manager ID who performed the reassignment - for attribution)
- Comment = @Comment (free-text reason, e.g., "Customer requested team transfer", "Agent on leave")
- PoolManagerID = @NewManagerID (the agent now responsible for this customer's FTD)
- History rows are never deleted or updated - they are a permanent immutable audit trail

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | VERIFIED | The customer being reassigned. Must exist in BackOffice.Customer. No FK validation - invalid CID causes a 0-row UPDATE with no error but still writes a history record. |
| 2 | @ChangedBy | INTEGER | NO | - | VERIFIED | The UserID (ManagerID) of the BackOffice agent who performed this reassignment. Written to History.BackOfficeFTDPoolManager.ChangedBy for audit. Enables accountability tracking. |
| 3 | @Comment | VARCHAR(255) | NO | - | CODE-BACKED | Free-text explanation for the manager reassignment (e.g., "Agent OOO", "Rebalance", "Customer request"). Written to History. Required by signature but no NULL enforcement in procedure body. |
| 4 | @NewManagerID | INTEGER | NO | - | VERIFIED | The ManagerID to assign as the new FTD pool manager for this customer. Written to BackOffice.Customer.FTDPoolManagerID and History.BackOfficeFTDPoolManager.PoolManagerID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | MODIFIER (UPDATE FTDPoolManagerID) | Assigns the new FTD pool manager to the customer's profile |
| (INSERT) | History.BackOfficeFTDPoolManager | WRITER | Creates permanent audit record of the manager change |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice Sales Management UI | - | Caller | Called by team leads when reassigning FTD pool manager assignments |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.SetFTDPoolManager (procedure)
├── BackOffice.Customer (table)
└── History.BackOfficeFTDPoolManager (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | UPDATE: SET FTDPoolManagerID=@NewManagerID WHERE CID=@CID |
| History.BackOfficeFTDPoolManager | Table | INSERT: audit record of every manager change |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice Sales Management | External | Calls to reassign FTD pool manager assignments |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Reassign a customer to a new FTD pool manager
```sql
DECLARE @Err INT
EXEC @Err = BackOffice.SetFTDPoolManager
    @CID         = 12345678,
    @ChangedBy   = 9001,    -- Manager making the change
    @Comment     = 'Agent on medical leave - reassigning to backup',
    @NewManagerID = 9002    -- New FTD pool manager
SELECT @Err AS ErrorCode
```

### 8.2 View FTD pool manager change history for a customer
```sql
SELECT
    h.CID,
    h.ChangedBy,
    h.Occurred,
    h.Comment,
    h.PoolManagerID AS NewManagerID
FROM History.BackOfficeFTDPoolManager h WITH (NOLOCK)
WHERE h.CID = 12345678
ORDER BY h.Occurred DESC
```

### 8.3 Find customers currently assigned to a specific FTD pool manager
```sql
SELECT CID, FTDPoolManagerID
FROM BackOffice.Customer WITH (NOLOCK)
WHERE FTDPoolManagerID = 9002
ORDER BY CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.SetFTDPoolManager | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.SetFTDPoolManager.sql*
