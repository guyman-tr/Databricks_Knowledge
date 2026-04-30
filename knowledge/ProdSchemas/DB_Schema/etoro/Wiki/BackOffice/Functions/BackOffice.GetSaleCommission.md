# BackOffice.GetSaleCommission

> Scalar function that calculates the flat sales commission earned by a BackOffice manager for a given deposit amount, using the tiered commission range table to look up the applicable commission.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns MONEY - commission amount in dollars |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetSaleCommission` calculates the sales commission earned by a BackOffice sales manager when their assigned customer reaches a given deposit amount. It implements a tiered flat-fee commission structure: small deposits earn no commission, mid-range deposits earn a fixed $40 or $50, and large deposits earn $100. This incentivizes sales managers to convert customers to larger deposit tiers.

The function is called by `BackOffice.DepositUpdateApproval` when a deposit is approved with a manager assigned (`@ManagerID IS NOT NULL AND @Approved = 1`). The deposit amount is converted to USD using the exchange rate before being passed to this function, so the function always operates in the primary currency (USD-equivalent dollars).

The commission lookup uses `BackOffice.SaleCommissionRange`, which defines 4 tiers:
- $0-$399.99: $0 commission (below threshold)
- $400-$999.99: $40 commission
- $1,000-$1,999.99: $50 commission
- $2,000+: $100 commission

All amounts in the commission range table are stored in minor currency units (cents), so this function converts @Amount to cents before the range lookup, then converts the result back to dollars.

---

## 2. Business Logic

### 2.1 Dollar-to-Cents Conversion for Range Lookup

**What**: The function converts the input dollar amount to cents (INTEGER), performs the range lookup against the cents-based commission table, then converts the result back to dollars.

**Columns/Parameters Involved**: `@Amount`, `@CentsAmount`, `@Commission`

**Rules**:
- `SET @CentsAmount = CAST(@Amount * 100 AS INTEGER)` - converts dollar MONEY amount to integer cents. CAST truncates fractional cents.
- `SELECT @Commission = MIN(Commission)/100.0 FROM BackOffice.SaleCommissionRange WHERE @CentsAmount BETWEEN MinRange AND MaxRange`
  - MinRange and MaxRange are in cents in the table.
  - MIN() is used defensively in case multiple ranges match (should not happen with non-overlapping ranges).
  - Division by 100.0 converts commission cents back to dollars.
- `IF @Commission IS NULL SET @Commission = 0` - handles amounts that fall outside all defined ranges (should not happen with correctly configured table, but defensive safety net).

**Diagram**:
```
@Amount (MONEY, in dollars)
     |
     * 100 -> @CentsAmount (INTEGER)
     |
     v
BackOffice.SaleCommissionRange
WHERE @CentsAmount BETWEEN MinRange AND MaxRange
MIN(Commission)
     |
     / 100.0 -> @Commission (MONEY, in dollars)
     |
     NULL? -> 0
     |
     v
Return: commission in dollars (0, 40, 50, or 100)
```

### 2.2 Tiered Commission Structure

**What**: Four commission tiers map deposit size ranges to flat commission amounts.

**Columns/Parameters Involved**: `@Amount` -> MinRange/MaxRange/Commission in BackOffice.SaleCommissionRange

**Rules**:
- Tier 1 (0-39,999 cents / $0-$399.99): Commission = 0 (no commission earned)
- Tier 2 (40,000-99,999 cents / $400-$999.99): Commission = $40 (4,000 cents / 100)
- Tier 3 (100,000-199,999 cents / $1,000-$1,999.99): Commission = $50 (5,000 cents / 100)
- Tier 4 (200,000-99,999,999 cents / $2,000+): Commission = $100 (10,000 cents / 100)
- See `BackOffice.SaleCommissionRange` for the authoritative tier definitions.

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Amount | MONEY | NO | - | CODE-BACKED | The deposit amount in dollars (MONEY type). Converted to cents internally before the range lookup. Caller (DepositUpdateApproval) converts the deposit amount using exchange rate before passing here: `CAST(Amount*ExchangeRate AS MONEY)`. |

### Return Value

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Commission | MONEY | NO | 0 | CODE-BACKED | The flat commission amount in dollars earned by the sales manager for the deposit. Returns 0 if no matching range is found or if the deposit is below the first tier threshold. Possible values: $0, $40, $50, $100 based on current SaleCommissionRange configuration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Amount (as cents) | BackOffice.SaleCommissionRange | Lookup | Range lookup: WHERE @CentsAmount BETWEEN MinRange AND MaxRange. Returns MIN(Commission)/100.0 as the commission in dollars. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.DepositUpdateApproval | @Commission | Function call | Called when a manager-assigned deposit is approved: `SELECT @Commission = BackOffice.GetSaleCommission(CAST(Amount*ExchangeRate AS MONEY)) FROM Billing.Deposit WHERE DepositID = @DepositID`. The @Commission result is used to record or pay the manager's commission for the approved deposit. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetSaleCommission (function)
└── BackOffice.SaleCommissionRange (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.SaleCommissionRange | Table | Range lookup: WHERE @CentsAmount BETWEEN MinRange AND MaxRange; MIN(Commission)/100.0 returned as dollar commission. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.DepositUpdateApproval | Stored Procedure | Calls this function after deposit approval to calculate the sales manager commission for the approved deposit. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function.

---

## 8. Sample Queries

### 8.1 Calculate commission for various deposit amounts

```sql
SELECT
    BackOffice.GetSaleCommission(200.00) AS Tier1Commission,   -- $0
    BackOffice.GetSaleCommission(500.00) AS Tier2Commission,   -- $40
    BackOffice.GetSaleCommission(1500.00) AS Tier3Commission,  -- $50
    BackOffice.GetSaleCommission(3000.00) AS Tier4Commission;  -- $100
```

### 8.2 Simulate commission calculation on recent deposits

```sql
SELECT TOP 20
    bd.DepositID,
    bd.Amount,
    bd.ExchangeRate,
    CAST(bd.Amount * bd.ExchangeRate AS MONEY) AS AmountUSD,
    BackOffice.GetSaleCommission(CAST(bd.Amount * bd.ExchangeRate AS MONEY)) AS Commission
FROM Billing.Deposit bd WITH (NOLOCK)
WHERE bd.ManagerID IS NOT NULL
ORDER BY bd.DepositDate DESC;
```

### 8.3 View commission range configuration directly

```sql
SELECT
    MinRange / 100.0 AS MinRangeUSD,
    MaxRange / 100.0 AS MaxRangeUSD,
    Commission / 100.0 AS CommissionUSD
FROM BackOffice.SaleCommissionRange WITH (NOLOCK)
ORDER BY MinRange;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetSaleCommission | Type: Scalar Function | Source: etoro/etoro/BackOffice/Functions/BackOffice.GetSaleCommission.sql*
