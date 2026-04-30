# Trade.ValidateSmallAmountsRangePercentage

> Validates CopyTrader allocation amounts using a tiered percentage model: small-equity customers ($250 or less) face a tighter percentage cap than customers with larger balances.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns INT (validation result code) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ValidateSmallAmountsRangePercentage is the most sophisticated of the mirror validation functions. It implements a tiered validation model that applies different percentage caps based on the customer's total equity size. Customers with small accounts (equity <= $250) face a stricter percentage limit (SmallAmountsRangePercentage), while customers with larger accounts use the standard MaxMirrorActionAmountPercentage.

This function exists to prevent small-equity customers from over-allocating to CopyTrader. A customer with $200 equity allocating 50% to a single copy is at much higher risk than a customer with $50,000 allocating the same percentage. The $250 threshold is hardcoded (per code comment: "change max small amount to always be 250 dollars /fb24143/").

The function reads the customer's Credit and RealizedEquity from Customer.Customer, then applies the appropriate tier's percentage validation. Error 60080 is specific to the small-amounts tier; error 60070 is the standard percentage exceeded error.

---

## 2. Business Logic

### 2.1 Tiered Equity-Based Validation

**What**: Applies different percentage caps based on customer equity size.

**Columns/Parameters Involved**: `@CID`, `@AmountInDollars`, `@MirrorTypeID`, `RealizedEquity`, `SmallAmountsRangePercentage`, `MaxMirrorActionAmountPercentage`

**Rules**:
- Reads FeatureID=23 XML for SmallAmountsRangePercentage and MaxMirrorActionAmountPercentage per MirrorType
- Reads customer Credit and RealizedEquity from Customer.Customer
- MaxSmallAmountAbsolute is hardcoded to $250 (fb24143)
- **Small equity tier** (Equity <= $250):
  - If ROUND(Equity / 100 * SmallAmountsRangePercentage, 2) < @AmountInDollars: returns 60080
  - Error 60080 is the small-accounts-specific rejection
- **Normal equity tier** (Equity > $250):
  - If ROUND(Equity / 100 * MaxMirrorActionAmountPercentage, 2) < @AmountInDollars AND @AmountInDollars > 0: returns 60070
  - Standard percentage-exceeded error (same as ValidateMaxMirrorActionAmountPercentage)
- If both checks pass: returns 1

**Diagram**:
```
  Customer.Customer(CID) --> Equity (RealizedEquity)
       |
       v
  Equity <= $250?
       |
  YES: SmallAmountsRangePercentage applies
       MaxAllowed = Equity * SmallAmountsPct / 100
       @Amount > MaxAllowed? --> RETURN 60080
       |
  NO:  MaxMirrorActionAmountPercentage applies
       MaxAllowed = Equity * MaxPct / 100
       @Amount > MaxAllowed AND @Amount > 0? --> RETURN 60070
       |
       v
  RETURN 1 (OK)
```

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer identifier. Used to retrieve Credit and RealizedEquity from Customer.Customer for tier determination and percentage calculation. |
| 2 | @AmountInDollars | dtPrice | NO | - | CODE-BACKED | The dollar amount the customer wants to allocate to the CopyTrader. Validated against the tier-appropriate percentage of equity. |
| 3 | @MirrorTypeID | INT | NO | - | CODE-BACKED | Mirror type identifier. Selects the correct SmallAmountsRangePercentage and MaxMirrorActionAmountPercentage from XML config. |
| 4 | Return value | INT | NO | - | CODE-BACKED | Validation result: 1 = valid, 60080 = small-equity tier percentage exceeded, 60070 = standard tier percentage exceeded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FeatureID=23 | Maintenance.Feature | SELECT (WHERE) | Reads mirror validation XML for percentage thresholds |
| @CID | Customer.Customer | SELECT (WHERE) | Reads Credit and RealizedEquity for tier determination |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ChangeMirrorAmount_testJunk | Function call | Called | Test procedure for mirror amount changes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ValidateSmallAmountsRangePercentage (function)
  +-- Maintenance.Feature (table)
  +-- Customer.Customer (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | SELECT XMLValue WHERE FeatureID = 23 for SmallAmountsRangePercentage, MinMirrorAmountAbsolute, MaxMirrorActionAmountPercentage |
| Customer.Customer | Table | SELECT Credit, RealizedEquity WHERE CID = @CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ChangeMirrorAmount_testJunk | Stored Procedure | Calls during mirror amount change validation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Validate amount for small-equity customer
```sql
SELECT Trade.ValidateSmallAmountsRangePercentage(12345, 150.00, 1) AS ValidationResult
```

### 8.2 Check configured small-amounts thresholds
```sql
SELECT F.XMLValue.value('(MirrorValidationInfo/MirrorType[@ID="1"]/@SmallAmountsRangePercentage)[1]', 'DECIMAL(10,2)') AS SmallAmtPct,
       F.XMLValue.value('(MirrorValidationInfo/MirrorType[@ID="1"]/@MaxMirrorActionAmountPercentage)[1]', 'DECIMAL(5,2)') AS StdMaxPct
FROM   Maintenance.Feature F WITH (NOLOCK)
WHERE  F.FeatureID = 23
```

### 8.3 Identify customers in the small-equity tier
```sql
SELECT C.CID, C.RealizedEquity,
       Trade.ValidateSmallAmountsRangePercentage(C.CID, 100.00, 1) AS CanAllocate100
FROM   Customer.Customer C WITH (NOLOCK)
WHERE  C.RealizedEquity <= 250.00
  AND  C.RealizedEquity > 0
ORDER BY C.RealizedEquity DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [EtoroOps Flows - Screen List Documentation](https://etoro.atlassian.net) | Confluence | CopyTrader tiered validation flows for small accounts |

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.7/10 (Elements: 10/10, Logic: 10/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ValidateSmallAmountsRangePercentage | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.ValidateSmallAmountsRangePercentage.sql*
