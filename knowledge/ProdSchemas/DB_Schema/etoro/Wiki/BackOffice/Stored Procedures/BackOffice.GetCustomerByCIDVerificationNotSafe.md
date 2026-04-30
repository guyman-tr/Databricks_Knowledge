# BackOffice.GetCustomerByCIDVerificationNotSafe

> Thin EXECUTE AS 'dbo' wrapper around BackOffice.GetCustomerByCIDVerification. Grants elevated database access so callers without direct table permissions can retrieve customer verification data.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - delegates directly to GetCustomerByCIDVerification |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a one-line security wrapper: it declares `WITH EXECUTE AS 'dbo'` and immediately calls `BackOffice.GetCustomerByCIDVerification @CID=@CID`. The "NotSafe" suffix indicates that it deliberately bypasses the normal permission model by impersonating the `dbo` user for the duration of the call.

**Why it exists**: `GetCustomerByCIDVerification` queries multiple schemas (Customer, BackOffice, Dictionary, History) and SQL Server's cross-schema permission boundary means that a calling context with only EXECUTE rights on a stored procedure may still lack SELECT rights on the underlying tables. The `EXECUTE AS 'dbo'` clause grants the procedure body full dbo-level access, allowing callers who have EXECUTE permission on this wrapper to retrieve the full verification data without requiring individual table grants.

**When to use NotSafe vs. the direct SP**: Application components or service accounts with restricted permission sets use this wrapper. Components with full database access call `BackOffice.GetCustomerByCIDVerification` directly. Created December 2017 (case 49860 - "GetCustomerByCID NotSafe").

**Output**: Identical to `BackOffice.GetCustomerByCIDVerification` - see that procedure's documentation for all output columns.

---

## 2. Business Logic

No additional logic beyond delegation. All business rules are in `BackOffice.GetCustomerByCIDVerification`.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters** | | | | | | |
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Passed directly to BackOffice.GetCustomerByCIDVerification. |
| **Output Columns** | | | | | | |
| - | (all columns) | - | - | - | CODE-BACKED | Output is identical to BackOffice.GetCustomerByCIDVerification. See that procedure's documentation for all ~43 output columns. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.GetCustomerByCIDVerification | EXEC delegation | Full call delegation; this procedure adds only EXECUTE AS 'dbo' |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application (BO) | N/A | Application call | Used by service accounts or application components with restricted permissions that need customer verification data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerByCIDVerificationNotSafe (procedure)
+-- BackOffice.GetCustomerByCIDVerification (full delegation)
    |- Customer.Customer
    |- BackOffice.Customer
    |- ... (see GetCustomerByCIDVerification docs)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetCustomerByCIDVerification | Procedure | Called directly; all data retrieval logic resides there |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (BO) | External application | Restricted-permission contexts needing customer verification data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- `WITH EXECUTE AS 'dbo'`: impersonates dbo for the procedure body. The caller's original security context is restored after the procedure returns.
- No `SET NOCOUNT ON` in this wrapper (it is set inside the called procedure).
- Single-statement body: `EXEC BackOffice.GetCustomerByCIDVerification @CID=@CID`.

---

## 8. Sample Queries

### 8.1 Call the wrapper

```sql
EXEC BackOffice.GetCustomerByCIDVerificationNotSafe @CID = 12345678;
```

### 8.2 Direct equivalent (requires full permissions)

```sql
EXEC BackOffice.GetCustomerByCIDVerification @CID = 12345678;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira records found for this procedure. (DDL comment references case 49860 - "GetCustomerByCID NotSafe", Dec 2017.)

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCustomerByCIDVerificationNotSafe | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomerByCIDVerificationNotSafe.sql*
