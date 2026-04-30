# Customer.GetCurrentFinancialDataByCID

> Real-time financial snapshot by CID: returns a single customer's current account balance, active mirror count, realized equity, and total equity including unrealized P&L.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Inline TVF |
| **Key Identifier** | @CID int (returns 0 or 1 rows) |
| **Partition** | N/A |
| **Indexes** | N/A (function) |

---

## 1. Business Meaning

Customer.GetCurrentFinancialDataByCID returns a real-time financial summary for a single customer identified by CID. It is the CID-keyed version of the financial data accessor - a companion to Customer.GetCurrentFinancialDataByGCID which does the same by GCID.

The function returns five values: GCID, current cash balance (Credit), active copy relationships (NumberOfActiveMirrors), cumulative realized profits/losses (RealizedEquity), and total equity including the unrealized P&L on all open positions (UnRealizedEquity). Together these five values give a complete picture of a customer's current financial standing.

The function is used by account services, risk management, and trading validation workflows that need to verify a customer has sufficient funds or check their overall equity position before allowing operations like deposits, withdrawals, or opening new trades.

---

## 2. Business Logic

### 2.1 Equity Calculation: Realized vs Unrealized

**What**: The distinction between RealizedEquity and UnRealizedEquity determines whether floating P&L on open positions is included.

**Columns/Parameters Involved**: `RealizedEquity`, `UnRealizedEquity`

**Rules**:
- `RealizedEquity`: stored on Customer.CustomerMoney - the sum of all settled, closed-position profits and current cash balance. Does NOT include open position floating P&L.
- `UnRealizedEquity = RealizedEquity + BackOffice.GetUnrealizedPnL(@CID) / 100`: adds the current floating P&L on all open positions. The /100 converts from cents to dollars (BackOffice.GetUnrealizedPnL returns cents).
- `UnRealizedEquity` is the total account equity at current market prices - the value you would receive if you closed all positions right now.

**Diagram**:
```
UnRealizedEquity = RealizedEquity + UnrealizedPnL
                 = Cash + ClosedPositionPnL + OpenPositionFloatingPnL
```

### 2.2 Active Mirror Count

**What**: NumberOfActiveMirrors counts how many copy-trading relationships (mirrors) the customer currently has open.

**Columns/Parameters Involved**: `NumberOfActiveMirrors`

**Rules**:
- Correlated subquery: `SELECT COUNT(*) FROM Trade.Mirror WHERE CID = @CID AND IsActive = 1`
- IsActive=1: the copy relationship is currently live (auto-copying trades from a leader)
- 0 = customer has no active copy positions; N = customer is currently copying N leaders
- Does NOT count historical (closed) mirrors

---

## 3. Data Overview

N/A for Inline TVF.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | VERIFIED | Customer ID to look up. Returns 0 rows if CID not found in Customer.Customer. Returns exactly 1 row when found. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | YES | - | VERIFIED | Group Customer ID - cross-product identity key. From Customer.Customer (CustomerStatic). Returned so callers have both CID and GCID available without a second query. |
| 2 | Credit | money | YES | - | VERIFIED | Current cash balance in the account (USD). From Customer.Customer (CustomerMoney). Does not include value of open positions - just the liquid cash available. |
| 3 | NumberOfActiveMirrors | int | NO | - | CODE-BACKED | Count of currently active copy-trading relationships: COUNT(*) from Trade.Mirror WHERE CID=@CID AND IsActive=1. 0 means customer is not currently copying any leader. |
| 4 | RealizedEquity | money | YES | - | VERIFIED | Cumulative realized profit/loss plus current cash balance. From Customer.Customer (CustomerMoney). Reflects settled gains/losses from closed positions. Does NOT include floating P&L on currently open positions. |
| 5 | UnRealizedEquity | money | YES | - | CODE-BACKED | Total account equity including open position floating P&L: RealizedEquity + (BackOffice.GetUnrealizedPnL(@CID) / 100). The /100 converts cents to dollars. NULL if RealizedEquity is NULL. This is the "mark-to-market" account value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID, Credit, RealizedEquity | Customer.Customer | FROM (CCST alias) WHERE CID=@CID | Customer profile and financial state |
| NumberOfActiveMirrors | Trade.Mirror | Correlated subquery (COUNT WHERE IsActive=1) | Active copy-trading count |
| UnRealizedEquity (component) | BackOffice.GetUnrealizedPnL | Scalar function call with @CID | Floating P&L on open positions in cents |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCurrentFinancialDataByCID (function)
|-  Customer.Customer (view)
|     |-  Customer.CustomerStatic (table)
|     `-  Customer.CustomerMoney (table)
|-  Trade.Mirror (table) [cross-schema, correlated subquery]
`-  BackOffice.GetUnrealizedPnL (function) [cross-schema, scalar call with @CID]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM (CCST alias) WHERE CID=@CID - GCID, Credit, RealizedEquity |
| Trade.Mirror | Table (cross-schema) | Correlated subquery COUNT(*) WHERE CID=@CID AND IsActive=1 |
| BackOffice.GetUnrealizedPnL | Scalar Function (cross-schema) | Called with @CID; returns unrealized P&L in cents |

### 6.2 Objects That Depend On This

Not analyzed in this phase. See companion function Customer.GetCurrentFinancialDataByGCID for the GCID-keyed equivalent.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WHERE CCST.CID = @CID | Row filter | Returns at most 1 row per call |
| IsActive = 1 | Subquery filter | Only live copy relationships counted |
| / cast(100 as money) | Unit conversion | BackOffice.GetUnrealizedPnL returns cents; dividing by 100 converts to dollars |

---

## 8. Sample Queries

### 8.1 Current financial state for a specific customer

```sql
SELECT GCID, Credit, NumberOfActiveMirrors, RealizedEquity, UnRealizedEquity
FROM Customer.GetCurrentFinancialDataByCID(12345) WITH (NOLOCK);
```

### 8.2 Check if customer has sufficient equity to allow withdrawal

```sql
DECLARE @WithdrawalAmount money = 500.00;
SELECT
    CID = 12345,
    UnRealizedEquity,
    CASE WHEN UnRealizedEquity >= @WithdrawalAmount THEN 'Allow' ELSE 'Block' END AS WithdrawalStatus
FROM Customer.GetCurrentFinancialDataByCID(12345) WITH (NOLOCK);
```

### 8.3 Bulk equity check for multiple customers (join pattern)

```sql
SELECT
    c.UserName,
    fd.Credit,
    fd.NumberOfActiveMirrors,
    fd.RealizedEquity,
    fd.UnRealizedEquity
FROM Customer.Customer c WITH (NOLOCK)
CROSS APPLY Customer.GetCurrentFinancialDataByCID(c.CID) fd
WHERE c.IsReal = 1
  AND c.PlayerLevelID = 4; -- Popular Investors only
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (function) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetCurrentFinancialDataByCID | Type: Inline TVF | Source: etoro/etoro/Customer/Functions/Customer.GetCurrentFinancialDataByCID.sql*
