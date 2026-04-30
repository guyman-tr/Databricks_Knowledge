# Billing.FundingDataForWithdraw

> Comprehensive withdrawal investigation view that joins a withdrawal payment leg with its payment instrument details and resolved country name, providing full cashout/refund payment context in one query for operations and risk workflows.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | View |
| **Key Identifier** | ID (WithdrawToFunding PK) + FundingID |
| **Partition** | N/A |
| **Indexes** | N/A for view |

---

## 1. Business Meaning

`Billing.FundingDataForWithdraw` is the primary ad-hoc query view for investigating a withdrawal payment leg. It mirrors the purpose of `Billing.FundingDataForDeposit` but for the withdrawal pipeline: it combines the payment instrument record (Billing.Funding) with the withdrawal execution leg (Billing.WithdrawToFunding), adding the country name resolved from the funding XML and optionally the original deposit's payment data (for PayPal refunds).

The view presents everything an operations agent needs to investigate a withdrawal or refund: which payment method was used, what the account details are (human-readable via PaymentDetails CASE), what the cashout status is, how much was processed, and whether the funding instrument is blocked. The DDL comment attributes creation to Maksym, 4/10/2020, referencing PAYUA-992.

Data flows from three sources: `Billing.Funding` (INNER JOIN - every withdrawal leg must have a funding record), `Billing.WithdrawToFunding` (INNER JOIN - the withdrawal payment leg), `Dictionary.Country` (LEFT JOIN - resolves CountryIDAsInteger from FundingData XML to a human-readable country name), and `Billing.Deposit` (LEFT JOIN via BWTF.DepositID - only populated for refund legs where CashoutTypeID=2, used to extract PayPal payer identity). SELECT DISTINCT is applied to avoid duplication from the Deposit JOIN. Contains approximately 1,071,451 rows matching the WithdrawToFunding row count.

---

## 2. Business Logic

### 2.1 PaymentDetails - Human-Readable Account Identifier per FundingType

**What**: The view extracts a human-readable payment account identifier from FundingData XML, with richer logic than the deposit view to cover more withdrawal-specific payment methods.

**Columns/Parameters Involved**: `FundingTypeID`, `FundingData` (XML), `CashoutTypeID`, `PaymentDetails`

**Rules** (by FundingTypeID):
- 1 (CreditCard): '...' (PCI masking)
- 2 (WireTransfer): Concatenation of PayeeName, BankName, ClientBankName, AccountID, IBAN, SwiftCode, Country (from Dictionary.Country JOIN), SortCode, RoutingNumber, BSBNumber (from WithdrawData), ClientAddress
- 3 (PayPal) CashoutTypeID=1: Email from FundingData
- 3 (PayPal) CashoutTypeID=2 (refund): Payer from Deposit.PaymentData XML
- 6 (Neteller): '#' + AccountID + '; ' + email
- 7 (Skrill): AccountID
- 8 (similar): Email
- 10 (WebMoney): AccountID + PurseID (from FundingData or WithdrawData)
- 11 (bank): IBAN if available, else 'AccID:#' + AccountID
- 20 (international bank): Full bank details (name, address, Swift, IBAN, account#, country)
- 21 (similar): AccountID + PayerID
- 22 (local bank): AccountID, CustomerName, BankID, BankName, BankCode, BankAddress, BankAccount
- 28 (local bank variant): CID, CustomerName, BankAccountNumber, BranchNameAndAddress, BankName
- 29/32 (ACH): Bank Name, last 4 digits, account type
- 33 (eToroMoney): PlatformAccountId
- 35 (Trustly): AccountID, BankName, BankID, AccountHolderName, BankCountry, IbanCode, SwiftCode
- All others: NULL

### 2.2 Cashout vs Refund Distinction

**What**: The view covers both direct cashouts (customer initiates withdrawal) and refunds (deposit is reversed back to original payment method).

**Columns/Parameters Involved**: `CashoutTypeID`, `DepositID`, `WithdrawID`

**Rules**:
- CashoutTypeID=1: Direct cashout - customer withdraws funds to their payment instrument
- CashoutTypeID=2: Refund - a prior deposit is being returned to the original payment method; DepositID is non-NULL, linking to the source deposit
- For PayPal (FundingTypeID=3) with CashoutTypeID=2, the PaymentDetails switches to using the original Deposit.PaymentData to identify the payer (necessary because PayPal refunds go to the original payer, not the registered account)

### 2.3 SELECT DISTINCT Deduplication

**What**: The view uses SELECT DISTINCT to prevent duplicate rows from the optional Deposit LEFT JOIN.

**Rules**:
- BWTF.DepositID is only non-NULL for refund legs (CashoutTypeID=2)
- One WithdrawToFunding row + one Deposit row = one result row (DISTINCT ensures this)
- Without DISTINCT, refund legs with multiple matching deposits could produce duplicates
- The DISTINCT applies across all ~40 output columns, making this an expensive operation on large result sets

---

## 3. Data Overview

| FundingID | FundingTypeID | WithdrawID | CashoutStatusID | Amount | ProcessCurrencyID | CashoutTypeID | Meaning |
|---|---|---|---|---|---|---|---|
| 2077896 | 1 (CC) | 1735041 | 14 (Pending Review) | 45 | 1 (USD) | 2 (Refund) | A credit card refund of $45 currently under Pending Review - operations team reviewing before releasing to the card network. |
| 2077896 | 1 (CC) | 1735041 | 14 (Pending Review) | 100 | 1 (USD) | 2 (Refund) | A second refund leg for the same withdrawal/funding, $100 also pending review. Same FundingID indicates same card used for both refund legs. |
| 2223471 | 1 (CC) | 1735037 | 14 (Pending Review) | 25 | 2 (EUR) | 1 (Cashout) | A direct cashout of 25 EUR via credit card, pending review. CashoutTypeID=1 distinguishes this as a voluntary withdrawal not a refund. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingID | int | NO | - | CODE-BACKED | Payment instrument identifier. From Billing.Funding (PK). Links to the specific registered card/bank/wallet used for this withdrawal. |
| 2 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method category. From Billing.Funding. Drives PaymentDetails parsing and determines which XML fields are extracted. See Billing.Funding.md for full type map. |
| 3 | ManagerID | int | YES | - | CODE-BACKED | Operations manager ID from Billing.Funding (instrument-level). NULL = self-registered by customer. Distinct from BwtfManagerID (Element 17). |
| 4 | IsBlocked | bit | NO | - | CODE-BACKED | From Billing.Funding. 1=payment instrument blocked from future use. 0=active. |
| 5 | BlockedDescription | nvarchar | YES | - | CODE-BACKED | From Billing.Funding. Reason for blocking (e.g., "Chargeback risk"). NULL if not blocked. |
| 6 | BlockedAt | datetime | YES | - | CODE-BACKED | From Billing.Funding. When the instrument was blocked. NULL if not blocked. |
| 7 | FundingData | nvarchar(4000) | YES | - | CODE-BACKED | FundingData XML from Billing.Funding, CAST to NVARCHAR(4000). Provider-specific payment instrument data. Subject to Dynamic Data Masking. Truncated at 4000 chars. |
| 8 | IsRefundExcluded | bit | NO | - | CODE-BACKED | From Billing.Funding. 1=instrument excluded from automatic refund processing. |
| 9 | DocumentRequired | bit | NO | - | CODE-BACKED | From Billing.Funding. 1=additional KYC documentation required before this instrument can process. |
| 10 | FundingDataCheckSum | int | YES | - | CODE-BACKED | CHECKSUM-based hash of FundingData. Computed column from Billing.Funding. Used for fast change detection and deduplication without full XML comparison. Exposed in this view (unlike FundingDataForDeposit which omitted it). |
| 11 | SecuredCardData | nvarchar | YES | - | CODE-BACKED | Secured card token extracted from FundingData XML. Computed column from Billing.Funding. Indexed for card-level lookup. Subject to masking. |
| 12 | Parameter | nvarchar | YES | - | CODE-BACKED | Primary identifying parameter for this payment instrument (e.g., card hash for CC, account number for wire). Computed column from Billing.Funding via dbo.F_FundingData(FundingTypeID, FundingData). Used by application for finding existing fundings by key identifier. |
| 13 | FundingHash | nvarchar | YES | - | CODE-BACKED | Canonical lowercase hash of FundingData for deduplication. Computed column from Billing.Funding via Billing.OrderedSmallCaseFundingHash(FundingData). Ensures same payment details always produce the same hash. |
| 14 | DateCreated | datetime | NO | - | CODE-BACKED | From Billing.Funding. UTC timestamp when the payment instrument was first registered. |
| 15 | WithdrawID | int | NO | - | CODE-BACKED | Withdrawal request ID from Billing.WithdrawToFunding. FK to Billing.Withdraw. The parent withdrawal request that this payment leg is executing. |
| 16 | CashoutStatusID | int | NO | - | CODE-BACKED | Payment leg execution status. From Billing.WithdrawToFunding. Key values: 1=Pending, 2=InProcess, 3=Processed (success), 4=Canceled, 7=Rejected, 8=RejectedByProvider, 14=Pending Review. See Billing.WithdrawToFunding.md Section 2.1 for full state machine. |
| 17 | ProcessCurrencyID | int | NO | - | CODE-BACKED | Currency in which this payment leg was processed. From Billing.WithdrawToFunding. FK to Dictionary.Currency. 1=USD, 2=EUR, 3=GBP, etc. |
| 18 | BwtfManagerID | int | YES | - | CODE-BACKED | Manager/operator ID from Billing.WithdrawToFunding (aliased from ManagerID). The operations staff who last actioned this payment leg. Distinct from ManagerID (Element 3) which is the funding instrument's manager. |
| 19 | ExchangeRate | decimal | YES | - | CODE-BACKED | Exchange rate applied for currency conversion on this payment leg. From Billing.WithdrawToFunding. |
| 20 | Amount | decimal | NO | - | CODE-BACKED | Amount of this payment leg in ProcessCurrencyID. From Billing.WithdrawToFunding. For refunds, this is the refund amount; for cashouts, the withdrawal amount. |
| 21 | ModificationDate | datetime | NO | - | CODE-BACKED | Last modification timestamp of the WithdrawToFunding row. From Billing.WithdrawToFunding. |
| 22 | ID | int | NO | - | CODE-BACKED | Primary key of the WithdrawToFunding row (IDENTITY). From Billing.WithdrawToFunding. Uniquely identifies this payment leg. |
| 23 | DepositID | int | YES | - | CODE-BACKED | Source deposit ID for refund payment legs. From Billing.WithdrawToFunding. Non-NULL only when CashoutTypeID=2 (Refund) - links back to the deposit being refunded. Used by PayPal refund logic to retrieve original payer from Deposit.PaymentData. |
| 24 | RefundAmountInDepositCurrency | decimal | YES | - | CODE-BACKED | Refund amount expressed in the original deposit's currency. From Billing.WithdrawToFunding. Non-NULL for refund legs (CashoutTypeID=2) where currency conversion was involved. |
| 25 | CashoutTypeID | int | NO | - | CODE-BACKED | Distinguishes withdrawal type. From Billing.WithdrawToFunding. 1=Cashout (voluntary withdrawal to payment instrument), 2=Refund (deposit returned to original payment method). Drives PaymentDetails parsing for PayPal (FundingTypeID=3). |
| 26 | VerificationCode | varchar | YES | - | CODE-BACKED | Verification code required to release this payment. From Billing.WithdrawToFunding. Security measure for certain payment methods or risk scenarios. |
| 27 | ProcessorValueDate | datetime | YES | - | CODE-BACKED | Payment processor settlement value date. From Billing.WithdrawToFunding. For bank transfers with delayed settlement. |
| 28 | MatchStatusID | int | YES | - | CODE-BACKED | Reconciliation match status with provider statement. From Billing.WithdrawToFunding. |
| 29 | DepotID | int | YES | - | CODE-BACKED | Payment gateway/terminal that processed this leg. From Billing.WithdrawToFunding. FK to Billing.Depot. |
| 30 | AutoPaymentStartDate | datetime | YES | - | CODE-BACKED | Start date for automatic payment processing. From Billing.WithdrawToFunding. Used for scheduled/automated payment legs. |
| 31 | ProtocolMIDSettingsID | int | YES | - | CODE-BACKED | Protocol-MID configuration used. From Billing.WithdrawToFunding. FK to Billing.ProtocolMIDSettings. |
| 32 | BaseExchangeRate | decimal | YES | - | CODE-BACKED | Mid-market FX rate before fee markup. From Billing.WithdrawToFunding. |
| 33 | ExchangeFee | decimal | YES | - | CODE-BACKED | FX conversion fee on this leg. From Billing.WithdrawToFunding. |
| 34 | CashoutModeID | int | YES | - | CODE-BACKED | Cashout processing mode. From Billing.WithdrawToFunding. Controls routing and processing behavior for the payment leg. |
| 35 | CreationDate | datetime | YES | - | CODE-BACKED | Creation timestamp of this payment leg. From Billing.WithdrawToFunding. NULL for records created before the column was added (early 2023). |
| 36 | AdditionalInformation | nvarchar | YES | - | CODE-BACKED | Free-text additional information for this payment leg. From Billing.WithdrawToFunding. |
| 37 | WithdrawData | nvarchar(3000) | YES | - | CODE-BACKED | Provider response XML from Billing.WithdrawToFunding, CAST to NVARCHAR(3000). Contains provider-specific execution response data. Used in PaymentDetails CASE for some payment types (WebMoney purse, WireTransfer BSBNumber/ClientAddress). |
| 38 | Name | nvarchar | YES | - | CODE-BACKED | Country name from Dictionary.Country. Resolved by LEFT JOIN on CountryIDAsInteger extracted from FundingData XML. Exposed as DC.Name for the PaymentDetails CASE (WireTransfer country display) and for direct querying. NULL if no country ID in FundingData or no match. |
| 39 | CountryID | int | YES | - | CODE-BACKED | Country ID from Dictionary.Country (DC.CountryID). The resolved country for this payment instrument. Matches the CountryIDAsInteger value parsed from FundingData XML. |
| 40 | PaymentDetails | varchar | YES | - | CODE-BACKED | Computed human-readable payment account identifier. CASE on FundingTypeID: WireTransfer shows full bank details (name, IBAN, Swift, address), e-wallets show email/account, eToroMoney shows platform ID, Trustly shows IBAN+Swift+holder. Returns '...' for credit cards. NULL for unhandled types. Richer than FundingDataForDeposit.PaymentDetails (covers more FundingTypes). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingID, FundingTypeID, FundingData, IsBlocked, ... | Billing.Funding | Source (INNER JOIN via BWTF.FundingID) | Payment instrument; every withdrawal leg must have a funding record |
| WithdrawID, CashoutStatusID, Amount, CashoutTypeID, ... | Billing.WithdrawToFunding | Source (INNER JOIN) | Withdrawal payment leg; primary entity in this view |
| Name, CountryID | Dictionary.Country | Source (LEFT JOIN via XML-extracted CountryID) | Resolves country name from the CountryIDAsInteger in FundingData XML |
| PaymentData (for PayPal refund) | Billing.Deposit | Source (LEFT JOIN via BWTF.DepositID) | Original deposit record; used only for PayPal refunds (FundingTypeID=3, CashoutTypeID=2) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No stored procedures in Billing schema reference this view | - | - | Operations/admin ad-hoc query view |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingDataForWithdraw (view)
├── Billing.Funding (table)
├── Billing.WithdrawToFunding (table)
├── Dictionary.Country (table, cross-schema)
└── Billing.Deposit (table, LEFT JOIN for refund legs only)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | INNER JOIN source: payment instrument data |
| Billing.WithdrawToFunding | Table | INNER JOIN source (BFUN.FundingID = BWTF.FundingID): withdrawal payment leg data |
| Dictionary.Country | Table | LEFT JOIN: CAST(CountryIDAsInteger from FundingData XML) = DC.CountryID - resolves country name |
| Billing.Deposit | Table | LEFT JOIN (BWTF.DepositID = BDEP.DepositID): retrieves PayerAsString for PayPal refunds |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No code-level dependents discovered in Billing schema | - | Ad-hoc operations query view |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. Performance note: SELECT DISTINCT across ~40 columns on 1M+ rows is expensive. Recommended to always filter by FundingID, WithdrawID, or ID when querying.

### 7.2 Constraints

N/A for view. No SCHEMABINDING. WithdrawData CAST to NVARCHAR(3000) - data beyond 3000 chars truncated. Country JOIN uses a complex CAST(NULLIF('', ...) AS INT) pattern to handle empty-string CountryIDAsInteger values in the XML gracefully. SELECT DISTINCT applied to prevent duplicates from the Deposit LEFT JOIN.

---

## 8. Sample Queries

### 8.1 Investigate a specific withdrawal payment leg

```sql
SELECT FundingID, FundingTypeID, PaymentDetails, Name AS Country,
       WithdrawID, CashoutStatusID, Amount, ProcessCurrencyID, CashoutTypeID,
       IsBlocked, BlockedDescription, CreationDate
FROM Billing.FundingDataForWithdraw WITH (NOLOCK)
WHERE ID = @WithdrawToFundingID
```

### 8.2 Find all pending-review withdrawals with payment details

```sql
SELECT ID, FundingID, FundingTypeID, PaymentDetails,
       WithdrawID, Amount, ProcessCurrencyID, CashoutTypeID,
       Name AS Country, ModificationDate
FROM Billing.FundingDataForWithdraw WITH (NOLOCK)
WHERE CashoutStatusID = 14  -- Pending Review
ORDER BY ModificationDate DESC
```

### 8.3 Find all withdrawals for a specific funding instrument

```sql
SELECT ID, WithdrawID, CashoutStatusID, Amount, ProcessCurrencyID,
       CashoutTypeID, CreationDate, PaymentDetails
FROM Billing.FundingDataForWithdraw WITH (NOLOCK)
WHERE FundingID = @FundingID
ORDER BY ID DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYUA-992 | Jira (referenced in DDL comment) | Initial implementation of this view by Maksym (4/10/2020) for withdrawal investigation workflow |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 40 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 1 Jira (DDL comment ref) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingDataForWithdraw | Type: View | Source: etoro/etoro/Billing/Views/Billing.FundingDataForWithdraw.sql*
