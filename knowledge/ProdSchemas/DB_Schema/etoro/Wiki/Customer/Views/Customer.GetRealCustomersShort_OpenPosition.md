# Customer.GetRealCustomersShort_OpenPosition

> Funded customer view showing current open position count, lifetime P&L, and account balance - filtered to customers who have received at least one deposit, compensation, or bonus.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | View |
| **Key Identifier** | GCID |
| **Partition** | N/A |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Customer.GetRealCustomersShort_OpenPosition returns a trading activity snapshot for every "funded" customer - those who have received at least one deposit, compensation payment, or bonus. It shows three key trading metrics per customer: how many positions they currently have open (NumOpenPosition), their lifetime realized P&L (PLReal), and their current account balance (BalanceReal).

The "funded" filter (BackOffice.CustomerAllTimeAggregatedData WHERE TotalDeposit>0 OR TotalCompensation>0 OR TotalBonus>0) ensures only customers who have meaningfully interacted with real money appear in results. This distinguishes it from views that show all customers including zero-activity accounts.

The view is used by email marketing to segment campaigns around trading activity: "customers with open positions", "customers with positive P&L", "funded customers who haven't yet opened a position" (NumOpenPosition=0), etc.

---

## 2. Business Logic

### 2.1 Funded Customer Filter

**What**: Only customers with financial activity (deposits, compensation, or bonus) are returned.

**Columns/Parameters Involved**: Implicit filter (not a visible column)

**Rules**:
- `BOCA.TotalDeposit > 0`: customer has made at least one deposit
- `OR BOCA.TotalCompensation > 0`: customer received compensation (e.g., data fix, dispute resolution)
- `OR BOCA.TotalBonus > 0`: customer received a promotional bonus
- BOCA and BOCD are both aliases of BackOffice.CustomerAllTimeAggregatedData - BOCA is the filter source, BOCD provides TotalProfit for PLReal
- Note: self-join to same table (BOCD for reading, BOCA for filtering) is functionally the same as a single JOIN since they join on the same CID

### 2.2 Open Position Count via CTE

**What**: NumOpenPosition counts LIVE (currently open) positions from Trade.Position, not historical positions.

**Columns/Parameters Involved**: `NumOpenPosition`

**Rules**:
- OpenPosition CTE: `COUNT(TP.CID)` from Trade.Position (live open positions only - not History.Position)
- LEFT JOIN allows 0 for customers with no open positions
- Grouped by GCID and CCST.CID in the CTE, then outer query joins CTE on GCID
- 0 = customer has no currently open positions; N = number of currently open positions

---

## 3. Data Overview

| GCID | CID | DemoCID | NumOpenPosition | PLReal | BalanceReal | Meaning |
|------|-----|---------|-----------------|--------|-------------|---------|
| 13599110 | 0 | 0 | 0 | 0.00 | 200.00 | Funded customer (deposited) but no open positions - test/early account with $200 balance. |
| 14499978 | 0 | 0 | 0 | 0.00 | 25736.90 | Funded customer with substantial balance ($25,736) but no open positions in this environment. |
| 15675360 | 0 | 0 | 0 | 0.00 | 123.11 | Small funded customer with no open positions. PLReal=0 in this test environment. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | YES | - | VERIFIED | Group Customer ID - cross-product identity key. From Customer.Customer (CustomerStatic). Primary identifier for marketing integration. |
| 2 | CID | int | NO | - | CODE-BACKED | Computed: CASE WHEN GCID <> 0 THEN 0 ELSE CID END. Returns actual CID only for pre-GCID accounts; 0 for modern accounts. |
| 3 | DemoCID | int | NO | - | CODE-BACKED | Always 0 (hardcoded). Schema contract field for GetRealCustomersShort_* family. |
| 4 | NumOpenPosition | int | NO | - | CODE-BACKED | Count of currently open trade positions. Sourced from Trade.Position (live positions only, not History.Position). 0 for funded customers who have not currently opened any positions. |
| 5 | PLReal | decimal(25,2) | YES | - | CODE-BACKED | Lifetime realized profit/loss in USD. CONVERT(decimal(25,2), BOCD.TotalProfit) from BackOffice.CustomerAllTimeAggregatedData. NULL if no BackOffice record. Positive=overall profitable, negative=overall loss. |
| 6 | BalanceReal | decimal(25,2) | YES | - | VERIFIED | Current account balance in USD. CONVERT(decimal(25,2), Credit) from Customer.Customer (CustomerMoney). NULL if no CustomerMoney row. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID, CID, BalanceReal | Customer.Customer | FROM (base view) | Customer identity and balance |
| NumOpenPosition | Trade.Position | LEFT JOIN (CTE: OpenPositions) | Live open position count |
| PLReal | BackOffice.CustomerAllTimeAggregatedData | LEFT JOIN (BOCD alias) | Lifetime profit/loss |
| (filter) | BackOffice.CustomerAllTimeAggregatedData | LEFT JOIN (BOCA alias) | Funded-customer filter (TotalDeposit/Compensation/Bonus) |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views reference this view in the SSDT repository. Terminal export view for email marketing.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRealCustomersShort_OpenPosition (view)
├── Customer.Customer (view)
│     ├── Customer.CustomerStatic (table)
│     └── Customer.CustomerMoney (table)
├── Trade.Position (table) [cross-schema, CTE: OpenPosition]
└── BackOffice.CustomerAllTimeAggregatedData (table) [cross-schema, x2 aliases]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM (base view) - identity and Credit/BalanceReal |
| Trade.Position | Table (cross-schema) | LEFT JOIN in CTE - COUNT of open positions per customer |
| BackOffice.CustomerAllTimeAggregatedData | Table (cross-schema) | LEFT JOIN x2: BOCD for PLReal, BOCA for funded filter |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WHERE BOCA.TotalDeposit>0 OR BOCA.TotalCompensation>0 OR BOCA.TotalBonus>0 | Data filter | Only funded customers returned; customers with no financial history excluded |
| Self-join on BackOffice.CustomerAllTimeAggregatedData | Design note | BOCD and BOCA are both JOINed to same table on same CID - could be simplified to a single JOIN |

---

## 8. Sample Queries

### 8.1 Funded customers with open positions
```sql
SELECT
    GCID,
    NumOpenPosition,
    PLReal,
    BalanceReal
FROM Customer.GetRealCustomersShort_OpenPosition WITH (NOLOCK)
WHERE NumOpenPosition > 0
ORDER BY NumOpenPosition DESC;
```

### 8.2 Funded customers who have deposited but have no open positions
```sql
SELECT
    GCID,
    NumOpenPosition,
    BalanceReal
FROM Customer.GetRealCustomersShort_OpenPosition WITH (NOLOCK)
WHERE NumOpenPosition = 0
  AND BalanceReal > 0
ORDER BY BalanceReal DESC;
```

### 8.3 Full profile of most profitable funded customers
```sql
SELECT
    op.GCID,
    c.UserName,
    c.Email,
    op.NumOpenPosition,
    op.PLReal,
    op.BalanceReal
FROM Customer.GetRealCustomersShort_OpenPosition op WITH (NOLOCK)
JOIN Customer.Customer c WITH (NOLOCK) ON c.GCID = op.GCID
WHERE op.PLReal > 1000
ORDER BY op.PLReal DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 10/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (view) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetRealCustomersShort_OpenPosition | Type: View | Source: etoro/etoro/Customer/Views/Customer.GetRealCustomersShort_OpenPosition.sql*
