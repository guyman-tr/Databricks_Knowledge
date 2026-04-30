# AffiliateCommission.GetAffiliateTypeDataByAffiliateId

> Retrieves the complete commission compensation plan for an affiliate by AffiliateID, returning four result sets covering base rates, first-position asset plans, IOB plans, and ISA plans.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 4 result sets of commission configuration |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetAffiliateTypeDataByAffiliateId is the primary configuration loader for the commission calculation engine. Given an affiliate's ID, it resolves the affiliate's compensation plan type and returns the complete set of commission rates, slab thresholds, tier structures, and country-specific plans that govern how commissions are calculated for every event attributed to this affiliate.

This procedure exists because the commission engine needs the full rate card before it can calculate any commission. The compensation plan is stored across multiple tables: the core rates in dbo.tblaff_AffiliateTypes, country-specific first-position asset plans in AffiliateConfiguration.FirstPositionAssetPlan, introduction-of-business plans in AffiliateConfiguration.IOBPlan, and ISA product plans in AffiliateConfiguration.ISAPlan. This procedure joins through the affiliate's AffiliateTypeID to retrieve all four datasets in a single call.

The procedure returns 4 result sets: (1) the full affiliate type configuration with 35+ columns of rates and thresholds, (2) FirstPositionAssetPlan entries with country-specific CPA amounts, (3) IOBPlan entries with country-specific introduction commissions, and (4) ISAPlan entries with product-specific ISA commissions.

---

## 2. Business Logic

### 2.1 Multi-Compensation-Model Rate Card

**What**: Returns the full commission rate configuration supporting multiple compensation models simultaneously.

**Columns/Parameters Involved**: `PerDeposit`, `CPAOrCPAD`, `PerSale`, `PerPNL`, `PerFirstPosition`, `PerRegistration`

**Rules**:
- PerDeposit: Commission earned per customer deposit (credit event)
- CPAOrCPAD: Determines whether the affiliate uses CPA (cost-per-acquisition) or CPAD (CPA + deposit requirement) model
- PerSale: Commission earned per closed position (sale/trade event)
- PerPNL: Commission based on position profit/loss
- PerFirstPosition: Commission for a customer's first position after registration
- PerRegistration: Commission for customer registration itself
- These are not mutually exclusive - an affiliate type can combine multiple models

### 2.2 Slab-Based Rate Tiers

**What**: Commission rates vary by volume through slab thresholds for deposits, sales, and PnL.

**Columns/Parameters Involved**: `DepositSlab*Amount`, `DepositSlab*To`, `SaleSlab*To`, `SaleSlab*Percent`, `PNLSlab*To`, `PNLSlab*Percent`

**Rules**:
- Deposit slabs: Up to 4 tiers (Slab1-4). DepositSlabNAmount = rate for that tier, DepositSlabNTo = upper bound
- Sale slabs: Up to 4 tiers. SaleSlabNPercent = percentage rate, SaleSlabNTo = upper bound
- PNL slabs: Up to 4 tiers. PNLSlabNPercent = percentage rate, PNLSlabNTo = upper bound
- MinimumCommission sets the floor - no payout below this threshold

### 2.3 Multi-Tier Affiliate Referral

**What**: Supports up to 5-tier deep affiliate referral chains with configurable rates per tier.

**Columns/Parameters Involved**: `Tiers`, `TierType`, `AllTiersRate2` through `AllTiersRate5`

**Rules**:
- Tiers: Number of active referral tiers (1-5)
- TierType: How tier rates are applied (flat vs percentage)
- AllTiersRate2-5: Commission rates for tiers 2 through 5 (tier 1 uses the base rates)

### 2.4 Country-Specific Plans (Result Sets 2-4)

**What**: Override commission rates per country for specific product lines.

**Columns/Parameters Involved**: `CountryID`, `PositionAssetTypeID`, `CPAAmount`, `Commission`

**Rules**:
- Result Set 2 (FirstPositionAssetPlan): CPA amounts by country and asset type for first-position commissions
- Result Set 3 (IOBPlan): Introduction-of-business commissions by country
- Result Set 4 (ISAPlan): ISA product commissions by SubAccountTypeID and ProductID (added PART-5458)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | int (IN) | NO | - | CODE-BACKED | The AffiliateID to look up. The procedure resolves the affiliate's AffiliateTypeID through dbo.tblaff_Affiliates, then retrieves the full compensation plan from dbo.tblaff_AffiliateTypes and associated plan tables. |

**Result Set 1 - Affiliate Type Configuration (35 columns):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | AffiliateTypeID | int | - | - | CODE-BACKED | Compensation plan identifier linking to dbo.tblaff_AffiliateTypes. |
| 3 | PerDeposit | - | - | - | CODE-BACKED | Commission rate per deposit event. |
| 4 | CPAOrCPAD | - | - | - | CODE-BACKED | Compensation model flag: CPA (cost-per-acquisition) vs CPAD (CPA with deposit). |
| 5 | PerSale | - | - | - | CODE-BACKED | Commission rate per closed position (sale). |
| 6 | DepositSlab1Amount-4 | - | - | - | CODE-BACKED | Commission amounts for each deposit volume slab tier (4 tiers). |
| 7 | DepositSlab1To-3 | - | - | - | CODE-BACKED | Upper bounds for deposit slab tiers 1-3. Slab4 has no upper bound (unlimited). |
| 8 | CPADPercent | - | - | - | CODE-BACKED | Percentage rate for CPAD compensation model. |
| 9 | FlatRateOrPercentOfSale | - | - | - | CODE-BACKED | Determines if sale commission is a flat amount or percentage of trade value. |
| 10 | PerPNL | - | - | - | CODE-BACKED | Commission rate based on position PnL. |
| 11 | Tiers | - | - | - | CODE-BACKED | Number of referral tiers active for this affiliate type (1-5). |
| 12 | TierType | - | - | - | CODE-BACKED | How tier rates are applied (flat vs percentage). |
| 13 | AllTiersRate2-5 | - | - | - | CODE-BACKED | Commission rates for tiers 2 through 5 in a multi-level referral chain. |
| 14 | MinimumCommission | - | - | - | CODE-BACKED | Floor amount - commissions below this threshold are not paid out. |
| 15 | SaleSlab1To-3, SaleSlab1Percent-4 | - | - | - | CODE-BACKED | Sale volume slab thresholds and percentage rates (4 tiers). |
| 16 | PNLSlab1To-3, PNLSlab1Percent-4 | - | - | - | CODE-BACKED | PnL volume slab thresholds and percentage rates (4 tiers). |
| 17 | RegistrationPerCountry | - | - | - | CODE-BACKED | Whether registration commissions vary by country. |
| 18 | PerFirstPosition | - | - | - | CODE-BACKED | Whether first-position CPA commissions are enabled. |
| 19 | PerFirstPositionRate | - | - | - | CODE-BACKED | Base rate for first-position commissions (may be overridden by country plan). |
| 20 | IsTradeRequired | - | - | - | CODE-BACKED | Whether the customer must make a trade for the affiliate to earn registration commission. Added PART-1195. |
| 21 | PerRegistration | - | - | - | CODE-BACKED | Commission rate for customer registration. Added PART-1195. |

**Result Set 2 - FirstPositionAssetPlan:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 22 | CountryID | int | - | - | CODE-BACKED | Country for which this first-position CPA rate applies. |
| 23 | PositionAssetTypeID | int | - | - | CODE-BACKED | Asset type classification for the first position (e.g., stocks, crypto, CFD). |
| 24 | MinimumCommission | money | - | - | CODE-BACKED | Minimum commission threshold for this country/asset combination. |
| 25 | CPAAmount | money | - | - | CODE-BACKED | CPA payment amount for first position in this country/asset combination. |

**Result Set 3 - IOBPlan:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 26 | CountryID | int | - | - | CODE-BACKED | Country for which this IOB commission applies. |
| 27 | Commission | money | - | - | CODE-BACKED | Introduction-of-business commission amount for this country. |

**Result Set 4 - ISAPlan:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 28 | SubAccountTypeID | int | - | - | CODE-BACKED | ISA sub-account type classification. Added PART-5458. |
| 29 | ProductID | int | - | - | CODE-BACKED | ISA product identifier. Added PART-5458. |
| 30 | Commission | money | - | - | CODE-BACKED | Commission amount for this ISA product/sub-account combination. Added PART-5458. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ID | dbo.tblaff_Affiliates | READ (JOIN) | Resolves AffiliateID to AffiliateTypeID |
| AffiliateTypeID | dbo.tblaff_AffiliateTypes | READ (JOIN) | Contains the full commission rate configuration |
| AffiliateTypeID | AffiliateConfiguration.FirstPositionAssetPlan | READ (JOIN) | Country-specific first-position CPA rates |
| AffiliateTypeID | AffiliateConfiguration.IOBPlan | READ (JOIN) | Country-specific introduction-of-business rates |
| AffiliateTypeID | AffiliateConfiguration.ISAPlan | READ (JOIN) | ISA product-specific commission rates |

### 5.2 Referenced By (other objects point to this)

No callers found in the AffiliateCommission schema. Called by the commission engine to load the full rate card before commission calculation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.GetAffiliateTypeDataByAffiliateId (procedure)
+-- dbo.tblaff_Affiliates (table, external)
+-- dbo.tblaff_AffiliateTypes (table, external)
+-- AffiliateConfiguration.FirstPositionAssetPlan (table, external)
+-- AffiliateConfiguration.IOBPlan (table, external)
+-- AffiliateConfiguration.ISAPlan (table, external)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table (external) | JOINed to resolve AffiliateID to AffiliateTypeID |
| dbo.tblaff_AffiliateTypes | Table (external) | JOINed to get the full commission rate configuration (35+ columns) |
| AffiliateConfiguration.FirstPositionAssetPlan | Table (external) | JOINed for country-specific first-position CPA rates |
| AffiliateConfiguration.IOBPlan | Table (external) | JOINed for country-specific IOB commission rates |
| AffiliateConfiguration.ISAPlan | Table (external) | JOINed for ISA product commission rates |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Commission calculation engine) | External | Loads the full rate card for an affiliate |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get full compensation plan for affiliate 3
```sql
EXEC [AffiliateCommission].[GetAffiliateTypeDataByAffiliateId] @ID = 3
```

### 8.2 Check which affiliates use CPA vs CPAD model
```sql
SELECT a.AffiliateID, att.AffiliateTypeID, att.CPAOrCPAD, att.PerDeposit, att.PerSale
FROM dbo.tblaff_AffiliateTypes AS att WITH (NOLOCK)
INNER JOIN dbo.tblaff_Affiliates AS a WITH (NOLOCK)
    ON a.AffiliateTypeID = att.AffiliateTypeID
ORDER BY a.AffiliateID
```

### 8.3 Find country-specific first-position CPA amounts for an affiliate type
```sql
SELECT fpa.CountryID, fpa.PositionAssetTypeID, fpa.MinimumCommission, fpa.CPAAmount
FROM AffiliateConfiguration.FirstPositionAssetPlan AS fpa WITH (NOLOCK)
INNER JOIN dbo.tblaff_AffiliateTypes AS att WITH (NOLOCK)
    ON att.AffiliateTypeID = fpa.AffiliateTypeID
INNER JOIN dbo.tblaff_Affiliates AS a WITH (NOLOCK)
    ON a.AffiliateTypeID = att.AffiliateTypeID
WHERE a.AffiliateID = 3
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found for this object. Jira MCP unavailable (410).

DDL comments reference:
- PART-4763: Update (2025-09-10)
- PART-2448: CPA New Compensation Design (2023-12-17)
- PART-1195: Added PerRegistration column (2023-02-26)
- PART-5458: Support for ISA plan (2026-01-22)
- Unlabeled: Added IsTradeRequired column (2022-01-02)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 30 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.GetAffiliateTypeDataByAffiliateId | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.GetAffiliateTypeDataByAffiliateId.sql*
