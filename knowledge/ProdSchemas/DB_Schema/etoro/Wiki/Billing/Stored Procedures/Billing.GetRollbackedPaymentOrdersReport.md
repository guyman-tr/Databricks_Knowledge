# Billing.GetRollbackedPaymentOrdersReport

> Operations report returning up to 50,000 rollbacked payment orders (WithdrawToFunding records in completed-rollback statuses) within a date range, with full enrichment: rollback amounts/dates, funding method payment details parsed from XML, MID resolution across depot/regulation tiers, customer profile, and brand.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate / @EndDate on CRT.ModificationDate + optional @CID / @IgnorePlayerLevelID / @WhiteLabels filters; TOP 50000 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetRollbackedPaymentOrdersReport` is the primary operations report for reviewing rollbacked payment orders - withdrawals that were initially processed but subsequently rolled back (reversed). The report is used by finance and operations teams to investigate, reconcile, and report on reversed withdrawal transactions.

A "rollbacked payment order" is a `Billing.WithdrawToFunding` record that has been reversed after processing. The reversal is tracked in `Billing.CashoutRollbackTracking`, which holds the rollback date, rollback amount in both local and USD currencies, exchange rate, reference number, and rollback reason. This procedure joins these two tables and enriches the result with the full payment context.

Introduced 01 May 2022 (Kate M., OPSE-958) with multiple evolutionary updates:
- Aug 2022 (Stav): Added "Executed by" and "Execution Type"; removed Country and Net $ Amount
- Nov 2022 (Kate M.): Added Payment Order Status and Status Modification Time; removed Request Time and Withdraw Status
- Jan 2023 (Dor I.): Added DepotID to MID resolution logic
- Jun 2024 (Yitzchak Wahnon): Added @WithdrawTypeID parameter parsing internally (not in output)

The TOP 50000 cap guards against performance issues when running without a CID filter. The @WhiteLabels CSV parameter is parsed into a table variable for efficient IN-style matching.

---

## 2. Business Logic

### 2.1 Rollback Status Filter

**What**: Only WithdrawToFunding records in rollback-completed statuses are returned.

**Columns/Parameters Involved**: `BWTF.CashoutStatusID`

**Rules**:
- `CashoutStatusID IN (3, 17, 16)`: The three statuses representing rollback-processed states:
  - 3 = Processed (completed withdrawal, subsequently rolled back)
  - 16 = status 16 (rollback-specific state)
  - 17 = status 17 (rollback-specific state)
- The `CashoutRollbackTracking` record drives the primary filter; `CashoutStatusID` provides the secondary gate

### 2.2 WhiteLabel Filter (CSV Parsing)

**What**: Optionally restricts results to customers belonging to specific white-label brands.

**Columns/Parameters Involved**: `@WhiteLabels`, `CCST.LabelID`, `@WhiteLabelTable`

**Rules**:
- `@WhiteLabels` is a comma-separated list of LabelIDs (e.g., "1,2,5")
- Parsed via `STRING_SPLIT(@WhiteLabels, ',')` into `@WhiteLabelTable (LabelID INT)` before the main query
- Filter: `(@WhiteLabels IS NULL OR EXISTS (SELECT 1 FROM @WhiteLabelTable wl WHERE wl.LabelID = CCST.LabelID))`
- NULL = no white-label filter (all customers returned)
- Uses EXISTS/table variable pattern for efficiency

### 2.3 Player Level Exclusion

**What**: Option to exclude customers at a specific player level (PlayerLevelID=4, typically VIP/regulated tier).

**Columns/Parameters Involved**: `@IgnorePlayerLevelID`, `CCST.PlayerLevelID`

**Rules**:
- `@IgnorePlayerLevelID = 0` (default): Excludes records where `CCST.PlayerLevelID = 4`
- `@IgnorePlayerLevelID = 1` or NULL: No player level filter - all levels included
- Interpretation: Level 4 customers may be excluded by default because they have different operational handling (VIP, regulated, or test accounts)

### 2.4 Payment Details XML Parsing (Per Funding Type)

**What**: The `Payment Details` column is computed from structured XML stored in `Billing.Funding.FundingData` / `Billing.Funding.PaymentDetails` / `Billing.WithdrawToFunding.WithdrawData`, with formatting rules specific to each funding type.

**Columns/Parameters Involved**: `BFUN.FundingTypeID`, `BFUN.FundingData`, `BWTF.WithdrawData`, `BDEP.PaymentData`

**Rules**:

| FundingTypeID | Funding Type | Payment Details Formula |
|--------------|-------------|------------------------|
| 2 | Wire Transfer/Bank | `PaymentDetails + BSBNumberAsString + '; ClientAddress: ' + ClientAddressAsString` (from WithdrawData XML) |
| 3 + CashoutTypeID=1 | PayPal (outbound) | `FundingData.value('.../EmailAsString')` |
| 3 + CashoutTypeID=2 | PayPal (deposit refund) | `DepositData.value('.../PayerAsString')` |
| 10 | WebMoney/eWallet | `'AccountID: ' + AccountIDAsDecimal + '; PurseID: ' + PurseAsString` (FundingData or WithdrawData) |
| 33 | eToroMoney | `GCID + PlatformAccountID + CurrencyBalanceId + Bic + AccountNumber + Iban + SortCode` (from WithdrawData) |
| 35 | (specific type) | `PaymentDetails + '; BirthDate: ' + FORMAT(BirthDate, 'dd/MM/yyyy')` from Customer.Customer |
| 39 | PayID/Osko | `'PayId: ' + AccountIDAsString + '; Email: ' + EmailAsString` (from WithdrawData) |
| Other | All others | `PaymentDetails` verbatim from Billing.Funding |

### 2.5 MID Name and MID Resolution (Multi-Tier)

**What**: The Merchant ID (MID) and MID Name are resolved through a complex cascade of depot-based and funding-type-based lookups.

**Columns/Parameters Involved**: `BWTF.DepotID`, `DFUT.FundingTypeID`, `BWTF.MerchantAccountID`, `BPMS1`, `BPMS2`, `BMMC`

**MID Name rules**:
```
IF DepotID IN (35-43) -> DR2.Name (Regulation name from deposit's ProtocolMIDSettings)
ELIF DepotID IN (1,24,25,26,78,79,80,4,75,86) -> Billing.GetMerchantDetailsForOneAccountByDepotOnly(DepotID, RegulationID, 1)
ELIF FundingTypeID = 2 (Wire Transfer) -> BPMS1.Description
ELSE -> BackOffice.GetMerchantDetails(MerchantAccountID, 1)
     OR BackOffice.GetMerchantDetails(BPMS1.MerchantAccountID, 1)
     OR DR1.Name (Regulation name from withdraw ProtocolMIDSettings)
```

**MID value rules** (similar cascade, parameter `0` instead of `1` for name):
```
IF DepotID IN (35-44) -> BPMS2.Value (deposit's ProtocolMIDSettings value)
ELIF DepotID IN (1,24,25,26,78,79,80,4,75,86) -> GetMerchantDetailsForOneAccountByDepotOnly(..., 0)
ELIF FundingTypeID = 2 OR DepotID = 18 -> BPMS1.Value
ELSE -> BackOffice.GetMerchantDetails(..., 0) OR BPMS1.Description OR BMMC.MID OR BPMS1.Value
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the report date range (inclusive). Applied to `Billing.CashoutRollbackTracking.ModificationDate`. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of the report date range (inclusive). Applied to `Billing.CashoutRollbackTracking.ModificationDate`. |
| 3 | @CID | INTEGER | YES | NULL | CODE-BACKED | Optional filter to a specific customer. NULL = all customers (subject to TOP 50000 cap). |
| 4 | @IgnorePlayerLevelID | INTEGER | YES | 0 | CODE-BACKED | 0 (default): Excludes PlayerLevelID=4 customers. 1 or NULL: Includes all player levels. Controls whether a specific tier (likely VIP or test) is excluded from the report. |
| 5 | @WhiteLabels | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated LabelIDs to restrict to specific white-label brands (e.g., "1,2,5"). NULL = all brands. Parsed via STRING_SPLIT into a table variable before the main query. |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 6 | CID | INT | NO | - | CODE-BACKED | Customer identifier. |
| 7 | Withdraw processing ID | INT | NO | - | CODE-BACKED | `Billing.WithdrawToFunding.ID` - PK of the payment leg that was rolled back. |
| 8 | WithdrawID | INT | NO | - | CODE-BACKED | `Billing.Withdraw.WithdrawID` - parent withdrawal request. |
| 9 | Process Time | DATETIME | YES | - | CODE-BACKED | `Billing.WithdrawToFunding.ProcessorValueDate` - when the payment was originally processed. |
| 10 | Net Amount | DECIMAL | YES | - | CODE-BACKED | `ISNULL(BWTF.RefundAmountInDepositCurrency, 0)` - refund amount in the deposit's original currency. |
| 11 | Currency | NVARCHAR | NO | - | CODE-BACKED | Abbreviation of the processing currency from `Dictionary.Currency` via `BWTF.ProcessCurrencyID` (e.g., "USD", "EUR"). |
| 12 | Net $ Amount | DECIMAL(16,2) | YES | - | CODE-BACKED | `CAST(ISNULL(BWTF.Amount, 0) AS DECIMAL(16,2))` - the payment leg amount in USD. |
| 13 | Rollback Date | DATETIME | YES | - | CODE-BACKED | `Billing.CashoutRollbackTracking.RollbackDate` - when the reversal was issued. |
| 14 | Rollback Amount | DECIMAL | YES | - | CODE-BACKED | `CRT.RollbackAmountInCurrency` - rollback amount in the original payment currency. |
| 15 | Exchange Rate | DECIMAL(16,4) | YES | - | CODE-BACKED | `CAST(ISNULL(CRT.ExchangeRate, 1) AS DECIMAL(16,4))` - exchange rate applied at rollback time (defaults to 1 if NULL). |
| 16 | Fee In PIPs | DECIMAL | YES | - | CODE-BACKED | `BWTF.ExchangeFee` - foreign exchange fee in PIPs (price interest points). |
| 17 | Rollback $ Amount | DECIMAL | YES | - | CODE-BACKED | `CRT.RollbackAmountInUSD` - rollback amount converted to USD. |
| 18 | Reference Number | NVARCHAR | YES | - | CODE-BACKED | `CRT.ReferenceNumber` - external PSP reference number for the rollback transaction. Used for reconciliation. |
| 19 | Rollback Reason | INT | YES | - | CODE-BACKED | `CRT.RollbackReasonID` - reason code for the rollback. FK to rollback reason lookup. |
| 20 | PaymentStatusID | INT | YES | - | CODE-BACKED | `CRT.PaymentStatusID` - payment status at rollback time from `Billing.CashoutRollbackTracking`. |
| 21 | Funding Method | NVARCHAR | NO | - | CODE-BACKED | `Dictionary.FundingType.Name` - name of the payment method (e.g., "Credit Card", "Wire Transfer", "ACH"). |
| 22 | Brand | NVARCHAR | YES | - | CODE-BACKED | `Dictionary.CardType.Name` parsed from `Billing.Funding.FundingData` XML CardTypeIDAsInteger field. Card brand for card payments (e.g., "Visa", "Mastercard"). NULL for non-card payments. |
| 23 | Payment Details | NVARCHAR | YES | - | CODE-BACKED | Payment destination details computed per-funding-type (see Section 2.4). Includes account numbers, IBANs, wallet addresses, email addresses, etc. depending on payment method. |
| 24 | Funding ID | INT | YES | - | CODE-BACKED | `BWTF.FundingID` - the payment instrument FK to `Billing.Funding`. |
| 25 | Depot | NVARCHAR | YES | - | CODE-BACKED | `Billing.Depot.Name` - name of the depot (payment processor infrastructure) used for this transaction. NULL if no depot configured for this payment leg. |
| 26 | Verification Code | NVARCHAR | YES | - | CODE-BACKED | `BWTF.VerificationCode` - transaction verification/authorization code from the payment processor. |
| 27 | Regulation | NVARCHAR | YES | - | CODE-BACKED | Customer's regulatory framework name from `Dictionary.Regulation` via `BackOffice.Customer.RegulationID`. |
| 28 | MID Name | NVARCHAR | YES | - | CODE-BACKED | Merchant name, resolved through multi-tier cascade (see Section 2.5): depot-range rules -> GetMerchantDetailsForOneAccountByDepotOnly -> FundingType override -> BackOffice.GetMerchantDetails fallback. |
| 29 | MID | NVARCHAR | YES | - | CODE-BACKED | Merchant ID value (numeric or alphanumeric), resolved through same multi-tier cascade as MID Name but with value (0) parameter instead of name (1). |
| 30 | Payment Order Status | INT | YES | - | CODE-BACKED | `History.WithdrawToFundingAction.CashoutStatusID` at the time of the rollback action (from `CRT.WithdrawToFundingActionID`). Represents the payment order status when the rollback was recorded. |
| 31 | Status Modification Time | DATETIME | YES | - | CODE-BACKED | `CRT.ModificationDate` - timestamp of the rollback record's last modification. The primary sort and date filter column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CRT.WitdrawToFundingID | Billing.CashoutRollbackTracking | Primary source (INNER JOIN) | Rollback event records |
| CRT.WitdrawToFundingID | Billing.WithdrawToFunding | INNER JOIN | Payment leg execution details |
| BWTF.WithdrawID | Billing.Withdraw | INNER JOIN | Parent withdrawal request |
| BWIT.CID | Customer.Customer | INNER JOIN | Customer profile (PlayerLevelID, LabelID, BirthDate) |
| BWIT.CID | BackOffice.Customer | INNER JOIN | Customer regulation |
| BWTF.FundingID | Billing.FundingPaymentDetailsForWithdraw | INNER JOIN (view) | Funding type and payment details |
| BFUN.FundingTypeID | Dictionary.FundingType | INNER JOIN | Funding method name |
| BWTF.ProcessCurrencyID | Dictionary.Currency | INNER JOIN | Processing currency name |
| CCST.PlayerLevelID | Dictionary.PlayerLevel | INNER JOIN | Player tier (used for filter) |
| CCST.PlayerStatusID | Dictionary.PlayerStatus | INNER JOIN | Player status (used for filter) |
| CRT.WithdrawToFundingActionID | History.WithdrawToFundingAction | LEFT JOIN | Payment Order Status at rollback time |
| BWTF.DepotID | Billing.Depot | LEFT JOIN | Depot name |
| CCST.LabelID | Dictionary.Label | LEFT JOIN | Label (for WhiteLabel filter) |
| BFUN.FundingData XML | Dictionary.CardType | LEFT JOIN | Card brand name |
| BWTF.DepositID | Billing.Deposit | LEFT JOIN | Original deposit (for PayPal payer + ProtocolMIDSettings) |
| BWTF.ProtocolMIDSettingsID | Billing.ProtocolMIDSettings (x2) | LEFT JOIN | MID resolution |
| BPMS1.RegulationID + BPMS2.RegulationID | Dictionary.Regulation (x3) | LEFT JOIN | Regulation names for MID resolution |
| BPMS1.Value + CurrencyID | Billing.MapMerchantCodeToMid | LEFT JOIN | MID mapping fallback |
| (per depot) | Billing.GetMerchantDetailsForOneAccountByDepotOnly | Function call | MID for specific depot groups |
| (fallback) | BackOffice.GetMerchantDetails | Function call (cross-schema) | MID via merchant account ID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Finance/Operations backoffice UI | @StartDate, @EndDate | EXEC | Rollback reconciliation and audit reports |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetRollbackedPaymentOrdersReport (procedure)
+-- Billing.CashoutRollbackTracking (table)
+-- Billing.WithdrawToFunding (table)
+-- Billing.Withdraw (table)
+-- Billing.FundingPaymentDetailsForWithdraw (view)
+-- Billing.Depot (table)
+-- Billing.Deposit (table)
+-- Billing.ProtocolMIDSettings (table, x2 alias)
+-- Billing.MapMerchantCodeToMid (table)
+-- Billing.GetMerchantDetailsForOneAccountByDepotOnly (function)
+-- Customer.Customer (table, cross-schema)
+-- BackOffice.Customer (table, cross-schema)
+-- BackOffice.GetMerchantDetails (function, cross-schema)
+-- History.WithdrawToFundingAction (table, cross-schema)
+-- Dictionary.FundingType (table)
+-- Dictionary.Currency (table)
+-- Dictionary.PlayerLevel (table)
+-- Dictionary.PlayerStatus (table)
+-- Dictionary.Label (table)
+-- Dictionary.CardType (table)
+-- Dictionary.Regulation (table, x3 alias)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CashoutRollbackTracking | Table | Primary source of rollback events and amounts |
| Billing.WithdrawToFunding | Table | Payment leg details (amounts, depot, MID, XML data) |
| Billing.Withdraw | Table | Parent withdrawal CID/WithdrawID |
| Billing.FundingPaymentDetailsForWithdraw | View | INNER JOIN for funding type and payment details XML |
| Billing.Depot | Table | Depot name lookup |
| Billing.Deposit | Table | Original deposit for PayPal payer + deposit ProtocolMIDSettings |
| Billing.ProtocolMIDSettings | Table | MID name and value resolution (x2 aliases) |
| Billing.MapMerchantCodeToMid | Table | MID fallback mapping |
| Billing.GetMerchantDetailsForOneAccountByDepotOnly | Function | MID resolution for specific depot groups |
| Customer.Customer | Table | PlayerLevelID, LabelID, BirthDate |
| BackOffice.Customer | Table | RegulationID |
| BackOffice.GetMerchantDetails | Function (cross-schema) | MID resolution via merchant account ID |
| History.WithdrawToFundingAction | Table (cross-schema) | Payment Order Status at rollback |
| Dictionary.FundingType | Table | Funding method name |
| Dictionary.Currency | Table | Processing currency abbreviation |
| Dictionary.PlayerLevel | Table | Player tier (for filter) |
| Dictionary.PlayerStatus | Table | Player status (for filter) |
| Dictionary.Label | Table | White-label brand filter |
| Dictionary.CardType | Table | Card brand from FundingData XML |
| Dictionary.Regulation | Table | Regulation name (x3 contexts) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Finance/Operations UI | External | Rollback audit and reconciliation reports |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TOP 50000 | Performance cap | Limits result set when no CID is specified to prevent runaway queries on large date ranges |
| @WhiteLabels CSV parsing | Design | STRING_SPLIT into @WhiteLabelTable before main query; empty string values filtered out via `RTRIM(value) <> ''` |
| @IgnorePlayerLevelID=0 excludes level 4 | Business rule | PlayerLevelID=4 customers excluded by default; pass 1 to include them |
| CashoutStatusID IN (3, 17, 16) | Filter | Only rollback-status payment legs returned |
| ORDER BY ModificationDate DESC | Sort | Most recent rollbacks first |
| NOLOCK throughout | Concurrency | All table reads use NOLOCK |
| WithdrawTypeID added but not in output | DDL note | Jun 2024 change (Yitzchak Wahnon) added @WithdrawTypeID internally but did not expose it in the SELECT list |

---

## 8. Sample Queries

### 8.1 Get all rollbacked payment orders in a date range
```sql
EXEC Billing.GetRollbackedPaymentOrdersReport
    @StartDate = '2026-03-01',
    @EndDate   = '2026-03-18 23:59:59';
```

### 8.2 Get rollbacks for a specific customer
```sql
EXEC Billing.GetRollbackedPaymentOrdersReport
    @StartDate = '2026-01-01',
    @EndDate   = '2026-03-18',
    @CID       = 12345678;
```

### 8.3 Get rollbacks for specific white-label brands including all player levels
```sql
EXEC Billing.GetRollbackedPaymentOrdersReport
    @StartDate          = '2026-03-01',
    @EndDate            = '2026-03-18',
    @IgnorePlayerLevelID = 1,
    @WhiteLabels        = '2,5,7';
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| OPSE-958 (referenced in DDL comment, Kate M., 01/05/2022) | Jira | Initial version created for rollback reporting (Jira unavailable for full details) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 31 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (unavailable) | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetRollbackedPaymentOrdersReport | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetRollbackedPaymentOrdersReport.sql*
