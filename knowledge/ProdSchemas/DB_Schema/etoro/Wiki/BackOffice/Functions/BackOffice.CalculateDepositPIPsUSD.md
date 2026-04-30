# BackOffice.CalculateDepositPIPsUSD

> Calculates the USD cost of currency exchange on a customer deposit, representing the FX spread or fee charged relative to the reference rate.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns [Value] DECIMAL(16,2) - exchange fee cost in USD |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.CalculateDepositPIPsUSD computes the USD value of the foreign exchange cost incurred when a customer deposits in a non-USD currency. When a customer deposits EUR, GBP, AED, or another currency, eToro converts it to USD at the trading rate. The difference between the "fair" mid-market rate (BaseExchangeRate) and the rate actually applied to the customer (ExchangeRate), multiplied by the deposit amount, yields the FX revenue eToro earns (or the cost absorbed) on that deposit. For wire transfers, the fee is explicit in the ExchangeFee field (quoted in PIPs/points), while for card and e-wallet deposits it is captured as a spread between the base and actual rates.

This function exists to standardize the PIP-to-USD conversion logic across all deposit reporting procedures. Without it, each reporting SP would need to re-implement the two-formula logic (wire vs. non-wire, AED vs. other currencies), creating drift and inconsistency across the BillingDepositsPCIVersion and GetRiskExposureReport procedures.

Data flows in via OUTER APPLY from deposit reporting procedures. The function is called once per deposit row, receives the deposit's funding type, exchange rates, fee, amount, and currency, and returns a single-row, single-column table with the USD-denominated FX cost. The result is exposed in BackOffice risk exposure and billing reports as "PIPs in USD" or "Exchange Fee In USD."

---

## 2. Business Logic

### 2.1 Dual-Formula FX Cost Calculation

**What**: Two different calculation methods depending on whether the deposit is a wire transfer or a card/e-wallet payment.

**Parameters Involved**: `@FundingTypeID`, `@ExchangeRate`, `@BaseExchangeRate`, `@ExchangeFee`, `@Amount`, `@CurrencyID`

**Rules**:
- **Wire Transfer (@FundingTypeID = 2)**: The FX fee is explicit in `@ExchangeFee` (quoted in PIPs/points). The USD cost is computed as: `(ExchangeFee / PipDivisor) * Amount`, where PipDivisor = 100,000 for AED (CurrencyID = 349) and 10,000 for all other currencies. The formula expands to: `((ExchangeRate + ExchangeFee/PipDivisor) * Amount) - (ExchangeRate * Amount)`.
- **Non-Wire (card, e-wallet, etc.)**: The FX fee is implicit as a spread. USD cost = `(BaseExchangeRate - ExchangeRate) * Amount`. BaseExchangeRate is the mid-market reference rate; ExchangeRate is the customer's actual rate. The spread represents eToro's FX margin.
- **AED Special Case (CurrencyID = 349)**: Wire transfer fee uses 100,000 as the PIP divisor instead of the standard 10,000. AED/USD is quoted with finer precision (5 decimal places vs 4), so PIPs have 10x smaller absolute value.

**Diagram**:
```
@FundingTypeID = 2 (Wire Transfer)?
       YES                    NO
        |                      |
@CurrencyID = 349 (AED)?   (BaseExchangeRate - ExchangeRate) * Amount
     YES         NO             = spread-based USD FX cost
      |           |
  /100000      /10000
      |           |
 (ExchangeFee/divisor) * Amount
      = explicit-fee USD FX cost

Result: [Value] DECIMAL(16,2) -- USD cost of FX conversion
```

### 2.2 Successor Relationship to CalculatePIPsUSD

**What**: This function is the updated successor to BackOffice.CalculatePIPsUSD, adding AED currency handling.

**Parameters Involved**: `@CurrencyID`

**Rules**:
- BackOffice.CalculatePIPsUSD (created OPSE-236, Nov 2021) always uses 10,000 as the PIP divisor and has no @CurrencyID parameter.
- BackOffice.CalculateDepositPIPsUSD was created in the same release (OPSE-236) and extended in Feb 2024 (MIMOPS2-239) to add the AED 100,000 divisor.
- New procedures should use CalculateDepositPIPsUSD; BillingDepositsPCIVersion (current) has migrated to a Billing schema version. BillingDepositsPCIVersion_Old still calls this BackOffice version.

---

## 3. Data Overview

N/A for Inline Table-Valued Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingTypeID | INT | NO | - | CODE-BACKED | Payment method type for the deposit. Determines which formula applies: 2 = Wire Transfer (explicit PIPs fee formula); all other values = card/e-wallet (spread formula). FK to Dictionary.FundingType. |
| 2 | @ExchangeRate | dtPrice (decimal(16,8)) | YES | - | CODE-BACKED | The actual exchange rate applied to the customer's deposit. ISNULL defaults to 1.0 (1:1, no conversion) when NULL. For USD deposits this would be 1.0. |
| 3 | @BaseExchangeRate | dtPrice (decimal(16,8)) | NO | - | CODE-BACKED | The mid-market reference/base exchange rate for the deposit currency at time of processing. Used as the "fair rate" baseline for non-wire deposits. For wire transfers this is unused if FundingTypeID=2. |
| 4 | @ExchangeFee | dtPrice (decimal(16,8)) | NO | - | CODE-BACKED | The exchange fee charged in PIPs (basis points) for wire transfer deposits. Only meaningful when @FundingTypeID = 2. Divided by 10,000 (or 100,000 for AED) to convert PIPs to a rate fraction. Ignored in non-wire formula. |
| 5 | @Amount | MONEY | NO | - | CODE-BACKED | The deposit amount in the deposit currency (not USD). Multiplied against the rate difference to yield the USD cost. In GetRiskExposureReportPCIVersion, this is the RollbackAmountInCurrency field (changed Nov 2023, KateM). |
| 6 | @CurrencyID | INT | NO | - | CODE-BACKED | The currency of the deposit. Controls the PIP divisor for wire transfers: 349 = AED uses 100,000 (finer AED quote precision); all other currencies use 10,000. Added Feb 2024 (MIMOPS2-239). FK to Dictionary.Currency. |
| 7 | [Value] (return) | DECIMAL(16,2) | - | - | CODE-BACKED | The calculated FX exchange fee cost in USD. Represents how much extra the customer paid (or how much FX revenue eToro captured) due to currency conversion on the deposit. Exposed as "PIPs in USD" or "Exchange Fee In USD" in reporting procedures. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingTypeID | Dictionary.FundingType | Lookup | 2 = Wire Transfer determines formula branch. No join - value check only. |
| @CurrencyID | Dictionary.Currency | Lookup | 349 = AED determines PIP divisor for wire transfer path. No join - value check only. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.BillingDepositsPCIVersion_Old | OUTER APPLY | Function call | Deposit billing report (legacy version) - computes "Exchange Fee In USD" column per deposit row |
| BackOffice.GetRiskExposureReportPCIVersion | OUTER APPLY | Function call | Risk exposure PCI report - computes PIPs cost for deposit rollback amounts |
| BackOffice.GetRiskExposureReportPCIVersion_Old | OUTER APPLY | Function call | Legacy risk exposure report - same usage as current version |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CalculateDepositPIPsUSD (inline TVF)
- No table or function dependencies (pure calculation)
- Input values sourced by callers from Billing.Deposit, Billing.Funding
```

### 6.1 Objects This Depends On

No dependencies. Pure arithmetic function with no table access.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.BillingDepositsPCIVersion_Old | Stored Procedure | OUTER APPLY - computes USD exchange cost per deposit in billing report |
| BackOffice.GetRiskExposureReportPCIVersion | Stored Procedure | OUTER APPLY - computes USD exchange cost on deposit rollbacks for risk report |
| BackOffice.GetRiskExposureReportPCIVersion_Old | Stored Procedure | OUTER APPLY - same as current version (legacy copy) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Inline Table-Valued Function.

### 7.2 Constraints

N/A for Inline Table-Valued Function.

---

## 8. Sample Queries

### 8.1 Calculate deposit FX cost for a wire transfer in EUR
```sql
SELECT Value AS ExchangeFeeUSD
FROM BackOffice.CalculateDepositPIPsUSD(
    2,           -- FundingTypeID: 2=Wire Transfer
    1.0850,      -- ExchangeRate: customer's applied rate
    1.0900,      -- BaseExchangeRate: mid-market rate
    50.0,        -- ExchangeFee in PIPs
    1000.00,     -- Amount: EUR 1,000 deposit
    4            -- CurrencyID: 4=EUR
)
```

### 8.2 Calculate deposit FX cost for a credit card deposit (spread-based)
```sql
SELECT Value AS ExchangeFeeUSD
FROM BackOffice.CalculateDepositPIPsUSD(
    1,           -- FundingTypeID: 1=Credit Card (non-wire)
    1.0850,      -- ExchangeRate: customer's actual rate
    1.0920,      -- BaseExchangeRate: mid-market reference rate
    0.0,         -- ExchangeFee: not used for non-wire
    500.00,      -- Amount: EUR 500 deposit
    4            -- CurrencyID: 4=EUR
)
-- Returns: (1.0920 - 1.0850) * 500 = 3.50 USD
```

### 8.3 View exchange fee costs across recent deposits in a risk report context
```sql
SELECT
    BDEP.DepositID,
    BDEP.CurrencyID,
    BFUN.FundingTypeID,
    BDEP.ExchangeRate,
    BDEP.BaseExchangeRate,
    BDEP.ExchangeFee,
    FX.Value AS ExchangeFeeUSD
FROM Billing.Deposit BDEP WITH (NOLOCK)
JOIN Billing.Funding BFUN WITH (NOLOCK) ON BDEP.FundingID = BFUN.FundingID
OUTER APPLY BackOffice.CalculateDepositPIPsUSD(
    BFUN.FundingTypeID, BDEP.ExchangeRate, BDEP.BaseExchangeRate,
    BDEP.ExchangeFee, BDEP.Amount, BDEP.CurrencyID
) FX
WHERE BDEP.CreationDate >= DATEADD(day, -7, GETDATE())
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CalculateDepositPIPsUSD | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.CalculateDepositPIPsUSD.sql*
