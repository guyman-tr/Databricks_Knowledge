# BackOffice.GetRiskExposureReportPCIVersion_Old

> Legacy version of the deposit risk exposure report that exposes the [PIPs in USD] FX-cost column and uses GeoIP country (CountryIDByIP); superseded by GetRiskExposureReportPCIVersion which replaced [PIPs in USD] with [Exchange Fee In USD] and switched to registration-form country (CountryID).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate / @EndDate (required); returns History.Credit rows with CreditTypeID IN (11, 12, 16, 32) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetRiskExposureReportPCIVersion_Old` is the preserved legacy version of the primary Back Office deposit risk/chargeback exposure report. Its parameters, core query logic, and most output columns are identical to `GetRiskExposureReportPCIVersion`. See that procedure's documentation for full business context, logic descriptions, and field-level details - this document covers only the divergences.

The procedure was retained to support consumers that depend on the `[PIPs in USD]` output column. That column was replaced in the current version by `[Exchange Fee In USD]` (sourced directly from `Billing.Deposit.ExchangeFeeInUSD`) when MIMOPSA-8107 reworked the MID calculation. At the same time the country lookup was changed from `CountryIDByIP` (IP-detected country at registration) to `CountryID` (country selected on the registration form) in the current version, creating a semantically different `[Country by Reg. Form]` column.

---

## 2. Business Logic

### 2.1 All Logic Inherited from GetRiskExposureReportPCIVersion

**What**: All core business logic is identical to the current version.

**Rules**:
- CreditTypeID IN (11, 12, 16, 32) filter - unchanged
- Deposit Status two-tier derivation logic - unchanged
- Previous Deposit Status via History.Deposit - unchanged
- 3DS parameters from Billing.Trace JSON - unchanged
- MID resolution logic (FundingTypeID=2, DepotID list, COALESCE fallback) - unchanged
- Dynamic SQL optional filtering (@WhiteLabels, @IgnorePlayerLevelID, @CID) - unchanged

See [BackOffice.GetRiskExposureReportPCIVersion](BackOffice.GetRiskExposureReportPCIVersion.md) Section 2 for full details.

### 2.2 PIPs in USD Column (Legacy)

**What**: This version explicitly exposes the FX spread cost in USD calculated by `BackOffice.CalculateDepositPIPsUSD`.

**Columns/Parameters Involved**: `CalculateDepositPIPsUSD.Value`, `T.FundingTypeID`, `T.ExchangeRate`, `T.BaseExchangeRate`, `T.ExchangeFee`, `T.RollbackAmountInCurrency`, `T.CurrencyID`

**Rules**:
- `CalculateDepositPIPsUSD.Value AS [PIPs in USD]` is projected in the SELECT (unlike the current version where the OUTER APPLY result is silently discarded)
- The function takes 6 parameters: FundingTypeID, ExchangeRate, BaseExchangeRate, ExchangeFee, RollbackAmountInCurrency (cast to DECIMAL(16,2)), CurrencyID
- The CurrencyID parameter was added in January 2024 (KateM) to support AED formula handling
- The RollbackAmountInCurrency parameter replaced Amount (deposit amount) in November 2023 (KateM) to correctly reflect the rollback amount rather than the original deposit amount
- This column allowed reconciliation of FX spread costs expressed in USD; superseded by `[Exchange Fee In USD]` from `BDEP.ExchangeFeeInUSD` in the current version

### 2.3 Country Source - GeoIP vs Registration Form (Legacy Difference)

**What**: The old version uses the IP-detected country at registration, while the current version uses the country selected on the registration form.

**Columns/Parameters Involved**: `T.CountryID AS [Country By Reg Form]` (old); `T.CountryByRegForm AS [Country by Reg. Form]` (current)

**Rules**:
- Old: `JOIN Dictionary.Country DCNT ON DCNT.CountryID = CCST.CountryIDByIP` - GeoIP-detected country
  - Column alias: `DCNT.Name AS CountryID` in inner SELECT (confusingly named); output column `[Country By Reg Form]`
- Current: `JOIN Dictionary.Country DCNT ON DCNT.CountryID = CCST.CountryID` - registration form country
  - Column alias: `DCNT.Name AS CountryByRegForm` in inner SELECT; output column `[Country by Reg. Form]`
- The old column name "CountryID" (the inner SELECT alias) is a naming artifact - the value is still a country name string, not an ID

### 2.4 Missing [Exchange Fee In USD] Column (Legacy)

**What**: The current version added `[Exchange Fee In USD]` sourced from `Billing.Deposit.ExchangeFeeInUSD`. This column does NOT exist in the old version.

**Rules**:
- Old version inner SELECT does NOT include `BDEP.ExchangeFeeInUSD`
- Old version SELECT list does NOT include `[Exchange Fee In USD]`
- The position after `[Total Commissions]` in the old version is `[PIPs in USD]` (from CalculateDepositPIPsUSD)
- In the current version, `[PIPs in USD]` was replaced by `[Exchange Fee In USD]`

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

Identical to `GetRiskExposureReportPCIVersion`. See [BackOffice.GetRiskExposureReportPCIVersion](BackOffice.GetRiskExposureReportPCIVersion.md) Section 4 Input Parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of date range. Filters on History.Credit.Occurred. Required. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of date range. |
| 3 | @CID | INTEGER | YES | 0 | CODE-BACKED | Optional customer ID filter. 0 = all. |
| 4 | @IgnorePlayerLevelID | INTEGER | YES | 0 | CODE-BACKED | Optional player level exclusion. 0 = include all. |
| 5 | @WhiteLabels | NVARCHAR(250) | YES | NULL | CODE-BACKED | Optional comma-separated white label IDs. |

### Output Columns (Differences from Current Version)

Columns 1-35 (CID through [Total Commissions]) are identical to `GetRiskExposureReportPCIVersion`.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1-35 | (same as current version) | - | - | - | - | See BackOffice.GetRiskExposureReportPCIVersion columns 1-35. |
| 36 | [PIPs in USD] | DECIMAL | YES | - | CODE-BACKED | FX exchange cost in USD calculated by BackOffice.CalculateDepositPIPsUSD OUTER APPLY. Uses 6 parameters: FundingTypeID, ExchangeRate, BaseExchangeRate, ExchangeFee, RollbackAmountInCurrency, CurrencyID. This column is ONLY in this legacy version. |
| Note | [Exchange Fee In USD] | - | - | - | - | NOT PRESENT in this version. Added to the current version in MIMOPSA-8107, replacing [PIPs in USD]. |
| 37 | [Total P&L] | DECIMAL(16,2) | YES | - | CODE-BACKED | Same as current version - TotalProfit. Position shifts by 1 vs current due to [PIPs in USD] vs [Exchange Fee In USD] swap. |
| 38-44 | (same as current version) | - | - | - | - | [Total Compensations] through [OldPaymentID] - same as current version columns 38-44. |
| Country difference | [Country By Reg Form] | NVARCHAR | YES | - | VERIFIED | Old version: from CCST.CountryIDByIP (GeoIP-detected country). Current version [Country by Reg. Form]: from CCST.CountryID (registration form selection). Both display country name from Dictionary.Country. |

---

## 5. Relationships

### 5.1 References To

Identical to `GetRiskExposureReportPCIVersion` with these differences:
- `BackOffice.CalculateDepositPIPsUSD` OUTER APPLY result IS projected as `[PIPs in USD]`
- Country JOIN uses `CCST.CountryIDByIP` instead of `CCST.CountryID`
- `BDEP.ExchangeFeeInUSD` is NOT in the inner SELECT

See [BackOffice.GetRiskExposureReportPCIVersion](BackOffice.GetRiskExposureReportPCIVersion.md) Section 5.1 for full dependency list.

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Legacy consumers) | [PIPs in USD] | Legacy dependency | Any BO reports or integrations expecting the [PIPs in USD] output column should use this version. |
| (Legacy consumers) | [Country By Reg Form] (CountryIDByIP) | Legacy dependency | Consumers relying on GeoIP country rather than registration-form country must use this version. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetRiskExposureReportPCIVersion_Old (procedure)
(Same dependency tree as BackOffice.GetRiskExposureReportPCIVersion)
├── Billing.Deposit (table) - driving
├── History.Credit (table)
├── BackOffice.DepositRollbackTracking (table)
├── History.Deposit (table)
├── Customer.CustomerStatic (table) - CountryIDByIP used (not CountryID)
├── BackOffice.Customer (table)
├── BackOffice.CustomerAllTimeAggregatedData (table)
├── Billing.FundingPaymentDetailsForDeposit (table)
├── Dictionary.* (multiple)
├── BackOffice.Manager (table)
├── BackOffice.GetUserRisksByCID (TVF)
├── BackOffice.CalculateDepositPIPsUSD (function) <- result IS projected as [PIPs in USD]
├── Billing.GetMerchantDetailsForOneAccountByDepotOnly (scalar function)
└── BackOffice.GetMerchantDetails (scalar function)
```

### 6.1 Objects This Depends On

Identical to `GetRiskExposureReportPCIVersion`. See that procedure's Section 6.1. Key difference: `BackOffice.CalculateDepositPIPsUSD` result IS projected here.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Legacy consumers) | External | Any BO reports that depend on the [PIPs in USD] output column or CountryIDByIP geography |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dynamic SQL | Implementation | Same as current version - sp_executesql with runtime WHERE clause, STRING_SPLIT for @WhiteLabels |
| Legacy version | Maintenance | Preserve this procedure for any consumers relying on [PIPs in USD] or CountryIDByIP geography before migrating to current version |
| CountryIDByIP geography | Data | Old version country reflects GeoIP detection at registration, which may differ from user's declared country in registration form |

---

## 8. Sample Queries

### 8.1 Report with PIPs in USD for FX cost reconciliation (legacy use case)
```sql
EXEC [BackOffice].[GetRiskExposureReportPCIVersion_Old]
    @StartDate = '20250101',
    @EndDate = '20250331',
    @CID = 0,
    @IgnorePlayerLevelID = 0,
    @WhiteLabels = NULL
-- Note: Output includes [PIPs in USD] column (absent from current version)
-- Note: Country is derived from CountryIDByIP (GeoIP), not CountryID (registration form)
```

### 8.2 Compare with current version to verify migration readiness
```sql
-- Run both and compare output for a known CID
EXEC [BackOffice].[GetRiskExposureReportPCIVersion_Old] '20250101', '20250131', 123456, 0, NULL
EXEC [BackOffice].[GetRiskExposureReportPCIVersion]     '20250101', '20250131', 123456, 0, NULL
-- Differences: Old has [PIPs in USD]; current has [Exchange Fee In USD]
-- Country column: old uses CountryIDByIP; current uses CountryID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [OPSE-236](https://etoro-jira.atlassian.net/browse/OPSE-236) | Jira | Added CalculateDepositPIPsUSD and initial [PIPs in USD] column to both versions (Nov 2021). Parent story OPSE-164: "OPS1743 - Add PIPS in USD to BO reports". |
| [MIMOPSA-8107](https://etoro-jira.atlassian.net/browse/MIMOPSA-8107) | Jira | Fixed MID/MIDName blank issue in Transactions Rollbacks Deposit screen. Current version updated; this legacy version preserved with original [PIPs in USD] and CountryIDByIP behavior (Dec 2022). |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 5, 8, 11 - Phase 10 via parent)*
*Sources: Atlassian: 0 Confluence + 2 Jira | Procedures: 1 current version analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetRiskExposureReportPCIVersion_Old | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetRiskExposureReportPCIVersion_Old.sql*
