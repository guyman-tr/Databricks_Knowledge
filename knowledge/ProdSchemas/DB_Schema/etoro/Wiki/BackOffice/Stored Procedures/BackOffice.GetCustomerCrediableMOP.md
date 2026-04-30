# BackOffice.GetCustomerCrediableMOP

> Returns two result sets for BackOffice cashout processing: (1) all creditable Methods of Payment (MOPs) for a customer with per-method totals and live exchange rates; (2) the specific withdrawal's funding details with applicable exchange rates.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer; @WithdrawID - the specific withdrawal being processed |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a BackOffice agent processes a cashout request, they need to know: "Which payment methods can we send money to for this customer, and how much have they deposited/withdrawn via each?" This procedure provides exactly that data.

**Result Set 1 (Creditable MOP list)**: One row per payment method (FundingID) the customer has used, showing total deposits, total cashouts, the applicable exchange rate for each method (adjusted for the customer's player level tier), the payment method's identifying details (email, bank account, wallet address), and whether it is a third-party funding arrangement. Used to populate the "select destination" dropdown in the cashout approval workflow.

**Result Set 2 (Withdrawal funding details)**: One row per funding method linked to the specific @WithdrawID withdrawal, showing the exchange rate applicable for that withdrawal's currency and funding type. Used to confirm the exchange rate at which the cashout will be processed.

The procedure handles 15+ distinct payment methods (FundingTypeIDs 2-32) each with their own XML parsing pattern for `[Payment Details]`. Exchange rates are calculated live from `Trade.CurrencyPrice` adjusted by `Billing.AllConversionFees` at the customer's player level tier.

---

## 2. Business Logic

### 2.1 Player Level Pre-Fetch for Exchange Rate Tier

**What**: @PlayerLevelID is fetched upfront to select the correct conversion fee tier in all exchange rate calculations.

**Columns/Parameters Involved**: `@PlayerLevelID`, `Customer.CustomerStatic.PlayerLevelID`

**Rules**:
- `SELECT @PlayerLevelID = PlayerLevelID FROM Customer.CustomerStatic WHERE CID = @CID`
- `Billing.AllConversionFees` stores different fee rates per PlayerLevelID (e.g., VIP customers get lower conversion fees)
- Used in both CurrencyRate subqueries (Result Set 1) and Result Set 2

### 2.2 WebMoney Temp Table Workaround

**What**: A temp table handles WebMoney (FundingTypeID=10) customers with very large deposit histories.

**Columns/Parameters Involved**: `#WebMoneyDepositPaymentDataOnly`, `Billing.Deposit.PaymentData`

**Rules**:
- Only for FundingTypeID=10 (WebMoney), extracts `PayerPurseAsString` from XML PaymentData
- Filters where the purse is not empty (`REPLACE(value, ' ', '') <> ''`)
- Used as a fallback when the withdrawal's WithdrawData doesn't have a payer purse
- Comment: "Work around for customer with thousands of deposits" - XPath queries on thousands of XML rows are expensive; this pre-filters to WebMoney only

### 2.3 GetFundingData CTE - Cross-Source Instrument Lookup

**What**: A CTE identifies which currency-conversion instruments apply to this customer's fundings.

**Columns/Parameters Involved**: `GetFundingData`, `Billing.ConversionFee`

**Rules**:
- UNION of deposit fundings + withdrawal fundings, joined to `Billing.ConversionFee` on CurrencyID
- Result: (FundingID, FundingTypeID, CurrencyID, InstrumentID) - maps each funding to the FX instrument needed to convert it to USD
- The InstrumentID is used to look up live Bid prices in Trade.CurrencyPrice

### 2.4 FULL JOIN Pattern for Deposit/Cashout Totals

**What**: Deposits and cashouts are aggregated separately then FULL JOINed to produce one row per funding method even if only deposits OR only cashouts exist.

**Columns/Parameters Involved**: `NotPayPalFundings`, `TotalDeposits`, `TotalCashouts`

**Rules**:
- Left side (T): GROUP BY FundingID/CurrencyID from Billing.Deposit - for FundingTypeIDs 2,6,8,10,21,22,28,29,32 (non-PayPal), PaymentStatusID IN (2,11,12,26) [approved variants]
- Right side (H): GROUP BY FundingID/CurrencyID from Billing.WithdrawToFunding - same types, CashoutStatusID=3 [processed]
- Cashout amounts: `SUM(Amount / ExchangeRate)` converts back to funding currency
- `PayPalFundings`: Same pattern but for FundingTypeID=3 (PayPal) only, handled separately to ensure correct currency matching
- FULL JOIN means: a funding method appears even if customer only deposited (never cashed out) or only cashed out

### 2.5 Exchange Rate Calculation (Result Set 1)

**What**: Exchange rates are computed from live Trade.CurrencyPrice adjusted by the player-level conversion fee spread.

**Columns/Parameters Involved**: `[Exchange Rate]`, `Trade.CurrencyPrice.Bid`, `Billing.AllConversionFees.DepositFee`

**Formula** (applied based on instrument direction):
```
WHEN SellCurrencyID = 1 (selling USD): Bid + DepositFee / 10^Precision
WHEN BuyCurrencyID = 1 (buying USD):  1 / (Bid - DepositFee / 10^Precision)
```
- `Bid` = current market bid from Trade.CurrencyPrice
- `DepositFee` = player-level spread adjustment from Billing.AllConversionFees
- `Precision` from Trade.ProviderToInstrument
- When Exchange Rate IS NULL (no conversion needed): defaults to 1

### 2.6 Payment Details XML Parsing per Funding Type

**What**: The [Payment Details] column parses Billing.Funding.FundingData XML differently for each funding type.

**Key FundingTypeID mappings**:
| FundingTypeID | Method | Payment Details Format |
|---------------|--------|------------------------|
| 2 | Wire Transfer | PayeeName + BankName + ClientBankName + AccountID + IBANCode + SwiftCode + Country + SortCode + RoutingNumber + BSBNumber + ClientAddress |
| 3, 8 | PayPal, Skrill | Email |
| 6 | Neteller | #AccountID; Email |
| 10 | WebMoney | #AccountID; PayerPurse |
| 21 | (unknown) | #AccountID; PayerID |
| 22 | UnionPay? | AccountID; CustomerName; BankID; BankName; BankCode; BankAddress; BankAccount |
| 28 | (bank transfer) | CID; CustomerName; BankAccountNumber; BranchNameAndAddress; BankName |
| 29, 32 | PWMB/ACH | BankName; Last4DigitsOfAccount; AccountType |
| others | - | NULL |

### 2.7 Wire Transfer (FundingID=1) Special Branch

**What**: A third UNION branch handles base-currency wire transfers that go through FundingID=1 (the catch-all wire funding record).

**Rules**:
- `WHERE BWTF.FundingID = 1 AND BWTF.CashoutStatusID = 3` - only processed wire cashouts via the base funding
- Payment details parsed from `Billing.WithdrawToFunding.WithdrawData` XML (not Billing.Funding.FundingData)
- Shows as FundingType=Wire (hardcoded FundingTypeID=2 JOIN)
- FundingID shown as 1 in the output to distinguish from customer-specific wire funding records

### 2.8 Third-Party Funding Flag

**What**: [3rd Party] indicates whether this funding method involves a third party.

**Columns/Parameters Involved**: `[3rd Party]`, `BackOffice.CustomerToThirdPartyFundings`

**Rules**:
- `EXISTS (SELECT * FROM BackOffice.CustomerToThirdPartyFundings WHERE CID=@CID AND FundingID=[Funding ID])`
- 'YES' if the funding is linked to a third-party relationship; 'NO' otherwise
- Third-party fundings require additional AML scrutiny before cashout is permitted

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Result Set 1 - Creditable MOPs**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Add | INT | NO | 0 | CODE-BACKED | Hardcoded 0. Legacy UI field indicating whether this row can be added as a new MOP; always 0 here (read-only). |
| 2 | Amount in USD | DECIMAL | NO | 0.0 | CODE-BACKED | Hardcoded 0.0. Legacy field for manual override of USD amount; not populated by this SP. |
| 3 | Exchange Rate | DECIMAL(16,4) | YES | - | CODE-BACKED | Live exchange rate for this funding method's currency, adjusted by player-level conversion fee spread. See section 2.5. 1.0 if no conversion applies. |
| 4 | Currency | NVARCHAR | YES | - | CODE-BACKED | Abbreviation of the currency used by this funding method. From Dictionary.Currency. |
| 5 | Total Deposits in orig. currency | DECIMAL(16,2) | NO | 0 | CODE-BACKED | Total amount deposited via this funding method in the method's native currency. Aggregated from Billing.Deposit. |
| 6 | Total Cashouts in orig. currency | DECIMAL(16,2) | NO | 0 | CODE-BACKED | Total amount cashed out via this funding method in the method's native currency. From Billing.WithdrawToFunding (CashoutStatusID=3). |
| 7 | Funding Type | NVARCHAR | YES | - | CODE-BACKED | Name of the payment method type. From Dictionary.FundingType.Name. |
| 8 | Funding ID | INT | YES | - | CODE-BACKED | Unique ID of the funding record. FK to Billing.Funding.FundingID. 1 = base wire transfer record. |
| 9 | 3rd Party | VARCHAR(3) | NO | NO | CODE-BACKED | 'YES' if this funding is linked to a third-party arrangement in BackOffice.CustomerToThirdPartyFundings; 'NO' otherwise. See section 2.8. |
| 10 | Depot | NVARCHAR | YES | NULL | CODE-BACKED | Name of the depot/bank gateway used for deposits via this funding method. From Billing.Depot.Name. |
| 11 | Payment Details | NVARCHAR | YES | NULL | CODE-BACKED | Key identifying information for this payment method, format varies by FundingTypeID (see section 2.6). Examples: email for PayPal/Skrill, bank details for Wire, wallet address for WebMoney. |
| 12 | Last Transaction Date | DATETIME | YES | - | CODE-BACKED | Most recent transaction date across deposits and cashouts for this funding method. MAX of deposit/cashout modification dates. |
| 13 | DepotID | INT | YES | NULL | CODE-BACKED | Numeric depot identifier. From Billing.Depot.DepotID. |
| 14 | Base Exchange Rate | DECIMAL | YES | - | CODE-BACKED | Raw market Bid price from Trade.CurrencyPrice before fee adjustment. |
| 15 | Exchange Fee | DECIMAL | YES | - | CODE-BACKED | The conversion fee component for this funding type and player level. From Billing.AllConversionFees.DepositFee. |

**Result Set 2 - Withdrawal Funding Details**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 16 | (Same columns as Result Set 1: Add, Amount in USD, Exchange Rate, Currency, Total Deposits, Total Cashouts, Funding Type, Payment Details, Last Transaction Date, Funding ID, 3rd Party, Base Exchange Rate, Exchange Fee) | - | - | - | CODE-BACKED | Same structure as Result Set 1, but filtered to fundings linked to @WithdrawID. Total Deposits and Total Cashouts are hardcoded 0.00 (not aggregated). Shows the specific payment route for the withdrawal. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerStatic | Pre-fetch | PlayerLevelID for exchange rate tier |
| FundingID | Billing.Funding | JOIN | Funding records for payment method details + XML parsing |
| CID | Billing.Deposit | Aggregation | Total deposits per funding method |
| WithdrawID | Billing.Withdraw | JOIN | Links cashouts to customer + FundingTypeID |
| FundingID | Billing.WithdrawToFunding | Aggregation | Total cashouts per funding method (CashoutStatusID=3) |
| FundingID | Billing.CustomerToFunding | JOIN | Confirms customer ownership of funding; provides IsRefundExcluded flag |
| FundingTypeID | Billing.ConversionFee | JOIN | Maps currency to FX instrument for exchange rate |
| FundingTypeID/CurrencyID | Billing.AllConversionFees | JOIN | Player-level conversion fee rates |
| CurrencyID | Dictionary.Currency | Lookup | Currency abbreviation |
| FundingTypeID | Dictionary.FundingType | Lookup | Funding type name |
| CID / FundingID | BackOffice.CustomerToThirdPartyFundings | EXISTS check | Third-party funding flag |
| DepotID | Billing.Depot | Lookup | Depot name |
| InstrumentID | Trade.Instrument | JOIN | FX instrument direction (SellCurrencyID vs BuyCurrencyID) |
| InstrumentID | Trade.CurrencyPrice | JOIN | Live Bid for exchange rate calculation |
| InstrumentID | Trade.ProviderToInstrument | JOIN | Precision for fee adjustment calculation |
| CountryIDAsInteger (XML) | Dictionary.Country | Subquery | Country name in bank wire details |
| CID | Billing.CustomerToFunding | JOIN (Result Set 2) | Customer's fundings for the specific withdrawal |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application (BO) | N/A | Application call | Populates the creditable MOP selector in the cashout processing workflow |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerCrediableMOP (procedure)
|- Customer.CustomerStatic (player level)
|- Billing.Deposit (deposit totals)
|- Billing.Funding (payment method details + FundingData XML)
|- Billing.CustomerToFunding (customer-funding ownership)
|- Billing.WithdrawToFunding (cashout totals + withdrawal routing)
|- Billing.Withdraw (cashout records)
|- Billing.ConversionFee (currency-to-instrument mapping)
|- Billing.AllConversionFees (player-level fee rates)
|- Billing.Depot (depot names)
|- BackOffice.CustomerToThirdPartyFundings (3rd party flag)
|- Dictionary.Currency (currency abbreviation)
|- Dictionary.FundingType (funding type name)
|- Dictionary.Country (country name in bank wire XML)
|- Trade.Instrument (FX instrument direction)
|- Trade.CurrencyPrice (live bid price)
+-- Trade.ProviderToInstrument (precision for fee calculation)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | Pre-fetch PlayerLevelID for exchange fee tier |
| Billing.Deposit | Table | Deposit totals per FundingID; WebMoney purse XML |
| Billing.Funding | Table | Payment method records + FundingData XML for [Payment Details] |
| Billing.CustomerToFunding | Table | Customer-funding ownership validation; IsRefundExcluded flag |
| Billing.WithdrawToFunding | Table | Cashout totals per FundingID (CashoutStatusID=3); Result Set 2 routing |
| Billing.Withdraw | Table | Customer's cashout records; FundingTypeID for Result Set 2 |
| Billing.ConversionFee | Table | Maps CurrencyID to InstrumentID for exchange rate calculation |
| Billing.AllConversionFees | Table | Player-level deposit/cashout fee rates by CurrencyID and FundingTypeID |
| Billing.Depot | Table | Depot names |
| BackOffice.CustomerToThirdPartyFundings | Table | Third-party funding flag check |
| Dictionary.Currency | Table | Currency abbreviation |
| Dictionary.FundingType | Table | Funding type name |
| Dictionary.Country | Table | Subquery to resolve CountryID to name in wire transfer details |
| Trade.Instrument | Table | FX instrument direction (SellCurrencyID/BuyCurrencyID) for rate formula |
| Trade.CurrencyPrice | Table | Live Bid price for exchange rate calculation |
| Trade.ProviderToInstrument | Table | Precision for fee-adjusted exchange rate calculation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (BO) | External application | Cashout MOP selection and exchange rate display in withdrawal workflow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- `ORDER BY AllFundingsCombined.[Total Deposits] DESC` (Result Set 1): highest-deposit MOPs shown first
- Temp table `#WebMoneyDepositPaymentDataOnly`: auto-dropped at procedure end
- `WITH(NOLOCK)` on most tables; Billing.CustomerToFunding does NOT use NOLOCK (intentional - requires consistent reads for ownership checks)

---

## 8. Sample Queries

### 8.1 Get creditable MOPs for a customer processing a specific withdrawal

```sql
EXEC BackOffice.GetCustomerCrediableMOP
    @CID        = 12345678,
    @WithdrawID = 9876543;
-- Returns Result Set 1: all creditable MOPs for this customer
-- Returns Result Set 2: funding details specific to withdrawal 9876543
```

### 8.2 Direct MOP totals query (simplified)

```sql
SELECT
    BF.FundingID, DFT.Name AS FundingType,
    SUM(BD.Amount) AS TotalDeposits
FROM Billing.Deposit BD WITH(NOLOCK)
JOIN Billing.Funding BF WITH(NOLOCK) ON BD.FundingID = BF.FundingID
JOIN Dictionary.FundingType DFT WITH(NOLOCK) ON DFT.FundingTypeID = BF.FundingTypeID
WHERE BD.CID = 12345678
    AND BD.PaymentStatusID IN (2, 11, 12, 26)
GROUP BY BF.FundingID, DFT.Name
ORDER BY SUM(BD.Amount) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira records found specifically for this procedure. The procedure was originally written as "SP instead of BO free text" (Sep 2018) - replacing ad-hoc queries. Multiple iterations refined WebMoney handling, IsRefundExcluded sourcing, and PWMB (FundingTypeID=32) support through late 2019.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCustomerCrediableMOP | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomerCrediableMOP.sql*
