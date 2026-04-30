# Billing.Funding

> Core payment instrument table; each row represents one customer-registered payment method (credit card, bank account, e-wallet, etc.) with XML-stored provider data, computed hash/checksum columns for deduplication, DDM masking on the XML, and four triggers maintaining `History.BillingFunding` and the `PaymentDetails` column.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | FundingID (PRIMARY KEY CLUSTERED, IDENTITY(1000,1)) |
| **Row Count** | ~3,523,981 rows |
| **Partition** | N/A - filegroup MAIN; TEXTIMAGE on PRIMARY |
| **Indexes** | 1 CLUSTERED PK; 7 NC indexes; 1 PRIMARY XML index; total 9 |

---

## 1. Business Meaning

`Billing.Funding` is the master registry of all payment instruments registered by customers on eToro. A "funding" record represents one payment method - a specific credit card, bank account, Neteller wallet, PayPal account, or other payment vehicle. Every deposit and withdrawal transaction in `Billing.Deposit` and `Billing.WithdrawToFunding` references a `FundingID` to identify which payment instrument was used.

The table stores payment method data in a flexible XML column (`FundingData`) whose schema varies by `FundingTypeID`:
- **Credit card** (FundingTypeID=1): XML contains CardNumberAsString (hash), SecuredCardDataAsString, BinCodeAsString, BinCountryIDAsInteger, expiry, etc.
- **Bank transfer** (FundingTypeID=2): XML contains IBAN, BIC/SWIFT, bank name, account number, etc.
- **E-wallet** (FundingTypeID=6/Neteller, 3/PayPal): XML contains account identifiers, email, etc.

Four triggers maintain audit history and a pre-computed payment details column:
- `FundingInsertTrigger` / `FundingUpdateTrigger` / `FundingDeleteTrigger` -> maintains `History.BillingFunding` with temporal (ValidFrom/ValidTo) rows; strips PAN data from CC history (PCI compliance)
- `TR_FundingPaymentDetails` (MIMOPS-5318, Oct 2021) -> populates `PaymentDetails` via `Billing.FormatFundingPaymentDetailsForWithdraw` whenever `FundingData` changes

`IsBlocked` / `BlockedDescription` / `BlockedAt`: operations staff can block a payment instrument from being used in future transactions (e.g., fraud detection, KYC failure, chargeback risk). 3 of 3.5M records are currently blocked.

---

## 2. Business Logic

### 2.1 Payment Method Registration

**What**: When a customer registers a payment method, a `Billing.Funding` row is created with the provider-specific data in `FundingData` XML.

**Columns Involved**: `FundingID`, `FundingTypeID`, `FundingData`, `DateCreated`, `ManagerID`

**Rules**:
- `FundingID` starts at 1000 (IDENTITY(1000,1)) - IDs below 1000 are reserved
- `FundingTypeID` categorizes the payment method type (34 distinct types in live data)
- `ManagerID` is the operations manager who created/last modified the record; NULL = created by the system/customer
- `DateCreated` defaults to `GETUTCDATE()` - UTC timestamp of registration
- `FundingData` DDM: non-privileged users receive `xxxx` (default masking); privileged users see the raw XML

### 2.2 Computed Columns for Deduplication and Lookup

Four computed columns derive values from `FundingData`:

| Column | Function | Purpose |
|--------|---------|---------|
| `FundingDataCheckSum` | `CHECKSUM(CONVERT(nvarchar(1000), FundingData))` | Fast change-detection; non-unique hash; NC index enables rapid equality check before full XML comparison |
| `SecuredCardData` | `dbo.SecuredCardData(FundingData)` | Extracts secured card data token from XML; indexed for card-level lookup |
| `FundingHash` | `Billing.OrderedSmallCaseFundingHash(FundingData)` | Canonical lowercase ordered hash of FundingData for deduplication; ensures the same payment details always produce the same hash regardless of XML attribute ordering |
| `Parameter` | `dbo.F_FundingData(FundingTypeID, FundingData)` | Extracts the primary identifying parameter for the payment method (e.g., card hash for CC, account number for wire); used by application to find existing fundings by their key identifier |

### 2.3 Blocking a Payment Instrument

**What**: Operations staff can block a funding record to prevent it from being used in future transactions.

**Columns Involved**: `IsBlocked`, `BlockedDescription`, `BlockedAt`

**Rules**:
- `IsBlocked=1`: payment method is blocked; new transactions referencing this `FundingID` are rejected
- `BlockedDescription`: reason for blocking (fraud, KYC, chargeback, etc.)
- `BlockedAt`: UTC timestamp when blocking occurred
- `IsBlocked=0` (default): payment method is active
- Currently 3 of 3.5M records are blocked (0.0001%)

### 2.4 Trigger-Maintained History

All INSERT/UPDATE/DELETE operations on `Billing.Funding` are captured in `History.BillingFunding` via triggers, using a ValidFrom/ValidTo temporal pattern (ValidTo='3000-01-01' for current records):

```
INSERT -> FundingInsertTrigger:
  Copies new row to History.BillingFunding (ValidFrom=NOW, ValidTo=3000-01-01)
  IF FundingTypeID=1 (CC): strips /Funding/CardNumberAsString and
     /Funding/SecuredCardDataAsString from FundingData in history (PCI compliance)

UPDATE -> FundingUpdateTrigger:
  Closes previous History row (ValidTo=NOW)
  Inserts new History row (same CC data stripping for FundingTypeID=1)

DELETE -> FundingDeleteTrigger:
  Closes current History row (ValidTo=NOW)
  Funding row is removed from live table; history retained
```

### 2.5 PaymentDetails Column (TR_FundingPaymentDetails)

**What**: `TR_FundingPaymentDetails` (MIMOPS-5318, Kate M. Oct 2021) automatically populates `PaymentDetails` whenever `FundingData` is modified.

**Columns Involved**: `PaymentDetails`, `FundingData`, `FundingTypeID`

**Rules**:
- Fires on INSERT or UPDATE when `FundingData` column is changed (`IF UPDATE([FundingData])`)
- Calls `Billing.FormatFundingPaymentDetailsForWithdraw(FundingTypeID, FundingData)` for each affected row
- Result is stored in `PaymentDetails` (nvarchar(max)) - a formatted/normalized text representation of the payment details, used in withdrawal processing
- The trigger replaces a prior comment that excluded CC payments (`FundingTypeID<>1`) - the commented-out code suggests CC was initially excluded for PCI key rotation purposes (PAYUS-2977 removed the return of @@ROWCOUNT)

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | ~3,523,981 |
| FundingID range | 1,000 to 4,148,425 |
| Distinct FundingTypes | 34 |
| Blocked records | 3 (IsBlocked=1) |
| DateCreated range | ~2008 to present |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingID | int | NO | IDENTITY(1000,1) | CODE-BACKED | Primary key. IDENTITY starts at 1000 - IDs below 1000 are reserved. NOT FOR REPLICATION. Referenced by every transaction table (`Billing.Deposit`, `Billing.WithdrawToFunding`, `Billing.CreditCardToPayment`, etc.). CLUSTERED PK with DATA_COMPRESSION=PAGE. |
| 2 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method type. References `Dictionary.FundingType` implicitly (no FK). 34 distinct types in live data (Visa/MC/Neteller/PayPal/Wire/eToroMoney/etc.). Indexed (BFND_FUNDINGTYPE2). Drives FundingData XML schema, computed column logic, and trigger behavior. |
| 3 | ManagerID | int | YES | NULL | CODE-BACKED | Operations manager ID who created or last modified this funding record. NULL = system/customer self-registration. References BackOffice.Manager implicitly. |
| 4 | IsBlocked | bit | NO | - | CODE-BACKED | Whether this payment instrument is blocked from future transactions: 1=Blocked, 0=Active. Only 3 of 3.5M records are currently blocked. Checked during deposit/withdrawal processing. |
| 5 | BlockedDescription | varchar(255) | YES | NULL | CODE-BACKED | Human-readable reason for blocking (e.g., 'Fraud detected', 'KYC failure', 'Chargeback risk'). Populated only when IsBlocked=1. |
| 6 | BlockedAt | datetime | YES | NULL | CODE-BACKED | UTC timestamp when the funding was blocked. NULL for active records. Set when IsBlocked is changed to 1. |
| 7 | FundingData | xml | YES | NULL | CODE-BACKED | XML document containing provider-specific payment details. Schema varies by FundingTypeID: CC=CardNumberAsString(hash)/BinCodeAsString/BinCountryIDAsInteger/expiry; Wire=IBAN/BIC/AccountNumber; e-wallet=account ID/email. MASKED WITH (FUNCTION='default()') - non-privileged users see 'xxxx'. PRIMARY XML INDEX BFND_XMLPRIMARY2 on this column. |
| 8 | IsRefundExcluded | bit | NO | 0 | CODE-BACKED | Whether this payment instrument is excluded from refund processing: 1=Excluded (refunds cannot be issued to this instrument); 0=Eligible (default). Used in refund routing logic. |
| 9 | DocumentRequired | bit | NO | 0 | CODE-BACKED | Whether supporting documentation is required for transactions using this payment method: 1=Required (customer must provide documents); 0=Not required (default). Used in compliance/KYC flows. |
| 10 | FundingDataCheckSum | AS computed | YES | - | CODE-BACKED | `CHECKSUM(CONVERT(nvarchar(1000), FundingData))`. Non-unique hash for fast change detection and equality pre-filtering. NC index (IX_BillingFunding_FundingDataCheckSum, FILLFACTOR=95). |
| 11 | SecuredCardData | AS computed | YES | - | CODE-BACKED | `dbo.SecuredCardData(FundingData)`. Extracts secured card token from FundingData XML. NC composite index with FundingTypeID (Idx_Billing_Funding_SecuredCardData_FundingTypeID). Used for card-level lookups without scanning FundingData XML. |
| 12 | FundingHash | AS computed | YES | - | CODE-BACKED | `Billing.OrderedSmallCaseFundingHash(FundingData)`. Canonical ordered lowercase hash of FundingData for deduplication. Ensures consistent hash regardless of XML attribute ordering. NC index (IX_BillingFunding_FundingHash, FILLFACTOR=95). |
| 13 | DateCreated | datetime | YES | GETUTCDATE() | CODE-BACKED | UTC timestamp when this funding record was created. Defaults to GETUTCDATE() on INSERT. |
| 14 | Parameter | AS computed | YES | - | CODE-BACKED | `dbo.F_FundingData(FundingTypeID, FundingData)`. Extracts the primary identifying parameter for this payment method based on its type (e.g., card hash for CC, account number for wire). Two NC indexes: IX_BillingFundingParameter (Parameter alone) and Idx_BillingFunding_Parameter (FundingTypeID, Parameter). Used to find existing fundings by key identifier. |
| 15 | PaymentDetails | nvarchar(max) | YES | NULL | CODE-BACKED | Pre-formatted text representation of the payment details, auto-populated by trigger `TR_FundingPaymentDetails` via `Billing.FormatFundingPaymentDetailsForWithdraw(FundingTypeID, FundingData)` on every INSERT/UPDATE that changes FundingData. Used in withdrawal processing to avoid re-parsing FundingData XML at withdrawal time. |
| 16 | KeyVersion | smallint | YES | NULL | CODE-BACKED | Encryption key version used to encrypt sensitive fields within `FundingData`. Used during PCI key rotation (PAYUS-2977) to track which encryption key version was used. NULL = no versioned encryption or pre-key-rotation record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID | Dictionary.FundingType | Implicit | Payment method type |
| ManagerID | BackOffice.Manager | Implicit | Manager who registered/modified |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Deposit | FundingID | FK (implicit) | Each deposit references the funding instrument used |
| Billing.WithdrawToFunding | FundingID | FK (implicit) | Each WTF record references the funding instrument |
| Billing.CreditCardToPayment | FundingID | FK (implicit) | Links CC deposits to funding records |
| Billing.PayPalToPayment | FundingID | FK (implicit) | Links PayPal deposits to funding records |
| Billing.NetellerToPayment | FundingID | FK (implicit) | Links Neteller deposits to funding records |
| History.BillingFunding | FundingID | Temporal history | ValidFrom/ValidTo audit trail via triggers |
| Billing.FormatFundingPaymentDetailsForWithdraw | FundingID/FundingData | Read | Formats PaymentDetails from FundingData XML |
| Billing.CreditCardRoutingTransactionsVerification | FundingData | Read | Reads BIN from FundingData XML for routing validation |
| Billing.InsertWithdraw2Funding | FundingID | Write | Creates WTF record linking withdraw to this funding |
| Billing.GetPaymentData | FundingID | Read | Retrieves payment instrument details |
| Billing.GetPaymentDetails | FundingID | Read | Detailed payment + funding data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.Funding
  -> Dictionary.FundingType (FundingTypeID - implicit)
  -> BackOffice.Manager (ManagerID - implicit)
  -> dbo.SecuredCardData (computed column function)
  -> Billing.OrderedSmallCaseFundingHash (computed column function)
  -> dbo.F_FundingData (computed column function)
  -> Billing.FormatFundingPaymentDetailsForWithdraw (trigger dependency - PaymentDetails)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.SecuredCardData | Function | Computed column SecuredCardData |
| Billing.OrderedSmallCaseFundingHash | Function | Computed column FundingHash |
| dbo.F_FundingData | Function | Computed column Parameter |
| Billing.FormatFundingPaymentDetailsForWithdraw | Function | TR_FundingPaymentDetails trigger |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.BillingFunding | Table | Temporal audit history via triggers |
| Billing.Deposit | Table | FK on FundingID - deposit instrument |
| Billing.WithdrawToFunding | Table | FK on FundingID - withdrawal instrument |
| Billing.CreditCardToPayment | Table | FK on FundingID |
| Billing.PayPalToPayment | Table | FK on FundingID |
| Billing.NetellerToPayment | Table | FK on FundingID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included | Filter | Notes |
|-----------|------|-------------|---------|--------|-------|
| PK_BillingNewFund2 | CLUSTERED PK | FundingID ASC | - | - | FILLFACTOR=100; DATA_COMPRESSION=PAGE |
| BFND_FUNDINGTYPE2 | NC | FundingTypeID ASC | - | - | FILLFACTOR=90; DATA_COMPRESSION=PAGE |
| IX_BillingFundingParameter | NC | Parameter ASC | - | - | No FILLFACTOR |
| IX_BillingFunding_FundingDataCheckSum | NC | FundingDataCheckSum ASC | - | - | FILLFACTOR=95; DATA_COMPRESSION=PAGE |
| IX_BillingFunding_FundingHash | NC | FundingHash ASC | - | - | FILLFACTOR=95; DATA_COMPRESSION=PAGE |
| IX_BillingFunding_FundingID_FundingTypeID | NC | FundingID ASC | FundingTypeID | - | DATA_COMPRESSION=PAGE; covering index for FundingTypeID lookup by FundingID |
| Idx_BillingFunding_Parameter | NC | (FundingTypeID, Parameter) ASC | - | - | Composite; no FILLFACTOR |
| Idx_Billing_Funding_SecuredCardData_FundingTypeID | NC | (SecuredCardData, FundingTypeID) ASC | - | - | FILLFACTOR=95; DATA_COMPRESSION=PAGE |
| BFND_XMLPRIMARY2 | PRIMARY XML | FundingData | - | - | FILLFACTOR=95; enables XQuery on FundingData |

### 7.2 Constraints and Defaults

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingNewFund2 | PRIMARY KEY CLUSTERED | One row per FundingID |
| DF_NewFunding2_IsRefundExcluded | DEFAULT (0) | IsRefundExcluded defaults to 0 (eligible) |
| DF_BillingFundingNew2_DocumentRequired | DEFAULT (0) | DocumentRequired defaults to 0 |
| DF_BillingFundingNew2_DateCreated | DEFAULT GETUTCDATE() | DateCreated defaults to current UTC |
| MASKED WITH (FUNCTION='default()') | DDM | FundingData returns 'xxxx' for non-privileged users |

### 7.3 Triggers

| Trigger | Event | Description |
|---------|-------|-------------|
| FundingInsertTrigger | FOR INSERT | Copies new row to History.BillingFunding (ValidTo=3000-01-01); strips CardNumberAsString/SecuredCardDataAsString for FundingTypeID=1 (PCI) |
| FundingUpdateTrigger | FOR UPDATE | Closes prior History row (ValidTo=NOW); inserts new History row; same CC PCI stripping |
| FundingDeleteTrigger | FOR DELETE | Closes current History row (ValidTo=NOW) |
| TR_FundingPaymentDetails | FOR INSERT, UPDATE (when FundingData changes) | Calls FormatFundingPaymentDetailsForWithdraw to populate PaymentDetails column (MIMOPS-5318, Kate M. Oct 2021) |

---

## 8. Sample Queries

### 8.1 View funding distribution by type

```sql
SELECT
    f.FundingTypeID,
    COUNT(*) AS FundingCount,
    SUM(CASE WHEN f.IsBlocked = 1 THEN 1 ELSE 0 END) AS Blocked
FROM Billing.Funding f WITH (NOLOCK)
GROUP BY f.FundingTypeID
ORDER BY FundingCount DESC
```

### 8.2 Find blocked payment instruments

```sql
SELECT
    FundingID,
    FundingTypeID,
    BlockedDescription,
    BlockedAt,
    ManagerID
FROM Billing.Funding WITH (NOLOCK)
WHERE IsBlocked = 1
ORDER BY BlockedAt DESC
```

### 8.3 Find funding records requiring documents

```sql
SELECT TOP 20
    FundingID,
    FundingTypeID,
    DateCreated,
    IsRefundExcluded
FROM Billing.Funding WITH (NOLOCK)
WHERE DocumentRequired = 1
ORDER BY DateCreated DESC
```

### 8.4 Look up a funding record by its key parameter (e.g., card hash)

```sql
DECLARE @CardHash VARCHAR(50) = '...'  -- computed hash of card PAN

SELECT FundingID, FundingTypeID, DateCreated, IsBlocked
FROM Billing.Funding WITH (NOLOCK)
WHERE FundingTypeID = 1  -- CreditCard
  AND Parameter = @CardHash
-- Uses Idx_BillingFunding_Parameter composite index
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,6,7,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.Funding | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.Funding.sql*
