# BackOffice.GetCashActivities

> Returns the eligible payment funding sources and refundable deposit details for a customer's cashout breakdown - the core data for the BackOffice cashout refund allocation tool that determines how a withdrawal should be paid back to each original funding source.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @WithdrawID - customer + specific withdrawal; produces two result sets (funding eligibility + refundable deposit details) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetCashActivities` is the engine behind the cashout refund breakdown tool in BackOffice. When a customer requests a withdrawal, the tool must determine: (a) which payment funding sources (credit cards, wire transfer, etc.) are eligible to receive the refund, and (b) which specific deposit transactions on those funding sources still have a remaining refundable balance (amount deposited minus amount already refunded).

This is a payment regulation requirement in many jurisdictions: refunds must be returned to the same funding source used for the original deposit, up to the amount of that deposit. This prevents money laundering by ensuring funds return via the same payment channel they entered through.

The procedure produces **two result sets**:
1. **Funding summary** (first SELECT): One row per FundingID+CurrencyID combination - shows the payment method, total deposits, total cashouts already processed, whether it is the AMOP (the specific funding source of this withdrawal request), and whether it is a 3rd party funding source.
2. **Refund details** (second SELECT): One row per DepositID - shows individual deposit transactions that still have remaining refundable balance (remaining > 0), filtered to deposits matching the refundable payment types within their activity period.

**AMOP** (Authorized Method of Payment) is the specific funding ID associated with the current withdrawal request. The IIF/EXISTS check flags exactly one FundingID as IsAMOP=1 to highlight it in the UI.

Created November 2019 by Ran Ovadia; heavily evolved with 8+ code changes from 2019-2023 covering performance, 3rd-party handling, BIN validation, currency handling, and filtering improvements.

---

## 2. Business Logic

### 2.1 Blocked Fundings Gate

**What**: Certain funding sources are excluded from refund eligibility based on configuration or explicit exclusion lists.

**Columns/Parameters Involved**: `@IsBlockAllow`, `@UnsupportedFundingIds`, `Billing.CustomerToFunding.IsRefundExcluded`

**Rules**:
- Always excluded: FundingIDs passed in @UnsupportedFundingIds TVP.
- If @IsBlockAllow=0 (default): Also exclude fundings where `Billing.CustomerToFunding.IsRefundExcluded=1` for this customer.
- If @IsBlockAllow=1: Only @UnsupportedFundingIds are blocked (IsRefundExcluded is overridden).
- Uses a temp table #BlockedFundings to hold all excluded FundingIDs, applied throughout subsequent temp table builds.

### 2.2 Payable vs Refundable Payment Type Separation

**What**: The two TVP parameters distinguish between types eligible for the funding summary vs. types eligible for individual deposit refunds.

**Columns/Parameters Involved**: `@PayablePaymentTypesAndDates` (BackOffice.PaymentTypesAndActivityPeriod), `@RefundablePaymentTypesAndDates` (same type)

**Rules**:
- `@PayablePaymentTypesAndDates`: FundingTypeIDs + MinActivityDate - determines which funding types appear in the aggregate summary (first result set). A funding is included if its last transaction date > MinActivityDate for its type, OR it is the AMOP, OR LastTransactionDate IS NULL.
- `@RefundablePaymentTypesAndDates`: FundingTypeIDs + MinActivityDate - determines which individual deposit records appear in the refund details (second result set). A deposit is included if it belongs to a matching FundingTypeID AND PaymentDate > MinActivityDate.
- Same FundingTypeID can appear in both with different MinActivityDates.

### 2.3 AMOP Identification

**What**: Flags the specific funding source of the current withdrawal request as the primary AMOP.

**Columns/Parameters Involved**: `@WithdrawID`, `@FundingID` (derived), `@AmopCurrency` (derived), `IsAMOP`

**Rules**:
- @FundingID is derived at startup: `SELECT @FundingID = FundingID FROM Billing.Withdraw WHERE WithdrawID = @WithdrawID`.
- @AmopCurrency: `ISNULL(AccountCurrencyID, CurrencyID)` from the same withdraw.
- #AMOP temp table selects Results rows where FundingID = @FundingID AND CurrencyID = @AmopCurrency.
- `IsAMOP = IIF(EXISTS (SELECT 1 FROM #AMOP WHERE #AMOP.FundingID = Results.FundingID), 1, 0)`.
- The AMOP funding is included even if it would otherwise be filtered by MinActivityDate (OR EXISTS check in WHERE clause).

### 2.4 Third-Party Funding Handling

**What**: Third-party fundings (belonging to someone other than the customer) have special inclusion rules.

**Columns/Parameters Involved**: `@IsThirdPartyBalanced`, `BackOffice.CustomerToThirdPartyFundings`, `Is3rdParty`

**Rules**:
- `Is3rdParty = IIF(BCTTPF.CID IS NULL, 0, 1)` - 1 if the funding is registered as a third-party funding for this customer.
- Third-party fundings are included only when: (a) @IsThirdPartyBalanced=1 (caller says to include them all), OR (b) TotalDeposits > TotalCashouts (still has balance to refund), OR (c) BCTTPF is NULL (not a third-party funding at all).
- This prevents refunding to a third-party source that is already fully balanced.

### 2.5 Credit Card Expiry Validation

**What**: Expired credit cards are excluded from the result set.

**Columns/Parameters Involved**: `Billing.Funding.FundingData`, `ExpirationDateAsString`, `FundingTypeID=1`

**Rules**:
- For FundingTypeID=1 (credit/debit cards only), validates ExpirationDateAsString from the XML FundingData.
- Parses MMYY format: first 2 chars = month (01-12), last 2 chars = year.
- `DATEADD(Month, 1, TRY_CONVERT(DATE, ...))` >= GETUTCDATE() - card is valid if the month AFTER expiry is still in the future (last day of expiry month is valid).
- Uses TRY_CONVERT for safe parsing of potentially malformed dates.
- For non-card types (FundingTypeID<>1), no expiry check is applied.

### 2.6 Remaining Refund Amount Calculation

**What**: The second result set only shows deposits that still have refundable balance.

**Columns/Parameters Involved**: `RemainingAmount`, `Billing.WithdrawToFunding.RefundAmountInDepositCurrency`, `CashoutStatusID`

**Rules**:
- `RemainingAmount = Deposit.Amount - ISNULL(SUM(WTF.RefundAmountInDepositCurrency) WHERE CashoutStatusID != 4, 0)`.
- Excludes WTF records with CashoutStatusID=4 (Canceled) from the refund sum.
- WHERE clause: `(RemainingAmount > 0)` - deposits fully refunded are excluded.
- Also requires `Billing.Depot.IsActive=1` - only active depots are included in refundable deposits.

### 2.7 Active Funding Verification

**What**: Only fundings with an active CustomerToFunding record are included in the first result set.

**Columns/Parameters Involved**: `Billing.CustomerToFunding.CustomerFundingStatusID`

**Rules**:
- `EXISTS (SELECT 1 FROM Billing.CustomerToFunding ctf WHERE ctf.FundingID = Results.FundingID AND ctf.CID = @CID AND ctf.CustomerFundingStatusID <> 2)`.
- CustomerFundingStatusID=2 = inactive/removed; excludes funding sources that are no longer active for this customer.
- Added June 2022 (MIMOPSA-7057).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer Identifier. Filters all billing and funding data to this customer. |
| 2 | @WithdrawID | INT | NO | - | CODE-BACKED | The specific withdrawal request being processed. Used to identify the AMOP (funding source of this withdrawal) and its currency. |
| 3 | @IsBlockAllow | BIT | NO | - | CODE-BACKED | Whether to override refund exclusion flags. 0=respect IsRefundExcluded; 1=ignore IsRefundExcluded (allow all except @UnsupportedFundingIds). |
| 4 | @PayablePaymentTypesAndDates | BackOffice.PaymentTypesAndActivityPeriod (TVP) | NO | - | CODE-BACKED | Eligible payment type IDs with their minimum activity dates for the funding summary result set. |
| 5 | @RefundablePaymentTypesAndDates | BackOffice.PaymentTypesAndActivityPeriod (TVP) | NO | - | CODE-BACKED | Refundable payment type IDs with activity dates for the individual deposit refund details result set. |
| 6 | @IsThirdPartyBalanced | BIT | NO | - | CODE-BACKED | Whether third-party fundings should be included regardless of balance. 0=only include if balance remains; 1=include all. |
| 7 | @UnsupportedFundingIds | BackOffice.IDs (TVP) | NO | - | CODE-BACKED | FundingIDs to always exclude from results (unsupported/problematic funding sources). |
| 8 | @ActivityPeriod | INT | YES | 0 | CODE-BACKED | When =2, includes manually-added BO fundings (those without deposit/withdraw history). 0=default behavior. |

### First Result Set (Funding Summary)

| # | Column | Type | Nullable | Confidence | Description |
|---|--------|------|----------|------------|-------------|
| 1 | FundingID | INT | NO | CODE-BACKED | Payment funding source identifier. FK to Billing.Funding. |
| 2 | PaymentMethodId | INT | NO | CODE-BACKED | Funding type (payment method). FK to Dictionary.FundingType (1=Credit Card, 2=Wire Transfer, etc.). |
| 3 | CurrencyId | INT | NO | CODE-BACKED | Currency of this funding+deposit combination. FK to Dictionary.Currency. |
| 4 | TotalDepositsInOrigCurrency | MONEY | YES | CODE-BACKED | Total amount deposited via this funding in this currency. NULL if no deposits. |
| 5 | TotalCashOutsInOrigCurrency | MONEY | YES | CODE-BACKED | Total amount already cashed out via this funding in this currency. CashoutStatusID=3 only. NULL if no cashouts. |
| 6 | PaymentDetails | XML | YES | CODE-BACKED | FundingData XML blob (Billing.Funding.FundingData) - contains BIN, expiry, card type, account number mask, etc. |
| 7 | IsAMOP | BIT | NO | CODE-BACKED | Whether this is the funding source of the current withdrawal request. 1=AMOP (the primary refund target); 0=alternative funding. |
| 8 | LastTransactionDate | DATETIME | YES | CODE-BACKED | Most recent deposit or cashout transaction date for this funding+currency. |
| 9 | Is3rdParty | BIT | NO | CODE-BACKED | Whether this funding belongs to a third party (registered in BackOffice.CustomerToThirdPartyFundings). 1=third party; 0=customer's own. |
| 10 | Brand | NVARCHAR | YES | CODE-BACKED | Credit card brand name (e.g., "Visa", "Mastercard"). From Dictionary.CardType via FundingData XML. NULL for non-card funding types. |

### Second Result Set (Refund Details)

| # | Column | Type | Nullable | Confidence | Description |
|---|--------|------|----------|------------|-------------|
| 11 | FundingID | INT | NO | CODE-BACKED | Payment funding source for this deposit. |
| 12 | FundingTypeID | INT | NO | CODE-BACKED | Funding type ID. |
| 13 | DepositID | INT | NO | CODE-BACKED | Specific deposit transaction ID. FK to Billing.Deposit. |
| 14 | Amount | MONEY | NO | CODE-BACKED | Original deposit amount in deposit currency. |
| 15 | DepositRequestDate | DATETIME | NO | CODE-BACKED | Date the deposit was made (Billing.Deposit.PaymentDate). |
| 16 | CurrencyID | INT | NO | CODE-BACKED | Currency of this deposit. FK to Dictionary.Currency. |
| 17 | CardCategory | NVARCHAR | YES | CODE-BACKED | Card category (e.g., Debit, Credit, Prepaid) from Dictionary.CountryBin via BIN lookup on FundingData XML. NULL for non-card types. |
| 18 | DepotName | NVARCHAR | YES | CODE-BACKED | Payment processor/depot name from Billing.Depot.Name. NULL if no depot. |
| 19 | DepotID | INT | YES | CODE-BACKED | Payment processor depot identifier. FK to Billing.Depot. |
| 20 | RemainingAmount | MONEY | NO | CODE-BACKED | Deposit amount minus already-refunded amounts (excluding canceled WTF records). Only rows where RemainingAmount > 0 are returned. |
| 21 | WithdrawID | INT | YES | CODE-BACKED | If this deposit is already linked to the current withdrawal, the WithdrawID. NULL if not yet linked. From Billing.WithdrawToFunding LEFT JOIN. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WithdrawID / @CID | Billing.Withdraw | Startup lookup | Get FundingID and AMOP currency for the withdraw. |
| @CID / FundingID | Billing.CustomerToFunding | BlockedFundings filter + active check | IsRefundExcluded flag and active status. |
| @CID | Billing.Deposit | #Deposits temp table | All payable deposits for this customer. |
| FundingID | Billing.Funding | JOIN | FundingData XML, FundingTypeID for all results. |
| DepositID | Billing.WithdrawToFunding | #WithdrawToFundings temp table + refund sum | Cashout refund history per deposit. |
| FundingID | BackOffice.CustomerToThirdPartyFundings | Is3rdParty check | Whether funding belongs to a third party. |
| BinCode (from XML) | Dictionary.CountryBin | BIN lookup (LEFT JOIN) | CardCategory for refund detail rows. |
| DepotID | Billing.Depot | LEFT JOIN | Depot name, IsActive filter. |
| FundingTypeID | Dictionary.CardType | LEFT JOIN | Brand name via CardTypeID in FundingData XML. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by BackOffice cashout breakdown tool. No SQL procedure callers found in repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCashActivities (procedure)
├── Billing.Withdraw (table) [cross-schema]
├── Billing.CustomerToFunding (table) [cross-schema]
├── Billing.Deposit (table) [cross-schema]
├── Billing.Funding (table) [cross-schema]
├── Billing.WithdrawToFunding (table) [cross-schema]
├── BackOffice.CustomerToThirdPartyFundings (table)
├── BackOffice.PaymentTypesAndActivityPeriod (UDT TVP)
├── BackOffice.RefundableTypesAndDates (UDT TVP - same as PaymentTypesAndActivityPeriod)
├── BackOffice.IDs (UDT TVP)
├── Dictionary.CountryBin (table) [cross-schema]
├── Billing.Depot (table) [cross-schema]
└── Dictionary.CardType (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | AMOP currency/FundingID lookup; #Withdraws temp. |
| Billing.Deposit | Table | All eligible deposits for refund calculation. |
| Billing.Funding | Table | FundingData XML, FundingTypeID for all result rows. |
| Billing.WithdrawToFunding | Table | Cashout history per deposit; refund amounts. |
| Billing.CustomerToFunding | Table | IsRefundExcluded flag; CustomerFundingStatusID active check. |
| BackOffice.CustomerToThirdPartyFundings | Table | Is3rdParty flag for third-party funding identification. |
| Dictionary.CountryBin | Table | BIN to CardCategory lookup in refund details. |
| Billing.Depot | Table | Depot name and IsActive filter in refund details. |
| Dictionary.CardType | Table | Card brand name via FundingData XML CardTypeID. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called externally by cashout breakdown tool. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Creates 6 temp tables: #BlockedFundings, #Deposits (with OPTIMIZE FOR hint CID=60), #Withdraws, #WithdrawToFundings (OPTIMIZE FOR CID=60), #Fundings, #TotalDeposits, #TotalCashouts, #Results, #Refunds, #AMOP. Two queries use OPTION(OPTIMIZE FOR(@CID=60)) for statistics. December 2023 change removed SELECT * INTO to reduce tempDB usage (MIMOPSA-11765).

### 7.2 Constraints

SET NOCOUNT ON. NOLOCK on most tables. No explicit NOLOCK on CustomerToFunding (live read). Two result sets returned sequentially. @ActivityPeriod=2 includes BO-manually-added fundings without deposit/withdraw history. FundingData XML parsing uses `.value()` method - requires valid XML in the column. TRY_CONVERT for safe card expiry date parsing.

---

## 8. Sample Queries

### 8.1 Basic cashout activities lookup
```sql
DECLARE @PayableTypes BackOffice.PaymentTypesAndActivityPeriod;
DECLARE @RefundableTypes BackOffice.PaymentTypesAndActivityPeriod;
DECLARE @UnsupportedIds BackOffice.IDs;

INSERT @PayableTypes VALUES (1,'20191004'),(2,'20191004');  -- Credit card, Wire
INSERT @RefundableTypes VALUES (1,'20191004');  -- Credit card refundable

EXEC BackOffice.GetCashActivities
    @CID = 9063675,
    @WithdrawID = 1447276,
    @IsBlockAllow = 0,
    @PayablePaymentTypesAndDates = @PayableTypes,
    @RefundablePaymentTypesAndDates = @RefundableTypes,
    @IsThirdPartyBalanced = 0,
    @UnsupportedFundingIds = @UnsupportedIds;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOPS-359 | Jira | Changed last select as part of cashout activities refund tool redesign (Feb 2020, Ran Ovadia). |
| MIMOPSA-5631 | Jira | Performance fix for BlockedFundings handling (Nov 2021, Shay Oren). |
| MIMOPSA-7057 | Jira | Added active funding verification (CustomerToFunding active check) June 2022, Stav R. |
| MIMOPSA-11184 | Jira | Remove filtering when refund lines remain amount = 0 (Sep 2023, KateM). |
| MIMOPSA-11765 | Jira | Stop using SELECT * INTO temp table to reduce tempDB usage (Dec 2023, KateM). |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 5 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCashActivities | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCashActivities.sql*
