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
- **Payment status denormalization** (4 columns): `Dim_PaymentStatus` (Dictionary.PaymentStatus) + `External_etoro_Dictionary_RiskManagementStatus`
- **Customer demographics** (5 columns): `Dim_Customer` (Registered, AffiliateID->SerialID) + `Dim_Country` (Country name, Dictionary.Country) + `External_etoro_Dictionary_MarketingRegion` (Region)
- **Acquisition attribution** (6 columns): `Dim_Funnel` (3 joins, Dictionary.Funnel), `Dim_Affiliate`+`Dim_Channel` (Channel, SubChannel)
- **Credit card BIN metadata** (6 columns): `Dim_CardType` (Dictionary.CardType), `Dim_CountryBin`, `Dim_Country` (BIN country)
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
- BinCode sourced from `Fact_BillingDeposit.BinCodeAsString` (XML-extracted from Billing.Deposit.FundingData)
- CreditCardType resolved via `Dim_CardType` on `fbd.CardTypeIDAsInteger`
- CardSubType and CardCategory resolved via `Dim_CountryBin` on `fbd.BinCodeAsString`
- BINCountry resolved via `Dim_Country` on `fbd.BinCountryIDAsInteger` — may differ from customer's registration country (fraud signal)

### 2.3 Acquisition Attribution

**What**: Customer acquisition details for marketing ROI analysis on deposits.
**Columns Involved**: SerialID, Channel, SubChannel, Funnel, FunnelFrom, AcquisitionFunnel, FirstDepositAttempt, FirstDepositDate, Registered
**Rules**:
- SerialID = `Dim_Customer.AffiliateID` (renamed back to original production name Customer.CustomerStatic.SerialID)
- Three funnel name lookups from `Dim_Funnel`: deposit funnel (fbd.FunnelID), customer's source funnel (CC.FunnelFromID), customer's current funnel (CC.FunnelID)
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
| Tier 1 | Verified from upstream wiki (verbatim from Fact_BillingDeposit, Dim_Customer, or root dictionary/production source) |
| Tier 2 | Derived from SP_H_Deposits code analysis (dim lookups with no upstream wiki, renames, hardcoded values) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DepositID | bigint | YES | Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). Passthrough from Fact_BillingDeposit. (Tier 1 — Billing.Deposit) |
| 2 | CID | int | YES | Customer ID. Identifies the eToro customer who made this deposit. References DWH_dbo.Dim_Customer. Passthrough from Fact_BillingDeposit. (Tier 1 — Billing.Deposit) |
| 3 | FundingID | bigint | YES | Payment instrument (credit card, bank account, e-wallet) used for this deposit. References Billing.Funding. Passthrough from Fact_BillingDeposit. (Tier 1 — Billing.Deposit) |
| 4 | FundingType | varchar(50) | YES | Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). Dim-lookup passthrough from Dim_FundingType.Name via External_etoro_Billing_Funding_Datafactory.FundingTypeID. (Tier 1 — Dictionary.FundingType) |
| 5 | CurrencyID | bigint | YES | Currency of the deposit amount. References DWH_dbo.Dim_Currency. 1=USD, 2=EUR, 3=GBP, etc. Passthrough from Fact_BillingDeposit. (Tier 1 — Billing.Deposit) |
| 6 | PaymentStatusID | bigint | YES | Current deposit status. Key values: 1=New, 2=Approved, 3=Decline, 5=InProcess, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE. Full 39-value enum in upstream wiki. Passthrough from Fact_BillingDeposit. (Tier 1 — Billing.Deposit) |
| 7 | ManagerID | bigint | YES | Operations manager who processed this deposit. 0=automated. Passthrough from Fact_BillingDeposit. (Tier 1 — Billing.Deposit) |
| 8 | RiskManagementStatusID | bigint | YES | Result of the pre-processing risk management check. 69 distinct risk reason codes. NULL=no risk check recorded. Key codes: 1=Success, 35=DeclineByRRE, 47=ML, 49=CustomerToFundingViolation. Passthrough from Fact_BillingDeposit. (Tier 1 — Billing.Deposit) |
| 9 | Amount | money | YES | Deposit amount in the deposit currency (CurrencyID). DWH note: as of 2025-04-17, capped via CASE expression in upstream ETL to prevent extreme outlier values from distorting aggregations. Passthrough from Fact_BillingDeposit. (Tier 1 — Billing.Deposit) |
| 10 | ExchangeRate | numeric(16,8) | YES | Exchange rate from deposit currency to USD at processing time. Cannot be 0 in production. Passthrough from Fact_BillingDeposit. (Tier 1 — Billing.Deposit) |
| 11 | ModificationDate | datetime | YES | UTC timestamp of the most recent modification to this deposit record. Used by ETL for incremental detection. Passthrough from Fact_BillingDeposit. (Tier 1 — Billing.Deposit) |
| 12 | TransactionID | varchar(6) | YES | Provider transaction ID string, renamed from Fact_BillingDeposit.TransactionIDAsString (XML-extracted from Billing.Deposit.PaymentData). Truncated to varchar(6). (Tier 2 — SP_H_Deposits) |
| 13 | IPAddress | numeric(18,0) | YES | Customer IP address at deposit time, as a 32-bit integer. Used for fraud detection. Passthrough from Fact_BillingDeposit. (Tier 1 — Billing.Deposit) |
| 14 | Approved | bit | YES | Legacy approval flag, superseded by PaymentStatusID=2. NULL for most modern records. Retained for backward compatibility. Passthrough from Fact_BillingDeposit. (Tier 1 — Billing.Deposit) |
| 15 | Commission | money | YES | Commission charged on this deposit. Default 0 in production. Passthrough from Fact_BillingDeposit. (Tier 1 — Billing.Deposit) |
| 16 | PaymentDate | datetime | YES | UTC timestamp when the deposit was submitted (set at INSERT in production). Not the approval time. Passthrough from Fact_BillingDeposit. (Tier 1 — Billing.Deposit) |
| 17 | ClearingHouseEffectiveDate | datetime | YES | Settlement date assigned by the clearing house. NULL for instant payment methods. Passthrough from Fact_BillingDeposit. (Tier 1 — Billing.Deposit) |
| 18 | OldPaymentID | bigint | YES | Hardcoded NULL in SP_H_Deposits. Legacy payment identifier placeholder — never populated. (Tier 2 — SP_H_Deposits) |
| 19 | IsFTD | bit | YES | First Time Deposit flag. 1=this was the customer's very first approved deposit (drives marketing attribution). 0=repeat deposit or ineligible type. DWH note: Fact_BillingDeposit stores as int; this DDL uses bit (type narrowing, no data loss). Passthrough from Fact_BillingDeposit. (Tier 1 — Billing.Deposit) |
| 20 | ProcessorValueDate | datetime | YES | Value date from the payment processor. Mandatory for offline/wire deposits. NULL for instant payment methods. Passthrough from Fact_BillingDeposit. (Tier 1 — Billing.Deposit) |
| 21 | RefundVerificationCode | varchar(50) | YES | Verification code for refund correlation. Set by UpdateRefundDetails. NULL for non-refunded deposits. Passthrough from Fact_BillingDeposit. (Tier 1 — Billing.Deposit) |
| 22 | DepotID | bigint | YES | Acquirer/gateway configuration used for this deposit. Validated at insert against DepotToCurrency in production. Passthrough from Fact_BillingDeposit. (Tier 1 — Billing.Deposit) |
| 23 | MatchStatusID | bigint | YES | PSP reconciliation match status. Default 0=Unmatched; 3=Matched. Used for provider reconciliation workflows. Passthrough from Fact_BillingDeposit. (Tier 1 — Billing.Deposit) |
| 24 | FunnelID | bigint | YES | Marketing funnel ID. FK to Dictionary.Funnel. Passthrough from Fact_BillingDeposit. (Tier 1 — Billing.Deposit) |
| 25 | Code | varchar(50) | YES | Hardcoded NULL in SP_H_Deposits. Transaction or promotional code placeholder — never populated. (Tier 2 — SP_H_Deposits) |
| 26 | ExTransactionID | varchar(50) | YES | External (payment provider) transaction ID. Used for provider-side reconciliation and dispute resolution. Passthrough from Fact_BillingDeposit. (Tier 1 — Billing.Deposit) |
| 27 | PaymentStatus_PaymentStatusID | bigint | YES | Primary key identifying the payment state. 1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Failed, 6=Reversed, 7=CompletedExternally. Denormalized dim-lookup passthrough from Dim_PaymentStatus.PaymentStatusID on fbd.PaymentStatusID. (Tier 1 — Dictionary.PaymentStatus) |
| 28 | PaymentStatus_Name | varchar(50) | YES | Human-readable status label. UNIQUE constraint. Used in back-office payment management UI and reconciliation reports. Denormalized dim-lookup passthrough from Dim_PaymentStatus.Name on fbd.PaymentStatusID. (Tier 1 — Dictionary.PaymentStatus) |
| 29 | RiskManagementStatus_RiskManagementStatusID | bigint | YES | Denormalized risk management status ID from External_etoro_Dictionary_RiskManagementStatus. Redundant with RiskManagementStatusID — pre-joined for explicit labeling. (Tier 2 — SP_H_Deposits) |
| 30 | RiskManagementStatus_Name | varchar(50) | YES | Denormalized risk management status name from External_etoro_Dictionary_RiskManagementStatus.Name. Resolves RiskManagementStatusID to human-readable label. No upstream wiki available for this external dictionary. (Tier 2 — SP_H_Deposits) |
| 31 | Channel | nvarchar(50) | YES | Top-level marketing channel category. Derived from AffWizz MarketingExpense.MarketingExpenseName with overrides: 'Introducing Agents' -> 'Affiliate', AffiliateID IN (56662,56663) -> 'Direct'. Common values: Direct, SEM, SEO, Affiliate, Mobile Acquisition, Friend Referral, Media Programmatic, TV, Social Organic. Dim-lookup via Dim_Affiliate (on CC.AffiliateID) -> Dim_Channel (on SubChannelID). (Tier 2 — SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse) |
| 32 | SubChannel | varchar(100) | YES | Granular sub-channel name within the parent Channel. Human-readable label for SubChannelID. Examples: 'Google Brand', 'Google Search', 'FB', 'Taboola', 'Twitter', 'Outbrain', 'Bing Search', 'Direct', 'SEO', 'Affiliate', 'IBs'. Dim-lookup via Dim_Affiliate -> Dim_Channel. (Tier 2 — SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse) |
| 33 | Region | varchar(50) | YES | Marketing region name from External_etoro_Dictionary_MarketingRegion.Name, resolved via Dim_Country.MarketingRegionID. No upstream wiki available for this external dictionary. (Tier 2 — SP_H_Deposits) |
| 34 | Country | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup passthrough from Dim_Country.Name via Dim_Customer.CountryID. (Tier 1 — Dictionary.Country) |
| 35 | FirstDepositAttempt | datetime | YES | Timestamp of the customer's first-ever deposit attempt. Renamed from External_etoro_BackOffice_CustomerAllTimeAggregatedData.FirstTimeDepositAttemptDate. Customer-level, not per-deposit. No upstream wiki available. (Tier 2 — SP_H_Deposits) |
| 36 | FirstDepositDate | datetime | YES | Date of the customer's first successful deposit. Renamed from External_etoro_BackOffice_CustomerAllTimeAggregatedData.FirstTimeDepositSuccessDate. Customer-level, not per-deposit. No upstream wiki available. (Tier 2 — SP_H_Deposits) |
| 37 | Registered | datetime | YES | Account registration date (renamed from Registered). Default=getdate(). Dim-lookup passthrough from Dim_Customer.RegisteredReal. (Tier 1 — Customer.CustomerStatic) |
| 38 | SerialID | bigint | YES | Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. Dim-lookup passthrough from Dim_Customer.AffiliateID (renamed from Customer.CustomerStatic.SerialID). (Tier 1 — Customer.CustomerStatic) |
| 39 | Funnel | varchar(50) | YES | Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. Dim-lookup passthrough from Dim_Funnel.Name via fbd.FunnelID. (Tier 1 — Dictionary.Funnel) |
| 40 | FunnelFrom | varchar(50) | YES | Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. Dim-lookup passthrough from Dim_Funnel.Name via Dim_Customer.FunnelFromID. (Tier 1 — Dictionary.Funnel) |
| 41 | AcquisitionFunnel | varchar(50) | YES | Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. Dim-lookup passthrough from Dim_Funnel.Name via Dim_Customer.FunnelID. (Tier 1 — Dictionary.Funnel) |
| 42 | BinCode | bigint | YES | Credit card BIN (Bank Identification Number). Renamed from Fact_BillingDeposit.BinCodeAsString (XML-extracted from Billing.Deposit.FundingData). Identifies the issuing bank. PII-adjacent. (Tier 2 — SP_H_Deposits) |
| 43 | CreditCardType | varchar(50) | YES | Card brand name. DDL note: source column has a typo ("CarTypeName" instead of "CardTypeName") — historical artifact from legacy DWH SQL Server migration. Key values: Visa, Master Card, MasterCard, Diners, Amex, American Express, Maestro, Discover, China Union Pay. Dim-lookup passthrough from Dim_CardType.CarTypeName via fbd.CardTypeIDAsInteger. (Tier 1 — Dictionary.CardType) |
| 44 | CardSubType | varchar(50) | YES | Sub-classification of the card product within its type (e.g., "CREDIT", "DEBIT", "PREPAID"). NULL when not available. Dim-lookup passthrough from Dim_CountryBin.CardSubType via fbd.BinCodeAsString. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 45 | BINCountry | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup passthrough from Dim_Country.Name via fbd.BinCountryIDAsInteger. May differ from customer's registration country (Country column) — useful for fraud detection. (Tier 1 — Dictionary.Country) |
| 46 | DepoName | varchar(50) | YES | Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports. Dim-lookup passthrough from Dim_BillingDepot.Name via fbd.DepotID. (Tier 1 — Billing.Depot) |
| 47 | CardCategory | varchar(50) | YES | Card product category (e.g., "STANDARD", "GOLD", "PLATINUM", "BUSINESS"). NULL when not available. Dim-lookup passthrough from Dim_CountryBin.CardCategory via fbd.BinCodeAsString. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| DepositID, CID, FundingID, CurrencyID, PaymentStatusID, ManagerID, RiskManagementStatusID, Amount, ExchangeRate, ModificationDate, IPAddress, Approved, Commission, PaymentDate, ClearingHouseEffectiveDate, IsFTD, ProcessorValueDate, RefundVerificationCode, DepotID, MatchStatusID, FunnelID, ExTransactionID | etoro.Billing.Deposit | Same names (via Fact_BillingDeposit) | Passthrough |
| Registered | Customer.CustomerStatic | Registered | Passthrough via Dim_Customer.RegisteredReal |
| SerialID | Customer.CustomerStatic | SerialID | Passthrough via Dim_Customer.AffiliateID (rename) |
| TransactionID | Billing.Deposit PaymentData XML | TransactionIDAsString | XML extraction + rename |
| BinCode | Billing.Deposit FundingData XML | BinCodeAsString | XML extraction + rename |
| FundingType | Dictionary.FundingType | Name | Dim-lookup passthrough via Billing.Funding |
| PaymentStatus_PaymentStatusID, PaymentStatus_Name | Dictionary.PaymentStatus | PaymentStatusID, Name | Dim-lookup denormalization |
| RiskManagementStatus_* | Dictionary.RiskManagementStatus | RiskManagementStatusID, Name | External table lookup |
| Channel, SubChannel | SP_Dim_Channel_Affiliate_UnifyCode | Channel, SubChannel | DWH-computed (Tier 2) via Affiliate->Channel |
| Region | Dictionary.MarketingRegion | Name | External table lookup via Dim_Country |
| Country | Dictionary.Country | Name | Dim-lookup passthrough via Dim_Customer.CountryID |
| BINCountry | Dictionary.Country | Name | Dim-lookup passthrough via fbd.BinCountryIDAsInteger |
| Funnel, FunnelFrom, AcquisitionFunnel | Dictionary.Funnel | Name | 3 Dim_Funnel lookups |
| CreditCardType | Dictionary.CardType | CarTypeName | Dim-lookup passthrough |
| CardSubType, CardCategory | Dim_CountryBin | CardSubType, CardCategory | Dim-lookup (Tier 2 staging passthrough) |
| DepoName | Billing.Depot | Name | Dim-lookup passthrough |
| FirstDepositAttempt, FirstDepositDate | BackOffice.CustomerAllTimeAggregatedData | FirstTimeDepositAttemptDate, FirstTimeDepositSuccessDate | External table rename |
| OldPaymentID, Code | (none) | — | Hardcoded NULL |

### 5.2 ETL Pipeline

```
etoro.Billing.Deposit (etoroDB-REAL)
  + Billing.Funding (payment instruments)
  |
  v [Generic Pipeline — daily]
DWH_staging -> DWH_dbo.Fact_BillingDeposit (73.9M rows)
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
BI_DB_dbo.BI_DB_AdvancedDeposit_Ext (0 rows — DORMANT, backed up 2024-11-17)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer who made the deposit |
| CurrencyID | DWH_dbo.Dim_Currency | Deposit currency |
| PaymentStatusID | DWH_dbo.Dim_PaymentStatus | Current deposit status |
| RiskManagementStatusID | DWH_dbo.Dim_RiskManagementStatus | Risk engine decision |
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

*Generated: 2026-04-27 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 34 T1, 13 T2, 0 T3, 0 T4 | Elements: 47/47, Logic: 7/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_AdvancedDeposit_Ext | Type: Table | Production Source: Unknown (dormant) — lineage traced via SP_H_Deposits*
