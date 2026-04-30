# Billing.GetAccount

> Legacy stub procedure - the original SELECT logic is fully commented out; the procedure now only returns 0 without executing any query.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 0 (RETURN 0 only - no data) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetAccount` is a decommissioned stub. Its original purpose was to retrieve a customer's `Billing.Account` record by CID and CurrencyID. That logic is now commented out (visible in the DDL as a `/* SELECT * FROM Billing.Account WITH (NOLOCK) WHERE CID=@CID AND CurrencyID=@CurrencyID */` comment). The procedure now does nothing except return 0.

The procedure still exists in the codebase because removing it would break any application or caller that references it by name - even if it never reads data from it. The stub keeps the interface alive while the underlying functionality is either deprecated or has been replaced by a different data access pattern.

The batch plan notes this as "stub - no active deps", confirming that no other SQL objects in the schema depend on it.

---

## 2. Business Logic

### 2.1 Decommissioned State

**What**: The procedure is a no-op stub.

**Rules**:
- Current behavior: SET NOCOUNT ON, then RETURN 0. No SELECT, no data returned.
- Original intent (commented out): SELECT * FROM Billing.Account WHERE CID=@CID AND CurrencyID=@CurrencyID.
- Callers that expect a result set receive an empty result - they must handle empty results gracefully.
- The Billing.Account table reference suggests this was part of the old customer account balance architecture, predating Customer.CustomerMoney as the balance source.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Parameter accepted but not used in any active logic (original SELECT is commented out). |
| 2 | @CurrencyID | INTEGER | NO | - | CODE-BACKED | Currency ID. Parameter accepted but not used in any active logic. Original intent: filter Billing.Account by currency. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no active outgoing references (the only reference - Billing.Account - is commented out).

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies (all code is commented out).

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Unknown legacy callers | External | May call for Billing.Account data - currently receives empty result set |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Uses SET NOCOUNT ON. RETURN 0. Commented-out SELECT on Billing.Account table. No DML, no transactions.

---

## 8. Sample Queries

### 8.1 Call the stub (returns empty result + 0 return code)

```sql
EXEC [Billing].[GetAccount]
    @CID = 12345,
    @CurrencyID = 4;  -- e.g., 4=USD
-- Returns: empty result set, return code 0
```

### 8.2 If the original intent was needed - query Billing.Account directly

```sql
-- Original commented-out query (for reference only):
SELECT *
FROM [Billing].[Account] WITH (NOLOCK)
WHERE CID = 12345
  AND CurrencyID = 4;
```

### 8.3 Alternative: current balance source (Customer.CustomerMoney)

```sql
SELECT CID, Credit AS Balance, BonusCredit, RealizedEquity
FROM [Customer].[CustomerMoney] WITH (NOLOCK)
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetAccount | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetAccount.sql*
