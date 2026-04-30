# Billing.GetCustomerAccounts

> Deprecated stub procedure that performs no work - the original SELECT from the now-removed Billing.Account table is commented out, leaving only a RETURN 0 with no result set.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID input - accepted but not used |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCustomerAccounts` is a deprecated stub procedure. It accepts a customer ID (@CID) but returns no data - its only executable statement is `RETURN 0`. The original SELECT statement (`SELECT * FROM Billing.Account WITH (NOLOCK) WHERE CID = @CID`) is commented out.

The `Billing.Account` table referenced in the commented code no longer exists in the SSDT project, indicating the procedure was decommissioned when the Account table was removed or when account data was restructured. The procedure body has not been dropped from the database, likely because callers still reference it and a schema-breaking removal was deferred.

Data flow: Callers receive an empty result set (zero rows) and return code 0. Any caller expecting account data from this procedure will receive no rows and must be updated to use the current account data source. Granted to PROD_BIadmins and BILLING_MANAGER users.

---

## 2. Business Logic

### 2.1 Stub Pattern

**What**: The procedure is an intentional no-op stub - accepts a parameter but performs no operation.

**Rules**:
- Body contains only `SET NOCOUNT ON` and `RETURN 0`.
- The original SELECT is preserved as a comment: `-- SELECT * FROM Billing.Account WITH (NOLOCK) WHERE CID = @CID`.
- `Billing.Account` table does not exist in the SSDT repo - the referenced table has been removed.
- Returns an empty result set (no columns, no rows) to all callers.
- RETURN 0 indicates success - no error is raised.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Accepted as a parameter but not used in any SQL statement - the procedure body is a stub that returns immediately with RETURN 0. |

**Returns**: No result set (empty - zero columns and zero rows).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (commented) | Billing.Account | Commented-out reference | Original SELECT referenced Billing.Account which no longer exists in SSDT. Table was removed. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | EXECUTE grant | Permission | BI admin user with execute permission - likely retained for backward compatibility |
| BILLING_MANAGER | EXECUTE grant | Permission | Billing manager role - retained for backward compatibility |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCustomerAccounts (procedure)
(no active dependencies - stub with commented-out body)
```

---

### 6.1 Objects This Depends On

No dependencies. The procedure body is a stub (RETURN 0 only). The original dependency on Billing.Account is commented out and that table no longer exists.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | No stored procedures call this procedure in the SSDT repo. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Confirm the stub behavior

```sql
-- Returns 0 rows, return code 0 - no data
DECLARE @rc INT
EXEC @rc = [Billing].[GetCustomerAccounts] @CID = 1234567
SELECT @rc AS ReturnCode
-- Expected: ReturnCode = 0, no result set
```

### 8.2 Check if Billing.Account table exists

```sql
-- Verify the referenced table no longer exists
SELECT OBJECT_ID('Billing.Account', 'U') AS AccountTableObjectID
-- Expected: NULL (table does not exist)
```

### 8.3 Historical context - what this used to return

```sql
-- The commented-out original logic was:
-- SELECT * FROM Billing.Account WITH (NOLOCK) WHERE CID = @CID
-- This table no longer exists. To find current customer payment accounts use:
SELECT f.FundingID, f.FundingTypeID, f.DateCreated
FROM [Billing].[Funding] f WITH (NOLOCK)
INNER JOIN [Billing].[CustomerToFunding] ctf WITH (NOLOCK) ON ctf.FundingID = f.FundingID
WHERE ctf.CID = 1234567
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped - no repos; 11 complete)*
*Sources: Atlassian: 0 Confluence + 0 Jira | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCustomerAccounts | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCustomerAccounts.sql*
