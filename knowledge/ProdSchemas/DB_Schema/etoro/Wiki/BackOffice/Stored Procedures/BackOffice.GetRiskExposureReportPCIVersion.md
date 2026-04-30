# BackOffice.GetRiskExposureReportPCIVersion

> Returns the deposit risk exposure report for Back Office - all chargebacks, refunds, and rollback events within a date range, enriched with live customer aggregates, 3DS fraud signals, MID details, and FX fee data. PCI-safe: no raw card numbers in output.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate / @EndDate (required); returns History.Credit rows with CreditTypeID IN (11, 12, 16, 32) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetRiskExposureReportPCIVersion` is the primary Back Office deposit risk/chargeback exposure report. It covers all adverse deposit events - chargebacks (CreditTypeID=11), refunds (12), refunds-treated-as-chargebacks (16), and reverse deposits (32) - for a given time window. The report is used by the Risk, Operations, and Finance teams to track financial exposure from payment reversals, monitor 3DS fraud rates, reconcile FX costs, and review MID-level performance.

"PCI Version" means the output is safe to distribute without PCI-DSS data handling requirements - payment details are extracted from XML as non-card-number identifiers (IBAN, BIC, wallet IDs), and 3DS parameters are extracted from Billing.Trace JSON.

The procedure uses dynamic SQL (`sp_executesql`) to build the query at runtime, allowing optional `@WhiteLabels`, `@IgnorePlayerLevelID`, and `@CID` filters to be added only when provided. White label filtering creates a temporary `#WhiteLabels` table and uses an INNER JOIN pattern to enforce it within the dynamic SQL.

A companion `BackOffice.CalculateDepositPIPsUSD` OUTER APPLY exists in the query but its result is NOT projected in the SELECT (dead code from a prior iteration). The FX cost is instead captured directly from `Billing.Deposit.ExchangeFeeInUSD` as `[Exchange Fee In USD]`.

---

## 2. Business Logic

### 2.1 Report Scope - Adverse Deposit Event Types

**What**: Selects only History.Credit rows representing a negative deposit outcome.

**Columns/Parameters Involved**: `CreditTypeID`, `[Deposit Status]`, `[Rollback $ Amount]`

**Rules**:
- CreditTypeID IN (11, 12, 16, 32) - the JOIN condition on History.Credit
- 11 = Chargeback (bank-initiated reversal)
- 12 = Refund (eToro-initiated refund)
- 16 = RefundAsChargeback (refund counted as chargeback for risk tracking)
- 32 = ReverseDeposit (deposit rollback tracked in BackOffice.DepositRollbackTracking)
- All other credit types are excluded - this is not a general deposit report

### 2.2 Deposit Status Derivation

**What**: Determines the human-readable status label for each event row.

**Columns/Parameters Involved**: `[Deposit Status]`, `PaymentStatusID`, `CreditTypeID`, `ReturnedAmount`

**Rules** (two-tier CASE expression):
- If `PaymentStatusID` is NOT NULL (rollback tracked in DepositRollbackTracking):
  - PaymentStatusID 2 -> name from Dictionary.PaymentStatus
  - PaymentStatusID 11, 12, 26, 37, 38, 39 -> name from Dictionary.PaymentStatus
  - Other PaymentStatusIDs -> NULL (CASE has no ELSE for this branch)
- If `PaymentStatusID` IS NULL (direct credit-type classification):
  - CreditTypeID=11 AND ReturnedAmount < 0 -> 'Chargeback'
  - CreditTypeID=12 AND ReturnedAmount < 0 -> 'Refund'
  - CreditTypeID=16 AND ReturnedAmount < 0 -> 'RefundAsChargeback'
  - CreditTypeID=32 AND ReturnedAmount < 0 -> 'ReverseDeposit'
  - CreditTypeID IN (11,12,16) AND ReturnedAmount > 0 -> 'Approved' (reversal was recovered)
  - Otherwise -> DepositStatus from Dictionary.PaymentStatus via Billing.Deposit.PaymentStatusID

### 2.3 Previous Deposit Status

**What**: Shows what status the deposit was in just before the chargeback/refund event occurred.

**Columns/Parameters Involved**: `[Previous Deposit Status]`, `PS.Name`, `History.Deposit.PaymentStatusID`

**Rules**:
- OUTER APPLY on History.Deposit: SELECT TOP 1 PaymentStatus name WHERE DepositID matches AND Occurred <= T.Occurred ORDER BY Occurred DESC
- This gives the last status change before or at the time the adverse credit event was recorded
- Used by risk teams to understand the deposit's timeline leading up to the reversal

### 2.4 Exchange Fee In USD (FX Cost)

**What**: Reports the platform's FX exchange fee charged on the deposit, expressed in USD. Sign-inverted for rollback events.

**Columns/Parameters Involved**: `[Exchange Fee In USD]`, `BDEP.ExchangeFeeInUSD`, `CreditTypeID`

**Rules**:
- CreditTypeID = 32 (ReverseDeposit): output is `-T.ExchangeFeeInUSD` (negated to represent reversal)
- All other CreditTypeIDs: output is `T.ExchangeFeeInUSD` as-is
- Source: `Billing.Deposit.ExchangeFeeInUSD` - the fee stored at deposit processing time
- NOTE: `BackOffice.CalculateDepositPIPsUSD` is also called via OUTER APPLY but its result is NOT selected. It is dead code retained from OPSE-236 when the column was first added; MIMOPSA-8107 reworked the calculation to use the stored `ExchangeFeeInUSD` value directly.

### 2.5 3DS Fraud Signals

**What**: Extracts 3D Secure authentication parameters and response codes for card deposits.

**Columns/Parameters Involved**: `[3ds parameters]`, `[3ds response]`

**Rules**:
- `[3ds parameters]`: OUTER APPLY on Billing.Trace WHERE TransactionId = DepositID, EventType=1 uses format `CAVV:{v}, ECI:{v}, XID:{v}` (legacy), EventType!=1 uses `$.Payload.Payment.ExtendedData.*` JSON path (3DS v2). Gets TOP 1 ordered by Created DESC, EventType DESC.
- `[3ds response]`: Dictionary.ThreeDsResponseTypes.Name via PaymentData XML `/Deposit/ThreeDsResponseType` field
- NULL for non-card funding types (IBAN, Trustly, crypto wallets)
- Present for card (FundingTypeID=1) deposits that went through 3DS authentication

### 2.6 MID Resolution

**What**: Determines the merchant account name and code for each deposit.

**Columns/Parameters Involved**: `[MID Name]`, `[MID]`, `BDEP.DepotID`, `BFUN.FundingTypeID`

**Rules**:
- FundingTypeID=2 (bank wire): MIDName = BPMS.Description; MID = BPMS.Value
- DepotID IN (78,79,80,4,75,86): use `Billing.GetMerchantDetailsForOneAccountByDepotOnly(DepotID, RegulationID, flag)`
- Otherwise: MIDName = COALESCE(DMA.BODescription, BackOffice.GetMerchantDetails(MerchantAccountID,1), DR.Name); MID = COALESCE(DMA.Name, BackOffice.GetMerchantDetails(MerchantAccountID,0), BPMS.Description, MapMerchantCodeToMid.MID, BPMS.Value)
- `Dictionary.MerchantAccount` (DMA) lookup uses `Billing.Deposit.MerchantAccountID` (fixed in MIMOPSA-8107)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the date range. Filters on History.Credit.Occurred BETWEEN @StartDate AND @EndDate. Required - no default. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of the date range. Filters on History.Credit.Occurred. Required - no default. |
| 3 | @CID | INTEGER | YES | 0 | CODE-BACKED | Optional customer ID filter. 0 = all customers. When > 0, appends AND T.CID = @CID to the dynamic WHERE clause. |
| 4 | @IgnorePlayerLevelID | INTEGER | YES | 0 | CODE-BACKED | Optional player level exclusion. 0 = include all levels. When > 0, appends AND T.PlayerLevelID <> @IgnorePlayerLevelID. Used to exclude internal/test accounts (PlayerLevelID=4). |
| 5 | @WhiteLabels | NVARCHAR(250) | YES | NULL | CODE-BACKED | Optional comma-separated white label IDs. NULL = all labels. When not NULL, creates #WhiteLabels temp table from STRING_SPLIT and adds INNER JOIN to the query to restrict to those labels. Example: N'1,2,5'. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Customer ID of the depositor (Billing.Deposit.CID). |
| 2 | WhiteLabelID | INT | NO | - | CODE-BACKED | White label identifier (Customer.CustomerStatic.LabelID). Used by @WhiteLabels filter. |
| 3 | DepositID | INT | NO | - | CODE-BACKED | Primary key of the original deposit (Billing.Deposit.DepositID). |
| 4 | Deposit Time | DATETIME | NO | - | CODE-BACKED | Original deposit payment date (Billing.Deposit.PaymentDate). |
| 5 | Deposit Amount | DECIMAL(16,2) | NO | - | CODE-BACKED | Deposit amount in the original currency (Billing.Deposit.Amount). |
| 6 | Currency | VARCHAR | NO | - | CODE-BACKED | ISO currency abbreviation of the deposit (Dictionary.Currency.Abbreviation). |
| 7 | Deposit $ Amount | DECIMAL(16,2) | NO | - | CODE-BACKED | Deposit amount converted to USD: Amount * ExchangeRate (Billing.Deposit). |
| 8 | Deposit Status | NVARCHAR | YES | - | VERIFIED | Derived status label for this adverse event. Two-tier logic: if PaymentStatusID is set uses Dictionary.PaymentStatus; otherwise derives from CreditTypeID + ReturnedAmount sign. Values: Chargeback, Refund, RefundAsChargeback, ReverseDeposit, Approved, or raw PaymentStatus name. See Section 2.2. |
| 9 | Previous Deposit Status | NVARCHAR | YES | - | CODE-BACKED | The deposit's status just before this adverse event occurred. From History.Deposit via TOP 1 DESC by Occurred. NULL if no history record precedes the event. |
| 10 | Deposit Status Modification Time | DATETIME | YES | - | CODE-BACKED | When this adverse event's status was set: BackOffice.DepositRollbackTracking.CreateDate if available, else History.Credit.Occurred. |
| 11 | Rollback Date | DATETIME | YES | - | CODE-BACKED | Effective date of the rollback: BackOffice.DepositRollbackTracking.RollbackDate if set, else Billing.Deposit.ClearingHouseEffectiveDate. |
| 12 | Rollback Amount | DECIMAL(16,2) | YES | - | CODE-BACKED | Amount of the rollback in the original currency (BackOffice.DepositRollbackTracking.RollbackAmountInCurrency). NULL for non-tracked chargebacks/refunds. |
| 13 | Exchange Rate | DECIMAL(16,4) | YES | - | CODE-BACKED | FX rate from deposit currency to USD at the time of processing (Billing.Deposit.ExchangeRate). NULL if BackOffice.DepositRollbackTracking.ExchangeRate is not populated. |
| 14 | Conversion Fee | DECIMAL(16,2) | YES | - | CODE-BACKED | FX conversion fee charged at the deposit (BackOffice.DepositRollbackTracking.ExchangeFee). NULL for non-rollback types. |
| 15 | Rollback $ Amount | DECIMAL(16,2) | NO | - | CODE-BACKED | USD value of the rollback: BackOffice.DepositRollbackTracking.RollbackAmountInUSD if available, else History.Credit.Payment (ReturnedAmount) as fallback. |
| 16 | Reference Number | NVARCHAR | YES | - | CODE-BACKED | External reference number: BackOffice.DepositRollbackTracking.ReferenceNumber if set, else Billing.Deposit.RefundVerificationCode. Used for payment processor reconciliation. |
| 17 | Rollback Reason | NVARCHAR | YES | - | CODE-BACKED | Human-readable reason for the rollback (Dictionary.DepositRollbackTypeReason.Name). NULL if no reason code set. |
| 18 | Rollback Canceled | VARCHAR(3) | YES | - | CODE-BACKED | Whether the rollback was subsequently canceled: 'Yes' or 'No' (from BackOffice.DepositRollbackTracking.IsCanceled). NULL if not a tracked rollback. |
| 19 | Funding Method | NVARCHAR | NO | - | CODE-BACKED | Payment method name (Dictionary.FundingType.Name). Examples: CreditCard, WireTransfer, Neteller, Skrill, Trustly. |
| 20 | Brand | NVARCHAR | YES | - | CODE-BACKED | Card brand name (Dictionary.CardType.Name). Populated only when FundingTypeID=1 (credit card). NULL for all other payment methods. |
| 21 | Payment Details | NVARCHAR | YES | - | CODE-BACKED | PCI-safe payment identifier extracted from PaymentData XML, varies by FundingTypeID. FundingTypeID=2: IBAN string; 33: CardID + GCID; 34: IBAN; 35: BIC + IBAN + AccountHolderName; 36: First + Middle + Last Name; others: FundingDetails raw value. |
| 22 | FundingID | INT | YES | - | CODE-BACKED | Internal funding record ID (Billing.Deposit.FundingID / Billing.FundingPaymentDetailsForDeposit). |
| 23 | Depot | NVARCHAR | YES | - | CODE-BACKED | Acquiring depot name (Billing.Depot.Name). NULL if no depot assigned. |
| 24 | Customer Status | NVARCHAR | NO | - | CODE-BACKED | Current customer account status (Dictionary.PlayerStatus.Name via Customer.CustomerStatic.PlayerStatusID). Example: Real, Closed, Blocked. |
| 25 | Risk Status | NVARCHAR | YES | - | CODE-BACKED | Comma-separated list of active risk flags (BackOffice.GetUserRisksByCID OUTER APPLY returning RiskStatusesNames). NULL if no risk flags set. |
| 26 | Verification Level | NVARCHAR | YES | - | CODE-BACKED | KYC verification level (Dictionary.VerificationLevel.Name via BackOffice.Customer.VerificationLevelID). Examples: NotVerified, Verified, FullyVerified. |
| 27 | Customer Level | NVARCHAR | NO | - | CODE-BACKED | Customer tier/VIP level (Dictionary.PlayerLevel.Name via Customer.CustomerStatic.PlayerLevelID). Trimmed of leading/trailing spaces. |
| 28 | Country by Reg. Form | NVARCHAR | YES | - | VERIFIED | Country the customer selected on their registration form (Dictionary.Country.Name via Customer.CustomerStatic.CountryID). NOTE: Current version uses CountryID (registration form country); the _Old version uses CountryIDByIP (GeoIP-detected country at registration). |
| 29 | Regulation | NVARCHAR | YES | - | CODE-BACKED | Regulatory jurisdiction of the customer's account (Dictionary.Regulation.Name via BackOffice.Customer.RegulationID). Example: CySEC, FCA, ASIC, FSCA. |
| 30 | White Label | NVARCHAR | YES | - | CODE-BACKED | White label display name (Dictionary.Label.Name via Customer.CustomerStatic.LabelID). |
| 31 | Account Manager | NVARCHAR | YES | - | CODE-BACKED | First name of the assigned BackOffice account manager (BackOffice.Manager.FirstName). NULL if no manager assigned. |
| 32 | Balance | DECIMAL(16,2) | YES | - | CODE-BACKED | Customer's balance at the time of the credit event (History.Credit.Credit). |
| 33 | Total Deposits | DECIMAL(16,2) | YES | - | CODE-BACKED | Customer's all-time total deposit amount (BackOffice.CustomerAllTimeAggregatedData.TotalDeposit). |
| 34 | Total Processed Cashouts | DECIMAL(16,2) | YES | - | CODE-BACKED | Customer's all-time total withdrawn amount (BackOffice.CustomerAllTimeAggregatedData.TotalCashout). |
| 35 | Total Commissions | DECIMAL(16,2) | YES | - | CODE-BACKED | Customer's all-time total commissions/spread paid (BackOffice.CustomerAllTimeAggregatedData.TotalCommission). |
| 36 | Exchange Fee In USD | DECIMAL | YES | - | VERIFIED | FX exchange fee in USD for this deposit, taken from Billing.Deposit.ExchangeFeeInUSD. For CreditTypeID=32 (ReverseDeposit), the value is negated to reflect the cost direction of a rollback. NULL if the deposit had no FX conversion fee. |
| 37 | Total P&L | DECIMAL(16,2) | YES | - | CODE-BACKED | Customer's all-time realized trading profit/loss (BackOffice.CustomerAllTimeAggregatedData.TotalProfit). |
| 38 | Total Compensations | DECIMAL(16,2) | YES | - | CODE-BACKED | Customer's all-time total compensation payments (BackOffice.CustomerAllTimeAggregatedData.TotalCompensation). |
| 39 | Total Credits | DECIMAL(16,2) | YES | - | CODE-BACKED | Customer's all-time total bonus/credit amount (BackOffice.CustomerAllTimeAggregatedData.TotalBonus). |
| 40 | MID Name | NVARCHAR | YES | - | CODE-BACKED | Merchant account display name. Resolution order: BPMS.Description (FundingTypeID=2), GetMerchantDetailsForOneAccountByDepotOnly (depot-specific), COALESCE(DMA.BODescription, GetMerchantDetails, DR.Name). |
| 41 | MID | NVARCHAR | YES | - | CODE-BACKED | Merchant account code. Resolution order: BPMS.Value (FundingTypeID=2), GetMerchantDetailsForOneAccountByDepotOnly (depot-specific), COALESCE(DMA.Name, GetMerchantDetails, BPMS.Description, MapMerchantCodeToMid.MID, BPMS.Value). |
| 42 | [3ds parameters] | NVARCHAR | YES | - | CODE-BACKED | 3D Secure authentication parameters extracted from Billing.Trace JSON. Format: 'CAVV:{v}, ECI:{v}, XID:{v}'. Null if no 3DS signals present. See Section 2.5. |
| 43 | [3ds response] | NVARCHAR | YES | - | CODE-BACKED | 3D Secure response type name (Dictionary.ThreeDsResponseTypes.Name extracted from Billing.Deposit.PaymentData XML). NULL for non-card or non-3DS deposits. |
| 44 | OldPaymentID | NVARCHAR | YES | - | CODE-BACKED | Legacy payment ID from the original payment system (Billing.Deposit.OldPaymentID). Used for historical reconciliation with pre-migration records. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BDEP.DepositID | Billing.Deposit | Read (driving) | Core deposit data - amount, currency, dates, XML payment data |
| HCRD.CreditTypeID | History.Credit | JOIN (filter) | CreditTypeID IN (11,12,16,32) - adverse event filter |
| BODRT.RollbackID | BackOffice.DepositRollbackTracking | LEFT JOIN | Rollback tracking data for CreditTypeID=32 events |
| T.DepositID | History.Deposit | OUTER APPLY (TOP 1) | Previous deposit status lookup |
| CCST.CID | Customer.CustomerStatic | JOIN | Customer label, country, player status/level |
| BCTM.CID | BackOffice.Customer | JOIN | BO customer profile: manager, regulation, verification level |
| BCTM.CID | BackOffice.GetUserRisksByCID | OUTER APPLY | Live risk flag names |
| BCAD.CID | BackOffice.CustomerAllTimeAggregatedData | JOIN | All-time deposit/cashout/profit aggregates |
| BFUN.FundingID | Billing.FundingPaymentDetailsForDeposit | JOIN | Funding type and payment data for details extraction |
| BDEP.DepotID | Billing.Depot | LEFT JOIN | Depot name |
| BDEP.ProtocolMIDSettingsID | Billing.ProtocolMIDSettings | LEFT JOIN | MID settings for non-depot routing |
| BPMS.RegulationID | Dictionary.Regulation | LEFT JOIN | MID regulation (used in MerchantCodeToMid lookup) |
| BDEP.CurrencyID | Dictionary.Currency | JOIN | Currency abbreviation |
| BDEP.FundingID | Billing.MapMerchantCodeToMid | LEFT JOIN | Fallback MID code via merchant code |
| BDEP.MerchantAccountID | Dictionary.MerchantAccount | LEFT JOIN | Direct merchant account BODescription / Name (MIMOPSA-8107) |
| BODRT.RollbackReasonID | Dictionary.DepositRollbackTypeReason | LEFT JOIN | Rollback reason name |
| BODRT.PaymentStatusID | Dictionary.PaymentStatus | LEFT JOIN (x2) | Status names for rollback and original deposit |
| BFUN.FundingTypeID | Dictionary.FundingType | JOIN | Payment method name |
| BCTM.RegulationID | Dictionary.Regulation | LEFT JOIN | Customer regulation name |
| CCST.PlayerLevelID | Dictionary.PlayerLevel | JOIN | Customer tier name |
| CCST.PlayerStatusID | Dictionary.PlayerStatus | JOIN | Account status name |
| BCTM.VerificationLevelID | Dictionary.VerificationLevel | LEFT JOIN | KYC level name |
| CCST.LabelID | Dictionary.Label | LEFT JOIN | White label name |
| BDEP.PaymentData | Dictionary.ThreeDsResponseTypes | LEFT JOIN | 3DS response type name via XML extraction |
| BDEP.DepositID | Billing.Trace | OUTER APPLY (TOP 1) | 3DS CAVV/ECI/XID parameters from JSON |
| BFUN.FundingData | Dictionary.CardType | LEFT JOIN | Card brand for FundingTypeID=1 |
| T.* | BackOffice.CalculateDepositPIPsUSD | OUTER APPLY | FX PIP cost calculation - result NOT projected in SELECT (dead code) |
| BCST.ManagerID | BackOffice.Manager | LEFT JOIN | Account manager first name |
| BDEP.DepotID | Billing.GetMerchantDetailsForOneAccountByDepotOnly | Scalar function | Depot-specific MID name/code resolution |
| BPMS.MerchantAccountID | BackOffice.GetMerchantDetails | Scalar function | Fallback MID name/code resolution |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetRiskExposureReportPCIVersion_Old | (same params) | Legacy version | Preserved version with [PIPs in USD] column and CountryIDByIP geography |
| (BO Risk/Finance reporting) | (direct call) | Application | Called by BO risk exposure screens and finance reconciliation reports |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetRiskExposureReportPCIVersion (procedure)
├── Billing.Deposit (table) - driving
├── History.Credit (table) - adverse event filter
├── BackOffice.DepositRollbackTracking (table) - rollback tracking
├── History.Deposit (table) - previous status
├── Customer.CustomerStatic (table)
├── BackOffice.Customer (table)
├── BackOffice.CustomerAllTimeAggregatedData (table)
├── Billing.FundingPaymentDetailsForDeposit (table)
├── Billing.Depot (table)
├── Billing.ProtocolMIDSettings (table)
├── Billing.MapMerchantCodeToMid (table)
├── Billing.Trace (table) - 3DS JSON
├── Dictionary.DepositRollbackTypeReason (table)
├── Dictionary.PaymentStatus (table - x2)
├── Dictionary.FundingType (table)
├── Dictionary.Currency (table)
├── Dictionary.Country (table)
├── Dictionary.Regulation (table - x2)
├── Dictionary.PlayerLevel (table)
├── Dictionary.PlayerStatus (table)
├── Dictionary.VerificationLevel (table)
├── Dictionary.Label (table)
├── Dictionary.CardType (table)
├── Dictionary.ThreeDsResponseTypes (table)
├── Dictionary.MerchantAccount (table)
├── BackOffice.Manager (table)
├── BackOffice.GetUserRisksByCID (function/TVF)
├── BackOffice.CalculateDepositPIPsUSD (function - OUTER APPLY, result unused)
├── Billing.GetMerchantDetailsForOneAccountByDepotOnly (scalar function)
└── BackOffice.GetMerchantDetails (scalar function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Driving table - deposit amounts, dates, currency, XML payment data, ExchangeFeeInUSD |
| History.Credit | Table | JOIN on CreditTypeID IN (11,12,16,32) AND DepositID - adverse event filter |
| BackOffice.DepositRollbackTracking | Table | LEFT JOIN - rollback dates, amounts, reasons, cancellation status |
| History.Deposit | Table | OUTER APPLY TOP 1 - previous deposit status before the adverse event |
| Customer.CustomerStatic | Table | JOIN - country, label, player level/status |
| BackOffice.Customer | Table | JOIN (x2 as BCTM/BCST) - manager, regulation, verification level |
| BackOffice.CustomerAllTimeAggregatedData | Table | JOIN - financial aggregates |
| Billing.FundingPaymentDetailsForDeposit | Table | JOIN - funding type, payment data for details extraction |
| Billing.Depot | Table | LEFT JOIN - depot name |
| Billing.ProtocolMIDSettings | Table | LEFT JOIN - MID settings value/description |
| Billing.MapMerchantCodeToMid | Table | LEFT JOIN - fallback MID code |
| Billing.Trace | Table | OUTER APPLY TOP 1 - 3DS JSON parameters |
| Dictionary.* (multiple) | Tables | Lookup tables for names/labels |
| BackOffice.Manager | Table | LEFT JOIN - account manager name |
| BackOffice.GetUserRisksByCID | TVF | OUTER APPLY - risk flag names |
| BackOffice.CalculateDepositPIPsUSD | Inline TVF | OUTER APPLY - FX PIP cost (result NOT projected) |
| Billing.GetMerchantDetailsForOneAccountByDepotOnly | Scalar Function | Depot-specific MID resolution |
| BackOffice.GetMerchantDetails | Scalar Function | Fallback MID resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetRiskExposureReportPCIVersion_Old | Stored Procedure | Legacy variant - same logic but [PIPs in USD] instead of [Exchange Fee In USD] |
| (BO application layer) | External | Called by Back Office risk exposure screens and finance reporting tools |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dynamic SQL | Implementation | Uses sp_executesql with runtime-constructed WHERE clause for optional filter parameters. White label filter adds INNER JOIN to temp table #WhiteLabels created from STRING_SPLIT. |
| Dead OUTER APPLY | Implementation | BackOffice.CalculateDepositPIPsUSD OUTER APPLY result is not in the SELECT list - retained from OPSE-236 when PIPs column was first added; superseded by BDEP.ExchangeFeeInUSD direct read. |
| CountryID vs CountryIDByIP | Geography | Current version uses CCST.CountryID (registration form country). _Old version uses CCST.CountryIDByIP (GeoIP detection at registration time). Both output column is labeled "Country by Reg. Form" / "Country By Reg Form" respectively. |
| CreditTypeID filter in JOIN | Performance | The CreditTypeID IN (11,12,16,32) predicate is in the JOIN ON clause (not WHERE), which limits the History.Credit rows early. |

---

## 8. Sample Queries

### 8.1 Standard risk exposure report for a date range
```sql
EXEC [BackOffice].[GetRiskExposureReportPCIVersion]
    @StartDate = '20250101',
    @EndDate = '20250331',
    @CID = 0,
    @IgnorePlayerLevelID = 0,
    @WhiteLabels = NULL
```

### 8.2 Chargebacks and refunds for a specific customer
```sql
EXEC [BackOffice].[GetRiskExposureReportPCIVersion]
    @StartDate = '20240101',
    @EndDate = '20251231',
    @CID = 123456,
    @IgnorePlayerLevelID = 0,
    @WhiteLabels = NULL
```

### 8.3 Risk exposure for specific white labels, excluding internal accounts (PlayerLevelID=4)
```sql
EXEC [BackOffice].[GetRiskExposureReportPCIVersion]
    @StartDate = '20250101',
    @EndDate = '20250131',
    @CID = 0,
    @IgnorePlayerLevelID = 4,
    @WhiteLabels = N'1,2'
```

### 8.4 Direct query for adverse deposit events (without SP overhead)
```sql
SELECT HCRD.CreditTypeID, BDEP.DepositID, BDEP.CID, HCRD.Occurred,
       BDEP.Amount, BDEP.ExchangeFeeInUSD
FROM Billing.Deposit BDEP WITH (NOLOCK)
JOIN History.Credit HCRD WITH (NOLOCK)
  ON HCRD.CreditTypeID IN (11, 12, 16, 32) AND HCRD.DepositID = BDEP.DepositID
WHERE HCRD.Occurred BETWEEN '20250101' AND '20250131'
ORDER BY HCRD.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [OPSE-236](https://etoro-jira.atlassian.net/browse/OPSE-236) | Jira | Sub-DB task under OPSE-164 "OPS1743 - Add PIPS in USD to BO reports". Added BackOffice.CalculateDepositPIPsUSD OUTER APPLY and initial [PIPs in USD] column to this procedure (Nov 2021). Also modified BillingDepositsPCIVersion, CalculateWithdrawPIPsUSD, GetProcessedWithdrawPCIVersion in same change. |
| [MIMOPSA-8107](https://etoro-jira.atlassian.net/browse/MIMOPSA-8107) | Jira | Sub-Dev task under MIMOPSA-8106 "Columns 'MID' and 'MID Name' are blank in the Transactions Rollbacks Deposit screen". Fixed MID and MIDName calculation to include Dictionary.MerchantAccount lookup (DMA.BODescription / DMA.Name) - this is the change that also replaced the projected CalculateDepositPIPsUSD result with ExchangeFeeInUSD (Dec 2022). |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 37 CODE-BACKED, 0 ATLASSIAN-ONLY, 5 NAME-INFERRED | Phases: 5/5 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 2 Jira | Procedures: 1 legacy variant | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetRiskExposureReportPCIVersion | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetRiskExposureReportPCIVersion.sql*
