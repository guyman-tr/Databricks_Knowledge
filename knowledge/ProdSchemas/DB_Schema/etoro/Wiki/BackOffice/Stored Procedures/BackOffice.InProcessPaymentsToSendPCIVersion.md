# BackOffice.InProcessPaymentsToSendPCIVersion

> Returns the in-process withdrawal payments queue with full processing detail - the main data source for Back Office payment processors to view, filter, and action withdrawals currently being processed, in PCI-compliant form.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingTypeIDs + @RegulationIDs + @IgnorePlayerLevelID filters; returns all approved in-process withdrawal funding records ordered by ModificationDate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`InProcessPaymentsToSendPCIVersion` is the primary query powering the Back Office **in-process payments** screen - the work queue used by payment processors to see which approved withdrawals are currently being processed and take action on them. It returns one row per `Billing.WithdrawToFunding` processing record in an active processing status (CashoutStatusID IN (2,6,8,9,10,11,12,13,14,15)) where the parent withdrawal is `Approved = 1`.

The "PCIVersion" suffix indicates this procedure complies with PCI DSS requirements: full card numbers and other sensitive payment data are not exposed in clear text. It replaces an older non-PCI version. The procedure surfaces all information a payment processor needs: customer identity, payment method, amounts, payment details (with method-specific formatting), MID routing, card details, customer status/level, rejection reason, and audit trail.

Three parameters allow filtering the queue by payment method type (`@FundingTypeIDs`), customer regulation (regulatory region) (`@RegulationIDs`), and by excluding a specific player level (`@IgnorePlayerLevelID` - typically used to exclude internal/test accounts). All filters are optional.

Data flow: Billing ops approve a withdrawal -> parent `Billing.Withdraw.Approved` is set to 1 -> this SP surfaces the matching `Billing.WithdrawToFunding` records for the assigned payment processor -> processor uses the data to submit the payment to the external payment provider -> on completion, the processing record CashoutStatusID transitions out of the active range.

---

## 2. Business Logic

### 2.1 In-Process Queue Filter

**What**: Defines the scope of the queue - only approved withdrawals in active processing states are shown.

**Columns/Parameters Involved**: `CashoutStatusID`, `Approved Withdraw`, `@FundingTypeIDs`, `@RegulationIDs`, `@IgnorePlayerLevelID`

**Rules**:
- `BWTF.CashoutStatusID IN (2, 6, 8, 9, 10, 11, 12, 13, 14, 15)` - active processing statuses (excludes terminal states Processed=3, Cancelled=4, Pending=1)
- `BWDR.Approved = 1` - only approved withdrawals (the two-step approval gate: first authorized by Back Office manager, then appears in processing queue)
- `@FundingTypeIDs`: when provided, filters to specific payment method types (comma-separated, parsed via STRING_SPLIT)
- `@RegulationIDs`: when provided, filters by regulatory region via `BackOffice.Customer.RegulationID` (comma-separated)
- `@IgnorePlayerLevelID > 0`: excludes customers at a specific PlayerLevelID (e.g. to hide internal accounts or a specific customer tier from the queue)

### 2.2 PaymentDetails Field (Method-Specific)

**What**: Payment processor-specific detail string for initiating the payment, constructed per funding method.

**Columns/Parameters Involved**: `PaymentDetails`, `FundingTypeID`, `CashoutTypeID`

**Rules**:
- `FundingTypeID = 2` (Bank Wire): PaymentDetails + BSB number + ClientAddress from WithdrawData XML
- `FundingTypeID = 3, CashoutTypeID = 1` (PayPal new money): Email + PayerID from FundingData XML (MIMOPS-5237)
- `FundingTypeID = 3, CashoutTypeID = 2` (PayPal refund): PayerAsString from Deposit XML
- `FundingTypeID = 10` (WebMoney): AccountID + PurseID from FundingData XML
- `FundingTypeID = 33` (wallet - eToro Money): GCID + PlatformAccountID + CurrencyBalanceID + Bic + AccountNumber + IBAN + SortCode from WithdrawData XML
- `FundingTypeID = 35` (regulated - requires age check): PaymentDetails + BirthDate (dd/MM/yyyy from Customer.Customer)
- `FundingTypeID = 39` (PayID): PayId + Email from WithdrawData XML
- All others: raw `Billing.Funding.PaymentDetails`

### 2.3 MID Resolution (Priority Order)

**What**: Merchant ID used for external payment routing, resolved via a priority chain.

**Columns/Parameters Involved**: `MID`, `DepotID`, `MerchantAccountID`

**Rules**:
- `DepotID IN (35-44)`: use `Billing.ProtocolMIDSettings BPMS2.Value` (linked via Deposit)
- `DepotID = 18`: use `Billing.ProtocolMIDSettings BPMS1.Value` (linked via WithdrawToFunding)
- All other depots: `ISNULL(GetMerchantDetails(MerchantAccountID, 0), ISNULL(BPMS1.Description, ISNULL(BMMC.MID, BPMS1.Value)))` - four-level fallback chain

### 2.4 Request Time from History

**What**: The "Request Time" shown to payment processors is not the row creation date but the last time the processing record entered CashoutActionStatusID=1 (sent for processing).

**Columns/Parameters Involved**: `Request Time`

**Rules**:
- OUTER APPLY: `SELECT TOP 1 ModificationDate FROM History.WithdrawToFundingAction WHERE CashoutActionStatusID = 1 AND BW2F_ID = BWTF.ID ORDER BY ModificationDate DESC`
- This correctly shows the most recent "sent to processor" timestamp, not an original creation date
- Change (2022-09-13): previous version had duplicated rows issue; OUTER APPLY with TOP 1 was the fix

### 2.5 Bank Country ISO Dual-Source Resolution

**What**: The bank country ISO code may come from two XML sources depending on the payment method.

**Columns/Parameters Involved**: `Bank Country ISO`

**Rules**:
- `COALESCE(DCON.Abbreviation, DCFN.Abbreviation, '')`: tries country from `WithdrawData XML CountryIDAsInteger` first (DCON), falls back to `FundingData XML CountryIDAsInteger` (DCFN)
- Added (OPSE-517, Jan 2022) along with Address Country ISO for compliance reporting

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingTypeIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated list of FundingTypeIDs to include (e.g. '1,2,3'). When provided, restricts the queue to specific payment methods. NULL or empty returns all types. Parsed via STRING_SPLIT. |
| 2 | @IgnorePlayerLevelID | INTEGER | YES | 0 | CODE-BACKED | Exclude customers at this PlayerLevelID from results. 0 or NULL disables the filter (all levels included). Typically used to exclude internal or test accounts from the processing queue. |
| 3 | @RegulationIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated list of RegulationIDs to include (e.g. '1,2,3'). Filters by customer's regulatory region from `BackOffice.Customer.RegulationID`. NULL returns all regulations. Parsed via STRING_SPLIT. |

**Output columns (result set):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Customer ID from the parent withdrawal record (`Billing.Withdraw.CID`). |
| 2 | Status | NVARCHAR | YES | - | CODE-BACKED | Human-readable processing status name (`Dictionary.CashoutStatus.Name` on `WithdrawToFunding.CashoutStatusID`). |
| 3 | CashoutStatusID | INT | NO | - | CODE-BACKED | Numeric cashout status of this processing record (`Billing.WithdrawToFunding.CashoutStatusID`). Always in the active range (2,6,8,9,10,11,12,13,14,15) per WHERE clause. |
| 4 | Funding Method | NVARCHAR | NO | - | CODE-BACKED | Human-readable payment method name (`Dictionary.FundingType.Name`). E.g. "Credit Card", "Wire Transfer", "PayPal". |
| 5 | FundingTypeID | INT | NO | - | CODE-BACKED | Numeric funding type identifier (`Billing.Funding.FundingTypeID`). Drives PaymentDetails format (Section 2.2). |
| 6 | Depot | NVARCHAR | YES | - | CODE-BACKED | Name of the payment depot/gateway (`Billing.Depot.Name`). NULL if unassigned. |
| 7 | DepotID | INT | YES | - | CODE-BACKED | Numeric depot ID (`Billing.Depot.DepotID`). Used for MID resolution logic (Section 2.3). |
| 8 | Regulation | NVARCHAR | YES | - | CODE-BACKED | Customer's regulatory region name (`Dictionary.Regulation.Name` via `BackOffice.Customer.RegulationID`). E.g. "CySEC", "ASIC". |
| 9 | Country by Reg. Form | NVARCHAR | YES | - | CODE-BACKED | Customer's country name from their profile (`Dictionary.Country.Name` via `Customer.Customer.CountryID`). |
| 10 | PaymentDetails | VARCHAR(MAX) | YES | - | CODE-BACKED | Method-specific payment routing data. See Section 2.2 for full per-FundingTypeID logic. |
| 11 | Funding ID | INT | NO | - | CODE-BACKED | Primary key of the `Billing.Funding` record linked to this processing attempt. |
| 12 | Withdraw ID | INT | NO | - | CODE-BACKED | Parent withdrawal ID (`Billing.WithdrawToFunding.WithdrawID`). |
| 13 | Withdraw Processing ID | INT | NO | - | CODE-BACKED | Primary key of this `Billing.WithdrawToFunding` processing record. |
| 14 | Amount in USD | DECIMAL(16,2) | NO | 0 | CODE-BACKED | Net disbursement amount (`Billing.WithdrawToFunding.Amount`), formatted to 2 decimal places. |
| 15 | Cashout Type | NVARCHAR | YES | - | CODE-BACKED | Cashout type name (`Dictionary.CashoutType.CashoutTypeName`). Differentiates new money vs. refund cashout paths. |
| 16 | CashoutTypeID | INT | YES | - | CODE-BACKED | Numeric cashout type (`Billing.WithdrawToFunding.CashoutTypeID`). Influences PaymentDetails format for PayPal (FundingTypeID=3). |
| 17 | Amount in Process Currency | DECIMAL(16,2) | NO | 0 | CODE-BACKED | Withdrawal amount expressed in the processing/deposit currency (`Billing.WithdrawToFunding.RefundAmountInDepositCurrency`), cast to 2 decimal places. |
| 18 | Currency | NVARCHAR | NO | - | CODE-BACKED | Processing currency display name: `COALESCE(DisplayName, Abbreviation)` from `Dictionary.Currency` on `ProcessCurrencyID`. |
| 19 | CurrencyID | INT | NO | - | CODE-BACKED | Numeric processing currency ID (`Billing.WithdrawToFunding.ProcessCurrencyID`). |
| 20 | RegulationID | INT | NO | - | CODE-BACKED | Customer's regulatory region ID (`BackOffice.Customer.RegulationID`). Used for `@RegulationIDs` filter and returned for caller to use in grouping. |
| 21 | DepositID | INT | NO | 0 | CODE-BACKED | Linked deposit ID (`Billing.WithdrawToFunding.DepositID`), 0 if NULL. Used for refund-path PayPal and MID resolution for depots 35-44. |
| 22 | FlowID | UNIQUEIDENTIFIER/VARCHAR | YES | - | CODE-BACKED | Correlation ID linking this withdrawal to an external payment flow (`Billing.Withdraw.FlowID`). Added MIMOPSA-13810 (Aug 2024) for distributed tracing and reconciliation with external payment systems. |
| 23 | MID | NVARCHAR | YES | - | CODE-BACKED | Merchant ID for external payment routing. Four-level fallback resolution. See Section 2.3. NULL if unresolved. |
| 24 | Verification Code | NVARCHAR | YES | - | CODE-BACKED | Verification code from the processing record (`Billing.WithdrawToFunding.VerificationCode`), empty string if NULL. Used by certain payment providers to confirm identity. |
| 25 | Vendor Code | NVARCHAR | YES | - | CODE-BACKED | Vendor-specific code from the processing record (`Billing.WithdrawToFunding.VendorCode`), empty string if NULL. Added Aug 2020 for payment vendor tracking. |
| 26 | Rejection Reason | NVARCHAR | YES | - | CODE-BACKED | Most recent remark from `History.WithdrawToFundingAction` matching the current CashoutStatusID, taken by OUTER APPLY TOP 1 ORDER BY WithdrawToFundingActionID DESC. Populated when the processing record is rejected. Added MIMOPS2-4271 (Mar 2026). |
| 27 | Comment | VARCHAR | NO | '' | CODE-BACKED | Always empty string (placeholder). |
| 28 | Processor Value Date | DATETIME | YES | GETUTCDATE() | CODE-BACKED | Value date from the payment processor (`Billing.WithdrawToFunding.ProcessorValueDate`), defaulting to current UTC time if NULL. |
| 29 | Request Time | DATETIME | YES | - | CODE-BACKED | Most recent timestamp when this processing record entered CashoutActionStatusID=1 (sent to processor), from `History.WithdrawToFundingAction`. See Section 2.4. |
| 30 | Email | NVARCHAR | NO | - | CODE-BACKED | Customer's email address (`Customer.Customer.Email`). Used for payment processor communication. |
| 31 | Card Category | NVARCHAR | YES | - | CODE-BACKED | Credit card category (e.g. "Debit", "Credit") from `Dictionary.CountryBin.CardCategory`, resolved via BIN code from FundingData XML. |
| 32 | Brand | NVARCHAR | YES | - | CODE-BACKED | Card brand name (e.g. "Visa", "Mastercard") from `Dictionary.CardType.Name`, resolved via CardTypeID from FundingData XML. |
| 33 | CC Expiry Date | VARCHAR | YES | - | CODE-BACKED | Credit card expiry date formatted as "MM/YY" - parsed from FundingData XML ExpirationDateAsString with "/" inserted at position 3. |
| 34 | Country by Form | NVARCHAR | YES | - | CODE-BACKED | Duplicate of "Country by Reg. Form" (same expression DCOU.Name). Appears to be retained for backward compatibility. |
| 35 | White Label | NVARCHAR | NO | - | CODE-BACKED | Customer's white label/brand name (`Dictionary.Label.Name` via `Customer.Customer.LabelID`). |
| 36 | WirePayeeName | VARCHAR(MAX) | YES | - | CODE-BACKED | For bank wire (FundingTypeID=2): the payee name from WithdrawData XML (`PayeeNameAsString`). NULL for all other payment types. |
| 37 | Approved Withdraw | VARCHAR(3) | NO | - | CODE-BACKED | Whether the parent withdrawal is approved: "YES" if `Billing.Withdraw.Approved = 1`, "NO" otherwise. Always "YES" given the WHERE clause filter. |
| 38 | Auto Payment Start Date | DATETIME | YES | - | CODE-BACKED | Start date for automatic payment scheduling (`Billing.WithdrawToFunding.AutoPaymentStartDate`). Used for scheduled/deferred payment processing. |
| 39 | Customer Status | NVARCHAR | YES | - | CODE-BACKED | Customer's current player/account status name (`Dictionary.PlayerStatus.Name` via `Customer.Customer.PlayerStatusID`). |
| 40 | Customer Level | NVARCHAR | YES | - | CODE-BACKED | Customer's player level name (`Dictionary.PlayerLevel.Name` via `Customer.Customer.PlayerLevelID`). Added MIMOPS2-4271 (Mar 2026). |
| 41 | Prepared By | NVARCHAR | YES | - | CODE-BACKED | Full name of the Back Office manager who first set this processing record to CashoutStatusID=1 or 14 (prepared/sent). Resolved via OUTER APPLY on `History.WithdrawToFundingAction` + `BackOffice.Manager`. |
| 42 | BackOffice Withdraw Reason | NVARCHAR | YES | - | CODE-BACKED | Reason for the withdrawal as recorded by Back Office (`Dictionary.CashoutReason.Name` via `Billing.Withdraw.CashoutReasonID`). |
| 43 | Additional Information | NVARCHAR | YES | - | CODE-BACKED | Free-text additional information from the processing record (`Billing.WithdrawToFunding.AdditionalInformation`). |
| 44 | Intermediary Bank Details | NVARCHAR | YES | - | CODE-BACKED | Wire transfer intermediary bank information from `Billing.WithdrawAdditionalParameters` where `ParameterTypeID = 2`. Renamed from "client comment" in Sep 2022 (OPSE-517). |
| 45 | BackOffice User Comment | NVARCHAR | YES | - | CODE-BACKED | Free-text comment entered on the parent withdrawal by a Back Office user (`Billing.Withdraw.Comment`). |
| 46 | Address Country ISO | VARCHAR | NO | '' | CODE-BACKED | ISO abbreviation of the customer's registration country (`Dictionary.Country.Abbreviation` via `Customer.Customer.CountryID`). Added OPSE-517 (Jan 2022). |
| 47 | Bank Country ISO | VARCHAR | NO | '' | CODE-BACKED | ISO abbreviation of the bank/payment destination country, resolved from `WithdrawData XML CountryIDAsInteger` first, falling back to `FundingData XML CountryIDAsInteger`. Added OPSE-517 (Jan 2022). |
| 48 | ExternalTransactionID | VARCHAR | NO | '' | CODE-BACKED | Always empty string (placeholder for future external transaction ID field). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (FROM) | Billing.WithdrawToFunding | Direct read | Main table - one row per in-process payment attempt |
| WithdrawToFunding.WithdrawID | Billing.Withdraw | LEFT JOIN | Parent withdrawal for approval status, CID, FlowID, Comment, CashoutReasonID |
| WithdrawToFunding.FundingID | Billing.Funding | INNER JOIN | Payment method details, FundingTypeID, FundingData XML |
| Withdraw.CID | Customer.Customer | INNER JOIN | Customer email, BirthDate, CountryID, PlayerStatusID, PlayerLevelID, LabelID |
| Withdraw.CID | BackOffice.Customer | INNER JOIN | Customer RegulationID |
| Customer.LabelID | Dictionary.Label | INNER JOIN | White label name |
| Funding.FundingTypeID | Dictionary.FundingType | INNER JOIN | Funding method name |
| WithdrawToFunding.ProcessCurrencyID | Dictionary.Currency | INNER JOIN | Processing currency display name |
| WithdrawToFunding.ManagerID | BackOffice.Manager | INNER JOIN | Manager for MID lookups |
| WithdrawToFunding.CashoutTypeID | Dictionary.CashoutType | LEFT JOIN | Cashout type name |
| WithdrawToFunding.DepotID | Billing.Depot | LEFT JOIN | Depot name and ID |
| WithdrawToFunding.DepositID | Billing.Deposit | LEFT JOIN | Deposit for refund/MID paths |
| WithdrawToFunding.CashoutStatusID | Dictionary.CashoutStatus | LEFT JOIN | Status name |
| Customer.CountryID | Dictionary.Country (DCOU) | LEFT JOIN | Country name + ISO for address |
| WithdrawData XML CountryID | Dictionary.Country (DCON) | LEFT JOIN | Bank country ISO |
| FundingData XML CountryID | Dictionary.Country (DCFN) | LEFT JOIN | Bank country ISO fallback |
| FundingData XML BinCode | Dictionary.CountryBin | LEFT JOIN | Card category |
| FundingData XML CardTypeID | Dictionary.CardType | LEFT JOIN | Card brand |
| BackOffice.Customer.RegulationID | Dictionary.Regulation (DCRG) | LEFT JOIN | Regulation name |
| Customer.PlayerStatusID | Dictionary.PlayerStatus | LEFT JOIN | Customer status name |
| Customer.PlayerLevelID | Dictionary.PlayerLevel | LEFT JOIN | Customer level name |
| Withdraw.WithdrawID ParameterTypeID=2 | Billing.WithdrawAdditionalParameters | LEFT JOIN | Intermediary bank details |
| ProtocolMIDSettingsID | Billing.ProtocolMIDSettings (BPMS1) | LEFT JOIN | MID primary lookup |
| BPMS1.RegulationID | Dictionary.Regulation (DR1) | LEFT JOIN | MID regulation name |
| Deposit.ProtocolMIDSettingsID | Billing.ProtocolMIDSettings (BPMS2) | LEFT JOIN | MID secondary lookup |
| BPMS1 + Deposit.CurrencyID | Billing.MapMerchantCodeToMid | LEFT JOIN | Enhanced MID mapping |
| Withdraw.CashoutReasonID | Dictionary.CashoutReason | LEFT JOIN | Withdrawal reason name |
| WithdrawToFunding.ID | History.WithdrawToFundingAction | OUTER APPLY x3 | Manager name, Request Time, Rejection Reason |
| MerchantAccountID | BackOffice.GetMerchantDetails | Function call | Primary MID resolution |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.InProcessPaymentsToSendPCIVersion (procedure)
├── Billing.WithdrawToFunding (table)
├── Billing.Withdraw (table)
├── Billing.Funding (table)
├── Billing.Depot (table)
├── Billing.Deposit (table)
├── Billing.ProtocolMIDSettings (table) [x2]
├── Billing.MapMerchantCodeToMid (table)
├── Billing.WithdrawAdditionalParameters (table)
├── Customer.Customer (table)
├── BackOffice.Customer (table)
├── BackOffice.Manager (table)
├── Dictionary.Label (table)
├── Dictionary.FundingType (table)
├── Dictionary.Currency (table)
├── Dictionary.CashoutStatus (table)
├── Dictionary.CashoutType (table)
├── Dictionary.Country (table) [x3 - DCOU + DCON + DCFN]
├── Dictionary.CountryBin (table)
├── Dictionary.CardType (table)
├── Dictionary.Regulation (table) [x2 - DCRG + DR1]
├── Dictionary.PlayerStatus (table)
├── Dictionary.PlayerLevel (table)
├── Dictionary.CashoutReason (table)
├── History.WithdrawToFundingAction (table) [x3 OUTER APPLY]
└── BackOffice.GetMerchantDetails (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | FROM (main); all processing record fields |
| Billing.Withdraw | Table | LEFT JOIN; parent withdrawal Approved flag, CID, FlowID |
| Billing.Funding | Table | INNER JOIN; FundingTypeID, PaymentDetails, FundingData XML |
| Billing.Depot | Table | LEFT JOIN; depot name and ID |
| Billing.Deposit | Table | LEFT JOIN; PayPal refund + MID for depots 35-44 |
| Billing.ProtocolMIDSettings | Table | LEFT JOIN x2; MID value lookups |
| Billing.MapMerchantCodeToMid | Table | LEFT JOIN; enhanced MID by merchant code + currency |
| Billing.WithdrawAdditionalParameters | Table | LEFT JOIN ParameterTypeID=2; intermediary bank details |
| Customer.Customer | Table | INNER JOIN; email, birthdate, country, status, level, label |
| BackOffice.Customer | Table | INNER JOIN; regulation ID |
| BackOffice.Manager | Table | INNER JOIN (for MID JOINS); also via OUTER APPLY for manager name |
| Dictionary.Label | Table | INNER JOIN; white label name |
| Dictionary.FundingType | Table | INNER JOIN; funding method name |
| Dictionary.Currency | Table | INNER JOIN; processing currency display name |
| Dictionary.CashoutStatus | Table | LEFT JOIN; status name |
| Dictionary.CashoutType | Table | LEFT JOIN; cashout type name |
| Dictionary.Country | Table | LEFT JOIN x3; country name + ISO codes |
| Dictionary.CountryBin | Table | LEFT JOIN; card category by BIN |
| Dictionary.CardType | Table | LEFT JOIN; card brand |
| Dictionary.Regulation | Table | LEFT JOIN x2; regulation name + MID regulation |
| Dictionary.PlayerStatus | Table | LEFT JOIN; customer status name |
| Dictionary.PlayerLevel | Table | LEFT JOIN; customer level name |
| Dictionary.CashoutReason | Table | LEFT JOIN; withdrawal reason name |
| History.WithdrawToFundingAction | Table | OUTER APPLY x3; manager name + request time + rejection reason |
| BackOffice.GetMerchantDetails | Function | Called x1 in MID CASE expression; primary MID resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SSDT dependents found. | - | Called by external Back Office service/UI for payment processing queue |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row-count messages |
| WITH (NOLOCK) | Query hint | Most tables use NOLOCK - queue read, dirty reads acceptable |
| WHERE CashoutStatusID IN (...) | Filter | Restricts to active processing states only |
| WHERE Approved = 1 | Filter | Only manager-approved withdrawals appear in the queue |
| STRING_SPLIT | Dynamic filter | Parses comma-separated parameter strings for FundingTypeID and RegulationID filters |
| OUTER APPLY x3 | Non-blocking JOINs | History lookups for manager name, request time, and rejection reason use OUTER APPLY to avoid row multiplication |
| Performance logging block | Commented out | A `dbo.ManageLoggedProcedures` / `dbo.SqlPerf` logging block exists but is commented out |

---

## 8. Sample Queries

### 8.1 Get all in-process payments (no filter)

```sql
EXEC [BackOffice].[InProcessPaymentsToSendPCIVersion]
    @FundingTypeIDs = NULL,
    @IgnorePlayerLevelID = 0,
    @RegulationIDs = NULL;
```

### 8.2 Get in-process credit card and wire transfer payments for CySEC regulation

```sql
EXEC [BackOffice].[InProcessPaymentsToSendPCIVersion]
    @FundingTypeIDs = '1,2',
    @IgnorePlayerLevelID = 0,
    @RegulationIDs = '1,2,3';
```

### 8.3 Check the raw queue size by status

```sql
SELECT
    wtf.CashoutStatusID,
    cs.Name AS StatusName,
    COUNT(*) AS Count
FROM Billing.WithdrawToFunding WITH (NOLOCK) wtf
JOIN Billing.Withdraw WITH (NOLOCK) w ON w.WithdrawID = wtf.WithdrawID
JOIN Dictionary.CashoutStatus WITH (NOLOCK) cs ON cs.CashoutStatusID = wtf.CashoutStatusID
WHERE wtf.CashoutStatusID IN (2, 6, 8, 9, 10, 11, 12, 13, 14, 15)
  AND w.Approved = 1
GROUP BY wtf.CashoutStatusID, cs.Name
ORDER BY Count DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 48 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SSDT (Back Office UI caller) | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.InProcessPaymentsToSendPCIVersion | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.InProcessPaymentsToSendPCIVersion.sql*
