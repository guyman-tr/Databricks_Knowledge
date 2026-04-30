# BackOffice.GetAccountStatusID

> Returns the account status ID for a given customer, treating NULL as Open (1).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer identifier; returns a single TINYINT scalar |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetAccountStatusID` is a lightweight lookup procedure that retrieves the account status of a single customer from `Customer.CustomerStatic`. The return value indicates whether the customer's trading account is currently Open (1) or Closed (2), with any NULL status treated as Open - reflecting the business rule that accounts are implicitly active until explicitly closed.

This procedure exists as a named, intent-declaring entry point for components that need to check account state before allowing operations (deposits, trades, withdrawals). It avoids ad-hoc SELECTs directly against `Customer.CustomerStatic` from application code.

The ISNULL default of 1 (Open) is significant: roughly 1 million customers (5.6% of the 18.7M+ total) have NULL in AccountStatusID on CustomerStatic, which the procedure treats identically to explicitly-Open accounts. This is a safe default since 2 (Closed) is the only meaningful non-Open state.

---

## 2. Business Logic

### 2.1 NULL-to-Open Default

**What**: Customers with no recorded AccountStatusID are treated as Open (active).

**Columns/Parameters Involved**: `@CID`, `AccountStatusID`

**Rules**:
- `ISNULL(AccountStatusID, 1)` means any customer with NULL status is returned as status 1 (Open).
- ~1.05M customers in production have NULL AccountStatusID - all are considered Open by this procedure.
- Only 2 statuses exist in Dictionary.AccountStatus: 1=Open, 2=Closed.
- AccountStatusID=2 (Closed) must be explicitly set by `BackOffice.AccountStatusChange` - it is never the NULL default.

**Diagram**:
```
Customer.CustomerStatic.AccountStatusID
        |
    ISNULL(AccountStatusID, 1)
        |
        +--- NULL  -> returns 1 (Open)
        +--- 1     -> returns 1 (Open)
        +--- 2     -> returns 2 (Closed)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer Identifier (CID). Identifies the customer to look up in Customer.CustomerStatic. Must match an existing CID; if no row exists the procedure returns an empty result set (no rows, not NULL). |
| 2 | (return) AccountStatusID | TINYINT | NO | - | VERIFIED | Account status: 1=Open (account is active, default when NULL); 2=Closed (account has been explicitly closed via BackOffice.AccountStatusChange). Source: Dictionary.AccountStatus. ISNULL defaults NULL to 1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerStatic | Lookup | Reads AccountStatusID by CID PK lookup. |
| (return) AccountStatusID | Dictionary.AccountStatus | Lookup | Returned value is a FK to Dictionary.AccountStatus (1=Open, 2=Closed). |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No callers found in the SQL repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetAccountStatusID (procedure)
└── Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | SELECT AccountStatusID WHERE CID = @CID. Cross-schema read. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | No procedures in the repository call this procedure. Invoked externally (application or BackOffice UI). |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. SET NOCOUNT ON is set. No error handling or validation beyond parameter type.

---

## 8. Sample Queries

### 8.1 Get account status for a specific customer
```sql
-- Returns 1 (Open) or 2 (Closed) for the given CID
EXEC BackOffice.GetAccountStatusID @CID = 12345678;
```

### 8.2 Verify status with human-readable label
```sql
-- Inline equivalent with label join
SELECT
    cs.CID,
    ISNULL(cs.AccountStatusID, 1) AS AccountStatusID,
    ast.AccountStatusName
FROM Customer.CustomerStatic cs WITH (NOLOCK)
JOIN Dictionary.AccountStatus ast WITH (NOLOCK)
    ON ISNULL(cs.AccountStatusID, 1) = ast.AccountStatusID
WHERE cs.CID = 12345678;
```

### 8.3 Count customers by account status (distribution)
```sql
SELECT
    ISNULL(cs.AccountStatusID, 1) AS AccountStatusID,
    ast.AccountStatusName,
    COUNT(*) AS CustomerCount
FROM Customer.CustomerStatic cs WITH (NOLOCK)
JOIN Dictionary.AccountStatus ast WITH (NOLOCK)
    ON ISNULL(cs.AccountStatusID, 1) = ast.AccountStatusID
GROUP BY ISNULL(cs.AccountStatusID, 1), ast.AccountStatusName
ORDER BY CustomerCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetAccountStatusID | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetAccountStatusID.sql*
