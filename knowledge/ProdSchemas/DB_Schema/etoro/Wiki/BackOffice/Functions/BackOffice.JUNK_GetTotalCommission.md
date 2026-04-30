# BackOffice.JUNK_GetTotalCommission

> DEPRECATED scalar function returning a customer's total lifetime commission in cents (integer), summing Commission from open positions (Trade.Position) and CommissionOnClose from closed positions (History.Position), both multiplied by 100.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns INTEGER (total commission in cents for @CID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.JUNK_GetTotalCommission` returns the total commission eToro has earned from a customer across all their positions (both open and closed), expressed as an integer in cents. The `JUNK_` prefix marks this function as deprecated - it is no longer called by any active BackOffice stored procedure.

The function answers: "What is the total commission charged to customer @CID across their entire trading history?" It sums two distinct commission columns from two tables:
- **Trade.Position.Commission**: The ongoing/open commission on positions still live.
- **History.Position.CommissionOnClose**: The final commission charged when positions were closed.

**Units: INTEGER in cents** - The DDL comment explicitly states `RETURNS INTEGER -- amount in cents`. Both `Commission` and `CommissionOnClose` are presumably stored in decimal dollars; multiplying by 100 converts to cents and stores as INTEGER. This is an unusual design choice - the integer type prevents cent-level precision loss but may truncate fractional cents.

**Business use case**: Total commission is a key revenue metric per customer. A customer with high total commission is highly profitable regardless of their deposit or PnL profile. Used in customer LTV calculations and affiliate commission reporting.

---

## 2. Business Logic

### 2.1 Two-Table Commission Aggregation

**What**: Queries both Trade.Position (open) and History.Position (closed) to sum all commission earned from a customer.

**Columns/Parameters Involved**: `@CID`, `@Commission`, `Commission`, `CommissionOnClose`

**Rules**:
- Initialises `@Commission = 0` to guarantee non-NULL return.
- Step 1: `SELECT @Commission = ISNULL(SUM(Commission * 100), 0) FROM Trade.Position WHERE CID = @CID`
  - Open positions use `Commission` column (ongoing spread/fee).
  - Multiplied by 100 to convert to cents.
  - ISNULL(..., 0) handles case where customer has no open positions.
- Step 2: `SELECT @Commission = @Commission + ISNULL(SUM(CommissionOnClose * 100), 0) FROM History.Position WHERE CID = @CID`
  - Closed positions use `CommissionOnClose` column (fee at close).
  - Added to the running total from Step 1.
- Returns the combined total as INTEGER cents.

**Note on column names**: Open positions track `Commission` (present tense); closed positions track `CommissionOnClose` (fee specifically at closure). These may represent different fee structures or just reflect the lifecycle stage.

**Diagram**:
```
@CID
  |
  +-> Trade.Position (open positions)
  |     ISNULL(SUM(Commission * 100), 0) -> cents from open positions
  |
  +-> History.Position (closed positions)
  |     ISNULL(SUM(CommissionOnClose * 100), 0) -> cents from closed positions
  |
  v
@Commission = open_cents + closed_cents
Returns: INTEGER (total cents, 0 if no positions at all)
```

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Used to filter both Trade.Position and History.Position to this customer's records. |

### Return Value

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (return) | INTEGER | NO | 0 | CODE-BACKED | Total lifetime commission in cents: SUM(Commission*100) from Trade.Position (open) + SUM(CommissionOnClose*100) from History.Position (closed). Returns 0 if customer has no positions. Always non-NULL. Divide by 100 to get dollar amount. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID, Commission | Trade.Position | Table read | Source of commission on open positions. SUM(Commission * 100) for live positions. |
| @CID, CommissionOnClose | History.Position | Table read | Source of commission on closed positions. SUM(CommissionOnClose * 100) for archived positions. |

### 5.2 Referenced By (other objects point to this)

No active callers found. JUNK_ prefix indicates deprecation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetTotalCommission (function)
+-- Trade.Position (table) [cross-schema]
+-- History.Position (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | Table | Queried for SUM(Commission * 100) WHERE CID = @CID (open positions). |
| History.Position | Table | Queried for SUM(CommissionOnClose * 100) WHERE CID = @CID (closed positions). |

### 6.2 Objects That Depend On This

No dependents. JUNK-prefixed and deprecated.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function. JUNK_ prefix = deprecated. Uses WITH (NOLOCK) on both tables. Return type INTEGER; values stored in cents. Fractional cents are truncated by integer conversion.

---

## 8. Sample Queries

### 8.1 Get total commission for a specific customer

```sql
SELECT
    BackOffice.JUNK_GetTotalCommission(12345) AS TotalCommissionCents,
    BackOffice.JUNK_GetTotalCommission(12345) / 100.0 AS TotalCommissionDollars;
```

### 8.2 Commission per customer (dollar format)

```sql
SELECT
    CID,
    BackOffice.JUNK_GetTotalCommission(CID) / 100.0 AS TotalCommissionUSD
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.3 Check if customer has generated any commission revenue

```sql
SELECT
    CASE
        WHEN BackOffice.JUNK_GetTotalCommission(12345) = 0 THEN 'No commission generated'
        ELSE CAST(BackOffice.JUNK_GetTotalCommission(12345) / 100.0 AS VARCHAR) + ' USD commission'
    END AS CommissionStatus;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. JUNK_ prefix indicates deprecation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetTotalCommission | Type: Scalar Function | Source: etoro/etoro/BackOffice/Functions/BackOffice.JUNK_GetTotalCommission.sql*
