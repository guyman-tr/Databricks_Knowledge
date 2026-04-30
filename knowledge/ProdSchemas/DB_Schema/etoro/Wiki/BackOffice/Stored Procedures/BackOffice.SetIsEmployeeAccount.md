# BackOffice.SetIsEmployeeAccount

> Sets or clears the employee account flag on a customer's BackOffice profile, marking whether the customer account belongs to an eToro employee for compliance segregation and special treatment purposes.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - the customer to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.SetIsEmployeeAccount marks or unmarks a customer account as belonging to an eToro employee. Employee accounts are subject to additional compliance controls under securities regulations - employees trading on a financial platform may be required to disclose trades, observe blackout periods, and seek pre-approval. The IsEmployeeAccount flag enables the BackOffice and compliance systems to identify and apply these controls.

The flag is set by BackOffice HR or compliance teams when an employee registers a trading account, and cleared when the person leaves the company. The procedure uses an enforced row-exists check (RAISERROR if @@ROWCOUNT != 1) ensuring the CID exists in BackOffice.Customer before accepting the update.

---

## 2. Business Logic

### 2.1 Validated Single-Row Update

**What**: Updates the employee account flag with strict existence validation.

**Columns/Parameters Involved**: `@CID`, `@isEmployeeAccount`

**Rules**:
- BEGIN TRY / BEGIN TRAN
- UPDATE BackOffice.Customer SET isEmployeeAccount=@isEmployeeAccount WHERE CID=@CID
- If @@ROWCOUNT != 1: RAISERROR(60000, 16, 1) - enforces that the CID must exist and exactly one row was updated
- COMMIT, RETURN 0 on success
- CATCH block: if @@TRANCOUNT > 1 COMMIT (nested transaction protection), else ROLLBACK. Re-raises error 60000 with error number. Returns error code.
- @isEmployeeAccount defaults to 0 (clearing the flag) if not supplied

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | VERIFIED | The customer to update. Must exist in BackOffice.Customer - the procedure raises error 60000 if @@ROWCOUNT!=1 after the UPDATE (unlike simpler SPs that silently no-op on missing CID). |
| 2 | @isEmployeeAccount | BIT | YES | 0 | VERIFIED | Whether this account belongs to an eToro employee: 1=employee account (compliance controls apply), 0=not an employee account (default). Defaults to 0 if not supplied - can be used to clear the flag by calling without the parameter. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | MODIFIER (UPDATE isEmployeeAccount) | Sets or clears the employee account designation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice HR/Compliance module | - | Caller | Called when an employee registers an account or leaves the company |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.SetIsEmployeeAccount (procedure)
└── BackOffice.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | UPDATE: SET isEmployeeAccount=@isEmployeeAccount WHERE CID=@CID; validates @@ROWCOUNT=1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice HR/Compliance | External | Sets employee flag on customer accounts for compliance segregation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Nested Transaction Handling

The CATCH block contains unusual nested transaction logic: `IF @@TRANCOUNT > 1 COMMIT TRAN` followed by `IF @@TRANCOUNT = 1 ROLLBACK TRAN`. This handles the case where this procedure is called within an outer transaction - it commits the inner savepoint without affecting the outer transaction, then allows the outer to decide. If standalone, it rolls back the single transaction. This is a defensive pattern for reuse in transaction-aware calling code.

---

## 8. Sample Queries

### 8.1 Mark a customer as an employee account
```sql
DECLARE @Err INT
EXEC @Err = BackOffice.SetIsEmployeeAccount
    @CID              = 12345678,
    @isEmployeeAccount = 1
SELECT @Err AS ErrorCode
```

### 8.2 Clear employee account flag (employee left company)
```sql
EXEC BackOffice.SetIsEmployeeAccount
    @CID              = 12345678,
    @isEmployeeAccount = 0
```

### 8.3 Find all employee accounts
```sql
SELECT CID, isEmployeeAccount
FROM BackOffice.Customer WITH (NOLOCK)
WHERE isEmployeeAccount = 1
ORDER BY CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,8,10,11; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.SetIsEmployeeAccount | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.SetIsEmployeeAccount.sql*
