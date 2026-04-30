# Customer.GetFinancialDataByCID

> Minimal financial data accessor: returns a single customer's current cash balance and realized equity by CID - the simplest financial read function in the Customer schema.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Inline TVF |
| **Key Identifier** | @CID int (returns 0 or 1 rows) |
| **Partition** | N/A |
| **Indexes** | N/A (function) |

---

## 1. Business Meaning

Customer.GetFinancialDataByCID is the minimal financial data reader for a single customer. It returns exactly two financial values: Credit (current cash balance) and RealizedEquity (settled P&L + cash). It is the simplest of the financial data functions in this schema, providing basic balance information without unrealized P&L, active mirror counts, or GCID lookup.

The function exists as a lightweight alternative to Customer.GetCurrentFinancialDataByCID for callers that only need the two core balance values and want to avoid the overhead of mirror count subqueries and cross-schema BackOffice calls. It is suitable for high-frequency operations that need a quick balance check.

---

## 2. Business Logic

### 2.1 Credit vs RealizedEquity

**What**: Two complementary views of a customer's account value.

**Columns/Parameters Involved**: `Credit`, `RealizedEquity`

**Rules**:
- `Credit`: liquid cash balance available for trading - value in the account that has not been deployed into open positions
- `RealizedEquity`: cumulative settled profit/loss including current cash - the total value after all closed trades
- Both come from Customer.CustomerMoney (via Customer.Customer view)
- Neither includes floating P&L on currently open positions (that requires GetCurrentFinancialDataByCID which adds BackOffice.GetUnrealizedPnL)

---

## 3. Data Overview

N/A for Inline TVF.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | VERIFIED | Customer ID to look up. Returns 0 rows if not found. Returns 1 row when found. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Credit | money | YES | - | VERIFIED | Current liquid cash balance (USD). From Customer.Customer (CustomerMoney). This is the available funds not currently invested in open positions. |
| 2 | RealizedEquity | money | YES | - | VERIFIED | Cumulative realized profit/loss plus current cash (USD). From Customer.Customer (CustomerMoney). Includes settled closed-position gains/losses. Excludes open position floating P&L. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Credit, RealizedEquity | Customer.Customer | FROM (CCST alias) WHERE CID=@CID | Core financial values from CustomerMoney |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Simpler alternative to Customer.GetCurrentFinancialDataByCID.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetFinancialDataByCID (function)
`-  Customer.Customer (view)
      |-  Customer.CustomerStatic (table)
      `-  Customer.CustomerMoney (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM (CCST alias) WHERE CID=@CID - Credit, RealizedEquity |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WHERE CCST.CID = @CID | Row filter | Returns at most 1 row |

---

## 8. Sample Queries

### 8.1 Quick balance check for a customer

```sql
SELECT Credit, RealizedEquity
FROM Customer.GetFinancialDataByCID(12345) WITH (NOLOCK);
```

### 8.2 Balance check in a JOIN context

```sql
SELECT c.UserName, fd.Credit, fd.RealizedEquity
FROM Customer.Customer c WITH (NOLOCK)
CROSS APPLY Customer.GetFinancialDataByCID(c.CID) fd
WHERE c.IsReal = 1
  AND fd.Credit > 10000;
```

### 8.3 Compare Credit vs RealizedEquity to estimate unrealized P&L range

```sql
SELECT
    Credit,
    RealizedEquity,
    RealizedEquity - Credit AS ApproxClosedPositionPnL
FROM Customer.GetFinancialDataByCID(12345) WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 10/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (function) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetFinancialDataByCID | Type: Inline TVF | Source: etoro/etoro/Customer/Functions/Customer.GetFinancialDataByCID.sql*
