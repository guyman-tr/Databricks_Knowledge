# BackOffice.GetWithdrawRequestsDetailsPCIVersion

> Synonym providing a generic alias for the crypto-transfer-specific withdraw details procedure, allowing callers to use a stable, funding-type-neutral name while the implementation targets crypto transfers.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Synonym |
| **Key Identifier** | N/A (synonym - see target) |
| **Partition** | N/A |
| **Indexes** | N/A (not applicable to synonym for a stored procedure) |

---

## 1. Business Meaning

`BackOffice.GetWithdrawRequestsDetailsPCIVersion` is a synonym that transparently redirects all `EXEC` calls to `[BackOffice].[GetCryptoTransferWithdrawRequestsDetailsPCIVersion]` - a stored procedure that returns a paginated, PCI-compliant view of withdrawal processing details filtered by funding type and date range.

The synonym decouples the caller-facing name from the implementation name. The target SP was originally focused on crypto transfer withdrawals (hence the `CryptoTransfer` prefix), but the synonym exposes it under the generic `GetWithdrawRequestsDetailsPCIVersion` name, suggesting the functionality is or will be used more broadly. The `PCIVersion` suffix indicates the result set is scrubbed of PCI-sensitive payment details: the `PaymentDetails` column is hardcoded to `NULL`, hiding raw card or bank account data from back-office consumers.

The target procedure accepts a date range, a list of funding type IDs (via the `BackOffice.IDs` TVT), and an optional customer CID, and returns withdraw-to-funding rows joined to funding method, currency, cashout status, depot, and processing manager details.

---

## 2. Business Logic

### 2.1 PCI-Compliant Withdrawal Detail Retrieval

**What**: Returns withdraw processing rows for a date range and set of funding types, with payment details suppressed for PCI compliance.

**Columns/Parameters Involved**: N/A (synonym - see target SP signature)

**Target SP Parameters**:
- `@StartDate datetime` - start of the `Billing.Withdraw.ModificationDate` range
- `@EndDate datetime` - end of the modification date range
- `@FundingTypeIDList BackOffice.IDs READONLY` - list of funding type IDs to include (e.g., crypto transfer types)
- `@CID int = NULL` - optional filter to a single customer; NULL returns all customers

**Rules**:
- The CTE filters `Billing.Withdraw` by `ModificationDate BETWEEN @StartDate AND @EndDate`.
- Joined to `Billing.WithdrawToFunding` to get per-funding-instrument processing rows.
- Filtered to `Dictionary.FundingType.FundingTypeID IN (SELECT ID FROM @FundingTypeIDList)` - caller controls which funding methods appear.
- `PaymentDetails` column is always `NULL` (PCI compliance - raw payment details never returned to back-office).
- Returns both `ParentStatusID` (status of the parent Withdraw record) and `CashoutStatusID` (status of the specific WithdrawToFunding processing row).
- Results ordered by `BWTF.ModificationDate DESC`.

**Diagram**:
```
EXEC BackOffice.GetWithdrawRequestsDetailsPCIVersion(@StartDate, @EndDate, @FundingTypeIDList, @CID)
  |
  v (resolved via synonym)
EXEC BackOffice.GetCryptoTransferWithdrawRequestsDetailsPCIVersion(@StartDate, @EndDate, @FundingTypeIDList, @CID)
  |
  +-- CTE: Billing.Withdraw filtered by ModificationDate range
  +-- JOIN Billing.WithdrawToFunding ON WithdrawID
  +-- JOIN Billing.Funding -> Dictionary.FundingType (filtered by @FundingTypeIDList)
  +-- JOIN Dictionary.Currency, Dictionary.CashoutStatus
  +-- LEFT JOIN BackOffice.Manager (processed by)
  +-- LEFT JOIN Billing.Depot
  |
  v
  Returns: Amount, ExchangeRate, Currency, Status, FundingMethod, Dates, Depot,
           PaymentDetails=NULL, FundingID, WithdrawID, ProcessorValueDate, ProcessedBy,
           ParentStatusID, CashoutStatusID
```

---

## 3. Data Overview

N/A for Synonym. Data is sourced from `Billing.Withdraw`, `Billing.WithdrawToFunding`, `Billing.Funding`, and related Dictionary tables in the target procedure.

---

## 4. Elements

N/A for Synonym. This synonymizes a stored procedure, not a table. Result set columns from the target SP:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Net. Cashout Amount | decimal(16,2) | - | - | CODE-BACKED | Withdraw amount in processing currency. From Billing.WithdrawToFunding.Amount. |
| 2 | Exchange Rate | decimal(16,4) | - | - | CODE-BACKED | Exchange rate used for currency conversion at time of processing. From Billing.WithdrawToFunding.ExchangeRate. |
| 3 | Currency | nvarchar | - | - | CODE-BACKED | Currency abbreviation (e.g., USD, EUR). From Dictionary.Currency.Abbreviation via ProcessCurrencyID. |
| 4 | Status | nvarchar | - | - | CODE-BACKED | Name of the cashout processing status for this row. From Dictionary.CashoutStatus.Name. |
| 5 | Funding Method | nvarchar | - | - | CODE-BACKED | Name of the funding method (e.g., CryptoWallet, Skrill). From Dictionary.FundingType.Name. |
| 6 | Request Time | datetime | - | - | CODE-BACKED | WithdrawToFunding modification date - when the processing status last changed. |
| 7 | Depot | nvarchar | YES | - | CODE-BACKED | Name of the payment depot/processor. NULL if not assigned. From Billing.Depot.Name. |
| 8 | PaymentDetails | null | YES | NULL | CODE-BACKED | Always NULL for PCI compliance. Raw payment details (card numbers, bank accounts) suppressed. |
| 9 | FundingID | int | - | - | CODE-BACKED | Specific funding instrument ID. FK to Billing.Funding.FundingID. |
| 10 | Status Modification Time | datetime | - | - | CODE-BACKED | Alias for ModificationDate (same value as Request Time). |
| 11 | Processor Value Date | datetime | YES | - | CODE-BACKED | Value date set by the payment processor. From Billing.WithdrawToFunding.ProcessorValueDate. |
| 12 | Processed By | nvarchar | YES | - | CODE-BACKED | Full name of the back-office manager who processed this withdrawal. NULL if not assigned. |
| 13 | WithdrawID | int | - | - | CODE-BACKED | Parent withdraw record ID. FK to Billing.Withdraw.WithdrawID. |
| 14 | Withdraw Processing ID | int | - | - | CODE-BACKED | WithdrawToFunding.ID - the specific processing row identifier. |
| 15 | ParentStatusID | int | - | - | CODE-BACKED | CashoutStatusID of the parent Billing.Withdraw record. |
| 16 | CashoutStatusID | int | - | - | CODE-BACKED | CashoutStatusID of this specific WithdrawToFunding processing row. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | BackOffice.GetCryptoTransferWithdrawRequestsDetailsPCIVersion | Synonym | All EXEC calls against this synonym are redirected to this stored procedure in the same schema |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application callers) | EXEC BackOffice.GetWithdrawRequestsDetailsPCIVersion | Caller | Application or reporting layer calls this generic name; found only in SSDT project file - no BackOffice SP callers identified |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetWithdrawRequestsDetailsPCIVersion (synonym)
+-- BackOffice.GetCryptoTransferWithdrawRequestsDetailsPCIVersion (stored procedure - same schema)
      +-- Billing.Withdraw
      +-- Billing.WithdrawToFunding
      +-- Billing.Funding
      +-- Billing.Depot
      +-- Dictionary.FundingType
      +-- Dictionary.Currency
      +-- Dictionary.CashoutStatus
      +-- BackOffice.Manager
      +-- BackOffice.IDs (parameter type)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetCryptoTransferWithdrawRequestsDetailsPCIVersion | Stored Procedure (same schema) | Synonym target - all EXEC calls are redirected here |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Application callers - not in SSDT repo) | Application/Service | EXEC via the stable generic synonym name |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym.

### 7.2 Constraints

N/A for Synonym.

---

## 8. Sample Queries

### 8.1 Get crypto transfer withdrawals for a date range (all customers)

```sql
DECLARE @fundingTypes BackOffice.IDs;

-- Insert crypto transfer funding type IDs
INSERT INTO @fundingTypes (ID) VALUES (42);  -- example: CryptoWallet FundingTypeID

EXEC BackOffice.GetWithdrawRequestsDetailsPCIVersion
    @StartDate = '2026-03-01',
    @EndDate   = '2026-03-17',
    @FundingTypeIDList = @fundingTypes,
    @CID = NULL;  -- all customers
```

### 8.2 Get withdrawal details for a specific customer

```sql
DECLARE @fundingTypes BackOffice.IDs;
INSERT INTO @fundingTypes (ID) VALUES (42);

EXEC BackOffice.GetWithdrawRequestsDetailsPCIVersion
    @StartDate = '2026-01-01',
    @EndDate   = '2026-03-17',
    @FundingTypeIDList = @fundingTypes,
    @CID = 12345;
```

### 8.3 Call the target SP directly (equivalent)

```sql
DECLARE @fundingTypes BackOffice.IDs;
INSERT INTO @fundingTypes (ID) VALUES (42);

-- Equivalent to calling the synonym
EXEC BackOffice.GetCryptoTransferWithdrawRequestsDetailsPCIVersion
    @StartDate = '2026-03-01',
    @EndDate   = '2026-03-17',
    @FundingTypeIDList = @fundingTypes;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Cashier Service Redesign (Confluence) | Confluence | Mentioned in context of withdraw request details flow - confirms the PCI-compliant version pattern is part of the cashier service architecture |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetWithdrawRequestsDetailsPCIVersion | Type: Synonym | Source: etoro/etoro/BackOffice/Synonyms/BackOffice.GetWithdrawRequestsDetailsPCIVersion.sql*
