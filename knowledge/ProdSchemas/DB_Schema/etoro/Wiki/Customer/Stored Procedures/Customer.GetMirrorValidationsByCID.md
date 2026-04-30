# Customer.GetMirrorValidationsByCID

> Returns a customer's financial snapshot (Credit, RealizedEquity) and active mirror count for copy-trading eligibility validation; called by trading services to determine whether a customer can copy a portfolio.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer to validate for mirror/copy eligibility) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetMirrorValidationsByCID aggregates the financial data required to validate a customer's eligibility to start or continue a copy-trading relationship (called "mirroring" in eToro's system). Before allowing a customer to copy a trader, the system must check:

1. **Credit**: Account cash balance - the customer needs sufficient funds
2. **NumberOfActiveMirrors**: How many portfolios the customer is currently copying - platform limits apply
3. **RealizedEquity**: Total account value (cash + open position PnL) - used for percentage-based minimum checks

The procedure crosses schema boundaries: it reads customer financials from Customer.Customer and active mirror count from Trade.Mirror. The RealizedEquity calculation is a compound aggregate: Credit (cash balance) + SUM of open position amounts from Trade.Position + SUM of active mirror amounts from Trade.Mirror. This gives the full picture of the customer's economic position across all copy-trading and direct-trading activity.

---

## 2. Business Logic

### 2.1 Active Mirror Count

**What**: Counts how many copy-trading portfolios the customer is currently copying.

**Columns/Parameters Involved**: `@CID`, `NumberOfActiveMirrors`, `Trade.Mirror.IsActive`

**Rules**:
- Subquery: `SELECT COUNT(*) FROM Trade.Mirror WITH (NOLOCK) WHERE CID = @CID AND IsActive = 1`
- IsActive=1: only currently active copy relationships; closed/paused mirrors are excluded
- The count is used against platform copy limits (e.g., max 100 mirrors per customer)

### 2.2 RealizedEquity Compound Calculation

**What**: Computes the customer's total economic value across cash, positions, and mirrors.

**Columns/Parameters Involved**: `Credit`, `RealizedEquity`, `Trade.Position.Amount`, `Trade.Mirror.Amount`

**Rules**:
- Formula: `Credit + SUM(Trade.Position.Amount WHERE CID=@CID) + SUM(Trade.Mirror.Amount WHERE CID=@CID AND IsActive=1)`
- Credit: cash balance from Customer.Customer
- SUM(Position.Amount): unrealized PnL from direct (non-mirrored) open positions
- SUM(Mirror.Amount): allocated capital in active copy portfolios
- This is a scalar subquery computation, not a column from Customer.Customer - it is the raw calculation vs. the Customer.Customer.RealizedEquity computed column which may differ in scope
- All components read WITH NOLOCK for consistent performance in high-frequency validation calls

### 2.3 Customer Financial Baseline

**What**: Returns Credit and GCID from Customer.Customer for the given CID.

**Rules**:
- Simple WHERE CID = @CID lookup on Customer.Customer view
- Credit: cash balance (the base component of the equity calculation)
- GCID: returned for correlation in the caller's logging/audit trail

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to validate for copy-trading eligibility. Used in Customer.Customer lookup and as the filter key for Trade.Mirror and Trade.Position subqueries. |

**Output result set:**

| Column | Source | Business Meaning |
|--------|--------|-----------------|
| GCID | Customer.Customer.GCID | Global Customer ID - returned for caller correlation and logging. |
| Credit | Customer.Customer.Credit | Customer's cash balance (excluding unrealized PnL). The base component of the equity calculation. Used to check minimum cash requirement for copy-trading. |
| NumberOfActiveMirrors | Subquery: COUNT(*) FROM Trade.Mirror WHERE CID=@CID AND IsActive=1 | Number of portfolios this customer is currently copying. Validated against the platform's copy limit per account (e.g., max 100). |
| RealizedEquity | Computed: Credit + SUM(Trade.Position.Amount) + SUM(Trade.Mirror.Amount WHERE IsActive=1) | Customer's full economic value: cash + open position PnL + active mirror allocated capital. Used for percentage-based minimum equity checks before allowing new copy relationships. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Read | Source of GCID and Credit |
| @CID | Trade.Mirror | Read (cross-schema subquery) | Source of NumberOfActiveMirrors (IsActive=1 count) and Mirror.Amount component of RealizedEquity |
| @CID | Trade.Position | Read (cross-schema subquery) | Source of Position.Amount component of RealizedEquity |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase (called by copy-trading eligibility validation services).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetMirrorValidationsByCID (procedure)
├── Customer.Customer (view)
│     └── Customer.CustomerStatic (table)
├── Trade.Mirror (table - cross-schema)
└── Trade.Position (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | Source of GCID and Credit for the customer |
| Trade.Mirror | Table (cross-schema) | COUNT of active mirrors (IsActive=1); SUM of Mirror.Amount for equity calculation |
| Trade.Position | Table (cross-schema) | SUM of Position.Amount for equity calculation |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IsActive=1 | Mirror filter | Only active copy relationships counted and included in equity; paused/closed mirrors excluded |
| Cross-schema access | Dependency | Requires SELECT permission on Trade.Mirror and Trade.Position from Customer schema context |
| WITH NOLOCK | Isolation | Read uncommitted on all tables - consistent with high-frequency validation pattern |
| Scalar subqueries | Design | NumberOfActiveMirrors and equity components computed as correlated subqueries; single-pass per CID |

---

## 8. Sample Queries

### 8.1 Get copy-trading validation data for a customer

```sql
EXEC Customer.GetMirrorValidationsByCID @CID = 12345678
-- Returns GCID, Credit, NumberOfActiveMirrors, RealizedEquity
-- Caller validates: NumberOfActiveMirrors < limit AND RealizedEquity >= minimum
```

### 8.2 Direct query equivalent

```sql
SELECT
    cc.GCID,
    cc.Credit,
    (SELECT COUNT(*) FROM Trade.Mirror WITH (NOLOCK) WHERE CID = 12345678 AND IsActive = 1) AS NumberOfActiveMirrors,
    cc.Credit
        + (SELECT ISNULL(SUM(Amount), 0) FROM Trade.Position WITH (NOLOCK) WHERE CID = 12345678)
        + (SELECT ISNULL(SUM(Amount), 0) FROM Trade.Mirror WITH (NOLOCK) WHERE CID = 12345678 AND IsActive = 1)
        AS RealizedEquity
FROM Customer.Customer cc WITH (NOLOCK)
WHERE cc.CID = 12345678
```

### 8.3 Check how many mirrors a customer has

```sql
SELECT COUNT(*) AS ActiveMirrors
FROM Trade.Mirror WITH (NOLOCK)
WHERE CID = 12345678 AND IsActive = 1
```

### 8.4 Find customers at or near mirror limit

```sql
SELECT CID, COUNT(*) AS ActiveMirrors
FROM Trade.Mirror WITH (NOLOCK)
WHERE IsActive = 1
GROUP BY CID
HAVING COUNT(*) >= 95
ORDER BY ActiveMirrors DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetMirrorValidationsByCID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetMirrorValidationsByCID.sql*
