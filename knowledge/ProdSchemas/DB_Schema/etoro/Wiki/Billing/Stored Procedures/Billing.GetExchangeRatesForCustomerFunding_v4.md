# Billing.GetExchangeRatesForCustomerFunding_v4

> Extends v3 with payment-type and transaction-type awareness, adding special handling for recurring investment deposits that use a separate fee table (DepositTypeConversionFeeOverride).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingTypeID + @PlayerLevelID + @CurrencyID + @PaymentTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the most feature-complete version of the exchange rate lookup chain. It extends v3 by adding two new parameters: @PaymentTypeID (distinguishes between deposit and payout operations) and @TransactionTypeID (identifies the specific transaction subtype, e.g., recurring investment).

The primary new capability is recurring investment fee support: when a customer sets up a recurring investment (PaymentTypeID=1, TransactionTypeID=5), the system first looks up a specialized DepositFeePercentage from Billing.DepositTypeConversionFeeOverride. This percentage fee overrides the standard ConversionFeeOverride value for the DepositFeePercentage column. The remaining fee logic (CashoutFee, Reciprocal, Bid/Ask, Precision) is identical to v3.

All other transaction types (non-recurring deposits, cashouts/payouts) flow through the same v3 logic with no special handling.

---

## 2. Business Logic

### 2.1 Recurring Investment Fee Override

**What**: Special DepositFeePercentage lookup for recurring investment transactions.

**Columns/Parameters Involved**: `@PaymentTypeID`, `@TransactionTypeID`, `@depositFeePercentage`

**Rules**:
- Condition: @PaymentTypeID = 1 (Deposit) AND @TransactionTypeID = 5 (Recurring investment DepositTypeID)
- When true: SELECT TOP 1 DepositFeePercentage FROM Billing.DepositTypeConversionFeeOverride WHERE FundingTypeID = @FundingTypeID AND CurrencyID = @CurrencyID AND PlayerLevelID = @PlayerLevelID AND DepositTypeID = @TransactionTypeID
- @depositFeePercentage defaults to NULL; only populated for recurring investments
- In the final SELECT: ISNULL(@depositFeePercentage, cfo.DepositFeePercentage) - recurring investment fee wins if found, otherwise fall back to standard percentage fee

**Diagram**:
```
IF @PaymentTypeID=1 AND @TransactionTypeID=5 (Recurring Investment)
  -> SELECT @depositFeePercentage FROM DepositTypeConversionFeeOverride
  (else @depositFeePercentage = NULL)

Final result: ISNULL(@depositFeePercentage, cfo.DepositFeePercentage)
  -> Recurring investment: uses dedicated fee table
  -> All other transactions: uses standard ConversionFeeOverride fee
```

### 2.2 Payment Type Semantics

**What**: Distinguishes between deposit and payout contexts.

**Columns/Parameters Involved**: `@PaymentTypeID`

**Rules**:
- @PaymentTypeID = 1: Deposit (customer sending money in)
- @PaymentTypeID = 2: Payout (customer withdrawing/cashing out)
- Currently only PaymentTypeID=1 has conditional logic; PaymentTypeID=2 flows through standard path
- @TransactionTypeID corresponds to DepositTypeID for deposits (e.g., 5 = Recurring Investment) or CashoutTypeID for payouts

### 2.3 Override Resolution (inherited from v3)

Same two-tier override logic as v3:
- Try ConversionFeeOverride for (FundingTypeID, CurrencyID, PlayerLevelID)
- Fall back to ConversionFee base rates if no override found
- CountryID filter still commented out (same as v3)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlayerLevelID | INT | NO | - | CODE-BACKED | Customer VIP/tier level. Used to select the applicable ConversionFeeOverride and DepositTypeConversionFeeOverride rows. |
| 2 | @CountryID | INT | YES | NULL | CODE-BACKED | Country identifier. Accepted but not applied in WHERE clause (commented out, same as v3). For API compatibility. |
| 3 | @CurrencyID | INT | NO | - | CODE-BACKED | Currency for which exchange rates are requested. Filters ConversionFeeOverride and ConversionFee. Lookup: Dictionary.Currency. |
| 4 | @FundingTypeID | INT | NO | - | CODE-BACKED | Payment method. Filters ConversionFeeOverride and DepositTypeConversionFeeOverride. Lookup: Dictionary.FundingType. |
| 5 | @PaymentTypeID | INT | NO | - | CODE-BACKED | Payment direction: 1 = Deposit, 2 = Payout. Triggers recurring investment logic when value is 1. Per code comment: Deposit=1, Payout=2. |
| 6 | @TransactionTypeID | INT | YES | NULL | CODE-BACKED | Transaction subtype. For deposits: corresponds to DepositTypeID (5 = Recurring Investment). For payouts: CashoutTypeID. NULL means no subtype-specific logic applies. |

**Return columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | FundingTypeID | INT | NO | - | CODE-BACKED | Returns @FundingTypeID. |
| R2 | CurrencyID | INT | NO | - | CODE-BACKED | Currency for the returned rate. Matches @CurrencyID. |
| R3 | DepositFee | INT | NO | - | CODE-BACKED | Flat deposit conversion fee from ConversionFeeOverride or ConversionFee fallback. |
| R4 | CashoutFee | INT | NO | - | CODE-BACKED | Flat cashout/withdrawal conversion fee. |
| R5 | DepositFeePercentage | DECIMAL(18,2) | YES | NULL | CODE-BACKED | Percentage deposit fee. For recurring investments (PaymentTypeID=1, TransactionTypeID=5), uses Billing.DepositTypeConversionFeeOverride value (ISNULL(@depositFeePercentage, cfo.DepositFeePercentage)). Otherwise from ConversionFeeOverride. |
| R6 | CashoutFeePercentage | DECIMAL(18,2) | YES | NULL | CODE-BACKED | Percentage cashout fee from ConversionFeeOverride. Not overridden by any TransactionType logic. |
| R7 | Reciprocal | INT | NO | - | CODE-BACKED | Rate direction: 1 = direct (BuyCurrencyID=1), 0 = reciprocal. IIF(TI.BuyCurrencyID = 1, 1, 0). |
| R8 | Bid | dtPrice | NO | - | CODE-BACKED | Current bid price from Trade.CurrencyPrice (ProviderID=1). |
| R9 | Ask | dtPrice | NO | - | CODE-BACKED | Current ask price from Trade.CurrencyPrice (ProviderID=1). |
| R10 | Precision | INT | NO | - | CODE-BACKED | ExchangeFeeMultiplier aliased as Precision. From Trade.ProviderToInstrument (ProviderID=1). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingTypeID + @CurrencyID + @PlayerLevelID + @TransactionTypeID | Billing.DepositTypeConversionFeeOverride | Lookup | Recurring investment fee override (PaymentTypeID=1, TransactionTypeID=5) |
| @FundingTypeID + @CurrencyID + @PlayerLevelID | Billing.ConversionFeeOverride | JOIN | Standard player-level fee override |
| @CurrencyID | Billing.ConversionFee | JOIN (fallback) | Base conversion fee when no override |
| InstrumentID | Trade.Instrument | JOIN | BuyCurrencyID for Reciprocal flag |
| InstrumentID | Trade.ProviderToInstrument | JOIN | ExchangeFeeMultiplier (ProviderID=1) |
| InstrumentID | Trade.CurrencyPrice | JOIN | Live Bid/Ask (ProviderID=1) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application payment services (recurring investment flow) | @PaymentTypeID + @TransactionTypeID | EXEC | Called specifically when recurring investment fee override is needed |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetExchangeRatesForCustomerFunding_v4 (procedure)
├── Billing.DepositTypeConversionFeeOverride (table)
├── Billing.ConversionFeeOverride (table)
├── Billing.ConversionFee (table)
├── Trade.Instrument (table)
├── Trade.ProviderToInstrument (table)
└── Trade.CurrencyPrice (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.DepositTypeConversionFeeOverride | Table | Recurring investment deposit fee override (conditional SELECT TOP 1) |
| Billing.ConversionFeeOverride | Table | Standard player-level fee override |
| Billing.ConversionFee | Table | Base fee fallback when no override |
| Trade.Instrument | Table | BuyCurrencyID for Reciprocal calculation |
| Trade.ProviderToInstrument | Table | ExchangeFeeMultiplier (Precision output) |
| Trade.CurrencyPrice | Table | Live Bid/Ask exchange rates |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Billing schema. | - | Called from application layer (recurring investment flow). |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get rates for a standard credit card deposit

```sql
EXEC Billing.GetExchangeRatesForCustomerFunding_v4
    @PlayerLevelID = 0,
    @CountryID = NULL,
    @CurrencyID = 1,          -- USD
    @FundingTypeID = 1,       -- Credit card
    @PaymentTypeID = 1,       -- Deposit
    @TransactionTypeID = NULL; -- No subtype
```

### 8.2 Get rates for a recurring investment deposit (triggers DepositTypeConversionFeeOverride)

```sql
EXEC Billing.GetExchangeRatesForCustomerFunding_v4
    @PlayerLevelID = 0,
    @CountryID = NULL,
    @CurrencyID = 1,
    @FundingTypeID = 1,
    @PaymentTypeID = 1,       -- Deposit
    @TransactionTypeID = 5;   -- Recurring Investment DepositTypeID
```

### 8.3 Inspect recurring investment fee override table

```sql
SELECT *
FROM Billing.DepositTypeConversionFeeOverride WITH (NOLOCK)
WHERE FundingTypeID = 1
  AND CurrencyID = 1
  AND PlayerLevelID = 0
  AND DepositTypeID = 5;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetExchangeRatesForCustomerFunding_v4 | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetExchangeRatesForCustomerFunding_v4.sql*
