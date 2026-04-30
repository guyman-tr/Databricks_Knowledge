# Trade.ValidateMaxMirrorActionAmountPercentage

> Validates that a CopyTrader allocation amount does not exceed a configured percentage of the customer's available credit, preventing over-concentration into a single copy relationship.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns INT (validation result code) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ValidateMaxMirrorActionAmountPercentage enforces a percentage-based cap on CopyTrader allocations relative to the customer's total available credit. While the sibling function ValidateMaxMirrorActionAmountAbsolute checks a hard dollar ceiling, this function ensures the copy amount does not represent too large a proportion of the user's funds.

This prevents users from putting, for example, 90% of their funds into a single copy relationship - which would concentrate risk dangerously. The maximum percentage is configured per mirror type in Maintenance.Feature (FeatureID=23).

The function reads the customer's Credit from Customer.Customer and the MaxMirrorActionAmountPercentage from the XML configuration. The validation only applies when allocating money to a mirror (positive amounts); withdrawals from mirrors are not checked. Comment in code: "If the user adds money for mirror, I have to check the percentage. If he takes money from mirror, I don't have to check the percentage."

---

## 2. Business Logic

### 2.1 Percentage-Based Cap Validation

**What**: Ensures copy amount does not exceed a configured percentage of customer's credit.

**Columns/Parameters Involved**: `@CID`, `@AmountInDollars`, `@MirrorTypeID`, `Credit`, `MaxMirrorActionAmountPercentage`

**Rules**:
- Reads FeatureID=23 XML for MaxMirrorActionAmountPercentage per MirrorType
- Reads customer Credit from Customer.Customer
- If (Credit / 100 * MaxMirrorActionAmountPercentage) < @AmountInDollars AND @AmountInDollars > 0: returns 60070
- The > 0 check means withdrawals (negative amounts) bypass this validation
- Error 60070: "You cannot copy trader with more than X% of your total available funds"

**Diagram**:
```
  Customer.Customer(CID) --> Credit
  Maintenance.Feature(23) --> MaxPercentage per MirrorType
       |
       v
  MaxAllowed = Credit * MaxPercentage / 100
       |
       v
  @AmountInDollars > 0 AND @AmountInDollars > MaxAllowed?
       YES --> RETURN 60070 (error: exceeds % limit)
       NO  --> RETURN 1 (OK)
```

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer identifier. Used to look up the customer's available Credit from Customer.Customer. |
| 2 | @AmountInDollars | dtPrice | NO | - | CODE-BACKED | The dollar amount the customer wants to allocate to the CopyTrader relationship. Positive = adding funds (validated), negative = withdrawing funds (not validated). |
| 3 | @MirrorTypeID | INT | NO | - | CODE-BACKED | The mirror type being created. Selects the correct MaxMirrorActionAmountPercentage from XML config. |
| 4 | Return value | INT | NO | - | CODE-BACKED | Validation result: 1 = valid (within percentage limit), 60070 = error (amount exceeds configured percentage of customer credit). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FeatureID=23 | Maintenance.Feature | SELECT (WHERE) | Reads mirror validation XML configuration |
| @CID | Customer.Customer | SELECT (WHERE) | Reads the customer's Credit balance |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dealing (permission script) | Function call | GRANT EXECUTE | Granted execute permission to Dealing role |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ValidateMaxMirrorActionAmountPercentage (function)
  +-- Maintenance.Feature (table)
  +-- Customer.Customer (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | SELECT XMLValue WHERE FeatureID = 23 for mirror validation rules |
| Customer.Customer | Table | SELECT Credit WHERE CID = @CID for customer's available funds |

### 6.2 Objects That Depend On This

No direct procedure consumers found (granted to Dealing role for application-level calls).

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Validate a copy amount against customer credit percentage
```sql
SELECT Trade.ValidateMaxMirrorActionAmountPercentage(12345, 5000.00, 1) AS ValidationResult
```

### 8.2 Check configured percentage limits
```sql
SELECT F.XMLValue.value('(MirrorValidationInfo/MirrorType[@ID="1"]/@MaxMirrorActionAmountPercentage)[1]', 'DECIMAL(5,2)') AS MaxPct_Type1
FROM   Maintenance.Feature F WITH (NOLOCK)
WHERE  F.FeatureID = 23
```

### 8.3 Preview which customers would fail validation
```sql
SELECT C.CID,
       C.Credit,
       C.Credit * 0.40 AS Max40Pct,
       Trade.ValidateMaxMirrorActionAmountPercentage(C.CID, 5000.00, 1) AS Result
FROM   Customer.Customer C WITH (NOLOCK)
WHERE  C.CID IN (12345, 23456, 34567)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [EtoroOps Flows - Screen List Documentation](https://etoro.atlassian.net) | Confluence | CopyTrader validation flow including percentage-based checks |

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.7/10 (Elements: 10/10, Logic: 10/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ValidateMaxMirrorActionAmountPercentage | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.ValidateMaxMirrorActionAmountPercentage.sql*
