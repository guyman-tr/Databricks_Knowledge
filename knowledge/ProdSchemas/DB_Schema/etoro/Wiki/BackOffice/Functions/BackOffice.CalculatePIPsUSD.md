# BackOffice.CalculatePIPsUSD

> Legacy predecessor of CalculateDepositPIPsUSD - calculates the USD FX cost on deposits using a fixed 10,000 PIP divisor without AED currency special handling.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns [Value] DECIMAL(16,2) - exchange fee cost in USD |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.CalculatePIPsUSD is the original version of the deposit PIP-to-USD conversion function, created in November 2021 as part of OPSE-236 to add "PIPs in USD" columns to deposit reporting. It computes the USD value of the FX exchange cost on a customer deposit using the same dual-formula logic as CalculateDepositPIPsUSD: an explicit-fee formula for wire transfers (ExchangeFee in PIPs divided by 10,000 to get a rate, then multiplied by amount) and a spread-based formula for card/e-wallet deposits (difference between base rate and applied rate times amount).

This function exists as a legacy artifact. It was superseded by BackOffice.CalculateDepositPIPsUSD (the "Deposit" variant), which added the AED (United Arab Emirates Dirham) currency special case requiring a 100,000 PIP divisor instead of 10,000 (added February 2024, MIMOPS2-239). The key difference is that CalculatePIPsUSD has no @CurrencyID parameter and always uses 10,000, making it incorrect for AED-denominated wire transfer deposits.

As of March 2026, no active BackOffice stored procedures call BackOffice.CalculatePIPsUSD directly - all have migrated to either CalculateDepositPIPsUSD or to a Billing schema equivalent. It is retained in the schema for backward compatibility and historical reference.

---

## 2. Business Logic

### 2.1 Fixed-Divisor PIP Calculation (Wire vs Non-Wire)

**What**: Identical to CalculateDepositPIPsUSD except no currency-specific PIP divisor override.

**Parameters Involved**: `@FundingTypeID`, `@ExchangeRate`, `@BaseExchangeRate`, `@ExchangeFee`, `@Amount`

**Rules**:
- **Wire Transfer (@FundingTypeID = 2)**: USD cost = `(ExchangeFee / 10000) * Amount`. The 10,000 divisor converts PIPs to a decimal rate fraction (1 PIP = 0.0001 of the rate). This formula is INCORRECT for AED (should be /100,000) - the limitation that prompted CalculateDepositPIPsUSD.
- **Non-Wire**: USD cost = `(BaseExchangeRate - ExchangeRate) * Amount`. Spread between reference rate and applied rate times deposit amount.
- **Migration note**: Any reporting procedure still calling this function should be evaluated for migration to CalculateDepositPIPsUSD to ensure AED accuracy.

**Diagram**:
```
BackOffice.CalculatePIPsUSD (legacy)
    |
    v
Same logic as CalculateDepositPIPsUSD
BUT: Wire Transfer always uses /10000 (no AED /100000 override)

Superseded by: BackOffice.CalculateDepositPIPsUSD
               (adds @CurrencyID param + AED special case)
```

---

## 3. Data Overview

N/A for Inline Table-Valued Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingTypeID | INT | NO | - | CODE-BACKED | Payment method type. 2 = Wire Transfer (explicit PIPs fee formula); all other values = card/e-wallet (spread formula). FK to Dictionary.FundingType. |
| 2 | @ExchangeRate | dtPrice (decimal(16,8)) | YES | - | CODE-BACKED | Actual exchange rate applied to the customer's deposit. ISNULL defaults to 1.0 when NULL. |
| 3 | @BaseExchangeRate | dtPrice (decimal(16,8)) | NO | - | CODE-BACKED | Mid-market reference rate. Used in non-wire formula as the "fair rate" baseline. |
| 4 | @ExchangeFee | dtPrice (decimal(16,8)) | NO | - | CODE-BACKED | Exchange fee in PIPs for wire transfers. Divided by 10,000 (fixed - no AED override, unlike CalculateDepositPIPsUSD). |
| 5 | @Amount | MONEY | NO | - | CODE-BACKED | Deposit amount in the deposit currency. Multiplied by the rate difference to yield USD cost. |
| 6 | [Value] (return) | DECIMAL(16,2) | - | - | CODE-BACKED | USD cost of FX conversion on the deposit. Equivalent to CalculateDepositPIPsUSD.[Value] for all non-AED wire transfers. For AED wire transfers, this value will be 10x overstated versus the correct amount. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingTypeID | Dictionary.FundingType | Lookup | 2 = Wire Transfer determines formula branch. |

### 5.2 Referenced By (other objects point to this)

No active callers confirmed in BackOffice stored procedures. This function has been superseded by BackOffice.CalculateDepositPIPsUSD. Legacy caller BillingDepositsPCIVersion migrated to Billing schema function.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CalculatePIPsUSD (inline TVF)
- No table or function dependencies (pure calculation)
```

### 6.1 Objects This Depends On

No dependencies. Pure arithmetic function with no table access.

### 6.2 Objects That Depend On This

No active dependents found. Superseded by BackOffice.CalculateDepositPIPsUSD.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Inline Table-Valued Function.

### 7.2 Constraints

N/A for Inline Table-Valued Function.

---

## 8. Sample Queries

### 8.1 Calculate legacy PIP cost for a wire transfer deposit
```sql
SELECT Value AS ExchangeFeeUSD
FROM BackOffice.CalculatePIPsUSD(
    2,       -- FundingTypeID: 2=Wire Transfer
    1.0850,  -- ExchangeRate
    1.0900,  -- BaseExchangeRate
    50.0,    -- ExchangeFee in PIPs
    1000.00  -- Amount in deposit currency
)
-- Note: Use CalculateDepositPIPsUSD for AED deposits
```

### 8.2 Compare legacy vs. current function output for EUR deposit
```sql
SELECT
    legacy.Value AS LegacyPIPsUSD,
    current.Value AS CurrentPIPsUSD
FROM BackOffice.CalculatePIPsUSD(2, 1.0850, 1.0900, 50.0, 1000.00) legacy
CROSS JOIN BackOffice.CalculateDepositPIPsUSD(2, 1.0850, 1.0900, 50.0, 1000.00, 4) current
-- For EUR (CurrencyID=4): results should be identical
-- For AED (CurrencyID=349): current.Value will be 10x smaller (correct)
```

### 8.3 Identify any remaining callers of the legacy function
```sql
-- Check sys.sql_expression_dependencies to find active references
SELECT
    OBJECT_SCHEMA_NAME(referencing_id) AS CallerSchema,
    OBJECT_NAME(referencing_id) AS CallerName,
    OBJECT_TYPE_DESC = OBJECTPROPERTYEX(referencing_id, 'BaseType')
FROM sys.sql_expression_dependencies WITH (NOLOCK)
WHERE referenced_schema_name = 'BackOffice'
  AND referenced_entity_name = 'CalculatePIPsUSD'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10.0/10, Logic: 9.0/10, Relationships: 7.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 active callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CalculatePIPsUSD | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.CalculatePIPsUSD.sql*
