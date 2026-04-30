# BackOffice.CustomerClear

> Sets or clears the Cleared flag on a customer's BackOffice.Customer record, toggling their "cleared" compliance status.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (Customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure manages the `Cleared` flag on BackOffice.Customer, which indicates that a customer has passed a compliance or AML clearance check. When a BackOffice compliance agent marks a customer as cleared (Cleared=1), they confirm that the customer's profile, documents, and activity have been reviewed and no compliance concerns remain. Setting Cleared=0 revokes this status - typically when new information emerges that requires re-review.

The `Cleared` flag is used in compliance workflows to distinguish customers who have been positively cleared (all checks passed) from those pending review or flagged for re-evaluation.

---

## 2. Business Logic

### 2.1 Cleared Flag Toggle

**What**: Updates the Cleared bit column for the specified customer.

**Columns/Parameters Involved**: `@CID`, `@IsClear`, `BackOffice.Customer.Cleared`

**Rules**:
- UPDATE BackOffice.Customer SET Cleared=@IsClear WHERE CID=@CID
- @IsClear=1: customer is marked as compliance-cleared
- @IsClear=0: customer's cleared status is revoked
- If @CID does not exist: UPDATE runs silently (0 rows affected), @@ERROR=0
- Returns @@ERROR: 0 on success or not-found; non-zero on DB error

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. The customer whose Cleared flag is being updated. PK of BackOffice.Customer. |
| 2 | @IsClear | BIT | NO | - | CODE-BACKED | New value for the Cleared flag. 1=customer is compliance-cleared; 0=cleared status revoked. |

**Return Value:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 3 | RETURN | INT | @@ERROR: 0 on success or not-found; non-zero on SQL error. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | MODIFIER | Updates Cleared flag WHERE CID=@CID |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found. Called from BackOffice compliance review UI.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerClear (procedure)
+-- BackOffice.Customer (table) [UPDATE target - Cleared flag]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | UPDATE: sets Cleared=@IsClear WHERE CID=@CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice compliance UI | External | Calls this to approve or revoke a customer's compliance clearance status |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Silent not-found | Design | If @CID does not exist, UPDATE runs with 0 rows affected; @@ERROR=0 (no exception) |

---

## 8. Sample Queries

### 8.1 Mark a customer as compliance-cleared

```sql
EXEC BackOffice.CustomerClear @CID = 12345, @IsClear = 1
-- Verify: SELECT Cleared FROM BackOffice.Customer WITH (NOLOCK) WHERE CID = 12345
```

### 8.2 Revoke a customer's cleared status

```sql
EXEC BackOffice.CustomerClear @CID = 12345, @IsClear = 0
```

### 8.3 Find all cleared customers

```sql
SELECT CID, Cleared FROM BackOffice.Customer WITH (NOLOCK)
WHERE Cleared = 1
ORDER BY CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.6/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerClear | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerClear.sql*
