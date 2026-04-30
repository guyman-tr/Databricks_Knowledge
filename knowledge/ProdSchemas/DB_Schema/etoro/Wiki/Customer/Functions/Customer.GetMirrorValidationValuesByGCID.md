# Customer.GetMirrorValidationValuesByGCID

> Copy-trading validation data by GCID: same mirror validation values as GetMirrorValidationValuesByCID but accepts Group Customer ID as the lookup key, returning CID instead of GCID in output.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Inline TVF |
| **Key Identifier** | @GCID int (returns 0 or 1 rows) |
| **Partition** | N/A |
| **Indexes** | N/A (function) |

---

## 1. Business Meaning

Customer.GetMirrorValidationValuesByGCID is the GCID-keyed companion to Customer.GetMirrorValidationValuesByCID. It provides the same six mirror-validation values (CID, Credit, NumberOfActiveMirrors, RealizedEquity, Orders, OrdersEntry) but accepts @GCID as the primary lookup key, returning CID in the output.

Created by Geri Reshef in May 2015 (case 25795), alongside GetMirrorValidationValuesByCID, this function was built for callers in the GCID-keyed code paths that need copy-trading validation data without a prior CID resolution step.

The function logic is identical to GetMirrorValidationValuesByCID except: (1) WHERE clause uses GCID=@GCID instead of CID=@CID, and (2) the output returns CID instead of GCID. All subqueries use CCST.CID (the resolved CID) so mirror, position, and order lookups are correctly CID-based.

---

## 2. Business Logic

### 2.1 Mirror-Aware RealizedEquity Computation

**What**: Same bottom-up equity calculation as GetMirrorValidationValuesByCID.

**Columns/Parameters Involved**: `RealizedEquity`, `Credit`

**Rules**:
- `RealizedEquity = ISNULL(Credit, 0) + SumOpenPositions (Trade.Position) + SumAvailableCash (Trade.Mirror)`
- Identical formula to GetMirrorValidationValuesByCID
- All subqueries correctly filter by `CCST.CID` (not @GCID), so they reference the correct customer's data

### 2.2 Pending Order Amounts

**What**: Orders and OrdersEntry represent pending capital commitments.

**Rules**:
- Same as GetMirrorValidationValuesByCID: SUM(Amount) from Trade.Orders and Trade.OrdersEntry WHERE CID=CCST.CID

---

## 3. Data Overview

N/A for Inline TVF.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | VERIFIED | Group Customer ID to look up. Returns 0 rows if not found, 1 row when found. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID (platform-internal). From Customer.Customer (CustomerStatic). Returned as output (inverse of the ByCID version which returns GCID). |
| 2 | Credit | money | YES | - | VERIFIED | Current liquid cash balance (USD). From Customer.Customer (CustomerMoney). |
| 3 | NumberOfActiveMirrors | int | NO | - | CODE-BACKED | Count of active copy-trading relationships: COUNT(*) from Trade.Mirror WHERE CID=CCST.CID AND IsActive=1. |
| 4 | RealizedEquity | money | NO | - | CODE-BACKED | Computed equity: ISNULL(Credit,0) + SUM(Trade.Position.Amount WHERE CID=CCST.CID) + SUM(Trade.Mirror.Amount WHERE CID=CCST.CID). Real-time calculation from live trade data, not from stored CustomerMoney.RealizedEquity. |
| 5 | Orders | money | NO | - | CODE-BACKED | Total pending order amounts: ISNULL(SUM(Amount),0) from Trade.Orders WHERE CID=CCST.CID. Capital committed to unexecuted orders. |
| 6 | OrdersEntry | money | NO | - | CODE-BACKED | Total pending order entry amounts: ISNULL(SUM(Amount),0) from Trade.OrdersEntry WHERE CID=CCST.CID. Sub-order leg values pending execution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, Credit | Customer.Customer | FROM (CCST alias) WHERE GCID=@GCID | Customer via GCID lookup |
| NumberOfActiveMirrors | Trade.Mirror | Correlated subquery COUNT IsActive=1 using CCST.CID | Active copy count |
| RealizedEquity (positions) | Trade.Position | Correlated subquery SUM(Amount) using CCST.CID | Open trade values |
| RealizedEquity (mirrors) | Trade.Mirror | Correlated subquery SUM(Amount) using CCST.CID | Mirror allocation |
| Orders | Trade.Orders | Correlated subquery SUM(Amount) using CCST.CID | Pending orders |
| OrdersEntry | Trade.OrdersEntry | Correlated subquery SUM(Amount) using CCST.CID | Pending order entries |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Companion: Customer.GetMirrorValidationValuesByCID (CID-keyed), Customer.GetMirrorValidationValuesByUserNameAndPassword (credential-keyed).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetMirrorValidationValuesByGCID (function)
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
| Customer.Customer | View | FROM (CCST alias) WHERE GCID=@GCID - CID, Credit |
| Trade.Mirror | Table (cross-schema) | COUNT IsActive=1 and SUM(Amount) by CCST.CID |
| Trade.Position | Table (cross-schema) | SUM(Amount) by CCST.CID |
| Trade.Orders | Table (cross-schema) | SUM(Amount) by CCST.CID |
| Trade.OrdersEntry | Table (cross-schema) | SUM(Amount) by CCST.CID |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WHERE CCST.GCID = @GCID | Row filter | Returns at most 1 row |
| ISNULL(..., 0) on all subqueries | NULL protection | Returns 0 not NULL when no records found |

---

## 8. Sample Queries

### 8.1 Mirror validation check by GCID

```sql
SELECT CID, Credit, NumberOfActiveMirrors, RealizedEquity, Orders, OrdersEntry
FROM Customer.GetMirrorValidationValuesByGCID(98765) WITH (NOLOCK);
```

### 8.2 Net available balance for copy trading

```sql
SELECT
    CID,
    Credit,
    RealizedEquity,
    Orders + OrdersEntry AS CommittedAmounts,
    RealizedEquity - (Orders + OrdersEntry) AS NetAvailableForMirror
FROM Customer.GetMirrorValidationValuesByGCID(98765) WITH (NOLOCK);
```

### 8.3 Compare CID vs GCID versions for same customer

```sql
DECLARE @GCID INT = 98765;
DECLARE @CID INT = (SELECT CID FROM Customer.Customer WITH (NOLOCK) WHERE GCID = @GCID);

SELECT 'ByGCID' AS Source, CID, Credit, NumberOfActiveMirrors, RealizedEquity
FROM Customer.GetMirrorValidationValuesByGCID(@GCID) WITH (NOLOCK)
UNION ALL
SELECT 'ByCID' AS Source, GCID AS CID, Credit, NumberOfActiveMirrors, RealizedEquity
FROM Customer.GetMirrorValidationValuesByCID(@CID) WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 7.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (function) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetMirrorValidationValuesByGCID | Type: Inline TVF | Source: etoro/etoro/Customer/Functions/Customer.GetMirrorValidationValuesByGCID.sql*
