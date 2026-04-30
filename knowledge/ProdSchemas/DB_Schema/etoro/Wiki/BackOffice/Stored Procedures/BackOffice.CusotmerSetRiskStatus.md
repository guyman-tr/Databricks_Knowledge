# BackOffice.CusotmerSetRiskStatus

> Atomically transitions a customer's risk status: closes the current active History.RiskStatus record (end-dating with GETUTCDATE()), inserts a new active record, and updates BackOffice.Customer.RiskStatusID - all within a single transaction.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (Customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure manages customer risk status transitions with full audit trail. Risk status is a compliance and trading-risk classification assigned to each customer (e.g., low risk, high risk, PEP - Politically Exposed Person, watchlist). Changing a customer's risk status requires both updating the current status (for fast lookups) and creating an immutable history record (for compliance auditing and regulatory reporting).

Note: The procedure name contains a typo - "CusotmerSetRiskStatus" instead of "CustomerSetRiskStatus". The error message in the CATCH block correctly spells the name as "CustomerSetRiskStatus". Callers must use the typo'd name.

The procedure uses the **sentinel end-date pattern** for `History.RiskStatus`: the currently active record has `ValidTo='30000101'` (year 3000, a sentinel for "no expiry"). When changing status, the current record is closed by setting ValidTo to now, and a new record with ValidTo='30000101' is opened. This creates a complete, non-overlapping audit chain of all risk status changes with timestamps.

---

## 2. Business Logic

### 2.1 Three-Step Atomic Risk Status Transition

**What**: Reads the current status, closes the active history record, opens a new one, and updates the customer record - all in one transaction.

**Columns/Parameters Involved**: `@CID`, `@RiskStatusID`, `@ManagerID`, `@OldRiskStatusID`, `BackOffice.Customer.RiskStatusID`, `History.RiskStatus.ValidTo`, `History.RiskStatus.OldRiskStatusID`, `History.RiskStatus.NewRiskStatusID`

**Rules**:
- Step 1 (Pre-read): SELECT @OldRiskStatusID = RiskStatusID FROM BackOffice.Customer WHERE CID=@CID (with NOLOCK - reads current status for audit trail)
- Step 2 (Close active): UPDATE History.RiskStatus SET ValidTo=GETUTCDATE() WHERE CID=@CID AND ValidTo='30000101' - end-dates the current active record
- Step 3 (Open new): INSERT INTO History.RiskStatus (CID, OldRiskStatusID, NewRiskStatusID, ManagerID, ValidFrom, ValidTo) VALUES (@CID, @OldRiskStatusID, @RiskStatusID, @ManagerID, GETUTCDATE(), '30000101') - creates the new active record
- Step 4 (Update current): UPDATE BackOffice.Customer SET RiskStatusID=@RiskStatusID WHERE CID=@CID - updates the denormalized current-status field
- All steps 2-4 inside BEGIN TRAN / COMMIT TRAN; on error: ROLLBACK and RETURN(-1)

**Diagram**:
```
History.RiskStatus (before):
  CID=X, OldRiskStatusID=1, NewRiskStatusID=2, ValidFrom=T0, ValidTo=30000101 (active)

After transition to @RiskStatusID=3:
  CID=X, OldRiskStatusID=1, NewRiskStatusID=2, ValidFrom=T0, ValidTo=GETUTCDATE()  (closed)
  CID=X, OldRiskStatusID=2, NewRiskStatusID=3, ValidFrom=GETUTCDATE(), ValidTo=30000101 (new active)

BackOffice.Customer.RiskStatusID updated to 3
```

### 2.2 TRY/CATCH and Transaction Safety

**What**: Ensures atomicity; all three writes succeed or all are rolled back.

**Rules**:
- TRY/CATCH wraps the entire BEGIN TRAN...COMMIT TRAN block
- On CATCH: ROLLBACK, build error message with line number and SQL error message, RAISERROR with severity 16
- RETURN 0 on success; RETURN -1 on any error

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. The customer whose risk status is being changed. Used for all three DML operations (SELECT, UPDATE history, UPDATE customer). |
| 2 | @RiskStatusID | INT | NO | - | CODE-BACKED | The new risk status to assign. Stored as NewRiskStatusID in the new History.RiskStatus record and as RiskStatusID in BackOffice.Customer. |
| 3 | @ManagerID | INT | NO | - | CODE-BACKED | The BackOffice manager authorizing the risk status change. Logged in History.RiskStatus.ManagerID for audit trail purposes. |

**Return Value:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 4 | RETURN | INT | 0 on success; -1 on any error (after ROLLBACK and RAISERROR with error details). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | Lookup (SELECT) | Reads current RiskStatusID as @OldRiskStatusID for audit trail |
| @CID | BackOffice.Customer | MODIFIER (UPDATE) | Sets RiskStatusID=@RiskStatusID as denormalized current status |
| @CID | History.RiskStatus | MODIFIER (UPDATE) | Closes current active record by setting ValidTo=GETUTCDATE() (cross-schema) |
| @CID | History.RiskStatus | WRITER (INSERT) | Creates new active record with OldRiskStatusID, NewRiskStatusID, ValidFrom, ValidTo='30000101' (cross-schema) |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found. Called from BackOffice risk management UI.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CusotmerSetRiskStatus (procedure)
|- BackOffice.Customer (table) [SELECT + UPDATE - current risk status]
+-- History.RiskStatus (table) [UPDATE + INSERT - risk status audit trail, cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | SELECT: reads current RiskStatusID for @OldRiskStatusID; UPDATE: sets new RiskStatusID |
| History.RiskStatus | Table | UPDATE: closes active record (ValidTo=GETUTCDATE()); INSERT: opens new active record (ValidTo='30000101') |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice risk management UI | External | Calls this when an operator changes a customer's risk classification |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Sentinel ValidTo='30000101' | Design | Year 3000 sentinel date marks the currently active risk status record in History.RiskStatus; used in WHERE ValidTo='30000101' to find and close the active record |
| Procedure name typo | Design | Name is "CusotmerSetRiskStatus" (typo) not "CustomerSetRiskStatus"; callers must use the typo'd name |
| WITH (NOLOCK) on pre-read | Design | The pre-read of BackOffice.Customer for @OldRiskStatusID uses NOLOCK - the actual UPDATE is inside the transaction, so the NOLOCK read only risks a slightly stale old value in the audit trail (acceptable) |
| GETUTCDATE() | Design | All timestamps in History.RiskStatus use UTC; consistent with the platform's UTC convention |

---

## 8. Sample Queries

### 8.1 Change a customer's risk status to High Risk

```sql
DECLARE @Result INT
EXEC @Result = BackOffice.CusotmerSetRiskStatus
    @CID = 12345,
    @RiskStatusID = 3,  -- e.g., 3 = High Risk
    @ManagerID = 678
SELECT @Result AS Result -- 0 = success, -1 = error
```

### 8.2 View the risk status history for a customer

```sql
SELECT
    CID, OldRiskStatusID, NewRiskStatusID, ManagerID,
    ValidFrom, ValidTo,
    CASE WHEN ValidTo = '30000101' THEN 'CURRENT' ELSE 'HISTORICAL' END AS Status
FROM History.RiskStatus WITH (NOLOCK)
WHERE CID = 12345
ORDER BY ValidFrom DESC
```

### 8.3 Find all customers with a specific current risk status

```sql
SELECT BC.CID, BC.RiskStatusID
FROM BackOffice.Customer BC WITH (NOLOCK)
WHERE BC.RiskStatusID = 3  -- e.g., High Risk
ORDER BY BC.CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CusotmerSetRiskStatus | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CusotmerSetRiskStatus.sql*
