# BackOffice.CustomerFXEligibilityUpdate

> Marks a customer as eligible for FX (forex) trading by setting FXEligibilityDate to the current UTC time on BackOffice.Customer. Raises error 60000 if the CID does not exist.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure grants FX eligibility to a customer by stamping the current timestamp into `BackOffice.Customer.FXEligibilityDate`. Once this date is set, the customer is eligible to trade foreign exchange instruments on the eToro platform.

FX eligibility is a compliance gate: not all customers are allowed to trade leveraged FX products. BackOffice agents or automated processes call this SP to record the moment eligibility was granted, after any required checks (appropriateness tests, regulatory review, etc.) have been completed.

The original version of this procedure also sent a Service Broker message to update Customer Dynamics (CRM system) with the new eligibility status. That integration was removed in December 2012 by Yitzchak Wahnon, leaving several unused variable declarations (`@OriginalCID`, `@ProviderID`, `@OriginalProviderID`, `@XMLDataDYN`, `@Handle`, `@IsReal`) as artifacts of the original design.

---

## 2. Business Logic

### 2.1 FXEligibilityDate Stamp with CID Existence Validation

**What**: Sets FXEligibilityDate to GETDATE() and validates the CID existed.

**Columns/Parameters Involved**: @CID, BackOffice.Customer.FXEligibilityDate

**Rules**:
- BEGIN TRAN
- UPDATE BackOffice.Customer SET FXEligibilityDate=GETDATE() WHERE CID=@CID
- If @@ROWCOUNT=0 (CID not found): RAISERROR(60000, 'Incorrect CID Value') -> enters CATCH -> ROLLBACK -> RETURN 60000
- If @@ROWCOUNT=1 (CID found): COMMIT -> RETURN 0

The procedure is idempotent in the sense that calling it again for an already-eligible customer simply overwrites FXEligibilityDate with the current timestamp (the column is not protected against re-grant).

### 2.2 Nested Transaction Handling in CATCH

**What**: CATCH branch handles both outermost and nested transaction contexts.

**Rules**:
- IF @@trancount=1: ROLLBACK TRAN (outermost transaction - full rollback)
- IF @@trancount>1: COMMIT TRAN (nested - commit the partial work rather than rolling back a savepoint that doesn't exist)
- After transaction handling, re-raises the appropriate 60000 error based on whether failure was CID-not-found or a different SQL error

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Must exist in BackOffice.Customer. If CID not found (@@ROWCOUNT=0 after UPDATE): RAISERROR 60000 is raised. |

**Return Values:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 2 | RETURN 0 | INT | Success: FXEligibilityDate was set and transaction committed. |
| 3 | RETURN 60000 | INT | Failure: either CID not found (error message: 'Incorrect CID Value') or other SQL error (error message: 'CustomerFXEligibilityUpdate'). |

**Unused Variables (legacy artifacts)**:

| Variable | Type | Note |
|----------|------|------|
| @OriginalCID | INT | Unused - artifact of removed Service Broker / Customer Dynamics integration |
| @ProviderID | INT | Unused - artifact of removed Service Broker / Customer Dynamics integration |
| @OriginalProviderID | INT | Unused - artifact of removed Service Broker / Customer Dynamics integration |
| @XMLDataDYN | XML | Unused - artifact of removed Service Broker message XML construction |
| @Handle | UNIQUEIDENTIFIER | Unused - artifact of removed Service Broker conversation handle |
| @IsReal | BIT | Unused - artifact of removed real-account check for Service Broker routing |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | UPDATE | Sets FXEligibilityDate=GETDATE() on the matching customer row |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice FX eligibility process | External | Direct call | Called when an agent or workflow grants FX trading eligibility to a customer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerFXEligibilityUpdate (procedure)
|- BackOffice.Customer (table) [UPDATE: FXEligibilityDate]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | UPDATE target: sets FXEligibilityDate to current timestamp |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice FX eligibility workflow | External | Calls this SP to grant FX trading eligibility |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Error 60000 | Application | Raised when CID not found (@@ROWCOUNT=0) or on unexpected SQL error |
| Explicit transaction | Design | BEGIN TRAN / COMMIT wraps the UPDATE for safety |
| Nested transaction safety | Design | CATCH handles @@trancount=1 (rollback) vs >1 (commit) to avoid orphaned transactions |
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| Removed Service Broker integration | History | Original version sent Customer Dynamics XML via Service Broker (removed Dec 2012 by Yitzchak Wahnon); 6 unused variables remain |

---

## 8. Sample Queries

### 8.1 Grant FX eligibility to a customer

```sql
EXEC BackOffice.CustomerFXEligibilityUpdate @CID = 12345;
-- RETURN 0 = success
-- RETURN 60000 = CID not found
```

### 8.2 Check current FX eligibility date

```sql
SELECT CID, FXEligibilityDate
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 12345;
-- NULL = not yet eligible
-- Non-NULL = date eligibility was last granted
```

### 8.3 Find recently granted FX eligibilities

```sql
SELECT TOP 100 CID, FXEligibilityDate
FROM BackOffice.Customer WITH (NOLOCK)
WHERE FXEligibilityDate >= DATEADD(DAY, -7, GETDATE())
ORDER BY FXEligibilityDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.CustomerFXEligibilityUpdate | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerFXEligibilityUpdate.sql*
