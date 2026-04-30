# BackOffice.GetProcessedWithdrawPCIVersion_Old

> Legacy version of the processed-withdrawal report that exposes the [PIPs in USD] FX-cost column; superseded by GetProcessedWithdrawPCIVersion which replaced that column with ExchangeFeeInPercentage and narrowed the MID depot list.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate / @EndDate (required); returns Billing.WithdrawToFunding rows with CashoutStatusID IN (3, 16, 17) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetProcessedWithdrawPCIVersion_Old` is the preserved legacy version of the primary Back Office processed-withdrawal report. Its logic, parameters, and most output columns are identical to `GetProcessedWithdrawPCIVersion`. It was retained to support consumers that depend on the `[PIPs in USD]` output column, which was removed from the current version when `[Exchange Fee In Percentage]` was added (MIMOPSA-16636).

The key behavioral difference is that this procedure exposes the calculated PIP-to-USD FX cost via `BackOffice.CalculateWithdrawPIPsUSD`, whereas the current version still calls that function via OUTER APPLY but does not project its result. The _Old version also uses a wider set of DepotIDs (includes 1, 24, 25, 26 in addition to the standard set) in the `GetMerchantDetailsForOneAccountByDepotOnly` call for MID resolution.

Any consumer still referencing this procedure should be evaluated for migration to `GetProcessedWithdrawPCIVersion`. See that procedure's documentation for full business context, logic descriptions, and field-level details - this document covers only the divergences.

---

## 2. Business Logic

### 2.1 All Logic Inherited from GetProcessedWithdrawPCIVersion

**What**: All core business logic is identical to the current version - see [BackOffice.GetProcessedWithdrawPCIVersion](BackOffice.GetProcessedWithdrawPCIVersion.md) Section 2.

**Columns/Parameters Involved**: All parameters and output columns listed in that procedure.

**Rules**:
- CashoutStatusID IN (3, 16, 17) filter - unchanged
- Dual-mode date filtering (@BasedOnTime) - unchanged
- Payment Details XML extraction by FundingTypeID - unchanged
- Dynamic SQL optional filtering - unchanged
- Executed-By resolution via History - unchanged

### 2.2 PIPs in USD Column (Legacy)

**What**: This version explicitly exposes the FX fee expressed in USD calculated by `BackOffice.CalculateWithdrawPIPsUSD`.

**Columns/Parameters Involved**: `CalculatePIPsUSD.Value`, `BWTF.ProcessCurrencyID`, `BWTF.ExchangeRate`, `BWTF.BaseExchangeRate`, `BWTF.Amount`

**Rules**:
- `CalculatePIPsUSD.Value [PIPs in USD]` is projected in the SELECT (unlike the current version where the OUTER APPLY result is silently discarded)
- Formula: difference between base-rate-based USD conversion and actual-rate-based USD conversion, multiplied by base rate (or inverse for non-inverse currencies)
- CurrencyIDs 5, 2, 3, 88, 90, 346, 347, 349 use direct-rate formula; all others use inverse-rate formula
- This column allowed reconciliation of FX spread costs in USD terms; replaced by `ExchangeFeeInPercentage` in the current version

### 2.3 MID Resolution - Wider DepotID Set (Legacy)

**What**: The old version includes additional DepotIDs (1, 24, 25, 26) in the `GetMerchantDetailsForOneAccountByDepotOnly` routing, which the current version removed.

**Columns/Parameters Involved**: `BWTF.DepotID`, `[MID Name]`, `[MID]`

**Rules**:
- Old: DepotIDs IN (1, 24, 25, 26, 78, 79, 80, 4, 75, 86) -> GetMerchantDetailsForOneAccountByDepotOnly
- Current: DepotIDs IN (78, 79, 80, 4, 75, 86) only
- DepotIDs 1, 24, 25, 26 were removed from this routing in the current version (likely migrated to a different depot or the depot routing was changed)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

Identical to `GetProcessedWithdrawPCIVersion`. See [BackOffice.GetProcessedWithdrawPCIVersion](BackOffice.GetProcessedWithdrawPCIVersion.md) Section 4 Input Parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of date range. See current version for full description. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of date range. |
| 3 | @CID | INT | YES | NULL | CODE-BACKED | Optional customer ID filter. |
| 4 | @FundingTypeID | INT | YES | NULL | CODE-BACKED | Optional funding method filter. |
| 5 | @WhiteLabelsIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Optional comma-separated white label IDs. |
| 6 | @RegulationIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Optional comma-separated regulation IDs. |
| 7 | @IncludeInternalAccounts | INTEGER | YES | 0 | CODE-BACKED | 0=exclude PlayerLevelID=4, 1=include all. |
| 8 | @BasedOnTime | INTEGER | YES | 1 | CODE-BACKED | 0=filter by ProcessorValueDate, 1=filter by ModificationDate. |

### Output Columns (Differences from Current Version)

Columns 1-21 (CID through [Fee In PIPs]) are identical to `GetProcessedWithdrawPCIVersion`.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1-21 | (same as current version) | - | - | - | - | See BackOffice.GetProcessedWithdrawPCIVersion columns 1-20, ending at [Fee In PIPs]. |
| 22 | [PIPs in USD] | DECIMAL(16,2) | YES | - | CODE-BACKED | FX exchange cost expressed in USD (CalculatePIPsUSD.Value from BackOffice.CalculateWithdrawPIPsUSD OUTER APPLY). Calculated as the difference between base-rate and actual-rate USD conversions. This column is present ONLY in this legacy version; the current version calls the same function but does not project its output. Added OPSE-236, updated MIMOPSA-9406. |
| 23 | [Net Amount in Orig. Currency] | MONEY | YES | - | VERIFIED | Same as current version - BWTF.RefundAmountInDepositCurrency. |
| 24-41 | (same as current version) | - | - | - | - | [Currency] through FlowID - identical to current version columns 24-41. |
| Note | [Exchange Fee In Percentage] | - | - | - | - | NOT PRESENT in this version. This column was added to the current version in MIMOPSA-16636 and was the trigger for creating this legacy branch. |

---

## 5. Relationships

### 5.1 References To

Identical to `GetProcessedWithdrawPCIVersion`. See [BackOffice.GetProcessedWithdrawPCIVersion](BackOffice.GetProcessedWithdrawPCIVersion.md) Section 5.1.

Additional note: `BackOffice.CalculateWithdrawPIPsUSD` result is projected as `[PIPs in USD]` in this version (vs silently discarded in the current version).

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Legacy consumers) | [PIPs in USD] | Legacy dependency | Any BO reports or integrations expecting the [PIPs in USD] output column should reference this version, not the current one. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetProcessedWithdrawPCIVersion_Old (procedure)
(Same dependency tree as BackOffice.GetProcessedWithdrawPCIVersion)
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
├── Dictionary.* (multiple tables)
├── BackOffice.CalculateWithdrawPIPsUSD (function) <- result IS projected here ([PIPs in USD])
├── BackOffice.GetMerchantDetails (function/proc)
└── Billing.GetMerchantDetailsForOneAccountByDepotOnly (function/proc)
```

### 6.1 Objects This Depends On

Identical to `GetProcessedWithdrawPCIVersion`. See that procedure's Section 6.1.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Legacy consumers) | External | Any BO reports that depend on the [PIPs in USD] output column |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dynamic SQL | Implementation | Same as current version - sp_executesql with runtime WHERE clause |
| Legacy version | Maintenance | Comment block in DDL states: "WHEN YOU ALTER THIS STORED PROCEDURE - REMEMBER TO ALTER ACCORDINGLY: DWH.BackOffice_GetProcessedWithdrawPCIVersion, Billing.GetRollbackedPaymentOrdersReport" |

---

## 8. Sample Queries

### 8.1 Report with PIPs in USD for FX cost reconciliation (legacy use case)
```sql
EXEC [BackOffice].[GetProcessedWithdrawPCIVersion_Old]
    @StartDate = '20250101',
    @EndDate = '20250331',
    @CID = NULL,
    @FundingTypeID = NULL,
    @WhiteLabelsIDs = NULL,
    @RegulationIDs = NULL,
    @IncludeInternalAccounts = 0,
    @BasedOnTime = 1
-- Note: Output includes [PIPs in USD] column (absent from current version)
```

### 8.2 Compare with current version to verify migration readiness
```sql
-- Run both and compare output for a known CID
EXEC [BackOffice].[GetProcessedWithdrawPCIVersion_Old] '20250101', '20250131', 123456, NULL, NULL, NULL, 0, 1
EXEC [BackOffice].[GetProcessedWithdrawPCIVersion]     '20250101', '20250131', 123456, NULL, NULL, NULL, 0, 1
-- Differences: Old has [PIPs in USD]; current has [Exchange Fee In Percentage]
```

### 8.3 Check which consumers still depend on the [PIPs in USD] column
```sql
-- Identify any BI/DWH consumers that call this legacy version
SELECT OBJECT_NAME(object_id) AS ProcName, OBJECT_SCHEMA_NAME(object_id) AS SchemaName
FROM sys.sql_modules WITH (NOLOCK)
WHERE definition LIKE '%GetProcessedWithdrawPCIVersion_Old%'
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [MIMOPSA-16636](https://etoro-jira.atlassian.net/browse/MIMOPSA-16636) | Jira | Addition of ExchangeFeeInPercentage to the current version was the event that created this legacy branch |
| [MIMOPSA-14499](https://etoro-jira.atlassian.net/browse/MIMOPSA-14499) | Jira | FlowID + WithdrawType concatenation and ExTransactionID added - both versions were updated |
| [MIMOPSA-9430](https://etoro-jira.atlassian.net/browse/MIMOPSA-9430) | Jira | RefundAmountInDepositCurrency fix applied to both versions |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 10 CODE-BACKED, 1 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 5, 8, 11 - Phase 10 via parent)*
*Sources: Atlassian: 0 Confluence + 3 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetProcessedWithdrawPCIVersion_Old | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetProcessedWithdrawPCIVersion_Old.sql*
