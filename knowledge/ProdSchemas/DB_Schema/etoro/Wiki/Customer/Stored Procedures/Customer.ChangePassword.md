# Customer.ChangePassword

> Changes a customer's password across three systems in a single transaction: the STS identity store, the demo accounts table, and the BackOffice force-change flag.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1 on success, 0 on any exception |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.ChangePassword` is the central password-change procedure for eToro customers. It orchestrates a three-system password update: the STS (Security Token Service) identity provider stores the authoritative hashed password via `dbo.STS_P_UpdateCustomerPassword`; the demo-account legacy table `dbo.DemoCustomers` keeps a plain-text copy for demo accounts; and `BackOffice.Customer.ChangePassword` flag is cleared after an admin-forced reset is completed.

The procedure exists because the password is stored in at least two locations - the STS system (for authentication) and a legacy demo table - and all must be kept in sync. The BackOffice flag (`ChangePassword = 1`) allows admins to force customers to reset their password on next login; this procedure clears that flag once the reset is done.

`XACT_ABORT ON` ensures the entire transaction rolls back atomically if the STS call or any update fails. The caller receives 1 on success and 0 on any exception.

---

## 2. Business Logic

### 2.1 Three-System Password Sync

**What**: The password change must succeed atomically across STS, demo table, and BackOffice flag.

**Columns/Parameters Involved**: `@CID`, `@NewPassword`, `BackOffice.Customer.ChangePassword`, `dbo.DemoCustomers.Password`, `Customer.Customer.GCID`

**Rules**:
- GCID is resolved from Customer.Customer before the transaction starts (NOLOCK read)
- EXEC `dbo.STS_P_UpdateCustomerPassword @gcid, @newPlainTextPassword` - updates the authoritative identity store
- `UPDATE dbo.DemoCustomers SET Password = @NewPassword WHERE GCID = @GCID AND GCID IS NOT NULL AND GCID > 0` - only runs when GCID is valid (> 0)
- `UPDATE BackOffice.Customer SET ChangePassword = 0 WHERE CID = @CID AND ChangePassword = 1` - only clears the flag if it was set; no-op if it was already 0
- All three run inside a single `BEGIN TRAN ... COMMIT TRAN` block with `XACT_ABORT ON`

**Diagram**:
```
Customer.ChangePassword(@CID, @NewPassword)
  |
  +--> Get GCID from Customer.Customer (NOLOCK)
  |
  +--> BEGIN TRAN (XACT_ABORT ON)
        |
        +--> EXEC STS_P_UpdateCustomerPassword(@GCID, @NewPassword)
        +--> UPDATE dbo.DemoCustomers (where GCID > 0)
        +--> UPDATE BackOffice.Customer SET ChangePassword = 0 (where = 1)
        |
        +--> COMMIT --> RETURN 1
        +--> CATCH --> ROLLBACK, RETURN 0
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Used to resolve GCID from Customer.Customer and to target the BackOffice.Customer row for flag clearance. |
| 2 | @NewPassword | VARCHAR(20) | NO | - | CODE-BACKED | The new plain-text password. Passed to STS_P_UpdateCustomerPassword (which hashes it) and stored as plain text in dbo.DemoCustomers (legacy demo store). |
| 3 | RETURN value | INT | NO | - | CODE-BACKED | 1 = success (all three systems updated and committed). 0 = failure (exception caught, transaction rolled back). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID -> GCID | Customer.Customer | Read | GCID lookup before the transaction starts |
| @GCID | dbo.STS_P_UpdateCustomerPassword | Call | STS identity provider - the authoritative password store (hashes the plain-text password) |
| @GCID | dbo.DemoCustomers | Write | Legacy demo accounts table - updated with plain-text password when GCID > 0 |
| @CID | BackOffice.Customer | Write | Clears ChangePassword flag (sets to 0 where it was 1) after admin-forced reset completes |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.UpdateBackOfficeChangeCustomerPassword | SQL reference | Caller | BackOffice admin workflow that forces a password reset |
| Application layer | API call | External | Called when a customer completes a password change in the platform UI |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.ChangePassword (procedure)
├── Customer.Customer (view)
├── dbo.STS_P_UpdateCustomerPassword (procedure - external STS)
├── dbo.DemoCustomers (table - legacy)
└── BackOffice.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | GCID lookup (NOLOCK) by CID before the transaction |
| dbo.STS_P_UpdateCustomerPassword | Procedure | External STS call to update the authoritative hashed password by GCID |
| dbo.DemoCustomers | Table | Legacy demo password store - updated by GCID when GCID is valid |
| BackOffice.Customer | Table | ChangePassword flag cleared (0) after successful reset |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.UpdateBackOfficeChangeCustomerPassword | Procedure | Admin-initiated forced password change flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

`SET XACT_ABORT ON` ensures any runtime error automatically rolls back the open transaction, preventing partial updates across the three systems.

---

## 8. Sample Queries

### 8.1 Execute password change for a customer

```sql
DECLARE @Result INT
EXEC @Result = [Customer].[ChangePassword]
    @CID         = 12345,
    @NewPassword = 'NewPass123'
SELECT @Result AS Success  -- 1=success, 0=failure
```

### 8.2 Check if a customer has a pending force-change flag

```sql
SELECT CID, ChangePassword
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 12345
-- ChangePassword=1 means admin has flagged this account for forced reset
```

### 8.3 Find all accounts with pending forced password resets

```sql
SELECT TOP 50
    bc.CID,
    cs.UserName,
    cs.Email
FROM BackOffice.Customer bc WITH (NOLOCK)
JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cs.CID = bc.CID
WHERE bc.ChangePassword = 1
ORDER BY bc.CID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3 (1, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.ChangePassword | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.ChangePassword.sql*
