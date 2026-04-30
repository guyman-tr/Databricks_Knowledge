# BackOffice.GetCustomersMarginCallStatus

> Returns the credit balance for a batch of customers, ordered ascending to surface margin-call candidates first.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns one row per CID in @CIDs; ordered by Credit ASC |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetCustomersMarginCallStatus retrieves the current credit balance (`Credit`) from `Customer.CustomerMoney` for a batch of customer accounts passed as a table-valued parameter. The result is sorted by Credit ascending, meaning customers with the lowest (most negative) credit appear first - placing those closest to or already in a margin call at the top of the result set.

The procedure exists to give the BackOffice system a fast batch view of financial exposure across a selected set of accounts. When a risk event triggers a margin call review - for example, after a market move, a batch of high-exposure accounts may need to be checked simultaneously. Instead of querying each account individually, the caller provides a TVP of CIDs and receives their credit balances sorted for triage.

Called from the BackOffice application when evaluating margin call risk for a batch of customers. No stored procedure callers were found within the BackOffice schema - this is a terminal read called directly from the application layer.

---

## 2. Business Logic

### 2.1 Credit as Margin Call Indicator

**What**: The Credit column from Customer.CustomerMoney represents the customer's net financial position; negative or near-zero Credit signals margin call risk.

**Columns/Parameters Involved**: `Credit` (from Customer.CustomerMoney)

**Rules**:
- Result is sorted by Credit ASC - most negative (worst case) customers appear first, enabling risk triage
- Callers should interpret Credit <= 0 as potential margin call candidates
- The procedure fetches ALL CIDs in the input set without additional filtering - it is the caller's responsibility to determine what Credit threshold constitutes a margin call

**Diagram**:
```
@CIDs = {CID-A, CID-B, CID-C, CID-D}
                 |
                 v
Customer.CustomerMoney.Credit
                 |
                 v
Ordered by Credit ASC:
  CID-C: Credit = -500  (margin call - first)
  CID-A: Credit = 0     (at threshold)
  CID-B: Credit = 1200  (normal)
  CID-D: Credit = 8500  (healthy - last)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CIDs | dbo.Typ_CID (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing the set of CIDs to check. Uses `dbo.Typ_CID` type (TABLE with single nullable INT column `CID`). READONLY. Unlike `BackOffice.IDs`, this type has no PK or duplicate protection - duplicate CIDs in input may produce duplicate rows in output. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | CID | int | NO | - | CODE-BACKED | Customer account ID. From Customer.CustomerMoney.CID. Uniquely identifies the trading account. |
| R2 | Credit | - | YES | - | CODE-BACKED | Customer's current credit/buying power balance from Customer.CustomerMoney. Negative values indicate the account owes money (margin call candidate). Result is sorted ascending by this column to surface the most at-risk accounts first. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CIDs | dbo.Typ_CID | TVP (UDT) | Input filter - set of CIDs to check |
| CID, Credit | Customer.CustomerMoney | SELECT | Source of credit balance data for margin call assessment |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from the BackOffice application when assessing margin call risk. No stored procedure callers found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomersMarginCallStatus (procedure)
├── Customer.CustomerMoney (table - cross-schema)
└── dbo.Typ_CID (user defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | SELECT of CID and Credit for all matching CIDs |
| dbo.Typ_CID | User Defined Type | TVP parameter type - simple TABLE([CID] INT NULL) for batch input |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (margin call module) | External | READER - batch credit balance check for margin call triage |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Uses `IN (SELECT CID FROM @CIDs)` subquery pattern rather than JOIN (no significant performance difference for typical TVP sizes).

---

## 8. Sample Queries

### 8.1 Check margin call status for a batch of CIDs
```sql
DECLARE @CIDs dbo.Typ_CID
INSERT INTO @CIDs VALUES (10001), (10002), (10003)

EXEC BackOffice.GetCustomersMarginCallStatus @CIDs = @CIDs
-- Returns CID + Credit ordered ASC (most negative first)
```

### 8.2 Find customers with negative credit (margin call candidates)
```sql
DECLARE @CIDs dbo.Typ_CID
INSERT INTO @CIDs VALUES (10001), (10002), (10003)

-- Equivalent ad-hoc query with filter
SELECT CID, Credit
FROM Customer.CustomerMoney WITH (NOLOCK)
WHERE CID IN (10001, 10002, 10003)
  AND Credit <= 0
ORDER BY Credit ASC
```

### 8.3 Check credit health for all customers flagged with AggressiveTrading risk
```sql
DECLARE @CIDs dbo.Typ_CID
INSERT INTO @CIDs
SELECT DISTINCT GCID  -- note: GCID may not equal CID in all cases
FROM BackOffice.CustomerRisk WITH (NOLOCK)
WHERE RiskStatusID = 29  -- AggressiveTrading
  AND RiskEventStatusID = 1  -- On (active)

EXEC BackOffice.GetCustomersMarginCallStatus @CIDs = @CIDs
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: SKIPPED (no BackOffice repos) | Corrections: 0 applied*
*Object: BackOffice.GetCustomersMarginCallStatus | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomersMarginCallStatus.sql*
