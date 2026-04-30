# BackOffice.UpdateBackOfficeChangeCustomerPassword

> Clears the "must change password" flag on a customer's back-office record after they have successfully changed their password.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - targets BackOffice.Customer.CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.UpdateBackOfficeChangeCustomerPassword` is the acknowledgment step in the forced password-change workflow. When a back-office manager or automated process requires a customer to change their password, `BackOffice.Customer.ChangePassword` is set to `1`. Once the customer logs in and changes their password, this SP is called to clear that flag back to `0`, completing the lifecycle.

The procedure exists to provide an explicit, auditable handshake between the "force change" trigger and the "change completed" confirmation. Without it, the `ChangePassword=1` flag would persist after the customer has already acted on it, causing them to be prompted again on their next login.

The `AND ChangePassword = 1` condition makes the operation safe and idempotent: if the flag is already `0` (change already confirmed or never requested), the UPDATE matches no rows and performs no write, avoiding unnecessary locking.

---

## 2. Business Logic

### 2.1 Forced Password-Change Acknowledgment

**What**: Clears the `ChangePassword` prompt flag to confirm that the customer has completed the required password change.

**Columns Involved**: `BackOffice.Customer.ChangePassword`

**Rules**:
- Only executes the UPDATE if `ChangePassword = 1` (flag was set). If the flag is already `0`, no rows are affected (safe no-op).
- Sets `ChangePassword = 0` - the customer is no longer required to change their password on next login.
- Always returns `0` (success) regardless of rows affected.

**Diagram**:
```
Back-office admin / automation:
  SET BackOffice.Customer.ChangePassword = 1   <- force password change
       |
       | Customer logs in, prompted to change password
       |
       v
  Customer changes password
       |
       v
  BackOffice.UpdateBackOfficeChangeCustomerPassword @CID=<CID>
  -> SET ChangePassword = 0 (only if = 1)      <- acknowledge completion
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID. Identifies the customer in BackOffice.Customer whose ChangePassword flag should be cleared. Must match an existing BackOffice.Customer.CID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | [BackOffice.Customer](../Tables/BackOffice.Customer.md).ChangePassword | UPDATE target | Clears the forced-password-change flag for this customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No direct callers found in BackOffice SPs. | - | - | Called from the application layer after a customer completes a forced password change. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.UpdateBackOfficeChangeCustomerPassword (procedure)
+-- BackOffice.Customer (table) [UPDATE target: ChangePassword column]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [BackOffice.Customer](../Tables/BackOffice.Customer.md) | Table | UPDATE target - sets ChangePassword=0 WHERE CID=@CID AND ChangePassword=1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in repo. | - | Called from back-office application after successful password change. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Clear the forced-password-change flag for a customer

```sql
EXEC BackOffice.UpdateBackOfficeChangeCustomerPassword @CID = 12345;
-- Clears ChangePassword from 1 to 0 if currently set.
-- No-op if ChangePassword is already 0 or NULL.
```

### 8.2 Verify ChangePassword state before and after

```sql
SELECT CID, ChangePassword
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.3 Find all customers currently flagged for forced password change

```sql
SELECT CID, ChangePassword
FROM BackOffice.Customer WITH (NOLOCK)
WHERE ChangePassword = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Dependency Inheritance, Caller Scan, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.UpdateBackOfficeChangeCustomerPassword | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.UpdateBackOfficeChangeCustomerPassword.sql*
