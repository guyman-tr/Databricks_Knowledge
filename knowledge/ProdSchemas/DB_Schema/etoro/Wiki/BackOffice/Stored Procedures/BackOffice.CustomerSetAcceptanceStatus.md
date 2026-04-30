# BackOffice.CustomerSetAcceptanceStatus

> Updates a customer's AcceptanceStatusID on BackOffice.Customer. Two execution branches: when ManagerID is provided (system override, no validation), and when it is absent (validated update with CID existence check).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure sets the customer acceptance status - a regulatory and compliance field that records whether a customer has passed appropriateness/suitability assessments required to trade certain product types. It controls what product categories and instruments a customer is permitted to trade.

The procedure has two distinct execution paths:

**Manager-initiated update** (when @ManagerID is supplied): A BackOffice agent is performing a direct override. Both `AcceptanceStatusID` and `AcceptanceStatusChanginManagerID` (the manager who changed it) are updated. No validation of the status value is performed - this is a privileged override path.

**System/automated update** (when @ManagerID is null/0): A service or automated process is updating the status. The new value is validated against `Dictionary.AcceptanceStatus` before applying, and the CID is validated to exist. Only `AcceptanceStatusID` is updated (the changing manager is not recorded).

`AcceptanceStatusID` is a key regulatory field - it determines whether a customer is accepted for trading specific products under MiFID or other regulatory frameworks.

---

## 2. Business Logic

### 2.1 Branching on ManagerID Presence

**What**: Two different UPDATE paths with different validation rules.

**Columns/Parameters Involved**: @ManagerID, @AcceptanceStatusID, @CID

**Branch A - Manager override** (ISNULL(@ManagerID, 0) != 0):
- Condition: @ManagerID IS NOT NULL AND @ManagerID != 0
- UPDATE BackOffice.Customer SET AcceptanceStatusID=@AcceptanceStatusID, AcceptanceStatusChanginManagerID=@ManagerID WHERE CID=@CID
- No validation of @AcceptanceStatusID or @CID existence
- No @@ROWCOUNT check - silent no-op if CID not found
- Records which manager made the change in AcceptanceStatusChanginManagerID

**Branch B - System update** (ISNULL(@ManagerID, 0) = 0):
- Condition: @ManagerID IS NULL OR @ManagerID = 0
- If @AcceptanceStatusID IS NOT NULL: validates it exists in Dictionary.AcceptanceStatus; RAISERROR(60000) + RETURN 60000 if not found
- UPDATE BackOffice.Customer SET AcceptanceStatusID=@AcceptanceStatusID WHERE CID=@CID (no manager recorded)
- If @@ROWCOUNT=0: RAISERROR(60000) + RETURN 60000 (CID not found)
- @AcceptanceStatusID=NULL: clears the status (NULL passes the validation gate since check is only "IS NOT NULL AND NOT EXISTS")

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. In Branch B, validated to exist in BackOffice.Customer via @@ROWCOUNT check. In Branch A, no validation - silent no-op if not found. |
| 2 | @ManagerID | INT | YES | NULL | CODE-BACKED | BackOffice agent ID triggering the change. NULL or 0 = system/automated path (Branch B, validated). Non-zero = manager override path (Branch A, also records manager in AcceptanceStatusChanginManagerID). |
| 3 | @AcceptanceStatusID | TINYINT | YES | NULL | CODE-BACKED | New acceptance status to set. In Branch B, validated against Dictionary.AcceptanceStatus when non-NULL. NULL = clear acceptance status. Maps to AcceptanceStatusID on BackOffice.Customer. |

**Return Values:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 4 | (implicit 0) | INT | Success in Branch A (no explicit RETURN). |
| 5 | RETURN 60000 | INT | Branch B failure: invalid AcceptanceStatusID or CID not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AcceptanceStatusID | Dictionary.AcceptanceStatus | SELECT (validation, Branch B only) | Validates AcceptanceStatusID exists before applying |
| @CID | BackOffice.Customer | UPDATE | Sets AcceptanceStatusID (both branches); also sets AcceptanceStatusChanginManagerID (Branch A only) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice compliance workflow | External | Direct call | Called by agents (Branch A) and automated appropriateness systems (Branch B) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerSetAcceptanceStatus (procedure)
|- Dictionary.AcceptanceStatus (table) [SELECT: validation in Branch B]
|- BackOffice.Customer (table) [UPDATE: AcceptanceStatusID (+ AcceptanceStatusChanginManagerID in Branch A)]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.AcceptanceStatus | Table | SELECT: validates @AcceptanceStatusID exists (Branch B, non-NULL values only) |
| BackOffice.Customer | Table | UPDATE target: AcceptanceStatusID and AcceptanceStatusChanginManagerID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice compliance and appropriateness workflows | External | Set customer acceptance status via agent override or automated update |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Branch A - no validation | Design | Manager override bypasses value and existence checks; AcceptanceStatusChanginManagerID recorded |
| Branch B - AcceptanceStatus validation | Application | Non-NULL @AcceptanceStatusID must exist in Dictionary.AcceptanceStatus |
| Branch B - CID validation | Application | @@ROWCOUNT=0 after UPDATE raises error 60000 |
| NULL clears status | Behavior | @AcceptanceStatusID=NULL skips the dictionary check and clears the field |
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Agent sets acceptance status (Branch A - manager override)

```sql
EXEC BackOffice.CustomerSetAcceptanceStatus
    @CID = 12345,
    @ManagerID = 99,           -- Non-zero: Branch A path
    @AcceptanceStatusID = 2;   -- Applied without dictionary validation
```

### 8.2 System sets acceptance status (Branch B - validated)

```sql
EXEC BackOffice.CustomerSetAcceptanceStatus
    @CID = 12345,
    @ManagerID = NULL,         -- NULL: Branch B path (validated)
    @AcceptanceStatusID = 2;   -- Must exist in Dictionary.AcceptanceStatus
-- Returns 60000 if AcceptanceStatusID invalid OR CID not found
```

### 8.3 Check current acceptance status and available values

```sql
SELECT bc.CID, bc.AcceptanceStatusID, bc.AcceptanceStatusChanginManagerID,
       ast.Name AS AcceptanceStatusName
FROM BackOffice.Customer bc WITH (NOLOCK)
INNER JOIN Dictionary.AcceptanceStatus ast WITH (NOLOCK) ON ast.AcceptanceStatusID = bc.AcceptanceStatusID
WHERE bc.CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.CustomerSetAcceptanceStatus | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerSetAcceptanceStatus.sql*
