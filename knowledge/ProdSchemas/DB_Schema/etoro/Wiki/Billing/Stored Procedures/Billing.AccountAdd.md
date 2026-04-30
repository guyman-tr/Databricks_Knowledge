# Billing.AccountAdd

> Stub stored procedure that previously created a billing account record for a customer-currency pair; all active logic has been commented out and the procedure currently returns 0 immediately without performing any operation.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID, @CurrencyID input; no output (returns 0) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.AccountAdd` was designed to create a new billing account entry in `Billing.Account` for a given customer and currency. It would first verify the customer is a real (non-demo) account, then create the account if it did not already exist, returning the new AccountID via SCOPE_IDENTITY(). If the account already existed, it would return the existing AccountID.

The procedure currently contains **no active logic** - all operational code is commented out, and the body consists only of `RETURN 0`. It is retained in the codebase (with permissions granted to BILLING_MANAGER and PROD_BIadmins) but does not perform any action when called. It has no active callers in the current stored procedure codebase.

The intent was to support account provisioning for multi-currency billing, where a customer may hold accounts in different currencies. The guard against demo accounts (`IsReal = 1` check on `Customer.Customer`) indicates this was restricted to live trading accounts.

---

## 2. Business Logic

### 2.1 Original (Commented-Out) Logic

**What**: The original procedure implemented an upsert pattern for billing accounts.

**Columns/Parameters Involved**: `@CID`, `@CurrencyID`

**Rules** (from commented code - historical reference only):
- Guard: Only process real customers (`Customer.Customer.IsReal = 1`).
- If no account exists for (CID, CurrencyID): INSERT into `Billing.Account` with AccountBalance=0, return new AccountID via SCOPE_IDENTITY().
- If account already exists: return existing AccountID via SELECT.
- If customer is not real (demo): no action, no return value.

**Diagram**:
```
[Commented-out logic - inactive]
Customer.IsReal = 1?
  YES:
    Billing.Account exists for (CID, CurrencyID)?
      NO  -> INSERT Billing.Account (CID, CurrencyID, Balance=0)
             -> RETURN SCOPE_IDENTITY() (new AccountID)
      YES -> SELECT AccountID FROM Billing.Account
             -> RETURN existing AccountID
  NO: (no action)

[Active logic]
RETURN 0  (always, unconditionally)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer identifier. In the original (commented-out) logic: used to look up customer real-status and scope the account lookup/insert. Currently not used as all logic is commented out. |
| 2 | @CurrencyID | INTEGER | NO | - | CODE-BACKED | Currency identifier for the billing account. In the original logic: defined the currency denomination of the account to be created. Currently not used. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID (commented) | Customer.Customer | Lookup (inactive) | Was used to verify IsReal=1; all code commented out |
| @CID, @CurrencyID (commented) | Billing.Account | Writer (inactive) | Was used to INSERT new account record; all code commented out |

### 5.2 Referenced By (other objects point to this)

No active callers found. The procedure exists in the codebase and has permissions granted, but is not called by any stored procedure.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.AccountAdd (procedure)
(no active dependencies - all code commented out)
```

### 6.1 Objects This Depends On

No active dependencies. The commented-out code referenced `Customer.Customer` and `Billing.Account`.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. SET NOCOUNT ON. RETURN 0 always.

---

## 8. Sample Queries

### 8.1 Verify procedure is a no-op (stub check)

```sql
-- This call returns 0 and does nothing
EXEC Billing.AccountAdd @CID = 12345, @CurrencyID = 1
```

### 8.2 Check what the procedure would have created (using commented-out intent)

```sql
-- Find customers without a USD billing account (what AccountAdd would have inserted)
SELECT c.CID
FROM Customer.CustomerStatic WITH (NOLOCK) AS c
WHERE c.IsReal = 1
  AND NOT EXISTS (
    SELECT 1 FROM Billing.Account WITH (NOLOCK) AS a
    WHERE a.CID = c.CID AND a.CurrencyID = 1
  )
```

### 8.3 View existing billing accounts (what AccountAdd managed)

```sql
SELECT
    a.AccountID,
    a.CID,
    a.CurrencyID,
    a.AccountBalance
FROM Billing.Account WITH (NOLOCK) AS a
WHERE a.CID = 12345
ORDER BY a.CurrencyID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 9/10, Logic: 7/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.AccountAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.AccountAdd.sql*
