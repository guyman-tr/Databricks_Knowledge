# BackOffice.GetProcessedWithdrawPCIVersion

> Returns a full audit-ready report of all completed withdrawal transactions (processed, reversed, or partially reversed) for a given date range, enriched with customer, payment, merchant, and FX-fee details - used by Back Office, BI, and data platform consumers.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate / @EndDate (required); returns Billing.WithdrawToFunding rows with CashoutStatusID IN (3, 16, 17) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetProcessedWithdrawPCIVersion` is the primary Back Office withdraw report for completed payment processing. It surfaces every withdrawal transaction that has reached a terminal state - Processed (3), Reversed (16), or Partially Reversed (17) - within the requested date range. Each row represents one `Billing.WithdrawToFunding` processing record joined to its parent `Billing.Withdraw` request, enriched with customer profile data, funding instrument details, FX exchange fees, and merchant identification.

The "PCIVersion" designation means this SP does not expose raw card numbers, full bank account numbers, or other full PAN/PII data in the output. Sensitive payment data is extracted from XML fields only to the level needed for reconciliation (masked identifiers, external transaction IDs) while remaining within PCI DSS scope controls. A paired `GetProcessedWithdrawPCIVersion_Old` exists as a legacy version before certain column renames.

Date filtering is dual-mode: by `ModificationDate` (when the Back Office agent changed the status - default) or by `ProcessorValueDate` (when the payment processor settled). Optional filters allow narrowing by customer, funding method, white label, or regulation. Internal/test accounts (PlayerLevelID = 4) are excluded by default. The result is ordered by the chosen date column descending.

---

## 2. Business Logic

### 2.1 Terminal-Status-Only Scope

**What**: Only withdrawal processing records in a final completed state are returned.

**Columns/Parameters Involved**: `BWTF.CashoutStatusID`, filter applied in WHERE clause

**Rules**:
- `CashoutStatusID IN (3, 16, 17)` is always enforced - never returns Pending, InProcess, Rejected, or other mid-flow statuses
- 3 = Processed (payment successfully sent and settled with provider)
- 16 = Reversed (payment was reversed after processing)
- 17 = Partially Reversed (partial amount returned after processing)
- This scope is fixed in the dynamic SQL - no parameter overrides it

**Diagram**:
```
Billing.Withdraw lifecycle:
  Pending(1) -> InProcess(2) -> [SentToProvider(10)] -> Processed(3)  <- INCLUDED
                             -> Rejected(7) / RejectedByProvider(8)
                             -> Reversed(16)                            <- INCLUDED
                             -> Partially Reversed(17)                 <- INCLUDED
                             -> Canceled(4)
```

### 2.2 Dual-Mode Date Filtering

**What**: The caller chooses whether to filter by when the processor settled or when the BO agent actioned the record.

**Columns/Parameters Involved**: `@BasedOnTime`, `@StartDate`, `@EndDate`, `BWTF.ProcessorValueDate`, `BWTF.ModificationDate`

**Rules**:
- `@BasedOnTime = 1` (default): WHERE on `BWTF.ModificationDate` - appropriate for BO agent workflow reports
- `@BasedOnTime = 0`: WHERE on `BWTF.ProcessorValueDate` - appropriate for reconciliation with payment processor settlement files
- ORDER BY mirrors the chosen date column (both sort DESC)
- The same date column selected for filtering is returned as `[Process Time]` / `[Status Modification Time]`

**Diagram**:
```
@BasedOnTime = 0 (Processor-based):  Filter on ProcessorValueDate  -> ORDER BY ProcessorValueDate DESC
@BasedOnTime = 1 (BO-based):         Filter on ModificationDate    -> ORDER BY ModificationDate DESC
```

### 2.3 Payment Details XML Extraction by Funding Type

**What**: The `[Payment Details]` column extracts the most relevant identifiers for the payment instrument from XML blobs stored in Billing.Withdraw and Billing.Funding, varying by funding type.

**Columns/Parameters Involved**: `BFUN.FundingTypeID`, `BWTF.WithdrawData` (XML), `BFUN.FundingData` (XML), `BDEP.PaymentData` (XML), `BFUN.PaymentDetails`, `CCST.BirthDate`

**Rules**:
- FundingTypeID = 2 (Wire Transfer): PaymentDetails + BSBNumber + ClientAddress from WithdrawData XML
- FundingTypeID = 3 + CashoutTypeID = 1 (PayPal initiated): email from FundingData XML
- FundingTypeID = 3 + CashoutTypeID = 2 (PayPal matched to deposit): payer from PaymentData XML
- FundingTypeID = 10 (WebMoney): AccountID + PurseID from FundingData/WithdrawData XML
- FundingTypeID = 33 (eToro Money/card-linked): CardID + AccountID + GCID; fallback to GCID + IBAN + BIC + SortCode from WithdrawData XML
- FundingTypeID = 35 (bank-with-birthdate required): PaymentDetails + formatted BirthDate (dd/MM/yyyy)
- FundingTypeID = 39 (PayID): PayId + Email from WithdrawData XML
- All other types: raw BFUN.PaymentDetails

### 2.4 Merchant Identification (MID) Resolution

**What**: The `[MID Name]` and `[MID]` columns identify the payment processor/merchant account used to process the withdrawal, using a multi-level priority fallback.

**Columns/Parameters Involved**: `BWTF.DepotID`, `DFUT.FundingTypeID`, `BWTF.MerchantAccountID`, `BPMS1`, `BPMS2`, `BMMC`, `DR`, `DR1`, `DR2`

**Rules**:
- DepotIDs 35-43 (crypto/special depots): Use DR2.Name (Regulation from deposit's ProtocolMIDSettings)
- DepotIDs 78,79,80,4,75,86 (specific processor depots): Call `Billing.GetMerchantDetailsForOneAccountByDepotOnly`
- FundingTypeID = 2 (Wire Transfer): Use BPMS1.Description / BPMS1.Value
- DepotID = 18: Use BPMS1.Value for MID
- All others: Try GetMerchantDetails(BWTF.MerchantAccountID) -> GetMerchantDetails(BPMS1.MerchantAccountID) -> DR1.Name -> MapMerchantCodeToMid -> BPMS1.Value

### 2.5 Dynamic SQL Optional Filtering

**What**: The WHERE clause is constructed at runtime, adding filter predicates only when optional parameters are supplied.

**Columns/Parameters Involved**: `@CID`, `@FundingTypeID`, `@WhiteLabelsIDs`, `@RegulationIDs`, `@IncludeInternalAccounts`

**Rules**:
- `@CID IS NOT NULL`: adds `AND BWIT.CID = @CID` - isolates one customer
- `@FundingTypeID IS NOT NULL`: adds `AND BFUN.FundingTypeID = @FundingTypeID` - isolates one payment method
- `@IncludeInternalAccounts = 0` (default): adds `AND CCST.PlayerLevelID != 4` - excludes eToro staff/test accounts
- `@WhiteLabelsIDs IS NOT NULL`: adds `AND CCST.LabelID IN (...)` - comma-separated list injected directly into SQL
- `@RegulationIDs IS NOT NULL`: adds `AND BCST.RegulationID IN (...)` - comma-separated list injected directly into SQL
- `@WhiteLabelsIDs` and `@RegulationIDs` are injected as string literals (not parameterized) - caller must validate input

### 2.6 Executed-By Resolution via History

**What**: The `[Executed by]` column traces back to the most recent BackOffice manager who took an approval action on this processing record.

**Columns/Parameters Involved**: `History.WithdrawToFundingAction`, `BackOffice.Manager`, `BWTF.ID`

**Rules**:
- Uses OUTER APPLY SELECT TOP 1 from History.WithdrawToFundingAction WHERE BW2F_ID = BWTF.ID AND CashoutStatusID IN (3, 17, 16)
- Orders by ModificationDate DESC to find the latest action
- CONCAT(FirstName, ' ', LastName) from BackOffice.Manager joined on ManagerID
- NULL if no manager action recorded (automated processing)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the date range (inclusive). Applied to either ProcessorValueDate or ModificationDate depending on @BasedOnTime. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of the date range (inclusive). Applied to the same date column as @StartDate. |
| 3 | @CID | INT | YES | NULL | CODE-BACKED | Optional customer ID filter. When provided, restricts results to a single customer's withdrawals. |
| 4 | @FundingTypeID | INT | YES | NULL | CODE-BACKED | Optional payment method filter (Dictionary.FundingType). When provided, restricts results to one funding method (e.g., Credit Card, Wire Transfer). |
| 5 | @WhiteLabelsIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Optional comma-separated list of LabelIDs (Dictionary.Label). Filters to customers registered under specified white label brands. Injected as literal string into dynamic SQL. |
| 6 | @RegulationIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Optional comma-separated list of Regulation IDs (Dictionary.Regulation). Filters to customers under specified regulatory jurisdictions. Injected as literal string into dynamic SQL. |
| 7 | @IncludeInternalAccounts | INTEGER | YES | 0 | CODE-BACKED | Controls whether eToro staff/internal accounts are included. 0 (default) = exclude PlayerLevelID=4 (internal). 1 = include all accounts. |
| 8 | @BasedOnTime | INTEGER | YES | 1 | CODE-BACKED | Selects the date column for filtering and sorting. 0 = use ProcessorValueDate (payment processor settlement date). 1 (default) = use ModificationDate (Back Office action date). |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Customer ID. Identifies the customer who requested the withdrawal. From Billing.Withdraw.CID. |
| 2 | [Payment Order Status] | NVARCHAR | YES | - | VERIFIED | Status of the withdrawal-to-funding processing record (BWTF level). Values: 1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Partially Processed, 6=Payment Sent, 7=Rejected, 8=RejectedByProvider, 9=PendingByProvider, 10=SentToProvider, 11=SentToBilling, 12=ReceivedByBilling, 13=Failed, 14=Pending Review, 15=Under Review, 16=Reversed, 17=Partially Reversed. (Dictionary.CashoutStatus via BWTF.CashoutStatusID) |
| 3 | [Process Time] | DATETIME | YES | - | CODE-BACKED | Timestamp when the payment processor settled the transaction (BWTF.ProcessorValueDate). Used as the filter date when @BasedOnTime = 0. |
| 4 | [Request Time] | DATETIME | NO | - | CODE-BACKED | Timestamp when the customer originally submitted the withdrawal request (BWIT.RequestDate). |
| 5 | [Status Modification Time] | DATETIME | YES | - | CODE-BACKED | Timestamp of the most recent status change on this processing record (BWTF.ModificationDate). Used as the filter date when @BasedOnTime = 1 (default). |
| 6 | [Withdraw Status] | NVARCHAR | YES | - | VERIFIED | Status of the parent Billing.Withdraw request (BWIT level). Same value set as [Payment Order Status] but reflects the top-level withdraw status. (Dictionary.CashoutStatus via BWIT.CashoutStatusID) |
| 7 | [Net Cashout $ Amount] | DECIMAL(16,2) | YES | - | CODE-BACKED | Amount paid out to the customer in USD (BWTF.Amount). Reflects the actual disbursement amount, converted to USD via ExchangeRate if the withdrawal was in a non-USD currency. |
| 8 | [Funding Method] | NVARCHAR | YES | - | CODE-BACKED | Name of the payment method used for this withdrawal (e.g., Credit Card, Wire Transfer, PayPal). From Dictionary.FundingType via BFUN.FundingTypeID. |
| 9 | [Payment Details] | NVARCHAR | YES | - | VERIFIED | Payment instrument identifier, extracted from XML or structured fields, varying by funding type. For Wire Transfer: PaymentDetails + BSBNumber + ClientAddress. For PayPal: email. For WebMoney: AccountID + PurseID. For eToro Money: CardID + AccountID + GCID or IBAN/BIC/SortCode. For PayID: PayId + Email. For others: raw PaymentDetails. PCI-safe: no full card numbers. |
| 10 | [Funding ID] | INT | NO | - | CODE-BACKED | ID of the funding instrument record (Billing.FundingPaymentDetailsForWithdraw.FundingID) used for this withdrawal processing. |
| 11 | [Withdraw Processing ID] | INT | NO | - | CODE-BACKED | Primary key of the Billing.WithdrawToFunding record - the individual processing attempt for this withdrawal. |
| 12 | [WithdrawID] | INT | NO | - | CODE-BACKED | Primary key of the parent Billing.Withdraw request. Links to the customer-facing withdrawal request. |
| 13 | [Customer Status] | NVARCHAR | YES | - | VERIFIED | Customer's current platform status (trimmed). From Dictionary.PlayerStatus via Customer.Customer.PlayerStatusID. Indicates account standing at time of report. |
| 14 | [Customer Level] | NVARCHAR | YES | - | VERIFIED | Customer's player level (trimmed). From Dictionary.PlayerLevel via Customer.Customer.PlayerLevelID. Level 4 = internal/staff accounts (excluded by default via @IncludeInternalAccounts). |
| 15 | [Country by Reg. Form] | NVARCHAR | YES | - | CODE-BACKED | Country name from the customer's registration form (Dictionary.Country via Customer.Customer.CountryID). May differ from regulatory or IP-derived country. |
| 16 | [Preparation Type] | NVARCHAR | YES | - | VERIFIED | Mode in which the withdrawal processing record was created. 0=Manual, 1=Auto Create, 2=Mass Auto Create, 3=Instant Withdrawal. (Dictionary.CashoutMode via BWTF.CashoutModeID) |
| 17 | [Executed by] | NVARCHAR | YES | - | CODE-BACKED | Full name (FirstName + LastName) of the most recent BackOffice manager who performed an approval/processing action on this record. NULL for automated executions. Sourced from History.WithdrawToFundingAction + BackOffice.Manager. |
| 18 | [Execution Type] | NVARCHAR | YES | - | VERIFIED | How the withdrawal was executed by the manager. 0=Manually Updated, 1=Auto Execute, 2=Manual Execute. (Dictionary.ExecuteEntryMethod via BWTF.RequestExecuteEntryMethodId) |
| 19 | [Exchange Rate] | DECIMAL(16,4) | YES | - | CODE-BACKED | FX exchange rate applied when converting the withdrawal amount from the customer's deposit currency to USD (BWTF.ExchangeRate). 1.0 for USD-denominated withdrawals. |
| 20 | [Fee In PIPs] | MONEY | YES | - | CODE-BACKED | FX fee charged for currency conversion, expressed in PIPs (BWTF.ExchangeFee). Represents the spread cost on currency exchange. |
| 21 | [Exchange Fee In Percentage] | DECIMAL | YES | - | ATLASSIAN-ONLY | FX exchange fee expressed as a percentage of the transaction amount (BWTF.ExchangeFeeInPercentage). Added in MIMOPSA-16636. |
| 22 | [Exchange Fee In USD] | MONEY | YES | - | CODE-BACKED | FX exchange fee expressed in USD equivalent (BWTF.ExchangeFeeInUSD). |
| 23 | [Net Amount in Orig. Currency] | MONEY | YES | - | VERIFIED | Net cashout amount in the customer's original deposit/withdrawal currency (BWTF.RefundAmountInDepositCurrency). Fixed in MIMOPSA-9430 to use this stored field instead of recalculating from Amount / ExchangeRate, which was producing rounding errors. |
| 24 | [Currency] | NVARCHAR | YES | - | CODE-BACKED | ISO currency abbreviation for the processing currency (Dictionary.Currency.Abbreviation via BWTF.ProcessCurrencyID). |
| 25 | [Brand] | NVARCHAR | YES | - | CODE-BACKED | Card brand name (e.g., Visa, Mastercard) extracted from FundingData XML field CardTypeIDAsInteger and resolved via Dictionary.CardType. NULL for non-card funding methods. |
| 26 | [Depot] | NVARCHAR | YES | - | CODE-BACKED | Name of the payment depot/gateway used for processing (Billing.Depot.Name via BWTF.DepotID). Identifies the payment processing channel. |
| 27 | [DepotID] | INT | YES | - | CODE-BACKED | ID of the payment depot (Billing.Depot.DepotID). Used to apply depot-specific MID resolution logic in MID Name / MID CASE expressions. |
| 28 | [Processor Value Date] | DATETIME | YES | - | CODE-BACKED | Duplicate of [Process Time] - both return BWTF.ProcessorValueDate. Retained for backwards compatibility with consumers that reference this column by name. |
| 29 | [VerificationCode] | NVARCHAR | YES | - | NAME-INFERRED | Verification code returned by the payment processor upon settlement (BWTF.VerificationCode). |
| 30 | [VendorCode] | NVARCHAR | YES | - | CODE-BACKED | Vendor/processor reference code for this transaction (BWTF.VendorCode). Added in MIMOPS-1864 for payment provider reconciliation. |
| 31 | [Deposit ID] | INT | YES | - | CODE-BACKED | ID of the original deposit that funded this withdrawal instrument (BWTF.DepositID). Links back to the deposit used as the funding source for the cashout. |
| 32 | [Cashout Type] | NVARCHAR | YES | - | CODE-BACKED | Type classification of the cashout method (Dictionary.CashoutType.CashoutTypeName via BWTF.CashoutTypeID). |
| 33 | [BackOffice Withdraw Reason] | NVARCHAR | YES | - | CODE-BACKED | Reason code for the withdrawal as selected or assigned in Back Office (Dictionary.CashoutReason.Name via BWIT.CashoutReasonID). |
| 34 | [White Label] | NVARCHAR | YES | - | CODE-BACKED | White label brand name for the customer's account (Dictionary.Label.Name via Customer.Customer.LabelID). NULL for main eToro brand. |
| 35 | [Regulation] | NVARCHAR | YES | - | CODE-BACKED | Regulatory jurisdiction the customer falls under (Dictionary.Regulation.Name via BackOffice.Customer.RegulationID). Used for compliance segmentation. |
| 36 | [MID Name] | NVARCHAR | YES | - | CODE-BACKED | Human-readable merchant name for the payment processor used. Resolution priority: depot-specific rules (DepotIDs 35-43: DR2; DepotIDs 78,79,80,4,75,86: GetMerchantDetailsForOneAccountByDepotOnly) -> FundingType=2: BPMS1.Description -> GetMerchantDetails(MerchantAccountID) -> GetMerchantDetails(BPMS1.MerchantAccountID) -> DR1.Name. |
| 37 | [MID] | NVARCHAR | YES | - | CODE-BACKED | Merchant account identifier (MID) for the payment processor. Same priority resolution chain as [MID Name] but returns the merchant ID code instead of the display name. |
| 38 | [WithdrawTypeID] | INT | YES | - | CODE-BACKED | Numeric type code of the withdrawal (Billing.Withdraw.WithdrawTypeID). References Dictionary.WithdrawType. |
| 39 | ExternalTransactionID | NVARCHAR | YES | - | ATLASSIAN-ONLY | External transaction reference provided by the payment processor or external system (BWIT.ExTransactionID). Added in MIMOPSA-14499 for Internal Transfer flow tracking. |
| 40 | WithdrawType | NVARCHAR | YES | - | VERIFIED | Human-readable withdraw type description. When FlowID is set and the Flow description is non-empty, displays as "{WithdrawType.Description} - {Flow.Description}" (e.g., "Withdrawal - Internal Transfer"). Otherwise displays Dictionary.WithdrawType.Description alone. (Dictionary.WithdrawType + Dictionary.Flow) |
| 41 | FlowID | INT | YES | - | VERIFIED | Flow classification of the withdrawal. 1=Open Trade Execution, 2=Close Trade Execution, 3=Internal Transfer. NULL for standard customer withdrawals. Added alongside WithdrawType concatenation per MIMOPSA-14499. (Dictionary.Flow via BWIT.FlowID) |

---

## 5. Relationships

### 5.1 References To (this object reads from)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (primary) | Billing.WithdrawToFunding | Read | Core driving table - each row is one processing record |
| BWIT.WithdrawID | Billing.Withdraw | JOIN | Parent withdrawal request for the processing record |
| BWIT.CID | Customer.Customer | JOIN | Customer profile for status, level, country, label |
| BWIT.CID | BackOffice.Customer | JOIN | Back Office customer attributes including RegulationID |
| BWTF.FundingID | Billing.FundingPaymentDetailsForWithdraw | JOIN | Payment instrument used for this cashout |
| BWTF.DepotID | Billing.Depot | LEFT JOIN | Payment depot/gateway name and ID |
| BWTF.DepositID | Billing.Deposit | LEFT JOIN | Original deposit record for PayPal payer and ProtocolMIDSettings |
| BWTF.ProtocolMIDSettingsID | Billing.ProtocolMIDSettings (BPMS1) | LEFT JOIN | MID settings for this processing record |
| BDEP.ProtocolMIDSettingsID | Billing.ProtocolMIDSettings (BPMS2) | LEFT JOIN | MID settings from deposit for MID resolution fallback |
| BWTF.ID | History.WithdrawToFundingAction | OUTER APPLY | Manager action history for Executed-by lookup |
| BWTF.ManagerID | BackOffice.Manager | JOIN | Manager who owns the processing record |
| BPMS1.MerchantCode | Billing.MapMerchantCodeToMid | LEFT JOIN | MID lookup by merchant code + currency + regulation |
| BWTF.ProcessCurrencyID | Dictionary.Currency | JOIN | Process currency abbreviation |
| BFUN.FundingTypeID | Dictionary.FundingType | JOIN | Funding method name |
| BWIT.WithdrawTypeID | Dictionary.WithdrawType | LEFT JOIN | Withdraw type description |
| BWIT.FlowID | Dictionary.Flow | LEFT JOIN | Flow classification description |
| BWTF.CashoutStatusID | Dictionary.CashoutStatus (DCWTFS) | LEFT JOIN | Processing-level status name |
| BWIT.CashoutStatusID | Dictionary.CashoutStatus (DCWCS) | LEFT JOIN | Withdraw-level status name |
| BWTF.CashoutTypeID | Dictionary.CashoutType | LEFT JOIN | Cashout type name |
| BWIT.CashoutReasonID | Dictionary.CashoutReason | LEFT JOIN | Withdraw reason name |
| CCST.LabelID | Dictionary.Label | LEFT JOIN | White label brand name |
| CCST.PlayerLevelID | Dictionary.PlayerLevel | JOIN | Customer level name |
| CCST.PlayerStatusID | Dictionary.PlayerStatus | JOIN | Customer status name |
| CCST.CountryID | Dictionary.Country | LEFT JOIN | Country from registration form |
| BWTF.CashoutModeID | Dictionary.CashoutMode | LEFT JOIN | Preparation type name |
| BWTF.RequestExecuteEntryMethodId | Dictionary.ExecuteEntryMethod | LEFT JOIN | Execution type name |
| BPMS1.RegulationID | Dictionary.Regulation (DR1) | LEFT JOIN | Regulation from primary MID settings |
| BPMS2.RegulationID | Dictionary.Regulation (DR2) | LEFT JOIN | Regulation from deposit MID settings |
| BCST.RegulationID | Dictionary.Regulation (DR) | LEFT JOIN | Customer's regulatory jurisdiction |
| FundingData XML | Dictionary.CardType | LEFT JOIN | Card brand name from XML-parsed CardTypeID |
| @CurrencyID, @ExchangeRate, ... | BackOffice.CalculateWithdrawPIPsUSD | OUTER APPLY | FX PIP-in-USD calculation (result column not projected in SELECT) |
| BWTF.MerchantAccountID | BackOffice.GetMerchantDetails | Scalar Call | MID Name/MID resolution for standard depots |
| BWTF.DepotID | Billing.GetMerchantDetailsForOneAccountByDepotOnly | Scalar Call | MID resolution for specific depot IDs |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DWH.BackOffice_GetProcessedWithdrawPCIVersion | (entire result) | DWH Mirror | DWH layer procedure that wraps or mirrors this SP's output for data warehouse loading |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetProcessedWithdrawPCIVersion (procedure)
├── Billing.WithdrawToFunding (table)
├── Billing.Withdraw (table)
├── Customer.Customer (table)
├── BackOffice.Customer (table)
├── Billing.FundingPaymentDetailsForWithdraw (table)
├── Billing.Depot (table)
├── Billing.Deposit (table)
├── Billing.ProtocolMIDSettings (table)
├── Billing.MapMerchantCodeToMid (table)
├── History.WithdrawToFundingAction (table)
├── BackOffice.Manager (table)
├── Dictionary.Currency (table)
├── Dictionary.FundingType (table)
├── Dictionary.WithdrawType (table)
├── Dictionary.Flow (table)
├── Dictionary.CashoutStatus (table)
├── Dictionary.CashoutType (table)
├── Dictionary.CashoutReason (table)
├── Dictionary.Label (table)
├── Dictionary.PlayerLevel (table)
├── Dictionary.PlayerStatus (table)
├── Dictionary.Country (table)
├── Dictionary.CashoutMode (table)
├── Dictionary.ExecuteEntryMethod (table)
├── Dictionary.Regulation (table)
├── Dictionary.CardType (table)
├── BackOffice.CalculateWithdrawPIPsUSD (function)
├── BackOffice.GetMerchantDetails (function/procedure)
└── Billing.GetMerchantDetailsForOneAccountByDepotOnly (function/procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Primary driving table (FROM) |
| Billing.Withdraw | Table | JOIN - parent withdrawal request |
| Customer.Customer | Table | JOIN - customer profile data |
| BackOffice.Customer | Table | JOIN - BO attributes including RegulationID |
| Billing.FundingPaymentDetailsForWithdraw | Table | JOIN - payment instrument details |
| Billing.Depot | Table | LEFT JOIN - depot name/ID |
| Billing.Deposit | Table | LEFT JOIN - deposit for PayPal payer and MID settings |
| Billing.ProtocolMIDSettings | Table | LEFT JOIN x2 - MID configuration |
| Billing.MapMerchantCodeToMid | Table | LEFT JOIN - MID code lookup |
| History.WithdrawToFundingAction | Table | OUTER APPLY - manager action history |
| BackOffice.Manager | Table | JOIN x2 - manager name and ownership |
| Dictionary.* (multiple) | Table | JOIN/LEFT JOIN - lookup resolution |
| BackOffice.CalculateWithdrawPIPsUSD | Function | OUTER APPLY - FX PIP calculation (column not projected) |
| BackOffice.GetMerchantDetails | Function/Proc | Scalar call in MID Name/MID CASE |
| Billing.GetMerchantDetailsForOneAccountByDepotOnly | Function/Proc | Scalar call in MID Name/MID CASE for specific depots |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DWH.BackOffice_GetProcessedWithdrawPCIVersion | Procedure | DWH mirror/wrapper consuming this procedure's result |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dynamic SQL | Implementation | WHERE clause built at runtime via sp_executesql; CashoutStatusID IN (3,16,17) always enforced |
| @WhiteLabelsIDs / @RegulationIDs injection | Security note | These parameters are injected as string literals into dynamic SQL - not parameterized. Callers must validate these inputs. |
| @IncludeInternalAccounts = 0 default | Logic | Excludes PlayerLevelID = 4 (eToro internal accounts) from all reports unless explicitly overridden |

---

## 8. Sample Queries

### 8.1 All processed withdrawals for March 2025 by BO modification date
```sql
EXEC [BackOffice].[GetProcessedWithdrawPCIVersion]
    @StartDate = '20250301',
    @EndDate = '20250331',
    @CID = NULL,
    @FundingTypeID = NULL,
    @WhiteLabelsIDs = NULL,
    @RegulationIDs = NULL,
    @IncludeInternalAccounts = 0,
    @BasedOnTime = 1
```

### 8.2 Processed withdrawals for a specific customer by processor value date
```sql
EXEC [BackOffice].[GetProcessedWithdrawPCIVersion]
    @StartDate = '20250101',
    @EndDate = '20251231',
    @CID = 123456,
    @FundingTypeID = NULL,
    @WhiteLabelsIDs = NULL,
    @RegulationIDs = NULL,
    @IncludeInternalAccounts = 0,
    @BasedOnTime = 0
```

### 8.3 Wire transfer withdrawals under a specific regulation for a date range
```sql
EXEC [BackOffice].[GetProcessedWithdrawPCIVersion]
    @StartDate = '20250101',
    @EndDate = '20250331',
    @CID = NULL,
    @FundingTypeID = 2,
    @WhiteLabelsIDs = NULL,
    @RegulationIDs = '5',
    @IncludeInternalAccounts = 0,
    @BasedOnTime = 1
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [MIMOPSA-16636](https://etoro-jira.atlassian.net/browse/MIMOPSA-16636) | Jira | Added ExchangeFeeInPercentage column from Billing.WithdrawToFunding (Mimo DB support, 2026-02) |
| [MIMOPSA-14499](https://etoro-jira.atlassian.net/browse/MIMOPSA-14499) | Jira | New Internal Transfer BO Support - added FlowID, WithdrawType concatenation with Flow description, and ExternalTransactionID column (2024-11) |
| [MIMOPSA-9430](https://etoro-jira.atlassian.net/browse/MIMOPSA-9430) | Jira | Fixed wrong amount on [Net Amount in Orig. Currency]: replaced recalculation formula with BWTF.RefundAmountInDepositCurrency field to eliminate rounding errors |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9.2/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 30 CODE-BACKED, 3 ATLASSIAN-ONLY, 8 NAME-INFERRED | Phases: 5/5 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 3 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetProcessedWithdrawPCIVersion | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetProcessedWithdrawPCIVersion.sql*
