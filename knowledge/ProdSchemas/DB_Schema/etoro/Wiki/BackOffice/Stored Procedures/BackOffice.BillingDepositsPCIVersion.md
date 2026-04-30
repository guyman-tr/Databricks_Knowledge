# BackOffice.BillingDepositsPCIVersion

> The primary BackOffice deposit management report: returns a filterable, pageable result set of deposit records enriched with customer, funding, merchant, risk, and 3DS data - the PCI-safe version that redacts raw card numbers.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate / @EndDate (date range required) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the main deposit report used by the BackOffice payments operations team to monitor, review, and manage customer deposits. It surfaces all deposit events within a date range, enriched with customer profile (player level, status, regulation, white label), payment gateway details (MID, funding method, response code), merchant account information, risk status, 3DS authentication parameters, rollback amounts and reasons, and PII-safe payment details. It is the "PCI Version" because raw card numbers are never exposed - instead it reads `PaymentData` as XML and extracts only non-sensitive fields (account sort codes, IBANs, transaction IDs) based on the funding type.

This procedure has a long maintenance history spanning 2020-2025 (MIMOPS, MIMOPSA, OPSE ticket series), reflecting its importance as the central deposit operations tool. Major revisions include: performance enhancement via `History.ActiveCredit_BIGINT` for post-2022 data (MIMOPS-5125), addition of PIPs-in-USD calculation (OPSE-236), rollback reason tracking (MIMOPSA-09421), processed-by agent attribution (MIMOPS2-1587), ExTransactionID exposure (MIMOPSA-14499), and crypto-to-USD correlation ID (MIMOPS2-3411).

Data flows in two phases: Phase 1 populates two temporary tables (`Billing.#MyDeposit` and `Billing.#MyCustomer`) via dynamic SQL, applying date, customer, and filter constraints. Phase 2 joins the temp tables back to `Billing.Deposit` and multiple lookup tables to produce the final enriched result set. All SQL is constructed via `sp_executesql` with parameterized queries to support optional, dynamically appended filter clauses. The optional TOP 1000 row limit (`@IsLimit=1`) is used in the web UI to keep response times fast; exports use `@IsLimit=0`.

---

## 2. Business Logic

### 2.1 Dynamic Credit Table Selection (Pre/Post 2022-02-08)

**What**: The primary credit events table changed from `History.Credit` (INT-based CreditID) to `History.ActiveCredit_BIGINT` (BIGINT-based, partitioned) on 2022-02-08. The SP selects the right table based on the start date.

**Columns/Parameters Involved**: `@StartDate`, `@MinDepositPaymentDate`, `@CreditTableName` (internal variable)

**Rules**:
- `@StartDate < '2022-02-08 06:27:39.863'` -> use `History.Credit`
- `@StartDate > '2022-02-08 06:27:39.863'` -> use `History.ActiveCredit_BIGINT`
- The same date boundary is applied a second time based on `@MinDepositPaymentDate` (the actual earliest deposit occurrence) to ensure correct table usage when the date range straddles the boundary
- This selection affects both the deposit ID lookup and the rollback amount calculation

**Diagram**:
```
@StartDate < 2022-02-08   ->  History.Credit (legacy INT CreditID)
@StartDate > 2022-02-08   ->  History.ActiveCredit_BIGINT (new BIGINT, partitioned)
```

### 2.2 Two Ordering Modes

**What**: The procedure supports two fundamentally different orderings that also change how deposits are anchored (different MIN DepositID derivation).

**Columns/Parameters Involved**: `@OrderByClause`, `@DepositID`, `@MinDepositPaymentDate`

**Rules**:
- `@OrderByClause = 'First Approved Time'` (default): anchors on minimum CreditID with CreditTypeID=1 (deposit approval credit) in the date range; filters by `FirstApprovedTable.Occurred BETWEEN @StartDate AND @EndDate`
- `@OrderByClause = 'Status Modification Time'`: anchors on minimum DepositID where `ModificationDate >= @StartDate`; filters by `BDEP.ModificationDate BETWEEN @StartDate AND @EndDate`
- Only these two modes are supported; any other value defaults to 'First Approved Time' ordering in the ORDER BY clause

### 2.3 Optional Filters via Dynamic SQL

**What**: Five optional filter parameters inject dynamic JOIN clauses into the SQL string.

**Columns/Parameters Involved**: `@RegulationIDs`, `@WhiteLabels`, `@FundingTypeIDs`, `@PaymentStatusIDs`, `@currenciesIDs`

**Rules**:
- Each non-NULL parameter creates a temp table, populated via `STRING_SPLIT`, and injects an `INNER JOIN` clause
- `@RegulationIDs` -> JOIN on `BackOffice.Customer.RegulationID`
- `@WhiteLabels` -> JOIN on `Customer.CustomerStatic.LabelID`
- `@FundingTypeIDs` -> JOIN on `Billing.Funding.FundingTypeID`
- `@PaymentStatusIDs` -> JOIN on `Billing.Deposit.PaymentStatusID`
- `@currenciesIDs` -> JOIN on `Billing.Deposit.CurrencyID`
- NULL parameters are skipped (no filter applied)

### 2.4 MID (Merchant ID) Resolution - Complex Multi-Path Logic

**What**: The MID and MID Name displayed in the report use a hierarchy of fallbacks depending on depot and funding type.

**Columns/Parameters Involved**: `[MID Name]`, `MID`, `DepotID`, `FundingTypeID`, `MerchantAccountID`

**Rules**:
- `FundingTypeID=2` (wire transfer): uses `ProtocolMIDSettings.Description` for MID Name, `ProtocolMIDSettings.Value` for MID
- `DepotID IN (78,79,80,75)` (special depots): uses `Billing.GetMerchantDetailsForOneAccountByDepotOnly` function
- Otherwise: `COALESCE(Dictionary.MerchantAccount.BODescription, BackOffice.GetMerchantDetails(...), Dictionary.Regulation.Name)` for MID Name; similar COALESCE chain for MID value including `MapMerchantCodeToMid.MID`

### 2.5 Payment Details - Funding-Type-Specific XML Extraction

**What**: The `[Payment Details]` column extracts PCI-safe payment metadata from the `PaymentData` XML column based on FundingTypeID.

**Columns/Parameters Involved**: `[Payment Details]`, `FundingTypeID`, `BDEP.PaymentData`

**Rules**:
- `FundingTypeID=2` (iDeal): IBANCodeAsString
- `FundingTypeID=33`: CardID + GCID
- `FundingTypeID=34`: BicCode + IBAN + BankName + AccountHolderName
- `FundingTypeID=35`: BicCode + IBAN + AccountHolderName
- `FundingTypeID=36` (Przelewy24): First/Middle/Last name
- `FundingTypeID=37`: AccountSortCode + Name + AccountNumber + BankName
- `FundingTypeID=38` (open banking): AccountHolderName + AccountID + BankName + Iban + SortCode + BicCode
- `FundingTypeID=39`: AccountID + Email + Name
- `FundingTypeID=42`: ExTransactionID
- `FundingTypeID=43`: BankReferenceId + ReceivingBankReferenceId + PaymentIntentId
- Default: `Billing.Funding.PaymentDetails` (pre-stored description)

### 2.6 Deposit Amount in USD (Bankers Rounding Correction)

**What**: The USD deposit amount calculation includes a special rounding correction to avoid displaying values that would round up due to the x.xx5 midpoint.

**Columns/Parameters Involved**: `[Deposit $ Amount]`, `ExchangeRate`, `Amount`

**Rules**:
- Formula: `ISNULL(ExchangeRate, 1) * Amount`
- If the result modulo 0.005 = 0 (exact midpoint), subtract 0.001 to force floor rounding
- Cast to DECIMAL(16,2) - avoids "bankers rounding" display issues in front-end grids

### 2.7 Rollback Amount Calculation

**What**: The total rollback dollar and currency amounts use two different sources depending on availability.

**Columns/Parameters Involved**: `[Total Rollback $ Amount]`, `[Total Rollback Amount]`, `RollbackReason`

**Rules**:
- If `BackOffice.DepositRollbackTracking` has a record (IsCanceled=0): use `TotalRollbackAmountInUSD` / `TotalRollbackAmountInCurrency`
- If `PaymentStatusID=2` (approved with no rollback): return 0
- Otherwise: use `-1 * LastRollbackAction2.RollbackAmount` from the credit table (CreditTypeIDs 11, 12, 16 = rollback credit types)
- `[Rollback Reason]`: from `Billing.DepositRollbackTracking` OUTER APPLY, joining `Dictionary.DepositRollbackTypeReason.Name`

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of date range (inclusive). Interpreted differently by ordering mode: 'First Approved Time' uses credit occurrence date; 'Status Modification Time' uses deposit ModificationDate. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of date range (inclusive upper bound for the chosen ordering mode). |
| 3 | @CID | INTEGER | YES | NULL | CODE-BACKED | Optional single customer filter. When NULL, all customers in the date range are returned. |
| 4 | @IgnorePlayerLevelID | INTEGER | YES | 0 | CODE-BACKED | When non-zero, excludes customers with this PlayerLevelID (e.g., exclude demo/internal accounts). |
| 5 | @RegulationIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated list of RegulationIDs to filter by. When NULL, all regulations included. Parsed via STRING_SPLIT into #Regulations temp table. |
| 6 | @WhiteLabels | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated list of LabelIDs (white labels/brands) to filter by. Parsed via STRING_SPLIT into #WhiteLabels temp table with CLUSTERED INDEX for performance. |
| 7 | @FundingTypeIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated list of FundingTypeIDs to filter by (e.g., 1=Credit Card, 2=Wire). Parsed into #FundingTypeIDs temp table. |
| 8 | @PaymentStatusIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated list of PaymentStatusIDs to filter by (e.g., approved=1, pending=3). Parsed into #PaymentStatusIDs temp table. |
| 9 | @currenciesIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated list of CurrencyIDs to filter by. Parsed into #currenciesIDs temp table. |
| 10 | @OrderByClause | NVARCHAR(100) | YES | 'First Approved Time' | CODE-BACKED | Sort mode: 'First Approved Time' (orders and filters by credit occurrence) or 'Status Modification Time' (orders and filters by deposit ModificationDate). Controls both the WHERE anchor and ORDER BY. |
| 11 | @IsLimit | BIT | YES | 1 | CODE-BACKED | 1 = apply TOP 1000 row limit (used by BackOffice web UI for fast load). 0 = return all rows (used for export). Also controls DECIMAL precision for exchange rates. |

**Result Set - Deposit Report Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 12 | CID | INT | NO | - | CODE-BACKED | Customer ID. The depositing customer's account identifier. |
| 13 | [Deposit Status] | NVARCHAR | NO | - | CODE-BACKED | Human-readable deposit payment status. From Dictionary.PaymentStatus. Examples: 'Approved', 'Pending', 'Rollback'. |
| 14 | [3ds response] | NVARCHAR | YES | - | CODE-BACKED | 3D Secure authentication response description. From Dictionary.ThreeDsResponseTypes via ThreeDsResponseType extracted from PaymentData XML. NULL if no 3DS authentication. |
| 15 | [Deposit Risk Status] | NVARCHAR | YES | - | CODE-BACKED | Risk management evaluation label for the deposit. From Dictionary.RiskManagementStatus. NULL if no risk evaluation assigned. |
| 16 | [Deposit Amount] | DECIMAL(16,2) | NO | - | CODE-BACKED | Original deposit amount in the deposit's currency (not USD). From Billing.Deposit.Amount. |
| 17 | [Currency] | NVARCHAR | NO | - | CODE-BACKED | Currency display name of the deposit. Uses DisplayName if available, else Abbreviation from Dictionary.Currency. |
| 18 | [Status Modification Time] | DATETIME | YES | - | CODE-BACKED | Timestamp of the last status change on the deposit record (Billing.Deposit.ModificationDate). Used as primary sort when @OrderByClause = 'Status Modification Time'. |
| 19 | [Deposit Time] | DATETIME | YES | - | CODE-BACKED | Timestamp the deposit was submitted/recorded (Billing.Deposit.PaymentDate). |
| 20 | [First Approved Time] | DATETIME | YES | - | CODE-BACKED | Timestamp the deposit received its first CreditTypeID=1 (approved) credit event in History.Credit or History.ActiveCredit_BIGINT. NULL for deposits that were never approved. |
| 21 | [Deposit Value Date] | DATETIME | YES | - | CODE-BACKED | Value date assigned by the payment processor (Billing.Deposit.ProcessorValueDate). Settlement date from the gateway's perspective. |
| 22 | [Deposit $ Amount] | DECIMAL(16,2) | NO | - | VERIFIED | Deposit amount converted to USD using ExchangeRate, with bankers-rounding correction: if `(ExchangeRate * Amount) % 0.005 = 0`, subtracts 0.001 before truncation to avoid midpoint rounding up. |
| 23 | [Funding Method] | NVARCHAR | NO | - | CODE-BACKED | Name of the funding type used (e.g., 'Credit Card', 'Wire Transfer', 'iDeal'). From Dictionary.FundingType. |
| 24 | [DepotID] | INT | YES | - | CODE-BACKED | Internal depot (payment processor account) identifier. From Billing.Deposit.DepotID. |
| 25 | [Depot] | NVARCHAR | YES | - | CODE-BACKED | Depot display name. From Billing.Depot. |
| 26 | [OldPaymentID] | NVARCHAR | YES | - | CODE-BACKED | Legacy payment ID from earlier system. From Billing.Deposit.OldPaymentID. Used for cross-reference to pre-migration records. |
| 27 | [DepositID] | INT | NO | - | CODE-BACKED | Primary key of the deposit record. From Billing.Deposit.DepositID. |
| 28 | [TransactionID (Internal)] | NVARCHAR | YES | - | CODE-BACKED | Internal transaction identifier. From Billing.Deposit.TransactionID. |
| 29 | [Country by Reg. Form] | NVARCHAR | YES | - | CODE-BACKED | Country name from the customer's registration form country (Customer.CustomerStatic.CountryID). From Dictionary.Country. |
| 30 | [Risk status] | NVARCHAR | YES | - | CODE-BACKED | Comma-concatenated risk status labels for the customer. From BackOffice.GetUserRisksByCID_AGG function (returns aggregated risk flags). |
| 31 | [FTD] | VARCHAR | NO | - | CODE-BACKED | First-time deposit flag: 'YES' if Billing.Deposit.IsFTD=1, else empty string. Marks the customer's very first deposit. |
| 32 | [BaseExchangeRate] | DECIMAL(16,4) or FLOAT | YES | - | CODE-BACKED | Base exchange rate for the deposit currency to USD. Precision: DECIMAL(16,4) when @IsLimit=1 (display), full precision when @IsLimit=0 (export). |
| 33 | [ExchangeRate] | DECIMAL(16,4) or FLOAT | YES | - | CODE-BACKED | Applied exchange rate for USD conversion. Precision controlled by @IsLimit same as BaseExchangeRate. |
| 34 | [Fee in PIPs] | DECIMAL | YES | - | CODE-BACKED | Exchange fee charged in PIPs (basis points). From Billing.Deposit.ExchangeFee. |
| 35 | [Exchange Fee Percentage] | DECIMAL | YES | - | CODE-BACKED | Exchange fee as a percentage of the deposit amount. From Billing.Deposit.ExchangeFeePercentage. Added in MIMOPSA-16636. |
| 36 | [Exchange Fee In USD] | MONEY | YES | - | CODE-BACKED | Exchange fee converted to USD. Calculated via Billing.CalculateDepositPIPsUSD(BDEP.DepositID) function. |
| 37 | [Customer Status] | NVARCHAR | NO | - | CODE-BACKED | Customer's current player status name. From Dictionary.PlayerStatus via Customer.CustomerStatic.PlayerStatusID. |
| 38 | [Brand] | NVARCHAR | YES | - | CODE-BACKED | Card brand name (e.g., 'Visa', 'Mastercard'). From Dictionary.CardType via FundingData XML for FundingTypeID=1 (credit card). NULL for non-card funding types. |
| 39 | [Card Category] | NVARCHAR | YES | - | CODE-BACKED | Card category (e.g., 'Debit', 'Credit', 'Prepaid'). From Dictionary.CountryBin via BIN code in FundingData XML. NULL for non-card funding. |
| 40 | [Payment Details] | NVARCHAR | YES | - | CODE-BACKED | PCI-safe payment method details. Content varies by FundingTypeID: wire IBANs, sort codes, account IDs, correlation IDs etc. Raw card numbers are NEVER exposed. See Section 2.5 for full funding-type mapping. |
| 41 | [FundingID] | INT | NO | - | CODE-BACKED | ID of the funding instrument used (Billing.Deposit.FundingID). Links to Billing.Funding record. |
| 42 | [Response Code] | VARCHAR | YES | - | CODE-BACKED | Combined response identifier: ProtocolID + '_' + ResponseCode from Dictionary.Response. Example: '1_00' = protocol 1, response 00 (approved). |
| 43 | [Transaction Response] | NVARCHAR | YES | - | CODE-BACKED | Human-readable description of the processor's response. From Dictionary.Response.ResponseName via the latest non-null DepositActionID. |
| 44 | [Customer Level] | NVARCHAR | NO | - | CODE-BACKED | Customer's player level name. From Dictionary.PlayerLevel via Customer.CustomerStatic.PlayerLevelID. |
| 45 | [Account Manager] | NVARCHAR | YES | - | CODE-BACKED | First name of the BackOffice account manager assigned to the customer. From BackOffice.Manager via BackOffice.Customer.ManagerID. NULL if no manager assigned. |
| 46 | [Total Rollback $ Amount] | DECIMAL(16,2) | NO | - | VERIFIED | Total amount rolled back on this deposit in USD. Uses BackOffice.DepositRollbackTracking if available, else calculates from credit table CreditTypeIDs 11/12/16. See Section 2.7. |
| 47 | [Total Rollback Amount] | DECIMAL(16,2) | NO | - | VERIFIED | Total amount rolled back in deposit currency. Same source logic as [Total Rollback $ Amount] but divided by ExchangeRate. |
| 48 | [Rollback Reason] | VARCHAR(225) | YES | - | CODE-BACKED | Most recent rollback reason description. From Dictionary.DepositRollbackTypeReason.Name via Billing.DepositRollbackTracking (IsCanceled=0). NULL if no rollback. |
| 49 | [User Name] | VARCHAR | NO | - | CODE-BACKED | Customer's eToro username. From Customer.CustomerStatic.UserName. |
| 50 | [Affiliate ID] | INT | YES | - | CODE-BACKED | Customer's affiliate serial ID. From Customer.CustomerStatic.SerialID. Used by affiliate tracking systems. |
| 51 | [ExternalTransactionID] | NVARCHAR | YES | - | CODE-BACKED | External transaction ID from the payment processor. From Billing.Deposit.ExTransactionID. Added/exposed in MIMOPSA-14499. |
| 52 | [Funnel] | NVARCHAR | YES | - | CODE-BACKED | Marketing/registration funnel name associated with the deposit. From Dictionary.Funnel via Billing.Deposit.FunnelID. |
| 53 | [Regulation] | NVARCHAR | YES | - | CODE-BACKED | Regulation name applicable to the customer at time of deposit. From Dictionary.Regulation via BackOffice.Customer.RegulationID. |
| 54 | [White Label] | NVARCHAR | YES | - | CODE-BACKED | White label / brand name for the customer's account. From Dictionary.Label via Customer.CustomerStatic.LabelID. |
| 55 | [Deposit Type] | NVARCHAR | YES | - | CODE-BACKED | Deposit type description, optionally concatenated with Flow description when FlowID is present: 'DepositType - FlowDescription'. From Dictionary.DepositType and Dictionary.Flow. |
| 56 | [Deposit Type ID] | INT | YES | - | CODE-BACKED | Numeric deposit type ID. From Billing.Deposit.DepositTypeID. Added in MIMOPSA-12252. |
| 57 | FlowID | INT | YES | - | CODE-BACKED | Flow identifier for deposit processing pipeline. From Billing.Deposit.FlowID. Added in MIMOPSA-12252. |
| 58 | [3ds parameters] | NVARCHAR | YES | - | CODE-BACKED | 3D Secure authentication parameters extracted from Billing.Trace JSON events (CAVV, ECI, XID). Returns the most recent trace event with non-null 3DS fields. NULL if no 3DS event recorded. |
| 59 | [MID Name] | NVARCHAR | YES | - | VERIFIED | Merchant account display name. Resolved via three-way CASE: FundingTypeID=2 uses ProtocolMIDSettings.Description; special DepotIDs use GetMerchantDetailsForOneAccountByDepotOnly; others use GetMerchantDetails or MerchantAccount.BODescription. See Section 2.4. |
| 60 | MID | NVARCHAR | YES | - | VERIFIED | Merchant account identifier/code. Same resolution hierarchy as [MID Name]. Returns the MID code used for payment processing. |
| 61 | [Processed By] | NVARCHAR | YES | - | CODE-BACKED | Full name of the BackOffice agent who processed the deposit (when ManagerID != 0). From BackOffice.Manager via Billing.Deposit.ManagerID. Added in MIMOPS2-1587. NULL for system-processed deposits. |
| 62 | [Correlation ID (C2F)] | NVARCHAR | YES | - | CODE-BACKED | Correlation ID for crypto-to-fiat (C2F) conversions. Only populated for FundingTypeID=27 (crypto-to-USD transactions). Extracted from PaymentData XML as TransactionIdAsString. Added in MIMOPS2-3411. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartDate / @EndDate | Billing.Deposit | Implicit | Primary data source for deposit records in the date range |
| CID | Customer.CustomerStatic | JOIN | Customer profile data (username, player level, status, label, country) |
| DepositID | History.Credit / History.ActiveCredit_BIGINT | Dynamic JOIN | First approved credit event lookup; rollback amount calculation |
| DepositID | Billing.DepositRollbackTracking | OUTER APPLY | Rollback reason lookup from most recent non-cancelled rollback |
| DepositID | BackOffice.DepositRollbackTracking | LEFT JOIN | Aggregate rollback amounts in USD and currency |
| DepositID | History.DepositAction | OUTER APPLY | Latest response code for the deposit |
| ResponseID | Dictionary.Response | LEFT JOIN | Response description and protocol info |
| FundingID | Billing.Funding | JOIN | Funding method details (FundingTypeID, PaymentDetails, PaymentData) |
| FunnelID | Dictionary.Funnel | LEFT JOIN | Marketing funnel name |
| PaymentStatusID | Dictionary.PaymentStatus | JOIN | Deposit status name |
| CurrencyID | Dictionary.Currency | JOIN | Currency display name |
| FundingTypeID | Dictionary.FundingType | JOIN | Funding method name |
| LabelID | Dictionary.Label | LEFT JOIN | White label name |
| CID | BackOffice.Customer | LEFT JOIN | Regulation, manager assignment |
| RegulationID | Dictionary.Regulation | LEFT JOIN | Regulation name |
| CID | BackOffice.GetUserRisksByCID_AGG | Function (OUTER APPLY) | Aggregated risk status string |
| PlayerLevelID | Dictionary.PlayerLevel | JOIN | Player level name |
| PlayerStatusID | Dictionary.PlayerStatus | JOIN | Player status name |
| CountryID | Dictionary.Country | LEFT JOIN | Country name from registration |
| ManagerID (BOCU) | BackOffice.Manager | LEFT JOIN | Account manager name |
| ManagerID (BDEP) | BackOffice.Manager | LEFT JOIN | Processor/agent name |
| CardTypeID | Dictionary.CardType | LEFT JOIN | Card brand (FundingTypeID=1 only) |
| BinCode | Dictionary.CountryBin | LEFT JOIN | Card category |
| RiskManagementStatusID | Dictionary.RiskManagementStatus | LEFT JOIN | Risk label |
| DepotID | Billing.Depot | LEFT JOIN | Depot name |
| DepositTypeID | Dictionary.DepositType | LEFT JOIN | Deposit type name |
| FlowID | Dictionary.Flow | LEFT JOIN | Flow description |
| ProtocolMIDSettingsID | Billing.ProtocolMIDSettings | LEFT JOIN | MID/merchant settings |
| MerchantCode | Billing.MapMerchantCodeToMid | LEFT JOIN | Merchant code to MID mapping |
| DepotID | Billing.GetMerchantDetailsForOneAccountByDepotOnly | Function | Special depot MID resolution |
| MerchantAccountID | BackOffice.GetMerchantDetails | Function | Standard MID resolution |
| MerchantAccountID | Dictionary.MerchantAccount | LEFT JOIN | BODescription for MID name |
| DepositID | Billing.Trace | OUTER APPLY | 3DS parameter extraction from JSON events |
| ThreeDsResponseType | Dictionary.ThreeDsResponseTypes | LEFT JOIN | 3DS response description |
| DepositID | Billing.CalculateDepositPIPsUSD | Function | Exchange fee in USD |
| RollbackReasonID | Dictionary.DepositRollbackTypeReason | LEFT JOIN | Rollback reason name |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.BillingDepositsPCIVersion_Old | Internal | Legacy reference | The _Old variant contains the previous implementation for comparison |
| BackOffice web application | External | Direct call | Primary caller for the Deposits section of the BackOffice UI |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.BillingDepositsPCIVersion (procedure)
|- Billing.Deposit (table) [primary source]
|- Customer.CustomerStatic (table) [customer profile]
|- History.Credit (table) [dynamic - pre 2022-02-08]
|- History.ActiveCredit_BIGINT (table) [dynamic - post 2022-02-08]
|- Billing.DepositRollbackTracking (table) [rollback tracking]
|- BackOffice.DepositRollbackTracking (table) [aggregate rollback amounts]
|- Dictionary.DepositRollbackTypeReason (table) [rollback reason names]
|- History.DepositAction (table) [response code lookup]
|- Dictionary.Response (table) [response descriptions]
|- Billing.Funding (table) [payment method details]
|- Dictionary.Funnel (table) [funnel names]
|- Dictionary.PaymentStatus (table) [deposit status]
|- Dictionary.Currency (table) [currency names]
|- Dictionary.FundingType (table) [funding type names]
|- Dictionary.Label (table) [white label names]
|- BackOffice.Customer (table) [customer BO profile]
|- Dictionary.Regulation (table) [regulation names]
|- BackOffice.GetUserRisksByCID_AGG (function) [risk status]
|- Dictionary.PlayerLevel (table) [player level]
|- Dictionary.PlayerStatus (table) [player status]
|- Dictionary.Country (table) [country names]
|- BackOffice.Manager (table) [account/processor managers]
|- Dictionary.CardType (table) [card brand]
|- Dictionary.CountryBin (table) [card category by BIN]
|- Dictionary.RiskManagementStatus (table) [risk status labels]
|- Billing.Depot (table) [depot names]
|- Dictionary.DepositType (table) [deposit type]
|- Dictionary.Flow (table) [flow descriptions]
|- Billing.ProtocolMIDSettings (table) [MID settings]
|- Billing.MapMerchantCodeToMid (table) [MID mapping]
|- Dictionary.MerchantAccount (table) [merchant BO descriptions]
|- Billing.Trace (table) [3DS JSON events]
|- Dictionary.ThreeDsResponseTypes (table) [3DS response names]
|- Billing.CalculateDepositPIPsUSD (function) [fee in USD]
|- BackOffice.GetMerchantDetails (function) [MID resolution]
|- Billing.GetMerchantDetailsForOneAccountByDepotOnly (function) [special depot MID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary source - all deposit records |
| Customer.CustomerStatic | Table | Customer profile (username, player level, status, label, country) |
| History.Credit | Table | Dynamic (pre-2022): first approved credit event and rollback amounts |
| History.ActiveCredit_BIGINT | Table | Dynamic (post-2022): same purpose as History.Credit |
| Billing.Funding | Table | Funding method details and PaymentData XML |
| BackOffice.Customer | Table | Customer regulation and manager assignment |
| BackOffice.Manager | Table | Account manager and processor agent names |
| BackOffice.GetUserRisksByCID_AGG | Function | Aggregated risk status string for a customer |
| Billing.CalculateDepositPIPsUSD | Function | Exchange fee converted to USD |
| BackOffice.GetMerchantDetails | Function | Standard MID name/code resolution |
| Billing.GetMerchantDetailsForOneAccountByDepotOnly | Function | MID resolution for special depot IDs |
| Billing.Trace | Table | 3DS authentication parameter extraction |
| Billing.DepositRollbackTracking | Table | Rollback reason (most recent non-cancelled) |
| BackOffice.DepositRollbackTracking | Table | Aggregate rollback amounts in USD and currency |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice web application | External | Deposit management UI - primary consumer |
| BackOffice.BillingDepositsPCIVersion_Old | Procedure | Legacy variant - contains previous implementation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dynamic SQL | Design | All major query blocks built via NVARCHAR(MAX) concatenation and executed via sp_executesql with typed parameters - prevents SQL injection via parameterization |
| PCI compliance | Design | Raw card numbers never exposed; card data only accessed via XML value extraction of non-sensitive fields |
| TOP 1000 limit | Application | @IsLimit=1 applies TOP 1000 to the final SELECT for UI responsiveness; set to 0 for full export |
| @MinDepositPaymentDate | Internal | Calculated as MIN(Occurred/PaymentDate) for the date range; used as a minimum scan boundary on the credit table to support partition elimination |
| OPTION RECOMPILE | Performance | Final SELECT uses OPTION(RECOMPILE) to avoid parameter-sniffing issues from the dynamic optional filters |
| History.Credit date boundary | Application | Exact boundary: 2022-02-08 06:27:39.863 - deposits before this date use History.Credit (INT CreditID); after use History.ActiveCredit_BIGINT |

---

## 8. Sample Queries

### 8.1 Get recent deposits (last 7 days, all customers, TOP 1000)

```sql
EXEC BackOffice.BillingDepositsPCIVersion
    @StartDate = '2026-03-10',
    @EndDate = '2026-03-17',
    @IsLimit = 1
-- Returns TOP 1000 deposits, sorted by First Approved Time DESC
```

### 8.2 Filter deposits by regulation and funding type (export mode)

```sql
EXEC BackOffice.BillingDepositsPCIVersion
    @StartDate = '2026-01-01',
    @EndDate = '2026-03-01',
    @RegulationIDs = '1,2,3',
    @FundingTypeIDs = '1',
    @IsLimit = 0
-- Returns ALL credit card deposits for regulations 1/2/3 - no row limit
```

### 8.3 Check deposit status by modification time for a specific customer

```sql
EXEC BackOffice.BillingDepositsPCIVersion
    @StartDate = '2026-01-01',
    @EndDate = '2026-03-17',
    @CID = 99999,
    @OrderByClause = 'Status Modification Time',
    @IsLimit = 0
-- Returns all deposits for CID 99999 ordered by when status last changed
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Handover Document - Payments Solutions (eToro)](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/13420920839/Handover+Document+Payments+Solutions+eToro) | Confluence | 2025 payments team handover document; likely contains context on deposit processing pipeline and MID configuration. LOW confidence - general team doc. |

Change history from SP comments:
- MIMOPS-2941 (Dec 2020): Shahin - additional payment details for iDeal
- MIMOPS-2100 (Sep 2020): Ran - Trustly payment details
- MIMOPS-2825 (Jun 2020): Ran - Przelewy24 payment details
- MIMOPS-4487 (Jul 2021): Michal - MID description vs regulation name fix
- MIMOPS-01648 (Jul 2021): Eliran - Open Banking FundingTypeID=38
- MIMOPS-5125 (Nov 2021): Shay Oren - Major performance revision (History.ActiveCredit)
- OPSE-236 (Nov 2021): Shay Oren - PIPs in USD calculation
- MIMOPSA-09421 (May 2023): Ran - Rollback Reason column
- MIMOPS2-1587 (Jan 2025): Merab - Processed By agent name
- MIMOPSA-14499 (Dec 2024): Evgeny - ExTransactionID and WithdrawTypeType description
- MIMOPS2-3411 (Sep 2025): Merab - Correlation ID for crypto-to-USD
- MIMOPSA-16636: ExchangeFeePercentage from Billing.Deposit

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 48 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 1 Confluence (LOW confidence) + 0 Jira | Procedures: 0 callers in schema | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.BillingDepositsPCIVersion | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.BillingDepositsPCIVersion.sql*
