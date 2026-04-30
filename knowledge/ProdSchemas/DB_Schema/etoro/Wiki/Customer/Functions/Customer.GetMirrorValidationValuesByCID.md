# Customer.GetMirrorValidationValuesByCID

> Copy-trading validation data by CID: returns a customer's equity breakdown (cash + open positions + mirrors), active mirror count, and pending order totals needed to validate whether a customer can open or maintain a copy relationship.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Inline TVF |
| **Key Identifier** | @CID int (returns 0 or 1 rows) |
| **Partition** | N/A |
| **Indexes** | N/A (function) |

---

## 1. Business Meaning

Customer.GetMirrorValidationValuesByCID returns the set of financial values needed to validate a customer's eligibility to participate in copy trading (Mirrors). Created by Geri Reshef in May 2015 (case 25795), the function provides six values that the mirror validation logic uses: GCID, Credit, NumberOfActiveMirrors, RealizedEquity (computed as cash + open positions value + mirror allocation), Orders, and OrdersEntry.

The function differs significantly from Customer.GetFinancialDataByCID and Customer.GetCurrentFinancialDataByCID in how it computes RealizedEquity. Here it is explicitly calculated as: `Credit + SumOpenPositions (Trade.Position) + SumAvailableCash (Trade.Mirror)`. This is a mirror-aware equity calculation - it includes the value allocated to copy-trading relationships.

Orders and OrdersEntry represent pending/queued order amounts that should be factored into the customer's available balance check - they represent capital that is committed but not yet deployed.

---

## 2. Business Logic

### 2.1 Mirror-Aware RealizedEquity Computation

**What**: RealizedEquity here is computed bottom-up from individual position and mirror values, not read from a stored column.

**Columns/Parameters Involved**: `RealizedEquity`, `Credit`

**Rules**:
- `RealizedEquity = ISNULL(Credit, 0) + SumOpenPositions + SumAvailableCash`
- `SumOpenPositions = ISNULL(SUM(Amount), 0) FROM Trade.Position WHERE CID=@CID` - total value of open direct positions
- `SumAvailableCash = ISNULL(SUM(Amount), 0) FROM Trade.Mirror WHERE CID=@CID` - total capital allocated to mirror/copy relationships
- This is NOT the same RealizedEquity as stored in CustomerMoney - this is a real-time calculation from live position data

**Diagram**:
```
RealizedEquity = Credit (cash)
               + SUM(Trade.Position.Amount WHERE CID=@CID)   [open trade value]
               + SUM(Trade.Mirror.Amount WHERE CID=@CID)     [mirror allocation]
```

### 2.2 Pending Order Amounts

**What**: Orders and OrdersEntry capture pending/queued orders that represent committed but unconfirmed capital.

**Columns/Parameters Involved**: `Orders`, `OrdersEntry`

**Rules**:
- `Orders = ISNULL(SUM(Amount), 0) FROM Trade.Orders WHERE CID=@CID` - pending orders
- `OrdersEntry = ISNULL(SUM(Amount), 0) FROM Trade.OrdersEntry WHERE CID=@CID` - order entries (sub-orders or legs)
- Both use SUM(Amount) - total dollar value of all pending orders/entries for this customer
- These values are used alongside RealizedEquity to determine net available balance

---

## 3. Data Overview

N/A for Inline TVF.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | VERIFIED | Customer ID for mirror validation. Returns 0 rows if not found, 1 row when found. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | YES | - | VERIFIED | Group Customer ID. From Customer.Customer (CustomerStatic). |
| 2 | Credit | money | YES | - | VERIFIED | Current liquid cash balance (USD). From Customer.Customer (CustomerMoney). |
| 3 | NumberOfActiveMirrors | int | NO | - | CODE-BACKED | Count of active copy relationships: COUNT(*) from Trade.Mirror WHERE CID=@CID AND IsActive=1. 0 = no active mirrors. |
| 4 | RealizedEquity | money | NO | - | CODE-BACKED | Computed total equity: ISNULL(Credit,0) + SUM(Trade.Position.Amount WHERE CID=@CID) + SUM(Trade.Mirror.Amount WHERE CID=@CID). This is a REAL-TIME calculation from live position/mirror data, NOT read from CustomerMoney.RealizedEquity. ISNULL(...,0) ensures NULL positions/mirrors return 0 rather than NULL. |
| 5 | Orders | money | NO | - | CODE-BACKED | Total amount of pending orders: ISNULL(SUM(Amount),0) from Trade.Orders WHERE CID=@CID. Represents committed capital in queued orders not yet opened. |
| 6 | OrdersEntry | money | NO | - | CODE-BACKED | Total amount of pending order entries: ISNULL(SUM(Amount),0) from Trade.OrdersEntry WHERE CID=@CID. Sub-order or order leg values pending execution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID, Credit | Customer.Customer | FROM (CCST alias) WHERE CID=@CID | Customer identity and cash balance |
| NumberOfActiveMirrors | Trade.Mirror | Correlated subquery (COUNT IsActive=1) | Active copy relationship count |
| RealizedEquity (positions component) | Trade.Position | Correlated subquery (SUM Amount) | Open direct position values |
| RealizedEquity (mirror component) | Trade.Mirror | Correlated subquery (SUM Amount) | Allocated mirror capital |
| Orders | Trade.Orders | Correlated subquery (SUM Amount) | Pending order totals |
| OrdersEntry | Trade.OrdersEntry | Correlated subquery (SUM Amount) | Pending order entry totals |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. See companion Customer.GetMirrorValidationValuesByGCID (GCID-keyed) and Customer.GetMirrorValidationValuesByUserNameAndPassword (credential-keyed).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetMirrorValidationValuesByCID (function)
|-  Customer.Customer (view)
|     |-  Customer.CustomerStatic (table)
|     `-  Customer.CustomerMoney (table)
|-  Trade.Mirror (table) [cross-schema, x2: IsActive count + Amount sum]
|-  Trade.Position (table) [cross-schema, Amount sum]
|-  Trade.Orders (table) [cross-schema, Amount sum]
`-  Trade.OrdersEntry (table) [cross-schema, Amount sum]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM (CCST alias) WHERE CID=@CID - GCID, Credit |
| Trade.Mirror | Table (cross-schema) | Correlated subqueries: COUNT(*) IsActive=1 (mirrors) + SUM(Amount) (equity component) |
| Trade.Position | Table (cross-schema) | Correlated subquery SUM(Amount) WHERE CID=@CID - open position values |
| Trade.Orders | Table (cross-schema) | Correlated subquery SUM(Amount) WHERE CID=@CID - pending order amounts |
| Trade.OrdersEntry | Table (cross-schema) | Correlated subquery SUM(Amount) WHERE CID=@CID - pending order entry amounts |

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
| ISNULL(..., 0) on all subqueries | NULL protection | Prevents NULL propagation when customer has no positions/mirrors/orders |
| No WITH (NOLOCK) on subqueries | Locking note | Trade.Mirror, Trade.Position, Trade.Orders subqueries do NOT use NOLOCK (unlike companion functions) - may block under high write load |

---

## 8. Sample Queries

### 8.1 Validate a customer's copy-trading eligibility

```sql
SELECT GCID, Credit, NumberOfActiveMirrors, RealizedEquity, Orders, OrdersEntry
FROM Customer.GetMirrorValidationValuesByCID(12345) WITH (NOLOCK);
```

### 8.2 Check available balance for a new mirror (subtract committed amounts)

```sql
SELECT
    Credit,
    RealizedEquity,
    Orders + OrdersEntry AS CommittedAmounts,
    RealizedEquity - (Orders + OrdersEntry) AS NetAvailableForCopying
FROM Customer.GetMirrorValidationValuesByCID(12345) WITH (NOLOCK);
```

### 8.3 Find active mirror copiers with significant allocated capital

```sql
SELECT
    c.UserName,
    mv.NumberOfActiveMirrors,
    mv.RealizedEquity,
    mv.Credit
FROM Customer.Customer c WITH (NOLOCK)
CROSS APPLY Customer.GetMirrorValidationValuesByCID(c.CID) mv
WHERE mv.NumberOfActiveMirrors > 0
  AND mv.RealizedEquity > 5000
  AND c.IsReal = 1
ORDER BY mv.RealizedEquity DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (function) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetMirrorValidationValuesByCID | Type: Inline TVF | Source: etoro/etoro/Customer/Functions/Customer.GetMirrorValidationValuesByCID.sql*
