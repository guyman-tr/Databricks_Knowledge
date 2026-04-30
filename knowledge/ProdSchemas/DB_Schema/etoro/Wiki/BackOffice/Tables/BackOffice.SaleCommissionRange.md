# BackOffice.SaleCommissionRange

> Configuration table defining tiered commission amounts earned by sales managers based on the net deposit amount ranges of their assigned customers.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | PK_SaleCommissionRange: MinRange + MaxRange + Commission (CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

`BackOffice.SaleCommissionRange` defines the tiered commission structure for back-office sales managers. When a customer assigned to a manager reaches a certain net deposit threshold, the manager earns a commission. This table maps deposit ranges (MinRange to MaxRange, in minor currency units) to their corresponding commission amounts, creating a step-function incentive structure that rewards managers who drive higher customer deposits.

This table exists to provide a configurable, data-driven commission calculation mechanism. The `BackOffice.GetSaleCommission` function reads this table to calculate the actual commission for a given deposit amount, avoiding hard-coded thresholds in application code.

Data has 4 rows representing 4 commission tiers:
- 0-39,999 (minor units, i.e., $0-$399.99): No commission
- 40,000-99,999 ($400-$999.99): Commission 4,000 (minor units = $40)
- 100,000-199,999 ($1,000-$1,999.99): Commission 5,000 ($50)
- 200,000+ ($2,000+): Commission 10,000 ($100)

---

## 2. Business Logic

### 2.1 Tiered Commission Step Function

**What**: A range lookup: given a deposit amount, find the matching range and return the flat commission.

**Columns/Parameters Involved**: `MinRange`, `MaxRange`, `Commission`

**Rules**:
- A deposit amount falls into the tier where `MinRange <= Amount <= MaxRange`.
- Commission is a flat amount (not a percentage) earned when a customer's deposit reaches that tier.
- The ranges are contiguous with no gaps: 0-39999, 40000-99999, 100000-199999, 200000-99999999.
- All values are in minor currency units (e.g., cents in USD: 40000 = $400.00).
- The highest tier (200000+) uses 99999999 as the upper bound (effectively unbounded).

**Diagram**:
```
Deposit Amount    -> Commission Earned
-----------------------------------------
$0 - $399.99      -> $0     (tier 1: 0-39999 minor)
$400 - $999.99    -> $40    (tier 2: 40000-99999 minor)
$1,000 - $1,999.99 -> $50   (tier 3: 100000-199999 minor)
$2,000+           -> $100   (tier 4: 200000-99999999 minor)
```

---

## 3. Data Overview

| MinRange | MaxRange | Commission | Meaning |
|----------|----------|-----------|---------|
| 0 | 39,999 | 0 | Deposits below $400: no commission earned - too small to qualify |
| 40,000 | 99,999 | 4,000 | Deposits $400-$999.99: $40 flat commission earned |
| 100,000 | 199,999 | 5,000 | Deposits $1,000-$1,999.99: $50 flat commission earned |
| 200,000 | 99,999,999 | 10,000 | Deposits $2,000+: $100 flat commission - top tier incentive |

All 4 rows exist. All values are in minor currency units (divide by 100 for USD equivalent).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MinRange | int | NO | - | CODE-BACKED | Lower bound (inclusive) of this commission tier, in minor currency units (cents). The deposit amount must be >= MinRange to fall in this tier. Part of the composite PK. |
| 2 | MaxRange | int | NO | - | CODE-BACKED | Upper bound (inclusive) of this commission tier, in minor currency units. The deposit amount must be <= MaxRange. 99999999 is used as the practical upper bound for the top tier. Part of the composite PK. |
| 3 | Commission | int | NO | - | CODE-BACKED | Flat commission amount earned when a deposit falls in this range, in minor currency units. Divide by 100 for USD: 0=$0, 4000=$40, 5000=$50, 10000=$100. Part of the composite PK. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetSaleCommission | FROM/JOIN | Lookup | Function reads this table to compute the commission for a given deposit amount |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (leaf configuration table).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetSaleCommission | Function | Reads this table to look up the commission tier for a given deposit amount |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SaleCommissionRange | CLUSTERED PK | MinRange ASC, MaxRange ASC, Commission ASC | - | - | Active |

### 7.2 Constraints

None beyond the PK.

---

## 8. Sample Queries

### 8.1 Find the commission for a given deposit amount

```sql
DECLARE @DepositAmount INT = 150000;  -- $1,500 in minor units

SELECT MinRange, MaxRange, Commission
FROM BackOffice.SaleCommissionRange WITH (NOLOCK)
WHERE @DepositAmount BETWEEN MinRange AND MaxRange;
-- Returns: Commission = 5000 ($50)
```

### 8.2 View the full commission schedule

```sql
SELECT
    MinRange / 100.0 AS MinRangeUSD,
    MaxRange / 100.0 AS MaxRangeUSD,
    Commission / 100.0 AS CommissionUSD
FROM BackOffice.SaleCommissionRange WITH (NOLOCK)
ORDER BY MinRange;
```

### 8.3 Calculate commission via the function

```sql
SELECT BackOffice.GetSaleCommission(150000);  -- $1,500 deposit -> returns 5000 ($50 commission)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Live Data, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.SaleCommissionRange | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.SaleCommissionRange.sql*
