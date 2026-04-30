# Trade.GetTotalCash_View

> Thin wrapper exposing Customer ID and Total Cash (available cash balance) from Customer.Customer for reporting and balance lookups.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetTotalCash_View is a simple pass-through view that exposes each customer's TotalCash (available cash balance) alongside their CID. It selects from Customer.Customer, which in turn joins Customer.CustomerStatic with Customer.CustomerMoney - TotalCash ultimately comes from Customer.CustomerMoney.

This view exists to provide a Trade-schema entry point for total-cash lookups. The synonym dbo.RealGetTotalCash points to this view, allowing callers to query cash balances without referencing Customer schema directly. TotalCash represents the customer's available cash (excluding unrealized P&L, bonus credits, etc.) - used for margin checks, withdrawal eligibility, and balance displays.

A commented-out alternative in the DDL would have used Trade.GetTotalCash(CID) - a scalar function - but the current implementation reads TotalCash directly from Customer.Customer for performance.

---

## 2. Business Logic

### 2.1 Total Cash Source

**What**: TotalCash is the customer's available cash balance, stored in Customer.CustomerMoney and exposed via Customer.Customer.

**Columns/Parameters Involved**: `CID`, `TotalCash`

**Rules**:
- One row per CID - Customer.Customer has one row per customer (CustomerStatic LEFT JOIN CustomerMoney)
- TotalCash type is dtPrice (custom type, typically decimal/money). Sample data shows integer values (0, 10000)
- NULL possible if CustomerMoney row missing (LEFT JOIN) - sample data showed no NULLs
- Updated by Customer.SetBalance, Customer.SetBalanceDeposit, Customer.SetBalanceCashOut, and related balance procedures

**Diagram**:
```
Customer.Customer (view)
  C1 = Customer.CustomerStatic
  C2 = Customer.CustomerMoney (LEFT JOIN)
  TotalCash = C2.TotalCash

Trade.GetTotalCash_View
  SELECT CID, TotalCash FROM Customer.Customer
```

---

## 3. Data Overview

| CID | TotalCash | Meaning |
|-----|-----------|---------|
| 3458634 | 10000 | Customer with 10,000 (USD?) available cash |
| 3458901 | 10000 | Same balance tier |
| 3459061 | 0 | Zero balance - possibly new or withdrawn |
| 3461799 | 10000 | Standard balance |
| 3461988 | 10000 | Standard balance |

**Selection criteria**: TOP 5 from view. Values suggest demo or test data (round 10,000 amounts). TotalCash of 0 indicates no available cash.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID. FK to Customer.CustomerStatic (via Customer.Customer). Primary identifier for the row. |
| 2 | TotalCash | dtPrice | YES | - | CODE-BACKED | Available cash balance. Source: Customer.CustomerMoney.TotalCash via Customer.Customer. Updated by balance procedures (SetBalance, SetBalanceDeposit, SetBalanceCashOut, etc.). Used for margin, withdrawals, and UI balance display. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | FROM | View reads from Customer.Customer |
| TotalCash | Customer.CustomerMoney | Via Customer.Customer | TotalCash originates from CustomerMoney.TotalCash |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.RealGetTotalCash | Synonym | Points to this view | Allows dbo schema callers to access view |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetTotalCash_View (view)
└── Customer.Customer (view)
      ├── Customer.CustomerStatic (table)
      └── Customer.CustomerMoney (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM - provides CID and TotalCash |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.RealGetTotalCash | Synonym | FOR Trade.GetTotalCash_View |

---

## 7. Technical Details

### 7.1 DDL Summary

- Single SELECT: `SELECT CID, TotalCash AS TotalCash FROM Customer.Customer WITH (NOLOCK)`
- Uses NOLOCK hint on base view (Customer.Customer passes through to its base tables)
- No SCHEMABINDING - view can be altered if Customer.Customer changes
- Commented alternative: `SELECT CID, [Trade].[GetTotalCash](CID) AS TotalCash FROM Customer.Customer` - not used

### 7.2 Column Mapping

| Output Column | Source |
|--------------|--------|
| CID | Customer.Customer.CID |
| TotalCash | Customer.Customer.TotalCash (from Customer.CustomerMoney.TotalCash) |

---

## 8. Sample Queries

### 8.1 Get total cash for a customer

```sql
SELECT CID,
       TotalCash
  FROM Trade.GetTotalCash_View WITH (NOLOCK)
 WHERE CID = 3458634
```

### 8.2 List customers with zero balance

```sql
SELECT CID,
       TotalCash
  FROM Trade.GetTotalCash_View WITH (NOLOCK)
 WHERE TotalCash = 0
 ORDER BY CID
```

### 8.3 Top customers by cash balance (via synonym)

```sql
SELECT TOP 20 CID,
             TotalCash
  FROM dbo.RealGetTotalCash WITH (NOLOCK)
 ORDER BY TotalCash DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 2/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetTotalCash_View | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetTotalCash_View.sql*
