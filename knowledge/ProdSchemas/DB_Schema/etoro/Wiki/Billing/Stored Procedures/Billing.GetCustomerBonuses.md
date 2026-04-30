# Billing.GetCustomerBonuses

> Deprecated stub procedure - the original bonus history query across Billing.Account, History.Account, History.AccountToBonus, and BackOffice.BonusType is fully commented out, leaving only RETURN 0.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID input - accepted but not used |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetCustomerBonuses` is a deprecated stub procedure. It accepts a customer ID but performs no work - the entire query body is commented out with `/* ... */`. The only executable statement is `RETURN 0`.

The commented-out query joined four tables to retrieve a customer's bonus history: `Billing.Account`, `History.Account`, `History.AccountToBonus`, and `BackOffice.BonusType`. All of these tables (except BackOffice.BonusType) no longer exist in the SSDT project, confirming the procedure was decommissioned when the old Account-based data model was replaced.

This is one of a family of legacy stubs (alongside `GetCustomerAccounts`, `GetCustomerCompensations` was rewritten) that were deactivated when the billing account model was restructured. Granted to PROD_BIadmins and BILLING_MANAGER - retained for backward compatibility.

---

## 2. Business Logic

### 2.1 Stub Pattern (Deprecated)

**What**: Accepted @CID but performed no operation. Original logic retrieved bonus history from the old account model.

**Rules**:
- Body is a single `RETURN 0` - no SELECT, no data returned.
- Commented code would have returned: AccountID, AccountBalance, CurrencyID, BonusTypeID, PreviousAccountBalance, NewAccountBalance, Amount, UpdateDate.
- Referenced tables `Billing.Account`, `History.Account`, `History.AccountToBonus` no longer exist in SSDT.
- For current bonus history, use `Billing.GetCreditsHistoryByDate` (CreditTypeID=7) instead.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Accepted as parameter but not used - procedure body is a stub returning RETURN 0. |

**Returns**: No result set (empty - zero columns and zero rows).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (commented) | Billing.Account | Commented-out reference | Original query source - table no longer exists in SSDT |
| (commented) | History.Account | Commented-out reference | Original query source - table no longer exists in SSDT |
| (commented) | History.AccountToBonus | Commented-out reference | Original join table - no longer exists in SSDT |
| (commented) | BackOffice.BonusType | Commented-out reference | Bonus type lookup - still exists |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | EXECUTE grant | Permission | BI admin access - retained for backward compatibility |
| BILLING_MANAGER | EXECUTE grant | Permission | Billing manager access - retained for backward compatibility |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCustomerBonuses (procedure)
(no active dependencies - stub with commented-out body)
```

---

### 6.1 Objects This Depends On

No active dependencies. Original dependencies (Billing.Account, History.Account, History.AccountToBonus) no longer exist.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Confirm stub behavior

```sql
-- Returns no rows, return code 0
EXEC [Billing].[GetCustomerBonuses] @CID = 1234567
```

### 8.2 Current replacement for bonus history

```sql
-- Use GetCreditsHistoryByDate for current bonus history (CreditTypeID=7)
EXEC [Billing].[GetCreditsHistoryByDate]
    @CID = 1234567,
    @FromDate = '2020-01-01',
    @CreditID = NULL
-- Filter results to CreditTypeID=7 (Bonus) from the result set
```

### 8.3 Check which Account-model tables are gone

```sql
-- Confirm the referenced tables no longer exist
SELECT
    OBJECT_ID('Billing.Account', 'U') AS BillingAccount,
    OBJECT_ID('History.Account', 'U') AS HistoryAccount,
    OBJECT_ID('History.AccountToBonus', 'U') AS HistoryAccountToBonus
-- Expected: all NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.2/10 (Elements: 10/10, Logic: 6/10, Relationships: 5/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 run; 9B skipped; 11 complete)*
*Sources: Atlassian: 0 Confluence + 0 Jira | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Billing.GetCustomerBonuses | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCustomerBonuses.sql*
