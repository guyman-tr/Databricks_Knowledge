# BackOffice.GetCashOutRequests

> Returns three result sets for the Cashout Requests report: (1) extended withdraw list via GetWithdrawRequests + withdraw type/flow, (2) processing-level details per funding with payment details, MID, and rollback amounts, (3) approval/rejection history. Created MIMOPSA-1466.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate/@EndDate window; optional @CID, status/type/regulation/customer filters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the main Cashout Requests procedure in BackOffice, returning a comprehensive three-result-set response for the cashout report UI:

- **Result Set 1**: The base withdraw list (all columns from `GetWithdrawRequests`) extended with withdraw type, flow, and external transaction ID. One row per Billing.Withdraw record.
- **Result Set 2**: Processing-level detail for each funding attached to the withdrawals, including payment method details (XML-parsed per funding type), MID (merchant identifier), rollback amounts, and processing status. One row per Billing.WithdrawToFunding record.
- **Result Set 3**: Complete approval and rejection history for the withdrawals, merging live and archived approval records. One row per BackOffice.WithdrawApproval or History.WithdrawApproval entry.

The procedure uses a temporary table `#t` as an intermediary: it calls `GetWithdrawRequests` and stores results in `#t`, then uses `#t`'s WithdrawID set (`WithdrawIDs` CTE) to scope Result Sets 2 and 3 to the same batch of withdrawals.

**History**: Created July 2020 (MIMOPSA-1466 - "Create SP GetCashOutRequests", parent MIMOPSA-1377 "Cashout Requests - Procedure improvement"). Multiple updates through 2025:
- Oct 2020 (MIMOPS-2387): Added BirthDate for FundingTypeID=35 (Trustly) in PaymentDetails
- Oct 2020 (MIMOPS-2393): Changed FundingTypeID=33 payment details format
- Nov 2020 (MIMOPS-2614): MID resolution via ProtocolMIDSettings + MapMerchantCodeToMid
- Dec 2020: Added GetMerchantDetails function for MID lookup
- Oct 2021 (MIMOPS-5237): PayPal New Money -> include Payer ID in PaymentDetails
- Dec 2024 (MIMOPSA-14499): Added WithdrawTypeID, FlowID, ExTransactionID, concatenated WithdrawalType description
- Dec 2025 (MIMOPS2-1843): [Net Amount in Orig. Currency] changed to read directly from BWTF.RefundAmountInDepositCurrency

**Relationship to GetCashOutRequests_Main**: `GetCashOutRequests_Main` (documented separately) uses a different architecture. `GetCashOutRequests` is the newer procedure created as part of MIMOPSA-1377 "Cashout Requests - Procedure improvement".

---

## 2. Business Logic

### 2.1 Three-Result-Set Architecture via #t Temp Table

**What**: Uses INSERT INTO #t EXEC to capture GetWithdrawRequests output, then uses it as the scope anchor for Result Sets 2 and 3.

**Rules**:
- `CREATE TABLE #t (...)` - 35 columns matching GetWithdrawRequests output exactly
- `INSERT INTO #t EXEC GetWithdrawRequests @StartDate, @EndDate, @CID, ...`
- `WITH WithdrawIDs AS (SELECT DISTINCT WithdrawID AS WID FROM #t)` - used in Result Set 2 and 3 to filter to only the same withdrawal batch

### 2.2 Result Set 1 - Extended Withdraw List

**What**: #t.* plus additional columns from Billing.Withdraw.

**Additional columns beyond GetWithdrawRequests**:
- `WithdrawTypeID`: type of withdrawal (e.g., standard, bonus)
- `FlowID`: flow identifier for routing/processing configuration
- `ExTransactionID AS ExTransactionID`: external transaction ID from the payment processor
- `WithdrawalType`: `CASE WHEN FlowID IS NOT NULL AND Flow.Description <> '' THEN CONCAT(DWT.Description, ' - ', DF.Description) ELSE DWT.Description END` - human-readable type combining WithdrawType and Flow descriptions

### 2.3 Result Set 2 - Per-Funding Processing Details

**What**: One row per Billing.WithdrawToFunding record for the WithdrawIDs batch, with full payment details and MID.

**Payment Details by FundingTypeID** (XML parsing from Billing.Funding.FundingData and Billing.Withdraw.WithdrawData):

| FundingTypeID | Method | PaymentDetails Content |
|---------------|--------|----------------------|
| 2 | Wire Transfer | BFUN.PaymentDetails + BSBNumberAsString + '; ClientAddress: ' + ClientAddressAsString |
| 3 + CashoutTypeID=1 | PayPal (new money) | email + ' Payer ID: ' + PayerIDAsString (MIMOPS-5237) |
| 3 + CashoutTypeID=2 | PayPal (return) | From Billing.Deposit.PaymentData: /Deposit/PayerAsString |
| 10 | WebMoney | 'AccountID: ' + AccountIDAsDecimal + '; PurseID: ' + PurseAsString (or PayerPurseAsString from WithdrawData) |
| 33 | eToro Money/Crypto | GCID + PlatformAccountID + CurrencyBalanceID + Bic + AccountNumber + Iban + SortCode |
| 35 | Trustly | BFUN.PaymentDetails + '; BirthDate: ' + FORMAT(Customer.BirthDate, 'dd/MM/yyyy') |
| ELSE | Others | BFUN.PaymentDetails |

**MID Resolution** (two-step fallback):
- Primary: `BackOffice.GetMerchantDetails(BWTF.MerchantAccountID, 1)` for [MID Name]; `GetMerchantDetails(BWTF.MerchantAccountID, 0)` for [MID]
- Fallback: CASE on CashoutTypeID + DepotID:
  - DepotIDs 18/92: DR1.Name (from BPMS1.RegulationID) for [MID Name]; BPMS1.Value for [MID]
  - DepotIDs 35-44: DR2.Name (from BPMS2.RegulationID) for [MID Name]; BPMS2.Value for [MID]
  - DepotID 92 with MIMOPS-2614: ISNULL(BPMS1.Description, ISNULL(BMMC.MID, BPMS1.Value)) via MapMerchantCodeToMid

**Rollback amounts**: Subqueries on `Billing.CashoutRollbackTracking` filtered by WitdrawToFundingID (note: typo in column name - "Witdraw" not "Withdraw"):
- `RollbackAmountInCurrency`: sum in the original currency
- `RollbackAmountInUSD`: sum in USD

### 2.4 Result Set 3 - Approval History

**What**: Full approve/reject trail for the withdrawal batch.

**Rules**:
- CTE `WithdrawApprovalWithHistory`: UNION ALL of live `BackOffice.WithdrawApproval` + archived `History.WithdrawApproval`
- JOINed to BackOffice.Manager (manager name), Dictionary.UserGroup (user group name), Dictionary.WithdrawApprovalReason (reason name), Billing.Withdraw (date filter + CID)
- Same date window filter: `BWIT.ModificationDate BETWEEN @StartDate AND @EndDate`
- `OPTION (RECOMPILE)` on both Result Set 2 and 3 queries

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters** | | | | | | |
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of ModificationDate window. Passed to GetWithdrawRequests and used directly in RS2/RS3. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of ModificationDate window. |
| 3 | @CID | INT | YES | NULL | CODE-BACKED | Optional single-customer filter. Passed to GetWithdrawRequests and applied to RS2/RS3. |
| 4 | @CashoutStatusIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated cashout status filter. Passed to GetWithdrawRequests. |
| 5 | @FundingTypeIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated funding type filter. Passed to GetWithdrawRequests. |
| 6 | @RegulationIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated regulation filter. Passed to GetWithdrawRequests. |
| 7 | @CustomerStatuses | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated customer status filter. Passed to GetWithdrawRequests. Note: parameter order differs from GetWithdrawRequests (here it comes before @Approved). |
| 8 | @Approved | BIT | YES | 0 | CODE-BACKED | Filter to approved=1 only. Passed to GetWithdrawRequests. |
| 9 | @IncludeInternalAccounts | BIT | YES | 1 | CODE-BACKED | When 0: exclude PlayerLevelID=4. Passed to GetWithdrawRequests. |
| **Result Set 1 Output (all columns from GetWithdrawRequests + below)** | | | | | | |
| 10-44 | (all #t columns) | - | - | - | CODE-BACKED | All 35 columns from GetWithdrawRequests. See that procedure's documentation. |
| 45 | WithdrawTypeID | INT | YES | - | CODE-BACKED | Type of withdrawal. From Billing.Withdraw.WithdrawTypeID. |
| 46 | FlowID | INT | YES | - | CODE-BACKED | Flow/routing configuration identifier. From Billing.Withdraw.FlowID. |
| 47 | ExTransactionID | NVARCHAR | YES | - | CODE-BACKED | External transaction ID from the payment processor. From Billing.Withdraw.ExTransactionID. Added MIMOPSA-14499. |
| 48 | WithdrawalType | NVARCHAR | YES | - | CODE-BACKED | Human-readable type string. CONCAT(DWT.Description, ' - ', DF.Description) when FlowID exists and Flow.Description is non-empty; else DWT.Description. From Dictionary.WithdrawType + Dictionary.Flow. |
| **Result Set 2 Output (processing details)** | | | | | | |
| 49 | [Net. Cashout Amount] | DECIMAL(16,2) | YES | - | CODE-BACKED | Net amount at processing level. From Billing.WithdrawToFunding.Amount. |
| 50 | [Exchange Rate] | DECIMAL(16,4) | YES | - | CODE-BACKED | Exchange rate applied at processing. From Billing.WithdrawToFunding.ExchangeRate. |
| 51 | [Currency] | VARCHAR | NO | - | CODE-BACKED | Processing currency. COALESCE(DisplayName, Abbreviation) from Dictionary.Currency on ProcessCurrencyID. |
| 52 | [Status] | VARCHAR | NO | - | CODE-BACKED | Processing-level status. From Dictionary.CashoutStatus.Name on Billing.WithdrawToFunding.CashoutStatusID. |
| 53 | [Funding Method] | VARCHAR | NO | - | CODE-BACKED | Payment method name. From Dictionary.FundingType.Name on Billing.Funding.FundingTypeID. |
| 54 | [Request Time] | DATETIME | YES | - | CODE-BACKED | When this processing record was created. From Billing.WithdrawToFunding.CreationDate. |
| 55 | [Brand] | NVARCHAR | YES | NULL | CODE-BACKED | Credit card brand (e.g., Visa, Mastercard). From Dictionary.CardType.Name when FundingTypeID=1; NULL otherwise. |
| 56 | [Depot] | NVARCHAR | YES | NULL | CODE-BACKED | Payment depot/processor name. From Billing.Depot.Name on Billing.WithdrawToFunding.DepotID. |
| 57 | [PaymentDetails] | VARCHAR | YES | NULL | CODE-BACKED | Payment identifier details. XML-parsed per FundingTypeID (see Section 2.3 for format per type). |
| 58 | [FundingID] | INT | YES | - | CODE-BACKED | Funding record ID at processing level. From Billing.WithdrawToFunding.FundingID. |
| 59 | [Status Modification Time] | DATETIME | YES | - | CODE-BACKED | Last status change at processing level. From Billing.WithdrawToFunding.ModificationDate. |
| 60 | [Processor Value Date] | DATETIME | YES | - | CODE-BACKED | Value date set by the processor. From Billing.WithdrawToFunding.ProcessorValueDate. |
| 61 | [Processed By] | NVARCHAR | YES | NULL | CODE-BACKED | Name of the manager who processed this funding. From BackOffice.Manager on Billing.WithdrawToFunding.ManagerID. |
| 62 | [Withdraw Processing ID] | INT | NO | - | CODE-BACKED | ID of the Billing.WithdrawToFunding row. BWTF.ID. |
| 63 | [ParentStatusID] | INT | NO | - | CODE-BACKED | CashoutStatusID from the parent Billing.Withdraw record. |
| 64 | [CashoutStatusID] | INT | NO | - | CODE-BACKED | CashoutStatusID at the processing level (Billing.WithdrawToFunding). |
| 65 | [WithdrawID] | INT | NO | - | CODE-BACKED | Parent withdrawal ID. From Billing.WithdrawToFunding.WithdrawID. |
| 66 | RollbackAmountInCurrency | DECIMAL | NO | 0 | CODE-BACKED | Total rollback amount in original currency. Subquery on Billing.CashoutRollbackTracking. |
| 67 | RollbackAmountInUSD | DECIMAL | NO | 0 | CODE-BACKED | Total rollback amount in USD. Subquery on Billing.CashoutRollbackTracking. |
| 68 | [Net Amount in Orig. Currency] | DECIMAL | YES | - | CODE-BACKED | Net withdrawal amount in the original deposit currency. From Billing.WithdrawToFunding.RefundAmountInDepositCurrency. Changed to read from table column per MIMOPS2-1843. |
| 69 | [MID Name] | NVARCHAR | YES | NULL | CODE-BACKED | Merchant name. GetMerchantDetails(MerchantAccountID, 1) with fallback to ProtocolMIDSettings/MapMerchantCodeToMid logic. |
| 70 | [MID] | NVARCHAR | YES | NULL | CODE-BACKED | Merchant identifier code. GetMerchantDetails(MerchantAccountID, 0) with same fallback. |
| 71 | ExternalTransactionID | NVARCHAR | YES | - | CODE-BACKED | External transaction ID from parent Billing.Withdraw. |
| 72 | WithdrawalTypeID | INT | YES | - | CODE-BACKED | Numeric withdrawal type from Billing.Withdraw.WithdrawTypeID. |
| **Result Set 3 Output (approval history)** | | | | | | |
| 73 | [WithdrawID] | INT | NO | - | CODE-BACKED | Withdrawal ID for the approval record. |
| 74 | [User Group] | NVARCHAR | NO | - | CODE-BACKED | User group that performed the action. From Dictionary.UserGroup.Name. |
| 75 | [Manager] | NVARCHAR | NO | - | CODE-BACKED | Full name of the manager who approved/rejected. From BackOffice.Manager. |
| 76 | [Approved] | BIT | NO | - | CODE-BACKED | 1=approved, 0=rejected. From WithdrawApproval.Approved. |
| 77 | [Reason] | NVARCHAR | NO | - | CODE-BACKED | Approval/rejection reason name. From Dictionary.WithdrawApprovalReason. |
| 78 | [Comment] | NVARCHAR | YES | - | CODE-BACKED | Free-text comment. From WithdrawApproval.Comment. |
| 79 | [Occurred] | DATETIME | NO | - | CODE-BACKED | When the approval/rejection was recorded. From WithdrawApproval.Occurred. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All parameters | BackOffice.GetWithdrawRequests | EXEC call | Base withdraw list inserted into #t temp table |
| WithdrawID | Billing.Withdraw | JOIN (RS1, RS2, RS3) | Extended fields for RS1; source for RS2/RS3 scope |
| FlowID | Dictionary.Flow | LEFT JOIN (RS1) | Flow description for WithdrawalType |
| WithdrawTypeID | Dictionary.WithdrawType | LEFT JOIN (RS1) | Type description for WithdrawalType |
| WithdrawToFunding | Billing.WithdrawToFunding | Primary (RS2) | Processing-level detail per funding |
| DepotID | Billing.Depot | LEFT JOIN (RS2) | Depot name |
| FundingID | Billing.Funding | JOIN (RS2) | Payment details XML; FundingTypeID |
| FundingTypeID | Dictionary.FundingType | JOIN (RS2) | Payment method name |
| ProcessCurrencyID | Dictionary.Currency | JOIN (RS2) | Processing currency |
| CashoutStatusID | Dictionary.CashoutStatus | JOIN (RS2) | Processing status |
| ManagerID | BackOffice.Manager | LEFT JOIN (RS2) | Processed by |
| CardTypeID | Dictionary.CardType | LEFT JOIN (RS2) | Credit card brand |
| DepositID | Billing.Deposit | LEFT JOIN (RS2) | PayPal return payment data + ProtocolMIDSettings |
| ProtocolMIDSettingsID | Billing.ProtocolMIDSettings | LEFT JOIN x2 (RS2) | MID fallback |
| RegulationID | Dictionary.Regulation | LEFT JOIN x2 (RS2) | Regulation for MID name fallback |
| MerchantCode | Billing.MapMerchantCodeToMid | LEFT JOIN (RS2) | MID code mapping (MIMOPS-2614) |
| FundingID / CID | Billing.CustomerToFunding | LEFT JOIN (RS2) | Customer-funding link |
| CID | Customer.Customer | LEFT JOIN (RS2) | BirthDate for Trustly PaymentDetails |
| WitdrawToFundingID | Billing.CashoutRollbackTracking | Subquery x2 (RS2) | Rollback amounts |
| MerchantAccountID | BackOffice.GetMerchantDetails | Scalar Function (RS2) | MID name and value |
| WithdrawID | BackOffice.WithdrawApproval | UNION (RS3) | Live approval records |
| WithdrawID | History.WithdrawApproval | UNION (RS3) | Archived approval records |
| ManagerID | BackOffice.Manager | JOIN (RS3) | Manager name |
| UserGroupID | Dictionary.UserGroup | JOIN (RS3) | User group name |
| WithdrawApprovalReasonID | Dictionary.WithdrawApprovalReason | JOIN (RS3) | Reason name |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application (BO) | N/A | Application call | Main Cashout Requests report (3-panel UI) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCashOutRequests (procedure)
|- BackOffice.GetWithdrawRequests (EXEC -> #t)
|   +-- (see GetWithdrawRequests dependency chain)
|- Billing.Withdraw (RS1 join + RS2/RS3 scope)
|- Dictionary.Flow, Dictionary.WithdrawType (RS1)
|- Billing.WithdrawToFunding (RS2 primary)
|- Billing.Funding (RS2 - payment details XML)
|- Billing.Depot, Billing.Deposit (RS2)
|- Billing.ProtocolMIDSettings x2 (RS2 - MID fallback)
|- Billing.MapMerchantCodeToMid (RS2 - MIMOPS-2614)
|- Billing.CustomerToFunding (RS2)
|- Billing.CashoutRollbackTracking (RS2 subqueries)
|- BackOffice.GetMerchantDetails (RS2 - scalar function)
|- Customer.Customer (RS2 - BirthDate)
|- BackOffice.Manager (RS2, RS3)
|- Dictionary.FundingType, Currency, CashoutStatus (RS2)
|- Dictionary.CardType, Regulation x2 (RS2)
|- BackOffice.WithdrawApproval (RS3)
|- History.WithdrawApproval (RS3)
|- BackOffice.Manager, Dictionary.UserGroup (RS3)
+-- Dictionary.WithdrawApprovalReason (RS3)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetWithdrawRequests | Procedure | Core data source - executed into #t |
| Billing.Withdraw | Table | RS1 join (type/flow/extransaction); RS2/RS3 scope |
| Dictionary.Flow | Table | RS1 - flow description for WithdrawalType |
| Dictionary.WithdrawType | Table | RS1 - type description for WithdrawalType |
| Billing.WithdrawToFunding | Table | RS2 primary - per-funding processing records |
| Billing.Funding | Table | RS2 - FundingData XML for PaymentDetails |
| Billing.Depot | Table | RS2 - depot name |
| Billing.Deposit | Table | RS2 - PayPal CashoutTypeID=2 + ProtocolMIDSettings |
| Billing.ProtocolMIDSettings | Table | RS2 - MID fallback (x2: from funding + from deposit) |
| Dictionary.Regulation | Table | RS2 - regulation name in MID fallback |
| Billing.MapMerchantCodeToMid | Table | RS2 - merchant code to MID mapping |
| Billing.CustomerToFunding | Table | RS2 - customer-funding link |
| Billing.CashoutRollbackTracking | Table | RS2 - rollback amount subqueries |
| BackOffice.GetMerchantDetails | Scalar Function | RS2 - primary MID resolution |
| Customer.Customer | Table | RS2 - BirthDate for Trustly PaymentDetails |
| BackOffice.Manager | Table | RS2 - Processed By; RS3 - Manager name |
| Dictionary.FundingType | Table | RS2 - payment method name |
| Dictionary.Currency | Table | RS2 - processing currency |
| Dictionary.CashoutStatus | Table | RS2 - processing status |
| Dictionary.CardType | Table | RS2 - credit card brand |
| BackOffice.WithdrawApproval | Table | RS3 - live approval history |
| History.WithdrawApproval | Table | RS3 - archived approval history |
| Dictionary.UserGroup | Table | RS3 - user group name |
| Dictionary.WithdrawApprovalReason | Table | RS3 - approval reason name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (BO) | External application | Main Cashout Requests report - 3 result sets for the full cashout review UI |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- `SET NOCOUNT ON`; `WITH(NOLOCK)` on all tables.
- `OPTION (RECOMPILE)` on Result Set 2 and Result Set 3 queries - prevents parameter-sniffing issues on large tables.
- Result Set 2 capped at `SELECT TOP 100` (implicit cap from the CTE-based scope)... actually no, no TOP on RS2 - scoped by WithdrawIDs CTE.
- Result Set 3: `ORDER BY WAWH.Occurred DESC` - most recent approvals first.
- `#t` temp table lifecycle: created and dropped within the procedure session.
- Note: `Billing.CashoutRollbackTracking` column name has a typo: `WitdrawToFundingID` (single 'd') - matches the actual table column name.

---

## 8. Sample Queries

### 8.1 Run the cashout requests report for a date range

```sql
EXEC BackOffice.GetCashOutRequests
    @StartDate = '2026-03-01',
    @EndDate = '2026-03-17',
    @CID = NULL,
    @CashoutStatusIDs = NULL,
    @FundingTypeIDs = NULL,
    @RegulationIDs = NULL,
    @CustomerStatuses = NULL,
    @Approved = 0,
    @IncludeInternalAccounts = 1;
-- Returns 3 result sets: RS1 (withdraw list), RS2 (processing detail), RS3 (approval history)
```

### 8.2 Single customer full cashout history

```sql
EXEC BackOffice.GetCashOutRequests
    @StartDate = '2020-01-01',
    @EndDate = '2026-12-31',
    @CID = 12345678,
    @CashoutStatusIDs = NULL,
    @FundingTypeIDs = NULL,
    @RegulationIDs = NULL,
    @CustomerStatuses = NULL,
    @Approved = 0,
    @IncludeInternalAccounts = 1;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOPSA-1466 | Jira Sub-Dev | "Create SP GetCashOutRequests" - Jul 2020, Ran Ovadia. Part of parent MIMOPSA-1377 "Cashout Requests - Procedure improvement". |
| MIMOPS-2387 (inferred from comment) | Jira | Oct 2020 - Added BirthDate to PaymentDetails for FundingTypeID=35 (Trustly). |
| MIMOPS-2393 (inferred from comment) | Jira | Oct 2020 - Changed FundingTypeID=33 payment details format to include banking identifiers (BIC, IBAN, SortCode, etc.). |
| MIMOPS-2614 (inferred from comment) | Jira | Nov 2020 - MID resolution via MapMerchantCodeToMid for DepotID=92 scenario. |
| MIMOPS-5237 (inferred from comment) | Jira | Oct 2021 - PayPal New Money: include Payer ID in PaymentDetails (CashoutTypeID=1). |
| MIMOPSA-14499 (inferred from comment) | Jira | Dec 2024 - Added WithdrawalType concatenation (WithdrawType + Flow description) and ExTransactionID. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 9/10, Relationships: 10/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 30 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 1 analyzed (GetWithdrawRequests) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCashOutRequests | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCashOutRequests.sql*
