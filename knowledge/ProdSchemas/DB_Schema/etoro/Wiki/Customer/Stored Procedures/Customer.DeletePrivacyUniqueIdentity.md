# Customer.DeletePrivacyUniqueIdentity

> Hard-deletes a specific social network connection for a customer from Customer.PrivacyUniqueIdentity by CID + PrivacyRecipientID (network ID), returning -1 if no matching row exists.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @PrivacyRecipientID (composite delete key) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.DeletePrivacyUniqueIdentity removes a customer's linked social network account from Customer.PrivacyUniqueIdentity. The combination of @CID and @PrivacyRecipientID identifies exactly which social platform connection to remove (e.g., CID 12345 + PrivacyRecipientID 2 = delete this customer's Facebook connection).

This procedure is used in two primary flows: (1) GDPR erasure - when a customer exercises their right to be forgotten, their social network connections must be removed; (2) Unlink social account - when a customer manually disconnects a social login ("Unlink Facebook"). The procedure performs a hard DELETE - the row is permanently removed, not soft-deleted.

The @GCID parameter is marked as "redundant" in the code comment and is excluded from the WHERE clause. It exists as a legacy parameter that callers may pass but has no effect on the deletion. Removing it from the interface would break existing callers, so it remains as dead code.

The return value (-1 = no row found, 0 = success) allows callers to detect whether the deletion was meaningful - useful for GDPR audit flows where confirming that data was actually deleted is required.

---

## 2. Business Logic

### 2.1 Delete Pattern with No-Op Detection

**What**: The DELETE returns a status code indicating whether any row was actually removed.

**Columns/Parameters Involved**: `@CID`, `@PrivacyRecipientID`, `@@ROWCOUNT`

**Rules**:
- DELETE WHERE CID = @CID AND PrivacyRecipientID = @PrivacyRecipientID
- If @@ROWCOUNT = 0 (no matching row): RETURN -1 (not found / already deleted)
- If @@ROWCOUNT > 0 (row deleted): RETURN 0 (success)
- Note: @GCID is accepted but NOT used in the WHERE clause - legacy dead parameter

### 2.2 Nested Transaction Safety

**What**: The error handler supports being called within an outer transaction.

**Rules**:
- On error with @@TRANCOUNT = 1: ROLLBACK (this procedure owns the transaction)
- On error with @@TRANCOUNT > 1: COMMIT (nested in outer transaction - do not rollback the outer transaction, commit the inner savepoint and let the outer handle its state)
- This pattern supports callers who wrap the call in a larger transaction (e.g., GDPR erasure deletes from multiple tables)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID - the eToro customer whose social connection is to be deleted. Maps to Customer.PrivacyUniqueIdentity.CID (part of composite PK). |
| 2 | @GCID | int | NO | - | CODE-BACKED | Group Customer ID - **REDUNDANT PARAMETER** (comment in code). Accepted for backward compatibility but NOT used in the WHERE clause. Pass any value; it has no effect on which row is deleted. |
| 3 | @PrivacyRecipientID | int | NO | - | CODE-BACKED | Social network platform ID. Maps to Customer.PrivacyUniqueIdentity.PrivacyRecipientID (part of composite PK). Identifies which social platform connection to remove. |

**Return value:**

| Value | Meaning |
|-------|---------|
| 0 | Row successfully deleted |
| -1 | No matching row found (already deleted or never existed) |
| Other | SQL error number (from CATCH block via RETURN @error_num) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @PrivacyRecipientID | Customer.PrivacyUniqueIdentity | DELETE | Removes the row matching the composite PK (CID, PrivacyRecipientID) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Likely called by GDPR erasure workflows and social login unlink UI flows.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.DeletePrivacyUniqueIdentity (procedure)
└── Customer.PrivacyUniqueIdentity (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.PrivacyUniqueIdentity | Table | DELETE target - removes social network connection by (CID, PrivacyRecipientID) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT repo. | - | Called from application GDPR/unlink flows. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURN @error_num | Return code | -1=not found, 0=success, SQL error number on exception |
| Nested transaction handling | Error handler | @@TRANCOUNT=1 -> ROLLBACK; @@TRANCOUNT>1 -> COMMIT (nested transaction safe) |

---

## 8. Sample Queries

### 8.1 Delete a customer's Facebook connection (PrivacyRecipientID=2)

```sql
DECLARE @result INT
EXEC @result = Customer.DeletePrivacyUniqueIdentity
    @CID = 12345678,
    @GCID = 0,  -- redundant, value ignored
    @PrivacyRecipientID = 2
SELECT @result AS ReturnCode  -- 0=deleted, -1=not found
```

### 8.2 Verify deletion

```sql
SELECT CID, GCID, PrivacyRecipientID, UserID, IsAuthorized
FROM Customer.PrivacyUniqueIdentity WITH (NOLOCK)
WHERE CID = 12345678
ORDER BY PrivacyRecipientID
```

### 8.3 Check all social connections for a customer before GDPR deletion

```sql
SELECT
    pui.CID,
    pui.PrivacyRecipientID,
    pui.UserID,
    pui.IsAuthorized,
    pui.TokenExpiry
FROM Customer.PrivacyUniqueIdentity pui WITH (NOLOCK)
WHERE pui.CID = 12345678
ORDER BY pui.PrivacyRecipientID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 9/10, Logic: 8/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.DeletePrivacyUniqueIdentity | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.DeletePrivacyUniqueIdentity.sql*
