# BackOffice.GetExchangeRatesAndFeesPerCustomer

> Returns the effective cashout exchange rate and fee for each payment method a customer has used, blending current FX bid rates with tier-based cashout fees to produce the all-in exchange rate shown during withdrawal.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (@CID, @PaymentMethodIds) - returns one row per (FundingTypeID, CurrencyID) combination |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.GetExchangeRatesAndFeesPerCustomer is the fee and exchange rate calculator for eToro's cashout (withdrawal) flow. Given a customer and an optional list of additional payment method IDs, it returns the effective exchange rate (Base Exchange Rate + fee adjustment) for each currency in which the customer's payment methods operate, taking into account the customer's player level (fee tier).

The procedure answers: "If this customer withdraws via each of their payment methods, what exchange rate and fee will they see?" It combines three pieces of data: the current live FX bid rate (from Trade.CurrencyPrice), the player-level-specific cashout fee (from Billing.AllConversionFees), and the fee scaling multiplier (from Trade.ProviderToInstrument.ExchangeFeeMultiplier).

The result powers the cashout UI to display the expected exchange rate to the customer before they confirm a withdrawal.

Created September 2020 (Shay Oren - use ExchangeFeeMultiplier instead of Precision). Enhanced Feb 2022 (MIMOPSA-6011, KateM) and Jul 2023 (emergency NOLOCK fix by Yitzchak Wahnon when instrument additions caused blocking).

---

## 2. Business Logic

### 2.1 FundingTypes CTE - Customer's Payment Method Universe

**What**: Collects all distinct FundingTypeIDs the customer has ever used for deposits or withdrawals, plus any explicitly requested IDs.

**Columns/Parameters Involved**: `@CID`, `@PaymentMethodIds`, `Billing.Funding`, `Billing.Deposit`, `Billing.Withdraw`, `Billing.WithdrawToFunding`

**Rules**:
- Set 1: FundingTypeIDs from funding records associated with the customer's deposits (`Billing.Deposit.CID = @CID`)
- Set 2: FundingTypeIDs from funding records linked to the customer's withdrawals via the WithdrawToFunding mapping table (`Billing.Withdraw.CID = @CID JOIN WithdrawToFunding JOIN Funding`)
- Set 3: FundingTypeIDs from funding records directly linked to withdrawals via `Billing.Withdraw.FundingID` (`Billing.Withdraw.CID = @CID`)
- Set 4: IDs from `@PaymentMethodIds` TVP - allows callers to request exchange rates for additional funding types not in the customer's history
- UNION (deduplicates) - each FundingTypeID appears once in the result

### 2.2 Exchange Rate Calculation

**What**: Computes the all-in exchange rate by adding the cashout fee (scaled by ExchangeFeeMultiplier) to the current bid rate, with different formulas depending on whether USD is the buy or sell currency.

**Columns/Parameters Involved**: `CashoutFee`, `ExchangeFeeMultiplier`, `Bid`, `SellCurrencyID`, `BuyCurrencyID`

**Rules**:
- `@PlayerLevelID` from `Customer.CustomerStatic` determines the fee tier: `Billing.AllConversionFees` has one row per (FundingTypeID, PlayerLevelID, CurrencyID) combination
- Fee scaling: `CashoutFee / POWER(10, ISNULL(ExchangeFeeMultiplier, 0))` converts the integer-stored fee to a rate adjustment. E.g., CashoutFee=150, ExchangeFeeMultiplier=4 -> fee = 0.015 (1.5 pips)
- **If SellCurrencyID=1 (USD is sold for foreign currency)**: `Exchange Rate = Bid + fee`. Direct addition - USD is the base, so a higher rate means the customer gets fewer foreign units per USD.
- **If BuyCurrencyID=1 (USD is bought, i.e., foreign currency sold for USD)**: `Exchange Rate = 1 / (Bid - fee)`. Inverse calculation - USD is the quote, so reducing the Bid (subtracting fee) before inverting.
- NULL exchange rate is returned when neither SellCurrencyID nor BuyCurrencyID equals 1 (edge case for non-USD instruments)

**Diagram**:
```
USD sell (SellCurrencyID=1):
  Exchange Rate = Bid + CashoutFee / 10^ExchangeFeeMultiplier

USD buy (BuyCurrencyID=1):
  Exchange Rate = 1 / (Bid - CashoutFee / 10^ExchangeFeeMultiplier)
```

### 2.3 AllConversionFees Join Pattern

**What**: The JOIN to Billing.AllConversionFees filters by the customer's player level, applying tier-based fee rates.

**Rules**:
- AllConversionFees contains multiple rows per (FundingTypeID) - one per (PlayerLevelID, CurrencyID) combination
- WHERE `BAF.PlayerLevelID = @PlayerLevelID` selects only the fee rows applicable to this customer's tier
- Higher player levels typically have lower fees (rewards for loyal/high-volume customers)
- If CustomerStatic has no PlayerLevelID (NULL), @PlayerLevelID will be NULL and the AllConversionFees JOIN will return no rows (no matching fees)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer account ID. Drives PlayerLevelID lookup and the FundingTypes CTE (deposit and withdrawal history). |
| 2 | @PaymentMethodIds | BackOffice.IDs READONLY | NO | - | CODE-BACKED | Table-valued parameter (TVP) of additional FundingTypeIDs to include in the result beyond the customer's own history. Each row provides an ID via the IDs UDT's single INT column. Pass empty TVP to include only the customer's historical funding types. |

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method type identifier. From the FundingTypes CTE. FK to Billing.FundingType or equivalent dictionary. |
| R2 | CurrencyID | int | NO | - | CODE-BACKED | Currency in which this payment method operates. From Billing.AllConversionFees. FK to Dictionary.Currency. |
| R3 | Fee | decimal | NO | - | VERIFIED | The cashout fee for this (FundingTypeID, PlayerLevelID, CurrencyID) combination. Integer value from Billing.AllConversionFees.CashoutFee, scaled by ExchangeFeeMultiplier. Not yet converted to a rate adjustment here - raw fee value returned. |
| R4 | Base Exchange Rate | decimal | NO | - | VERIFIED | The current live bid rate for the instrument corresponding to this currency pair. From Trade.CurrencyPrice.Bid for the InstrumentID in AllConversionFees. Real-time FX rate without fee adjustment. |
| R5 | Exchange Rate | decimal(16,8) | YES | - | VERIFIED | The all-in effective exchange rate after applying the cashout fee. `Bid + fee_scaled` for USD-sell instruments; `1 / (Bid - fee_scaled)` for USD-buy instruments. NULL for non-USD instruments (CASE returns NULL). This is the rate shown to the customer during cashout. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PlayerLevelID lookup | Customer.CustomerStatic | SELECT | Gets customer's fee tier (PlayerLevelID) |
| FT (CTE Set 1) | Billing.Deposit | SELECT | Customer's deposit-side funding types |
| BF (CTE Sets 1-3) | Billing.Funding | JOIN | Funding type for each deposit/withdrawal |
| BW (CTE Sets 2-3) | Billing.Withdraw | SELECT | Customer's withdrawal-side funding types |
| BWTF (CTE Set 2) | Billing.WithdrawToFunding | JOIN | Maps withdrawals to funding records |
| BAF | Billing.AllConversionFees | INNER JOIN | Fee configuration per (FundingTypeID, PlayerLevelID, CurrencyID) |
| TINS | Trade.Instrument | INNER JOIN | Provides SellCurrencyID, BuyCurrencyID for direction logic |
| TCRP | Trade.CurrencyPrice | INNER JOIN | Current bid rate for the instrument |
| TPTI | Trade.ProviderToInstrument | INNER JOIN | ExchangeFeeMultiplier for fee scaling |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from the withdrawal/cashout flow to populate the exchange rate and fee display in the BackOffice and customer-facing cashout UI.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetExchangeRatesAndFeesPerCustomer (procedure)
├── Customer.CustomerStatic (table - cross-schema)
├── Billing.Deposit (table - cross-schema)
├── Billing.Funding (table - cross-schema)
├── Billing.Withdraw (table - cross-schema)
├── Billing.WithdrawToFunding (table - cross-schema)
├── Billing.AllConversionFees (table/view - cross-schema)
├── Trade.Instrument (table - cross-schema)
├── Trade.CurrencyPrice (table - cross-schema)
└── Trade.ProviderToInstrument (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | SELECT PlayerLevelID WHERE CID = @CID |
| Billing.Deposit | Table | CTE: deposit-side FundingTypeID collection for @CID |
| Billing.Funding | Table | CTE: FundingTypeID source for deposit and withdrawal records |
| Billing.Withdraw | Table | CTE: withdrawal-side FundingTypeID collection for @CID |
| Billing.WithdrawToFunding | Table | CTE: maps withdraw to funding via WithdrawID |
| Billing.AllConversionFees | Table/View | Fee rates per (FundingTypeID, PlayerLevelID, CurrencyID); filtered to @PlayerLevelID |
| Trade.Instrument | Table | INNER JOIN on InstrumentID; provides SellCurrencyID, BuyCurrencyID for exchange direction |
| Trade.CurrencyPrice | Table | INNER JOIN on InstrumentID; provides current Bid (live FX rate) |
| Trade.ProviderToInstrument | Table | INNER JOIN on InstrumentID; provides ExchangeFeeMultiplier |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Cashout/withdrawal service | External | READER - calculates effective exchange rates for cashout display |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Emergency NOLOCK notes: NOLOCK hints were added to Trade.Instrument JOIN in Jul 2023 as an emergency fix because the procedure was taking table/page locks that interfered with instrument additions by other processes. SET NOCOUNT ON is present. The Exchange Rate CAST to DECIMAL(16,8) ensures precision for the rate calculation.

---

## 8. Sample Queries

### 8.1 Get exchange rates for a customer's existing payment methods
```sql
DECLARE @ids BackOffice.IDs;
EXEC BackOffice.GetExchangeRatesAndFeesPerCustomer
    @CID = 12345,
    @PaymentMethodIds = @ids  -- empty TVP = use only customer's history
-- Returns: FundingTypeID, CurrencyID, Fee, Base Exchange Rate, Exchange Rate
```

### 8.2 Include specific additional payment methods
```sql
DECLARE @ids BackOffice.IDs;
INSERT INTO @ids (ID) VALUES (1), (5);  -- credit card + Neteller
EXEC BackOffice.GetExchangeRatesAndFeesPerCustomer
    @CID = 12345,
    @PaymentMethodIds = @ids
```

### 8.3 Ad-hoc: get fee tiers for a specific customer
```sql
SELECT cs.CID, cs.PlayerLevelID, baf.FundingTypeID, baf.CurrencyID, baf.CashoutFee
FROM Customer.CustomerStatic cs WITH (NOLOCK)
JOIN Billing.AllConversionFees baf WITH (NOLOCK) ON baf.PlayerLevelID = cs.PlayerLevelID
WHERE cs.CID = 12345
ORDER BY baf.FundingTypeID, baf.CurrencyID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [MIMOPSA-6011](https://etoro-jira.atlassian.net/browse/MIMOPSA-6011) | Jira | Add WITH(NOLOCK) hints - Feb 2022 (KateM) |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9B-skipped,10,11)*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 0 callers | App Code: SKIPPED | Corrections: 0 applied*
*Object: BackOffice.GetExchangeRatesAndFeesPerCustomer | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetExchangeRatesAndFeesPerCustomer.sql*
