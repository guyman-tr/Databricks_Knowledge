# BackOffice.GetCryptoTransferWithdrawRequestsDetailsPCIVersion

> Returns PCI-compliant processing-level details for crypto-transfer withdrawal records, showing exchange rates, depot routing, and processing status without exposing sensitive payment data.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate / @EndDate on Billing.Withdraw.ModificationDate; one row per Billing.WithdrawToFunding processing record |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides the processing-level drilldown for crypto-transfer withdrawal requests. Where `GetCryptoTransferWithdrawRequests` shows one row per withdrawal (Billing.Withdraw), this procedure shows one row per processing record (Billing.WithdrawToFunding) - the record created when BackOffice routes a withdrawal to a specific payment processor or depot.

The "PCIVersion" suffix indicates PCI DSS compliance: the `[PaymentDetails]` column is hardcoded to NULL, ensuring no cardholder data, bank account numbers, or other sensitive payment identifiers are returned. BackOffice roles that are not PCI-authorized can safely call this procedure without risk of exposing regulated data.

Use cases:
- Drilldown panel in BackOffice showing how a withdrawal was routed: which depot, at what exchange rate, in which processing currency
- Audit of processing-level status changes (BWTF.CashoutStatusID) vs parent withdrawal status (BWIT.CashoutStatusID)
- Tracking the processor value date for settlement reconciliation

This procedure was originally named `BackOffice.GetWithdrawRequestsDetailsPCIVersion`; a synonym under that name still exists pointing here.

---

## 2. Business Logic

### 2.1 Processing-Level Granularity (WithdrawToFunding as Primary Source)

**What**: The primary source is Billing.WithdrawToFunding, not Billing.Withdraw - this gives one row per processing attempt.

**Columns/Parameters Involved**: `Billing.WithdrawToFunding (BWTF)`, `BWIT CTE`

**Rules**:
- `Billing.Withdraw` is in the CTE solely to apply the date filter and carry the parent CashoutStatusID
- `Billing.WithdrawToFunding` drives the result rows: one row per time a withdrawal was routed to a funding channel
- A single withdrawal can have multiple WithdrawToFunding rows (e.g., partial fulfillment, failed attempt followed by successful retry)

### 2.2 PCI Compliance - PaymentDetails Always NULL

**What**: The `[PaymentDetails]` column is hardcoded to NULL regardless of underlying data.

**Rules**:
- `NULL [PaymentDetails]` in SELECT - no expression, no join, just a literal NULL
- This means callers never receive card numbers, bank account numbers, wallet addresses, or any sensitive payment identifier
- The non-PCI version of this type of query would JOIN Billing.Funding.FundingData and parse the XML for payment details

### 2.3 Date Filter on Parent Withdrawal, Not Processing Record

**What**: The BETWEEN filter is applied to Billing.Withdraw.ModificationDate via the CTE, not to BWTF.ModificationDate.

**Columns/Parameters Involved**: `@StartDate`, `@EndDate`, `Billing.Withdraw.ModificationDate`

**Rules**:
- CTE: `WHERE ModificationDate BETWEEN @StartDate AND @EndDate` - targets Billing.Withdraw rows
- Processing records (BWTF) for those withdrawals are then returned regardless of when the processing record was created/modified
- This matches how BO operators think: "show me the processing details for withdrawals that changed this week"

### 2.4 Processing Currency vs Withdrawal Currency

**What**: The `[Currency]` column shows the currency in which the payment was PROCESSED, not the currency the customer requested.

**Columns/Parameters Involved**: `BWTF.ProcessCurrencyID`, `Dictionary.Currency`

**Rules**:
- `BWTF.ProcessCurrencyID` - the currency used by the payment processor/depot
- This can differ from Billing.Withdraw.CurrencyID when currency conversion occurs during processing
- The `[Exchange Rate]` (BWTF.ExchangeRate) reflects the conversion rate applied at processing time

### 2.5 Orphan JOIN on Billing.Deposit

**What**: Billing.Deposit is LEFT JOINed but no column from it appears in the SELECT list.

**Columns/Parameters Involved**: `BDEP (Billing.Deposit LEFT JOIN)`

**Rules**:
- `LEFT JOIN Billing.Deposit BDEP ON BDEP.DepositID = BWTF.DepositID` exists in the FROM clause
- No BDEP.* column is selected - this is a legacy artifact, likely from a previous version that returned deposit data
- Has no effect on results but adds a minor JOIN overhead

### 2.6 Dual Status Columns (Parent vs Processing)

**What**: Two status ID columns expose both the parent withdrawal status and the processing record status.

**Columns/Parameters Involved**: `[ParentStatusID]`, `[CashoutStatusID]`

**Rules**:
- `[ParentStatusID]` = BWIT.CashoutStatusID: the overall status of the parent Billing.Withdraw record
- `[CashoutStatusID]` = BWTF.CashoutStatusID: the status of this specific processing record (WithdrawToFunding)
- These can diverge: e.g., a parent withdrawal might be "Approved" while a processing record is "Failed" after a routing attempt

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters** | | | | | | |
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the date window applied to Billing.Withdraw.ModificationDate (via CTE). Withdrawals whose status last changed on or after this date are included. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of the date window applied to Billing.Withdraw.ModificationDate (via CTE). Withdrawals whose status last changed on or before this date are included. |
| 3 | @FundingTypeIDList | BackOffice.IDs (TVP) | NO | - | CODE-BACKED | Table-valued parameter of FundingType IDs to include. Filters by DFUT.FundingTypeID from the Billing.Funding record linked to the processing row. Pass crypto funding type IDs to restrict to crypto withdrawal processing records. |
| 4 | @CID | INT | YES | NULL | CODE-BACKED | Optional single-customer filter. When NULL: returns all customers matching other filters. When provided: restricts results to the one customer via BWIT.CID. |
| **Output Columns** | | | | | | |
| 5 | Net. Cashout Amount | DECIMAL(16,2) | YES | - | CODE-BACKED | The net amount in the processing record. From BWTF.Amount (Billing.WithdrawToFunding.Amount). This is the amount at the processing level, which may differ from the parent Billing.Withdraw.Amount if partial fulfillment occurred. |
| 6 | Exchange Rate | DECIMAL(16,4) | YES | - | CODE-BACKED | The exchange rate applied when converting the withdrawal amount to the processing currency. From BWTF.ExchangeRate. 1.0 if no conversion was needed. |
| 7 | Currency | NVARCHAR | NO | - | CODE-BACKED | Abbreviation of the currency used by the payment processor for this processing record. From Dictionary.Currency.Abbreviation via BWTF.ProcessCurrencyID. May differ from the customer's withdrawal currency when conversion applies. |
| 8 | Status | NVARCHAR | NO | - | CODE-BACKED | Status of this specific processing record. From Dictionary.CashoutStatus.Name via BWTF.CashoutStatusID. Reflects the state of the WithdrawToFunding row, not the parent withdrawal. |
| 9 | Funding Method | NVARCHAR | NO | - | CODE-BACKED | Name of the funding type used in this processing record. From Dictionary.FundingType.Name via Billing.Funding.FundingTypeID. |
| 10 | Request Time | DATETIME | NO | - | CODE-BACKED | Modification date of the processing record. From BWTF.ModificationDate. Note: identical source to [Status Modification Time] - both columns map to BWTF.ModificationDate. |
| 11 | Depot | NVARCHAR | YES | NULL | CODE-BACKED | Name of the depot (bank/payment gateway) used to route this processing record. From Billing.Depot.Name via BWTF.DepotID. NULL if no specific depot was assigned. |
| 12 | PaymentDetails | NULL | YES | NULL | CODE-BACKED | Always NULL. PCI compliance: this field would normally contain sensitive payment identifiers (card numbers, bank accounts, wallet addresses). Hardcoded to NULL to prevent exposure of regulated payment data. |
| 13 | FundingID | INT | NO | - | CODE-BACKED | The unique ID of the funding record (payment method instance) used for this processing attempt. From BWTF.FundingID -> Billing.Funding.FundingID. Allows callers to cross-reference the full funding record if needed. |
| 14 | Status Modification Time | DATETIME | NO | - | CODE-BACKED | Modification date of the processing record. From BWTF.ModificationDate. Same source as [Request Time] - this column appears to be a duplicate alias, likely a legacy artifact. |
| 15 | Processor Value Date | DATETIME | YES | NULL | CODE-BACKED | The value date assigned by the payment processor for settlement. From BWTF.ProcessorValueDate. Used in settlement reconciliation to match processing records to bank statements. NULL if the processor has not yet assigned a value date. |
| 16 | Processed By | NVARCHAR | YES | NULL | CODE-BACKED | Full name of the BackOffice manager who processed this WithdrawToFunding record. Computed as FirstName + ' ' + LastName from BackOffice.Manager via BWTF.ManagerID. NULL if not manually processed. |
| 17 | WithdrawID | INT | NO | - | CODE-BACKED | Parent withdrawal ID. From BWTF.WithdrawID -> Billing.Withdraw.WithdrawID. Links this processing record back to the originating withdrawal request. |
| 18 | Withdraw Processing ID | INT | NO | - | CODE-BACKED | Unique ID of this specific processing record. From BWTF.ID (Billing.WithdrawToFunding PK). Identifies the exact routing attempt, distinct from the parent WithdrawID. |
| 19 | ParentStatusID | INT | NO | - | CODE-BACKED | The cashout status ID of the parent Billing.Withdraw record. From BWIT.CashoutStatusID. Compare with [CashoutStatusID] (processing-level status) to detect divergence between parent and processing state. |
| 20 | CashoutStatusID | INT | NO | - | CODE-BACKED | The cashout status ID of this processing record (Billing.WithdrawToFunding). From BWTF.CashoutStatusID. May differ from [ParentStatusID] when a processing attempt has a different state from the overall withdrawal. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID / CID / ModificationDate | Billing.Withdraw | CTE / Date Filter Source | Provides the date window filter and parent CashoutStatusID |
| (primary data) | Billing.WithdrawToFunding | Primary Source | Processing-level records: amount, exchange rate, depot, processing currency, dates |
| DepotID | Billing.Depot | Lookup / LEFT JOIN | Resolves depot ID to name |
| FundingID | Billing.Funding | Lookup / JOIN | Resolves funding ID to get FundingTypeID |
| FundingTypeID | Dictionary.FundingType | Lookup / JOIN | Resolves funding type to name; applies TVP filter |
| ProcessCurrencyID | Dictionary.Currency | Lookup / JOIN | Resolves processing currency ID to abbreviation |
| CashoutStatusID (BWTF) | Dictionary.CashoutStatus | Lookup / JOIN | Resolves processing record status to name |
| ManagerID | BackOffice.Manager | Lookup / LEFT JOIN | Resolves processing manager to full name |
| DepositID | Billing.Deposit | Orphan / LEFT JOIN | Joined but not referenced in SELECT; legacy artifact |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetWithdrawRequestsDetailsPCIVersion | (synonym) | Synonym | `CREATE SYNONYM BackOffice.GetWithdrawRequestsDetailsPCIVersion FOR BackOffice.GetCryptoTransferWithdrawRequestsDetailsPCIVersion` - the original name before the CryptoTransfer prefix was added |
| BackOffice application (BO) | N/A | Application call | Called by BackOffice UI to show the processing-level drilldown for a selected withdrawal |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCryptoTransferWithdrawRequestsDetailsPCIVersion (procedure)
|- Billing.Withdraw (CTE - date filter + parent status)
|- Billing.WithdrawToFunding (primary source - processing records)
|- Billing.Depot (depot name)
|- Billing.Funding (funding type ID lookup)
|- Dictionary.FundingType (funding type name + TVP filter)
|- Dictionary.Currency (processing currency abbreviation)
|- Dictionary.CashoutStatus (processing status name)
|- BackOffice.Manager (processed by name)
+-- Billing.Deposit (orphan LEFT JOIN - legacy, unused in SELECT)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | CTE - applies @StartDate/@EndDate date filter on ModificationDate; carries CashoutStatusID for [ParentStatusID] |
| Billing.WithdrawToFunding | Table | Primary source - one row per processing record (amount, exchange rate, depot, currency, dates, manager) |
| Billing.Depot | Table | LEFT JOINed to resolve DepotID to depot name |
| Billing.Funding | Table | JOINed to navigate from FundingID to FundingTypeID |
| Dictionary.FundingType | Table | JOINed to resolve FundingTypeID to name and apply @FundingTypeIDList TVP filter |
| Dictionary.Currency | Table | JOINed to resolve ProcessCurrencyID to abbreviation |
| Dictionary.CashoutStatus | Table | JOINed to resolve BWTF.CashoutStatusID to name |
| BackOffice.Manager | Table | LEFT JOINed to resolve BWTF.ManagerID to full name |
| Billing.Deposit | Table | Orphan LEFT JOIN (legacy artifact - no columns selected from it) |
| BackOffice.IDs | User Defined Type | TVP type for @FundingTypeIDList |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetWithdrawRequestsDetailsPCIVersion | Synonym | Points to this procedure under the original pre-rename name |
| BackOffice application (BO) | External application | Reads processing-level details for withdrawal drilldown view in UI |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get crypto processing details for a date window

```sql
DECLARE @Fundings BackOffice.IDs;
-- Example: FundingTypeID 25 = Bitcoin
INSERT @Fundings VALUES (25);

EXEC BackOffice.GetCryptoTransferWithdrawRequestsDetailsPCIVersion
    @StartDate         = '2026-03-01',
    @EndDate           = '2026-03-17',
    @FundingTypeIDList = @Fundings;
```

### 8.2 Processing details for a specific customer

```sql
DECLARE @Fundings BackOffice.IDs;
INSERT @Fundings VALUES (25), (26), (27); -- multiple crypto types

EXEC BackOffice.GetCryptoTransferWithdrawRequestsDetailsPCIVersion
    @StartDate         = '2025-01-01',
    @EndDate           = '2026-12-31',
    @FundingTypeIDList = @Fundings,
    @CID               = 12345678;
```

### 8.3 Check for parent vs processing status divergence

```sql
-- Use synonym name for backward compatibility
DECLARE @Fundings BackOffice.IDs;
INSERT @Fundings VALUES (25);

DECLARE @Results TABLE (
    [Net. Cashout Amount] DECIMAL(16,2), [Exchange Rate] DECIMAL(16,4),
    [Currency] NVARCHAR(50), [Status] NVARCHAR(100), [Funding Method] NVARCHAR(100),
    [Request Time] DATETIME, [Depot] NVARCHAR(200), [PaymentDetails] NVARCHAR(MAX),
    [FundingID] INT, [Status Modification Time] DATETIME, [Processor Value Date] DATETIME,
    [Processed By] NVARCHAR(200), [WithdrawID] INT, [Withdraw Processing ID] INT,
    [ParentStatusID] INT, [CashoutStatusID] INT
);
INSERT @Results
EXEC BackOffice.GetWithdrawRequestsDetailsPCIVersion  -- synonym still works
    @StartDate = '2026-03-01', @EndDate = '2026-03-17',
    @FundingTypeIDList = @Fundings;

-- Find cases where processing status diverges from parent
SELECT * FROM @Results WHERE ParentStatusID <> CashoutStatusID;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira records found for this procedure. Key context: a synonym `BackOffice.GetWithdrawRequestsDetailsPCIVersion` points to this procedure, indicating a rename occurred (the "CryptoTransfer" prefix was added to align naming with related procedures in the crypto withdrawal workflow).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCryptoTransferWithdrawRequestsDetailsPCIVersion | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCryptoTransferWithdrawRequestsDetailsPCIVersion.sql*
