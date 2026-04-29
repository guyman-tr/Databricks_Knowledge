# BI_DB_dbo.BI_DB_AdvancedDeposit_Ext

> **DORMANT TABLE — 0 rows.** Extended deposit denormalization table with 47 columns combining deposit transactions from Fact_BillingDeposit (via Billing.Deposit) with customer demographics (Dim_Customer, Dim_Country), acquisition attribution (Dim_Funnel, Dim_Affiliate/Dim_Channel), payment status lookups (Dim_PaymentStatus, Dictionary_RiskManagementStatus), and credit card BIN metadata (Dim_CardType, Dim_CountryBin). Populated historically by SP_H_Deposits (which creates an identically-structured `#AdvancedDeposit_Ext` temp table). Backed up and emptied ~November 2024; superseded by BI_DB_Deposits.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown (dormant) — column lineage traced via SP_H_Deposits temp table to Fact_BillingDeposit (Billing.Deposit) + 10 dim/external lookups |
| **Refresh** | None — table is dormant (0 rows, no active writer targets this table) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Row Count** | 0 (empty) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_AdvancedDeposit_Ext` was an **extended deposit analysis table** that denormalized deposit transactions with customer demographics, acquisition channel attribution, payment and risk status lookups, and credit card BIN metadata into a single wide table for BI reporting.

**This table is now EMPTY (0 rows)** and no stored procedure actively writes to it. However, `SP_H_Deposits` creates a temp table `#AdvancedDeposit_Ext` with an identical 47-column structure (plus 5 extra columns: ResponseName, ResponseRN, Date, DateID, UpdateDate), which is then filtered and inserted into `BI_DB_dbo.BI_DB_Deposits`. This shared structure confirms the column lineage.

A backup cleanup script (`BI_DB_AdvancedDeposit_Ext_Backup_20241117`) was executed on 2024-12-01, suggesting the table was decommissioned around November 2024.

**Data sources (traced from SP_H_Deposits):**
- **Deposit core** (22 columns): `DWH_dbo.Fact_BillingDeposit` — passthrough from `etoro.Billing.Deposit`
- **Payment status denormalization** (4 columns): `Dim_PaymentStatus` + `External_etoro_Dictionary_RiskManagementStatus`
- **Customer demographics** (5 columns): `Dim_Customer` (Registered, AffiliateID->SerialID) + `Dim_Country` (Country name) + `External_etoro_Dictionary_MarketingRegion` (Region)
- **Acquisition attribution** (6 columns): `Dim_Funnel` (3 joins), `Dim_Affiliate`+`Dim_Channel` (Channel, SubChannel)
- **Credit card BIN metadata** (6 columns): `Dim_CardType`, `Dim_CountryBin`, `Dim_Country` (BIN country)
- **FTD dates** (2 columns): `External_etoro_BackOffice_CustomerAllTimeAggregatedData`
- **Hardcoded NULLs** (2 columns): OldPaymentID, Code

**Recommendation**: This DDL is a candidate for cleanup (DROP from SSDT). Use `BI_DB_Deposits` instead.

---

## 2. Business Logic

### 2.1 Extended Deposit Denormalization

**What**: Combines deposit fact data with all relevant dimension lookups in a single wide table, eliminating JOINs for BI consumers.
**Columns Involved**: All 47 columns
**Rules**:
- Deposit core fields pass through from Fact_BillingDeposit without transformation
- PaymentStatus and RiskManagementStatus are pre-joined (both ID and Name columns present as separate column pairs)
- Channel/SubChannel are resolved through a two-hop lookup: Dim_Customer.AffiliateID -> Dim_Affiliate.SubChannelID -> Dim_Channel
- SP filters `WHERE PlayerLevelID != 4` (excludes Popular Investors) and `WHERE fbd.ModificationDate >= @Date` (daily incremental)

### 2.2 Credit Card BIN Analysis

**What**: Credit card metadata was included for deposit method analysis and fraud detection.
**Columns Involved**: BinCode, CreditCardType, CardSubType, BINCountry, CardCategory
**Rules**:
- BinCode sourced from `Fact_BillingDeposit.BinCodeAsString`
- CreditCardType resolved via `Dim_CardType` on `fbd.CardTypeIDAsInteger`
- CardSubType and CardCategory resolved via `Dim_CountryBin` on `fbd.BinCodeAsString`
- BINCountry resolved via `Dim_Country` on `fbd.BinCountryIDAsInteger` — may differ from customer's registration country (fraud signal)

### 2.3 Acquisition Attribution

**What**: Customer acquisition details for marketing ROI analysis on deposits.
**Columns Involved**: SerialID, Channel, SubChannel, Funnel, FunnelFrom, AcquisitionFunnel, FirstDepositAttempt, FirstDepositDate, Registered
**Rules**:
- SerialID = `Dim_Customer.AffiliateID` (renamed; production origin: Customer.CustomerStatic.SerialID)
- Three distinct funnel name lookups from `Dim_Funnel`: (1) Funnel via `fbd.FunnelID` = deposit-level funnel, (2) FunnelFrom via `CC.FunnelFromID` = customer's originating registration funnel, (3) AcquisitionFunnel via `CC.FunnelID` = customer's current acquisition funnel
- FirstDepositAttempt and FirstDepositDate from `External_etoro_BackOffice_CustomerAllTimeAggregatedData` (customer-level aggregated dates, not per-deposit)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP. **Table is empty — no queries will return data.**

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Deposit analysis with demographics | Use `BI_DB_dbo.BI_DB_Deposits` (active replacement) or `Fact_BillingDeposit` + dim JOINs |
| Credit card BIN analysis | Use `BI_DB_Deposits` or join `Fact_BillingDeposit` with `Dim_CardType` and `Dim_CountryBin` |
| FTD attribution by channel | Use `BI_DB_Deposits` WHERE IsFTD=1 |

### 3.3 Common JOINs

None applicable — table is empty. Historical JOINs would have been unnecessary since all lookups are denormalized into this table.

### 3.4 Gotchas

- **TABLE IS EMPTY**: Do not query this table expecting results. Use `BI_DB_Deposits` instead.
- **No active writer**: SP_H_Deposits creates a matching temp table but writes to `BI_DB_Deposits`, not this table.
- **OldPaymentID and Code are always NULL**: Hardcoded as NULL in the SP — these columns were never populated.
- **PII content**: Contains IPAddress (numeric) and BinCode — treat as sensitive if table is ever repopulated.
- **PlayerLevelID=4 excluded**: Popular Investors were filtered out in the SP; this table never contained PI deposits.
- **CID type mismatch**: DDL has CID as `int`, while the backup table has it as `bigint`. The current DDL may have been modified after decommissioning.
- **IsFTD type narrowing**: Fact_BillingDeposit stores IsFTD as `int` (0/1); this DDL uses `bit`. No data loss but type-aware queries should account for this.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP_H_Deposits code analysis — no upstream wiki was available in the pre-resolved bundle, so Tier 1 verbatim inheritance is not possible |

### Phase Gate Checklist

```
PHASE GATE — BI_DB_dbo.BI_DB_AdvancedDeposit_Ext:
  [x] P1 DDL          [x] P2 Sample        [-] P3 Dist (0 rows)
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (dormant) [x] P8 SP-scan     [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (none)  [x] P10A Upstream
  [x] P10B Lineage    -> Ready for P11
```

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DepositID | bigint | YES | Unique identifier for each deposit attempt. Passthrough from Fact_BillingDeposit.DepositID (production origin: Billing.Deposit). PK in the production source. (Tier 2 — SP_H_Deposits code analysis) |
| 2 | CID | int | YES | Customer ID identifying the customer who made this deposit. Passthrough from Fact_BillingDeposit.CID. JOIN key to Dim_Customer.RealCID. (Tier 2 — SP_H_Deposits code analysis) |
| 3 | FundingID | bigint | YES | Payment instrument identifier (credit card, bank account, e-wallet) used for this deposit. Passthrough from Fact_BillingDeposit.FundingID. FK to Billing.Funding. (Tier 2 — SP_H_Deposits code analysis) |
| 4 | FundingType | varchar(50) | YES | Payment method name (e.g., CreditCard, Wire, PayPal). Dim-lookup from Dim_FundingType.Name via External_etoro_Billing_Funding_Datafactory on Funding.FundingTypeID. (Tier 2 — SP_H_Deposits code analysis) |
| 5 | CurrencyID | bigint | YES | Currency of the deposit amount. Passthrough from Fact_BillingDeposit.CurrencyID. FK to Dim_Currency. (Tier 2 — SP_H_Deposits code analysis) |
| 6 | PaymentStatusID | bigint | YES | Current deposit payment status. Passthrough from Fact_BillingDeposit.PaymentStatusID. FK to Dim_PaymentStatus. (Tier 2 — SP_H_Deposits code analysis) |
| 7 | ManagerID | bigint | YES | Operations manager who processed this deposit. 0 = automated processing. Passthrough from Fact_BillingDeposit.ManagerID. (Tier 2 — SP_H_Deposits code analysis) |
| 8 | RiskManagementStatusID | bigint | YES | Risk management check result code. Passthrough from Fact_BillingDeposit.RiskManagementStatusID. FK to External_etoro_Dictionary_RiskManagementStatus. NULL = no risk check recorded. (Tier 2 — SP_H_Deposits code analysis) |
| 9 | Amount | money | YES | Deposit amount in the deposit currency (CurrencyID). Passthrough from Fact_BillingDeposit.Amount. (Tier 2 — SP_H_Deposits code analysis) |
| 10 | ExchangeRate | numeric(16,8) | YES | Exchange rate from deposit currency to USD at processing time. Passthrough from Fact_BillingDeposit.ExchangeRate. (Tier 2 — SP_H_Deposits code analysis) |
| 11 | ModificationDate | datetime | YES | UTC timestamp of the most recent modification to this deposit record. Used by ETL for incremental detection. Passthrough from Fact_BillingDeposit.ModificationDate. (Tier 2 — SP_H_Deposits code analysis) |
| 12 | TransactionID | varchar(6) | YES | Provider transaction ID string. Renamed from Fact_BillingDeposit.TransactionIDAsString. Truncated to varchar(6) in DDL. (Tier 2 — SP_H_Deposits code analysis) |
| 13 | IPAddress | numeric(18,0) | YES | Customer IP address at deposit time stored as a 32-bit integer. PII — used for fraud detection and geo-verification. Passthrough from Fact_BillingDeposit.IPAddress. (Tier 2 — SP_H_Deposits code analysis) |
| 14 | Approved | bit | YES | Legacy approval flag. Passthrough from Fact_BillingDeposit.Approved. Superseded by PaymentStatusID for current status tracking. (Tier 2 — SP_H_Deposits code analysis) |
| 15 | Commission | money | YES | Commission charged on this deposit. Passthrough from Fact_BillingDeposit.Commission. (Tier 2 — SP_H_Deposits code analysis) |
| 16 | PaymentDate | datetime | YES | UTC timestamp when the deposit was submitted. Passthrough from Fact_BillingDeposit.PaymentDate. Not the approval time. (Tier 2 — SP_H_Deposits code analysis) |
| 17 | ClearingHouseEffectiveDate | datetime | YES | Settlement date assigned by the clearing house. NULL for instant payment methods. Passthrough from Fact_BillingDeposit.ClearingHouseEffectiveDate. (Tier 2 — SP_H_Deposits code analysis) |
| 18 | OldPaymentID | bigint | YES | Hardcoded NULL in SP_H_Deposits. Legacy payment identifier placeholder — never populated. (Tier 2 — SP_H_Deposits code analysis) |
| 19 | IsFTD | bit | YES | First Time Deposit flag. 1 = customer's first approved deposit; 0 = repeat deposit. Passthrough from Fact_BillingDeposit.IsFTD. DDL type narrowing: source is int, this DDL uses bit. (Tier 2 — SP_H_Deposits code analysis) |
| 20 | ProcessorValueDate | datetime | YES | Value date from the payment processor. NULL for instant payment methods. Passthrough from Fact_BillingDeposit.ProcessorValueDate. (Tier 2 — SP_H_Deposits code analysis) |
| 21 | RefundVerificationCode | varchar(50) | YES | Verification code for refund correlation. NULL for non-refunded deposits. Passthrough from Fact_BillingDeposit.RefundVerificationCode. (Tier 2 — SP_H_Deposits code analysis) |
| 22 | DepotID | bigint | YES | Acquirer/gateway configuration used for this deposit. Passthrough from Fact_BillingDeposit.DepotID. FK to Dim_BillingDepot. (Tier 2 — SP_H_Deposits code analysis) |
| 23 | MatchStatusID | bigint | YES | PSP reconciliation match status. Passthrough from Fact_BillingDeposit.MatchStatusID. Used for provider reconciliation workflows. (Tier 2 — SP_H_Deposits code analysis) |
| 24 | FunnelID | bigint | YES | Marketing funnel ID associated with the deposit. Passthrough from Fact_BillingDeposit.FunnelID. FK to Dim_Funnel. (Tier 2 — SP_H_Deposits code analysis) |
| 25 | Code | varchar(50) | YES | Hardcoded NULL in SP_H_Deposits. Transaction or promotional code placeholder — never populated. (Tier 2 — SP_H_Deposits code analysis) |
| 26 | ExTransactionID | varchar(50) | YES | External payment provider transaction ID. Used for provider-side reconciliation and dispute resolution. Passthrough from Fact_BillingDeposit.ExTransactionID. (Tier 2 — SP_H_Deposits code analysis) |
| 27 | PaymentStatus_PaymentStatusID | bigint | YES | Denormalized payment status ID. Dim-lookup from Dim_PaymentStatus.PaymentStatusID joined on fbd.PaymentStatusID. Redundant with PaymentStatusID — pre-joined for explicit labeling alongside PaymentStatus_Name. (Tier 2 — SP_H_Deposits code analysis) |
| 28 | PaymentStatus_Name | varchar(50) | YES | Human-readable payment status label. Dim-lookup from Dim_PaymentStatus.Name joined on fbd.PaymentStatusID. Denormalized for reporting convenience. (Tier 2 — SP_H_Deposits code analysis) |
| 29 | RiskManagementStatus_RiskManagementStatusID | bigint | YES | Denormalized risk management status ID. Lookup from External_etoro_Dictionary_RiskManagementStatus on fbd.RiskManagementStatusID. Redundant with RiskManagementStatusID — pre-joined for explicit labeling. (Tier 2 — SP_H_Deposits code analysis) |
| 30 | RiskManagementStatus_Name | varchar(50) | YES | Human-readable risk management status name. Lookup from External_etoro_Dictionary_RiskManagementStatus.Name on fbd.RiskManagementStatusID. (Tier 2 — SP_H_Deposits code analysis) |
| 31 | Channel | nvarchar(50) | YES | Top-level marketing channel category. Derived via two-hop lookup: Dim_Affiliate (joined on CC.AffiliateID as SerialID) -> Dim_Channel (joined on SubChannelID). Values include Direct, SEM, SEO, Affiliate, Mobile Acquisition, Friend Referral, Media Programmatic, TV, Social Organic. (Tier 2 — SP_H_Deposits code analysis) |
| 32 | SubChannel | varchar(100) | YES | Granular sub-channel name within the parent Channel. Derived via two-hop lookup: Dim_Affiliate -> Dim_Channel on SubChannelID. Examples: Google Brand, Google Search, FB, Taboola, Direct, SEO, Affiliate. (Tier 2 — SP_H_Deposits code analysis) |
| 33 | Region | varchar(50) | YES | Marketing region name. Lookup from External_etoro_Dictionary_MarketingRegion.Name via Dim_Country.MarketingRegionID, where Dim_Country is joined via Dim_Customer.CountryID. (Tier 2 — SP_H_Deposits code analysis) |
| 34 | Country | varchar(50) | YES | Customer's registration country name. Dim-lookup from Dim_Country.Name via Dim_Customer.CountryID (the country where the customer registered their account). Distinct from BINCountry which reflects the card-issuing bank's country. (Tier 2 — SP_H_Deposits code analysis) |
| 35 | FirstDepositAttempt | datetime | YES | Timestamp of the customer's first-ever deposit attempt (regardless of outcome). Renamed from External_etoro_BackOffice_CustomerAllTimeAggregatedData.FirstTimeDepositAttemptDate. Customer-level aggregate, not per-deposit. (Tier 2 — SP_H_Deposits code analysis) |
| 36 | FirstDepositDate | datetime | YES | Date of the customer's first successful (approved) deposit. Renamed from External_etoro_BackOffice_CustomerAllTimeAggregatedData.FirstTimeDepositSuccessDate. Customer-level aggregate, not per-deposit. (Tier 2 — SP_H_Deposits code analysis) |
| 37 | Registered | datetime | YES | Customer's account registration date. Dim-lookup from Dim_Customer.RegisteredReal (production origin: Customer.CustomerStatic.Registered). (Tier 2 — SP_H_Deposits code analysis) |
| 38 | SerialID | bigint | YES | Affiliate (partner) ID under which the customer was acquired. Dim-lookup from Dim_Customer.AffiliateID (production origin: Customer.CustomerStatic.SerialID, renamed in DWH). NULL for direct/organic registrations. FK to Dim_Affiliate. (Tier 2 — SP_H_Deposits code analysis) |
| 39 | Funnel | varchar(50) | YES | Deposit-level funnel name. Dim-lookup from Dim_Funnel.Name (aliased df) joined on fbd.FunnelID — identifies the marketing funnel associated with this specific deposit transaction. (Tier 2 — SP_H_Deposits code analysis) |
| 40 | FunnelFrom | varchar(50) | YES | Customer's originating registration funnel name. Dim-lookup from Dim_Funnel.Name (aliased df2) joined on Dim_Customer.FunnelFromID — identifies the marketing funnel that originally brought the customer to the platform at sign-up time. (Tier 2 — SP_H_Deposits code analysis) |
| 41 | AcquisitionFunnel | varchar(50) | YES | Customer's current acquisition funnel name. Dim-lookup from Dim_Funnel.Name (aliased df3) joined on Dim_Customer.FunnelID — identifies the customer's currently assigned acquisition funnel, which may differ from FunnelFrom if reassigned post-registration. (Tier 2 — SP_H_Deposits code analysis) |
| 42 | BinCode | bigint | YES | Credit card BIN (Bank Identification Number) identifying the issuing bank. Renamed from Fact_BillingDeposit.BinCodeAsString. PII-adjacent — used for fraud detection and card analytics. (Tier 2 — SP_H_Deposits code analysis) |
| 43 | CreditCardType | varchar(50) | YES | Card brand/network name. Dim-lookup from Dim_CardType.CarTypeName (note: source column has historical typo "CarTypeName" instead of "CardTypeName") joined on fbd.CardTypeIDAsInteger. (Tier 2 — SP_H_Deposits code analysis) |
| 44 | CardSubType | varchar(50) | YES | Sub-classification of the card product (e.g., CREDIT, DEBIT, PREPAID). Dim-lookup from Dim_CountryBin.CardSubType joined on fbd.BinCodeAsString. NULL when BIN data is unavailable. (Tier 2 — SP_H_Deposits code analysis) |
| 45 | BINCountry | varchar(50) | YES | Country name of the card-issuing bank. Dim-lookup from Dim_Country.Name (aliased dc3) joined on fbd.BinCountryIDAsInteger. May differ from the customer's registration Country — a mismatch between BINCountry and Country is a common fraud signal. (Tier 2 — SP_H_Deposits code analysis) |
| 46 | DepoName | varchar(50) | YES | Human-readable depot/payment-processor name. Dim-lookup from Dim_BillingDepot.Name joined on fbd.DepotID. Identifies the acquirer or gateway configuration used for this deposit. (Tier 2 — SP_H_Deposits code analysis) |
| 47 | CardCategory | varchar(50) | YES | Card product category (e.g., STANDARD, GOLD, PLATINUM, BUSINESS). Dim-lookup from Dim_CountryBin.CardCategory joined on fbd.BinCodeAsString. NULL when BIN data is unavailable. (Tier 2 — SP_H_Deposits code analysis) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| DepositID, CID, FundingID, CurrencyID, PaymentStatusID, ManagerID, RiskManagementStatusID, Amount, ExchangeRate, ModificationDate, IPAddress, Approved, Commission, PaymentDate, ClearingHouseEffectiveDate, IsFTD, ProcessorValueDate, RefundVerificationCode, DepotID, MatchStatusID, FunnelID, ExTransactionID | Billing.Deposit (via Fact_BillingDeposit) | Same names | Passthrough |
| TransactionID | Billing.Deposit (via Fact_BillingDeposit) | TransactionIDAsString | Rename |
| BinCode | Billing.Deposit (via Fact_BillingDeposit) | BinCodeAsString | Rename |
| Registered | Customer.CustomerStatic (via Dim_Customer) | Registered (as RegisteredReal) | Passthrough via Dim_Customer |
| SerialID | Customer.CustomerStatic (via Dim_Customer) | SerialID (as AffiliateID) | Passthrough via Dim_Customer (rename) |
| FundingType | Dictionary.FundingType (via Dim_FundingType) | Name | Dim-lookup via Billing.Funding |
| PaymentStatus_PaymentStatusID, PaymentStatus_Name | Dictionary.PaymentStatus (via Dim_PaymentStatus) | PaymentStatusID, Name | Dim-lookup denormalization |
| RiskManagementStatus_* | Dictionary.RiskManagementStatus (via external table) | RiskManagementStatusID, Name | External table lookup |
| Channel, SubChannel | Dim_Channel (via Dim_Affiliate) | Channel, SubChannel | Two-hop dim-lookup |
| Region | Dictionary.MarketingRegion (via external table) | Name | External table lookup via Dim_Country.MarketingRegionID |
| Country | Dictionary.Country (via Dim_Country) | Name | Dim-lookup via Dim_Customer.CountryID (registration country) |
| BINCountry | Dictionary.Country (via Dim_Country) | Name | Dim-lookup via fbd.BinCountryIDAsInteger (card-issuing country) |
| Funnel | Dictionary.Funnel (via Dim_Funnel df) | Name | Dim-lookup via fbd.FunnelID (deposit funnel) |
| FunnelFrom | Dictionary.Funnel (via Dim_Funnel df2) | Name | Dim-lookup via CC.FunnelFromID (registration funnel) |
| AcquisitionFunnel | Dictionary.Funnel (via Dim_Funnel df3) | Name | Dim-lookup via CC.FunnelID (current funnel) |
| CreditCardType | Dictionary.CardType (via Dim_CardType) | CarTypeName | Dim-lookup |
| CardSubType, CardCategory | Dim_CountryBin | CardSubType, CardCategory | Dim-lookup via fbd.BinCodeAsString |
| DepoName | Billing.Depot (via Dim_BillingDepot) | Name | Dim-lookup |
| FirstDepositAttempt | BackOffice.CustomerAllTimeAggregatedData (via external table) | FirstTimeDepositAttemptDate | Rename |
| FirstDepositDate | BackOffice.CustomerAllTimeAggregatedData (via external table) | FirstTimeDepositSuccessDate | Rename |
| OldPaymentID, Code | (none) | — | Hardcoded NULL |

### 5.2 ETL Pipeline

```
etoro.Billing.Deposit (etoroDB-REAL)
  + Billing.Funding (payment instruments)
  |
  v [Generic Pipeline -- daily]
DWH_staging -> DWH_dbo.Fact_BillingDeposit
  |
  v [SP_H_Deposits @Date=GETDATE()-1]
    1. EXEC SP_Create_External_etoro_History_DepositAction
    2. CTAS #AdvancedDeposit_Ext (SELECT from Fact_BillingDeposit
       + 10 dim/external table JOINs, WHERE PlayerLevelID!=4)
    3. CTAS #BI_DB_Deposits_tmp (add Channel/SubChannel via Affiliate->Channel)
    4. CTAS #BI_DB_Deposits_updates (filter ResponseRN=1)
    5. UPDATE/INSERT -> BI_DB_dbo.BI_DB_Deposits
  |
  v [NOTE: BI_DB_AdvancedDeposit_Ext is NOT the active target]
BI_DB_dbo.BI_DB_AdvancedDeposit_Ext (0 rows -- DORMANT, backed up 2024-11-17)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer who made the deposit |
| CurrencyID | DWH_dbo.Dim_Currency | Deposit currency |
| PaymentStatusID | DWH_dbo.Dim_PaymentStatus | Current deposit status |
| RiskManagementStatusID | External_etoro_Dictionary_RiskManagementStatus | Risk engine decision |
| FunnelID | DWH_dbo.Dim_Funnel | Marketing funnel |
| DepotID | DWH_dbo.Dim_BillingDepot | Payment processor |
| DepositID | DWH_dbo.Fact_BillingDeposit | Source deposit fact |

### 6.2 Referenced By (other objects point to this)

No known consumers — table is empty and dormant.

---

## 7. Sample Queries

### 7.1 Alternative: Query BI_DB_Deposits Instead

```sql
-- BI_DB_AdvancedDeposit_Ext is empty. Use its active replacement:
SELECT TOP 10 *
FROM [BI_DB_dbo].[BI_DB_Deposits]
WHERE PaymentStatusID = 2
ORDER BY ModificationDate DESC
```

### 7.2 Alternative: Rebuild Equivalent from Fact_BillingDeposit

```sql
-- Reconstruct the denormalized deposit view from source tables:
SELECT TOP 10
    fbd.DepositID, fbd.CID, fbd.Amount, fbd.PaymentDate,
    dps.Name AS PaymentStatus_Name,
    dc.Name AS Country,
    ct.CarTypeName AS CreditCardType
FROM [DWH_dbo].[Fact_BillingDeposit] fbd
JOIN [DWH_dbo].[Dim_PaymentStatus] dps ON fbd.PaymentStatusID = dps.PaymentStatusID
JOIN [DWH_dbo].[Dim_Customer] cc ON fbd.CID = cc.RealCID
JOIN [DWH_dbo].[Dim_Country] dc ON cc.CountryID = dc.CountryID
LEFT JOIN [DWH_dbo].[Dim_CardType] ct ON fbd.CardTypeIDAsInteger = ct.CardTypeID
WHERE fbd.PaymentStatusID = 2
ORDER BY fbd.ModificationDate DESC
```

---

## 8. Atlassian Knowledge Sources

No specific Confluence or Jira sources found for this table.

---

*Generated: 2026-04-27 | Quality: pending judge | Phases: 11/14 (P3 skipped: 0 rows; P7 skipped: dormant; P10 skipped: none found)*
*Tiers: 0 T1, 47 T2, 0 T3, 0 T4 | Elements: 47/47, Logic: 7/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_AdvancedDeposit_Ext | Type: Table | Production Source: Unknown (dormant) — lineage traced via SP_H_Deposits*
