# Billing.FundingDataForDeposit

> Comprehensive deposit investigation view that joins a deposit transaction with its payment instrument details and any associated credit/chargeback/refund ledger entry, providing full payment context in one query for operations and risk workflows.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | View |
| **Key Identifier** | DepositID (from Billing.Deposit) + FundingID (from Billing.Funding) |
| **Partition** | N/A |
| **Indexes** | N/A for view |

---

## 1. Business Meaning

`Billing.FundingDataForDeposit` is the primary ad-hoc query view for investigating a deposit transaction. It presents all three dimensions of a deposit in a single result set: the deposit record (payment status, amount, currency, routing, dates), the funding instrument used (payment method, block status, XML-stored card/account data), and any credit ledger entries linked to the deposit (the approval credit, chargeback, refund, or refund-as-chargeback).

The view exists because most deposit investigations require all three layers simultaneously: "show me the deposit amount and status, what card/account was used, and whether money was credited or reversed." Without this view, a backoffice agent or SP would need to write a multi-table join every time. The comment in the DDL references PAYUA-9992, indicating this was built for a specific workflow need.

Data flows from three sources: `Billing.Deposit` (INNER JOIN - every deposit must have a Funding record), `Billing.Funding` (INNER JOIN - every deposit is made via a registered payment instrument), and `History.Credit` (LEFT JOIN - not all deposits have a credit entry; credit entries are filtered to deposit-related credit types: 1=Deposit, 11=Chargeback, 12=Refund, 16=Refund As ChargeBack). Note: History.Credit is in EtoroArchive and requires that database to be accessible - the view cannot be queried without EtoroArchive access.

---

## 2. Business Logic

### 2.1 PaymentDetails - Human-Readable Account Identifier per FundingType

**What**: The view extracts a human-readable payment account identifier from the XML-stored FundingData column, with logic specific to each payment method type.

**Columns/Parameters Involved**: `FundingTypeID`, `FundingData` (XML), `PaymentDetails`

**Rules**:
- FundingTypeID = 1 (CreditCard): Returns '...' (card details are masked/hidden for PCI compliance)
- FundingTypeID = 3 or 8 (PayPal/similar): Email address from XML `/Funding/EmailAsString`
- FundingTypeID = 7 or 10 (Neteller/similar): '#' + AccountID from XML `/Funding/AccountIDAsDecimal`
- FundingTypeID = 11 (bank transfer): IBAN if available ('#' + IBAN), else 'AccID:#' + AccountID
- FundingTypeID = 6 (Neteller): '#' + AccountID + '; ' + email
- FundingTypeID = 17 (UnionPay?): BankCode from XML
- FundingTypeID = 2 (WireTransfer): IBAN from Deposit.PaymentData XML
- FundingTypeID = 29 or 32 (ACH): Bank Name, last 4 digits, account type concatenated
- FundingTypeID = 33 (eToroMoney): PlatformAccountId from XML
- FundingTypeID = 34 (SEPA?): IBAN + BIC/SWIFT + Bank Name + Account Holder Name from Deposit.PaymentData
- All other types: NULL

### 2.2 Credit Ledger Join - Deposit Settlement Tracking

**What**: The LEFT JOIN to History.Credit links each deposit to its financial settlement record in the credit ledger, enabling visibility into whether money actually moved.

**Columns/Parameters Involved**: `CreditTypeID`, `Credit`, `Payment`, `Occurred`, `DepositRollbackID`

**Rules**:
- CreditTypeID = 1 (Deposit): The credit entry created when the deposit was approved; `Credit` = amount credited to customer account; `Payment` = payment amount
- CreditTypeID = 11 (Chargeback): Credit entry reversing the deposit when a chargeback was filed; `Credit` = negative amount (debit to customer)
- CreditTypeID = 12 (Refund): Credit entry for a processed refund
- CreditTypeID = 16 (Refund As ChargeBack): A refund classified as a chargeback for accounting purposes
- NULL values in Occurred/Credit/Payment: deposit has no credit ledger entry yet (pending, declined, or no archive access)
- Additional filter: `HC.DepositID >= 1` excludes DepositID=0 edge cases in the archive

---

## 3. Data Overview

N/A for this view - History.Credit is in EtoroArchive (database inaccessible to read-only MCP connection). The view cannot be queried without EtoroArchive access.

Representative row structure:
- A successful EUR deposit of $200 via credit card: FundingTypeID=1, PaymentStatusID=2 (Approved), Amount=200, CurrencyID=2, CreditTypeID=1, Credit=200, PaymentDetails='...' (CC masked)
- A reversed deposit (chargeback): same DepositID but CreditTypeID=11, Credit=-200 (debit)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingID | int | NO | - | CODE-BACKED | Payment instrument identifier. From Billing.Funding. FK to Billing.Deposit.FundingID. Identifies which registered payment method (card, bank account, wallet) was used for this deposit. |
| 2 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method category. From Billing.Funding. 1=CreditCard, 2=WireTransfer, 3=PayPal, 6=Neteller, 7=Skrill, 8=similar, 10=similar, 11=bank, 17=UnionPay, 29/32=ACH, 33=eToroMoney, 34=SEPA. Drives the PaymentDetails CASE expression and controls which XML fields are parsed. See Billing.Funding.md for full type map. |
| 3 | ManagerID | int | YES | - | CODE-BACKED | Manager/operator ID from Billing.Funding. NULL = customer self-registered payment method. Non-NULL = operations staff created or last modified the instrument. Distinct from DepositManagerID (Element 8) which comes from Billing.Deposit. |
| 4 | IsBlocked | bit | NO | - | CODE-BACKED | From Billing.Funding. 1=this payment instrument is blocked from use in future transactions. 0=active. Blocking is set by operations staff for fraud/KYC/chargeback-risk reasons. The view exposes this so investigators can see if the card/account was blocked after this deposit was made. |
| 5 | BlockedDescription | nvarchar | YES | - | CODE-BACKED | From Billing.Funding. Human-readable reason for the block (e.g., "Chargeback risk", "Stolen card"). NULL if IsBlocked=0. |
| 6 | BlockedAt | datetime | YES | - | CODE-BACKED | From Billing.Funding. UTC timestamp when IsBlocked was set to 1. NULL if not blocked. |
| 7 | FundingData | nvarchar(4000) | YES | - | CODE-BACKED | Payment method XML data from Billing.Funding, CAST to NVARCHAR(4000). Truncated from the original XML type for display. Contains provider-specific payment details (card hash, IBAN, account numbers, etc.) varying by FundingTypeID. Subject to Dynamic Data Masking - non-privileged users see 'xxxx'. |
| 8 | IsRefundExcluded | bit | NO | - | CODE-BACKED | From Billing.Funding. 1=this payment instrument is excluded from automatic refund processing. 0=eligible for refunds. Set by operations for instruments that cannot receive refunds (e.g., prepaid cards, gift cards). |
| 9 | DocumentRequired | bit | NO | - | CODE-BACKED | From Billing.Funding. 1=additional documentation is required before this payment instrument can process transactions. 0=no documentation hold. |
| 10 | DateCreated | datetime | NO | - | CODE-BACKED | From Billing.Funding. UTC timestamp when the payment instrument was first registered on eToro. Useful for detecting whether the card was newly registered just before this deposit (potential fraud signal). |
| 11 | DepositID | int | NO | - | CODE-BACKED | Primary key of the deposit transaction. From Billing.Deposit (IDENTITY PK). Uniquely identifies this deposit attempt. |
| 12 | CID | int | NO | - | CODE-BACKED | Customer ID from Billing.Deposit. FK to Customer schema. The customer who initiated this deposit. |
| 13 | CurrencyID | int | NO | - | CODE-BACKED | Deposit currency. From Billing.Deposit. References Dictionary.Currency. CurrencyID=1=USD (eToro base), 2=EUR, 3=GBP, etc. |
| 14 | PaymentStatusID | int | NO | - | CODE-BACKED | Current deposit status. From Billing.Deposit. Key values: 1=New, 2=Approved, 3=Declined, 5=InProcess, 11=Chargeback, 12=Refund, 13=Pending. References Dictionary.PaymentStatus. See Billing.Deposit.md Section 2.1 for full state machine. |
| 15 | DepositManagerID | int | YES | - | CODE-BACKED | Manager ID from Billing.Deposit (aliased from DepositManagerID). The operations staff member who last touched this deposit record. Distinct from ManagerID (Element 3) which is the Funding instrument's manager. NULL for system-processed deposits. |
| 16 | RiskManagementStatusID | int | YES | - | CODE-BACKED | Risk management decision status. From Billing.Deposit. References Dictionary.RiskManagementStatus. Non-NULL when a risk rule was triggered for this deposit. |
| 17 | Amount | decimal | NO | - | CODE-BACKED | Deposit amount in the deposit currency (CurrencyID). From Billing.Deposit. The amount before conversion to USD. |
| 18 | ExchangeRate | decimal | YES | - | CODE-BACKED | Exchange rate applied when converting from CurrencyID to USD. From Billing.Deposit. NULL for USD deposits. |
| 19 | PaymentDate | datetime | YES | - | CODE-BACKED | Date when the payment was processed by the provider. From Billing.Deposit. May be NULL for pending/declined deposits. |
| 20 | ModificationDate | datetime | NO | - | CODE-BACKED | Last modification timestamp of the deposit record. From Billing.Deposit. Updated by any status change or update SP. |
| 21 | TransactionID | varchar | YES | - | CODE-BACKED | Provider's transaction reference number. From Billing.Deposit. The ID assigned by the payment processor (e.g., Adyen, Checkout.com reference). Used for provider reconciliation. |
| 22 | IPAddress | varchar | YES | - | CODE-BACKED | Customer's IP address at time of deposit. From Billing.Deposit. Used for fraud and geolocation analysis. |
| 23 | Approved | bit | YES | - | CODE-BACKED | Quick approval flag from Billing.Deposit. 1=deposit was approved (PaymentStatusID=2). 0 or NULL=not approved. Redundant with PaymentStatusID=2 but convenient for filtering. |
| 24 | Commission | decimal | YES | - | CODE-BACKED | Commission amount charged on this deposit. From Billing.Deposit. |
| 25 | PaymentData | nvarchar(4000) | YES | - | CODE-BACKED | Provider response XML from Billing.Deposit, CAST to NVARCHAR(4000). Contains provider-specific response data (authorization codes, decline reasons, etc.) varying by payment method. |
| 26 | ClearingHouseEffectiveDate | datetime | YES | - | CODE-BACKED | Clearing house settlement date. From Billing.Deposit. For bank wire and ACH deposits that have delayed settlement. |
| 27 | OldPaymentID | int | YES | - | CODE-BACKED | Previous payment/deposit ID if this deposit replaced or is linked to an older record. From Billing.Deposit. Used in migration/retry scenarios. |
| 28 | IsFTD | bit | NO | - | CODE-BACKED | First-time deposit flag. From Billing.Deposit. 1=this was the customer's first approved deposit on eToro. Drives marketing attribution events (AppsFlyer, pixel firing, affiliate commissions). |
| 29 | ProcessorValueDate | datetime | YES | - | CODE-BACKED | Value date assigned by the payment processor. From Billing.Deposit. For bank-type payments that have a settlement date separate from the processing date. |
| 30 | RefundVerificationCode | varchar | YES | - | CODE-BACKED | Verification code required to authorize a refund on this deposit. From Billing.Deposit. Security measure to prevent unauthorized refunds. |
| 31 | DepotID | int | YES | - | CODE-BACKED | Payment gateway/terminal (depot) that processed this deposit. From Billing.Deposit. FK to Billing.Depot. Identifies which MID/acquirer processed the transaction for routing and reconciliation. |
| 32 | MatchStatusID | int | YES | - | CODE-BACKED | Matching/reconciliation status with provider statement. From Billing.Deposit. Used in the deposit matching workflow. |
| 33 | FunnelID | int | YES | - | CODE-BACKED | Marketing funnel identifier associated with this deposit. From Billing.Deposit. Links the deposit to a specific acquisition campaign or funnel. |
| 34 | Code | varchar | YES | - | CODE-BACKED | Deposit code reference. From Billing.Deposit. |
| 35 | ExTransactionID | varchar | YES | - | CODE-BACKED | External transaction ID from the payment provider's system. From Billing.Deposit. Secondary provider reference for reconciliation. |
| 36 | CampaignCodeID | int | YES | - | CODE-BACKED | Campaign code associated with this deposit. From Billing.Deposit. Links to a promotional campaign for bonus attribution. |
| 37 | BonusStatusID | int | YES | - | CODE-BACKED | Status of the bonus awarded for this deposit. From Billing.Deposit. References Dictionary.BonusStatus. |
| 38 | BonusAmount | decimal | YES | - | CODE-BACKED | Amount of bonus credited in connection with this deposit. From Billing.Deposit. |
| 39 | BonusErrorCode | int | YES | - | CODE-BACKED | Error code if bonus processing failed for this deposit. From Billing.Deposit. NULL if bonus processed successfully or no bonus applied. |
| 40 | SessionID | varchar | YES | - | CODE-BACKED | Session identifier from the customer's web session at deposit time. From Billing.Deposit. Used for session-level fraud analysis. |
| 41 | DepositTypeID | int | YES | - | CODE-BACKED | Deposit type category. From Billing.Deposit. References Dictionary.DepositType. Distinguishes standard deposits from recurring, internal transfers, etc. |
| 42 | StatusReasonID | int | YES | - | CODE-BACKED | Specific reason code for the current PaymentStatusID. From Billing.Deposit. Provides granular decline/hold reason beyond the status alone. |
| 43 | DRStatusID | int | YES | - | CODE-BACKED | Dispute Resolution status ID. From Billing.Deposit. Tracks the chargeback dispute process status. |
| 44 | DRDate | datetime | YES | - | CODE-BACKED | Dispute Resolution date. From Billing.Deposit. When the DR case was opened or last updated. |
| 45 | ProtocolMIDSettingsID | int | YES | - | CODE-BACKED | The specific Protocol-MID combination used for this deposit. From Billing.Deposit. FK to Billing.ProtocolMIDSettings. Identifies the acquirer configuration used. |
| 46 | ExchangeFee | decimal | YES | - | CODE-BACKED | FX exchange fee charged for this deposit. From Billing.Deposit. The flat/percentage fee applied to convert from deposit currency to USD. |
| 47 | BaseExchangeRate | decimal | YES | - | CODE-BACKED | Base (mid-market) exchange rate before fee markup. From Billing.Deposit. The raw FX rate used as the starting point for ExchangeRate calculation. |
| 48 | PaymentDetails | varchar | YES | - | CODE-BACKED | Computed human-readable payment account identifier. CASE expression on FundingTypeID parsing FundingData XML: e-wallet email, bank IBAN/account#, eToroMoney platform ID, ACH bank+last4, SEPA IBAN+BIC+holder. Returns '...' for credit cards (PCI masking). NULL for unhandled FundingTypes. Key column for operations staff identifying the payment account without reading raw XML. |
| 49 | CardTypeIDasInteger | int | YES | - | CODE-BACKED | Card type ID extracted from FundingData XML: `/Funding/CardTypeIDAsInteger`. Only populated for credit card payments (FundingTypeID=1). References Dictionary.CardType. |
| 50 | BinCodeAsString | varchar(50) | YES | - | CODE-BACKED | Bank Identification Number (BIN/IIN) of the credit card, extracted from FundingData XML: `/Funding/BinCodeAsString`. First 6 digits of the card number identifying the issuing bank. Only populated for credit card payments. Used for bank routing, country detection, and fraud analysis. |
| 51 | Occurred | datetime | YES | - | CODE-BACKED | Timestamp when the credit/chargeback/refund event occurred. From History.Credit (LEFT JOIN). NULL if no credit ledger entry exists for this deposit. |
| 52 | DepositRollbackID | int | YES | - | CODE-BACKED | Rollback tracking ID from History.Credit. Non-NULL when this credit entry is associated with a deposit rollback. References Billing.DepositRollbackTracking. |
| 53 | CreditTypeID | int | YES | - | CODE-BACKED | Credit event type from History.Credit. 1=Deposit (initial credit when approved), 11=Chargeback, 12=Refund, 16=Refund As ChargeBack. NULL if no credit entry. Distinguishes the type of financial movement associated with this deposit. |
| 54 | Credit | decimal | YES | - | CODE-BACKED | Amount credited/debited in the credit ledger event. From History.Credit. Positive for deposits and refunds (money to customer); negative for chargebacks (money from customer). NULL if no credit entry. |
| 55 | Payment | decimal | YES | - | CODE-BACKED | Payment amount in the credit event. From History.Credit. Represents the payment provider settlement amount. May differ from Credit when FX conversion is involved. NULL if no credit entry. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingID, FundingTypeID, FundingData, IsBlocked, ... | Billing.Funding | Source (INNER JOIN on FundingID) | Payment instrument data; every deposit must have a linked funding record |
| DepositID, CID, Amount, PaymentStatusID, ... | Billing.Deposit | Source (INNER JOIN) | Deposit transaction; primary entity in this view |
| Occurred, Credit, CreditTypeID, ... | History.Credit | Source (LEFT JOIN on DepositID, CreditTypeID IN (1,11,12,16)) | Credit/chargeback/refund ledger entries; EtoroArchive DB |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No stored procedures in Billing schema reference this view | - | - | Operations/admin ad-hoc query view (PAYUA-9992) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.FundingDataForDeposit (view)
├── Billing.Deposit (table)
├── Billing.Funding (table)
└── History.Credit (table, EtoroArchive DB - cross-database, LEFT JOIN)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | FROM/INNER JOIN: deposit transaction records |
| Billing.Funding | Table | INNER JOIN on BDEP.FundingID = BFUN.FundingID: payment instrument records |
| History.Credit | Table (EtoroArchive) | LEFT JOIN on HC.DepositID = BDEP.DepositID AND CreditTypeID IN (1,11,12,16): credit ledger events |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No code-level dependents discovered | - | Ad-hoc operations query view |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. Performance depends on indexes on Billing.Deposit (DepositID clustered PK, FundingID NC index) and Billing.Funding (FundingID clustered PK). History.Credit JOIN may be expensive without EtoroArchive-side DepositID index.

### 7.2 Constraints

N/A for view. No SCHEMABINDING (cross-database LEFT JOIN to EtoroArchive). FundingData and PaymentData are CAST to NVARCHAR(4000) - data beyond 4000 characters is truncated. Note: the DDL has commented-out columns (FundingDataCheckSum, SecuredCardData, Parameter, FundingHash) indicating these were intentionally excluded for security/performance reasons.

---

## 8. Sample Queries

### 8.1 Investigate a specific deposit with full payment details

```sql
-- Requires EtoroArchive access
SELECT FundingID, FundingTypeID, PaymentDetails, BinCodeAsString,
       DepositID, CID, Amount, CurrencyID, PaymentStatusID, IsFTD,
       IsBlocked, BlockedDescription,
       CreditTypeID, Credit, Occurred
FROM Billing.FundingDataForDeposit WITH (NOLOCK)
WHERE DepositID = @DepositID
```

### 8.2 Find all chargebacks for a specific customer

```sql
-- Requires EtoroArchive access
SELECT DepositID, Amount, CurrencyID, PaymentDate, PaymentDetails,
       Occurred AS ChargebackDate, Credit AS ChargebackAmount
FROM Billing.FundingDataForDeposit WITH (NOLOCK)
WHERE CID = @CID
  AND CreditTypeID = 11  -- Chargeback
ORDER BY Occurred DESC
```

### 8.3 Find deposits using a blocked payment instrument

```sql
-- Requires EtoroArchive access
SELECT DepositID, CID, Amount, PaymentStatusID, PaymentDetails,
       BlockedAt, BlockedDescription
FROM Billing.FundingDataForDeposit WITH (NOLOCK)
WHERE IsBlocked = 1
ORDER BY DepositID DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYUA-9992 | Jira (referenced in DDL comment) | Initial implementation of this view for payment investigation workflow |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 55 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 1 Jira (DDL comment ref) | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.FundingDataForDeposit | Type: View | Source: etoro/etoro/Billing/Views/Billing.FundingDataForDeposit.sql*
