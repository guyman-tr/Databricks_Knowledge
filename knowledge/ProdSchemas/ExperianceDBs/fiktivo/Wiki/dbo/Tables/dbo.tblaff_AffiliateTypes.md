# dbo.tblaff_AffiliateTypes

> Commission plan templates that define how affiliates earn money - which event types trigger commissions, rate structures across up to 5 tiers, slab-based pricing, payout thresholds, and what data affiliates can see.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | AffiliateTypeID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 active (1 clustered PK, 1 covering AffiliateTypeID+Description, 1 on FatherAffiliateTypeID+IsActive) |

---

## 1. Business Meaning

This table is the core commission configuration engine of the affiliate platform. Each row defines a complete commission plan template (called an "affiliate type") that can be assigned to one or more affiliates. The plan specifies which events earn commissions (deposits, sales, leads, registrations, clicks, PnL, copy traders, first positions), the commission rates for up to 5 hierarchical tiers, slab-based pricing tiers, bonus thresholds, and what data affiliates can see in their dashboard.

Without this table, the platform could not calculate affiliate commissions. Every commission event (deposit, registration, sale, etc.) is evaluated against the affiliate's assigned type to determine the payout amount. The table also controls the affiliate portal UI - which data columns affiliates see for their events.

Plans are created/modified by admin users with AffiliateTypes_* permissions. Each affiliate in tblaff_Affiliates references an AffiliateTypeID. Plans support hierarchy via FatherAffiliateTypeID for inherited configurations. The table is system-versioned with temporal history for audit tracking of commission plan changes.

---

## 2. Business Logic

### 2.1 Multi-Event Commission Model

**What**: Each plan enables/disables independent commission streams for different customer lifecycle events.

**Columns/Parameters Involved**: `PerDeposit`, `PerSale`, `PerLead`, `PerRegistration`, `PerClick`, `PerPNL`, `PerCopyTrader`, `PerFirstPosition`, `CommissionByOpenPosition`

**Rules**:
- Each Per* flag independently enables that commission stream
- An affiliate type can combine multiple streams (e.g., RevShare: PerDeposit=1 + PerSale=1)
- CPL plans typically only have PerLead=1 + PerRegistration=1
- FlatRateOrPercentOfSale controls whether sale commissions are a flat amount or percentage
- CPAOrCPAD controls whether CPA commissions follow CPA or CPAD (CPA with deposit) model

**Diagram**:
```
Commission Event Types:
  PerDeposit -----> Deposit commission (revenue share or CPA)
  PerSale -------> Sale/trading activity commission
  PerLead -------> Lead/download commission
  PerRegistration -> Registration commission
  PerClick ------> Click commission
  PerPNL --------> PnL (profit and loss) share commission
  PerCopyTrader --> Copy trader activity commission
  PerFirstPosition -> First position commission
  CommissionByOpenPosition -> Open position-based commission
```

### 2.2 Multi-Tier Rate Structure

**What**: Each commission stream supports up to 5 hierarchical tiers with independent rates, enabling multi-level affiliate programs.

**Columns/Parameters Involved**: `Tiers`, `TierType`, `Per{Event}Rate`, `Per{Event}Rate2` through `Per{Event}Rate5`

**Rules**:
- Tiers (1-5) defines how many tiers deep the commission hierarchy goes
- Tier 1 is the direct affiliate; Tier 2+ are sub-affiliates who referred the tier-1 affiliate
- Each tier has its own rate (Rate=Tier1, Rate2=Tier2, ..., Rate5=Tier5)
- AllTiersRate2/3/4/5 provide override rates across all event types for tiers 2-5
- TierType controls how tier commissions are calculated (0=standard)

### 2.3 Slab-Based Commission Tiers

**What**: Commission rates can vary based on volume thresholds (slabs), rewarding higher-volume affiliates with better rates.

**Columns/Parameters Involved**: `DepositSlab1To`/`2To`/`3To`, `DepositSlab1Amount`/`2Amount`/`3Amount`/`4Amount`, `SaleSlab*`, `PNLSlab*`, `CopyTraderSlab*`

**Rules**:
- Slab1To/2To/3To define the upper threshold boundaries for each tier
- Slab1Amount is for volume below Slab1To, Slab2Amount for volume between Slab1To and Slab2To, etc.
- Slab4Amount applies to volume above Slab3To (uncapped top tier)
- Available for deposits, sales, PnL, and copy trader commission types
- CPADPercent provides an additional percentage for CPA with deposit model

### 2.4 Affiliate Portal Visibility Controls

**What**: Controls what data affiliates can see in their self-service portal for each event type.

**Columns/Parameters Involved**: `ShowDepositDetail`, `ShowSalesDetail`, `ShowPendingSalesCount`, `ShowTieredAffiliateCount`, `ShowTieredAffiliateDetail`, `ShowLeadDetail`, `ShowSale*`, `ShowLead*`

**Rules**:
- Each Show* flag toggles visibility of a specific data point in the affiliate dashboard
- This allows different transparency levels per plan - premium affiliates may see more detail
- ShowSaleAmount, ShowSaleCountry, ShowSaleOrderNumber control sale event detail granularity

### 2.5 Plan Hierarchy

**What**: Affiliate types can form a parent-child hierarchy for inherited configurations.

**Columns/Parameters Involved**: `FatherAffiliateTypeID`, `IsActive`

**Rules**:
- FatherAffiliateTypeID points to the parent plan (self-referencing FK)
- NULL FatherAffiliateTypeID = top-level/standalone plan
- IsActive controls whether the plan is available for assignment
- Index on FatherAffiliateTypeID+IsActive supports efficient hierarchy queries

---

## 3. Data Overview

| AffiliateTypeID | Description | Commission Model | Tiers | MinimumPayout | Meaning |
|-----------------|------------|-----------------|-------|---------------|---------|
| 2 | RevShare 25% (default) | Deposit + Sale | 2 | $100 | Default revenue share plan - affiliates earn 25% of referred customers' trading revenue. 2-tier hierarchy allows sub-affiliate commissions. |
| 3 | Internal Campaigns | All types enabled | 5 | $99,999,999 | Internal/testing plan with all commission types active. Extremely high minimum payout ($99.9M) prevents actual payouts - used for internal tracking only. |
| 4 | CPL $2 | Lead + Registration | 2 | $100 | Cost-per-lead plan paying $2 per qualified lead/registration. No deposit or sale commissions. Standard for content/media affiliates. |
| 7 | rev.share 45% | Deposit + Sale + Lead | 2 | $100 | Premium revenue share plan at 45% - higher rate for top-performing or strategic affiliates. |
| 8 | CPL$4 | Lead + Registration | 1 | $100 | Higher-value CPL plan at $4/lead. Single tier (no sub-affiliate commissions). For quality traffic sources. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateTypeID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Identifies the commission plan. Referenced by tblaff_Affiliates.AffiliateTypeID, tblaff_AffiliateTypeCategories.AffiliateTypeID, tblaff_Announcement_AffiliateType.AffiliateTypeID, tblaff_Country.AffiliateTypeID, tblaff_CPACountriesToAffiliateTypeID. |
| 2 | Description | nvarchar(100) | YES | - | CODE-BACKED | Human-readable plan name (e.g., "RevShare 25%", "CPL $2", "CPA $300"). Shown in admin UI and affiliate dashboards. |
| 3 | Notes | nvarchar(255) | YES | - | NAME-INFERRED | Internal notes about the commission plan for admin reference. |
| 4 | Tiers | int | NO | 1 | CODE-BACKED | Number of hierarchical tiers (1-5). Tier 1 = direct affiliate. Tiers 2-5 = sub-affiliates who referred the tier-1 affiliate. Default 1 = single tier (no sub-affiliate commissions). |
| 5 | TierType | int | NO | 0 | CODE-BACKED | Controls how tier commissions are calculated. 0 = standard tier calculation. |
| 6 | PerDeposit | bit | NO | 0 | CODE-BACKED | Enables deposit-based commissions. 1 = affiliates earn when referred customers deposit funds. |
| 7 | PerSale | bit | NO | 1 | CODE-BACKED | Enables sale/trading activity commissions. 1 = affiliates earn from trading revenue. Default ON - most plans include sale commissions. |
| 8 | PerLead | bit | NO | 0 | CODE-BACKED | Enables lead/download commissions. 1 = affiliates earn per qualified lead. |
| 9 | PerRegistration | bit | NO | 0 | CODE-BACKED | Enables registration commissions. 1 = affiliates earn per customer registration. |
| 10 | PerClick | bit | NO | 0 | CODE-BACKED | Enables click-based commissions. 1 = affiliates earn per click on tracking links. |
| 11 | FlatRateOrPercentOfSale | bit | NO | 0 | CODE-BACKED | Commission calculation mode for sales. 0 = percentage of sale revenue (RevShare). 1 = flat rate per sale (CPA-style). |
| 12 | CPAOrCPAD | bit | NO | 0 | CODE-BACKED | CPA model selector. 0 = standard CPA (cost per acquisition). 1 = CPAD (CPA with deposit requirement - only pays when customer also deposits). |
| 13 | PerDepositRate | float | NO | 0 | CODE-BACKED | Tier 1 deposit commission rate. Percentage or flat amount depending on FlatRateOrPercentOfSale. |
| 14 | PerDepositRate2 | float | NO | 0 | CODE-BACKED | Tier 2 deposit commission rate for sub-affiliates. |
| 15 | PerDepositRate3 | float | NO | 0 | CODE-BACKED | Tier 3 deposit commission rate. |
| 16 | PerDepositRate4 | float | NO | 0 | CODE-BACKED | Tier 4 deposit commission rate. |
| 17 | PerDepositRate5 | float | NO | 0 | CODE-BACKED | Tier 5 deposit commission rate. |
| 18 | PerSaleRate | float | NO | 0 | CODE-BACKED | Tier 1 sale commission rate. |
| 19 | PerSaleRate2 | float | NO | 0 | CODE-BACKED | Tier 2 sale commission rate. |
| 20 | PerSaleRate3 | float | NO | 0 | CODE-BACKED | Tier 3 sale commission rate. |
| 21 | PerSaleRate4 | float | NO | 0 | CODE-BACKED | Tier 4 sale commission rate. |
| 22 | PerSaleRate5 | float | NO | 0 | CODE-BACKED | Tier 5 sale commission rate. |
| 23 | PerLeadRate | float | NO | 0 | CODE-BACKED | Tier 1 lead commission rate. |
| 24 | PerLeadRate2 | float | NO | 0 | CODE-BACKED | Tier 2 lead commission rate. |
| 25 | PerLeadRate3 | float | NO | 0 | CODE-BACKED | Tier 3 lead commission rate. |
| 26 | PerLeadRate4 | float | NO | 0 | CODE-BACKED | Tier 4 lead commission rate. |
| 27 | PerLeadRate5 | float | NO | 0 | CODE-BACKED | Tier 5 lead commission rate. |
| 28 | PerRegistrationRate | float | NO | 0 | CODE-BACKED | Tier 1 registration commission rate. |
| 29 | PerRegistrationRate2 | float | NO | 0 | CODE-BACKED | Tier 2 registration commission rate. |
| 30 | PerRegistrationRate3 | float | NO | 0 | CODE-BACKED | Tier 3 registration commission rate. |
| 31 | PerRegistrationRate4 | float | NO | 0 | CODE-BACKED | Tier 4 registration commission rate. |
| 32 | PerRegistrationRate5 | float | NO | 0 | CODE-BACKED | Tier 5 registration commission rate. |
| 33 | PerClickRate | float | NO | 0 | CODE-BACKED | Tier 1 click commission rate. |
| 34 | PerClickRate2 | float | NO | 0 | CODE-BACKED | Tier 2 click commission rate. |
| 35 | PerClickRate3 | float | NO | 0 | CODE-BACKED | Tier 3 click commission rate. |
| 36 | PerClickRate4 | float | NO | 0 | CODE-BACKED | Tier 4 click commission rate. |
| 37 | PerClickRate5 | float | NO | 0 | CODE-BACKED | Tier 5 click commission rate. |
| 38 | AutomaticallyAcceptSales | bit | NO | 0 | CODE-BACKED | Auto-approval for sale events. 1 = sale commissions are automatically accepted without manual review. |
| 39 | AutomaticallyAcceptLeads | bit | NO | 0 | CODE-BACKED | Auto-approval for lead events. 1 = lead commissions are automatically accepted. |
| 40 | ShowDepositDetail | bit | NO | 0 | CODE-BACKED | Affiliate portal: show detailed deposit event data to affiliates. |
| 41 | ShowSalesDetail | bit | NO | 0 | CODE-BACKED | Affiliate portal: show detailed sale event data. |
| 42 | ShowPendingSalesCount | bit | NO | 0 | CODE-BACKED | Affiliate portal: show count of pending (unprocessed) sale events. |
| 43 | ShowTieredAffiliateCount | bit | NO | 0 | CODE-BACKED | Affiliate portal: show count of sub-affiliates in the hierarchy. |
| 44 | ShowTieredAffiliateDetail | bit | NO | 0 | CODE-BACKED | Affiliate portal: show detailed sub-affiliate information. |
| 45 | CookieExpiration | int | NO | 30 | CODE-BACKED | Attribution cookie lifetime in days. Default 30 days. Determines how long after a click the affiliate can be credited for a conversion. |
| 46 | MinimumPayout | float | NO | 0 | CODE-BACKED | Minimum accumulated commission balance (in USD) before payment is generated. $99,999,999 for internal plans prevents payouts. |
| 47 | ShowLeadDetail | bit | NO | 0 | CODE-BACKED | Affiliate portal: show detailed lead event data. |
| 48 | ShowPendingLeadCount | bit | NO | 0 | CODE-BACKED | Affiliate portal: show count of pending lead events. |
| 49 | ShowSaleOptional1 | bit | NO | 0 | CODE-BACKED | Affiliate portal: show Optional1 field in sale detail view. |
| 50 | ShowSaleOptional2 | bit | NO | 0 | CODE-BACKED | Affiliate portal: show Optional2 field in sale detail view. |
| 51 | ShowSaleOptional3 | bit | NO | 0 | CODE-BACKED | Affiliate portal: show Optional3 field in sale detail view. |
| 52 | ShowSaleAmount | bit | NO | 0 | CODE-BACKED | Affiliate portal: show sale amount in detail view. |
| 53 | ShowSaleOrderNumber | bit | NO | 0 | CODE-BACKED | Affiliate portal: show order number in sale detail view. |
| 54 | ShowSaleCountry | bit | NO | 0 | CODE-BACKED | Affiliate portal: show customer country in sale detail view. |
| 55 | ShowLeadNumber | bit | NO | 0 | CODE-BACKED | Affiliate portal: show lead number in detail view. |
| 56 | ShowLeadOptional1 | bit | NO | 0 | CODE-BACKED | Affiliate portal: show Optional1 field in lead detail view. |
| 57 | ShowLeadOptional2 | bit | NO | 0 | CODE-BACKED | Affiliate portal: show Optional2 field in lead detail view. |
| 58 | ShowLeadOptional3 | bit | NO | 0 | CODE-BACKED | Affiliate portal: show Optional3 field in lead detail view. |
| 59 | DepositCommission1BonusType | int | NO | 0 | CODE-BACKED | Bonus structure type for deposit commission tier 1. Controls how the bonus is calculated. |
| 60 | DepositCommission1BonusAmount | float | NO | 0 | CODE-BACKED | Bonus amount for deposit commission tier 1. |
| 61 | DepositCommission1BonusThreshold | float | NO | 0 | CODE-BACKED | Volume threshold that must be reached before the deposit bonus tier 1 activates. |
| 62 | DepositCommission2BonusType | int | NO | 0 | CODE-BACKED | Bonus structure type for deposit commission tier 2. |
| 63 | DepositCommission2BonusAmount | float | NO | 0 | CODE-BACKED | Bonus amount for deposit commission tier 2. |
| 64 | DepositCommission2BonusThreshold | float | NO | 0 | CODE-BACKED | Volume threshold for deposit bonus tier 2. |
| 65 | SaleCommission1BonusType | int | NO | 0 | CODE-BACKED | Bonus structure type for sale commission tier 1. |
| 66 | SaleCommission1BonusAmount | float | NO | 0 | CODE-BACKED | Bonus amount for sale commission tier 1. |
| 67 | SaleCommission1BonusThreshold | float | NO | 0 | CODE-BACKED | Volume threshold for sale bonus tier 1. |
| 68 | SaleCommission2BonusType | int | NO | 0 | CODE-BACKED | Bonus structure type for sale commission tier 2. |
| 69 | SaleCommission2BonusAmount | float | NO | 0 | CODE-BACKED | Bonus amount for sale commission tier 2. |
| 70 | SaleCommission2BonusThreshold | float | NO | 0 | CODE-BACKED | Volume threshold for sale bonus tier 2. |
| 71 | LeadCommission1BonusType | int | NO | 0 | CODE-BACKED | Bonus structure type for lead commission tier 1. |
| 72 | LeadCommission1BonusAmount | float | NO | 0 | CODE-BACKED | Bonus amount for lead commission tier 1. |
| 73 | LeadCommission1BonusThreshold | float | NO | 0 | CODE-BACKED | Volume threshold for lead bonus tier 1. |
| 74 | LeadCommission2BonusType | int | NO | 0 | CODE-BACKED | Bonus structure type for lead commission tier 2. |
| 75 | LeadCommission2BonusAmount | float | NO | 0 | CODE-BACKED | Bonus amount for lead commission tier 2. |
| 76 | LeadCommission2BonusThreshold | float | NO | 0 | CODE-BACKED | Volume threshold for lead bonus tier 2. |
| 77 | ClickCommission1BonusType | int | NO | 0 | CODE-BACKED | Bonus structure type for click commission tier 1. |
| 78 | ClickCommission1BonusAmount | float | NO | 0 | CODE-BACKED | Bonus amount for click commission tier 1. |
| 79 | ClickCommission1BonusThreshold | float | NO | 0 | CODE-BACKED | Volume threshold for click bonus tier 1. |
| 80 | ClickCommission2BonusType | int | NO | 0 | CODE-BACKED | Bonus structure type for click commission tier 2. |
| 81 | ClickCommission2BonusAmount | float | NO | 0 | CODE-BACKED | Bonus amount for click commission tier 2. |
| 82 | ClickCommission2BonusThreshold | float | NO | 0 | CODE-BACKED | Volume threshold for click bonus tier 2. |
| 83 | DeleteCookieAfterSale | bit | NO | 0 | CODE-BACKED | Cookie behavior: delete attribution cookie after a sale event fires. 1 = one-time attribution per sale. |
| 84 | DeleteCookieAfterLead | bit | NO | 0 | CODE-BACKED | Cookie behavior: delete attribution cookie after a lead event fires. |
| 85 | DeleteCookieAfterClick | bit | NO | 0 | CODE-BACKED | Cookie behavior: delete attribution cookie after a click event. |
| 86 | ShowCreateALinkOption | bit | NO | 0 | CODE-BACKED | Affiliate portal: show the "Create a Link" tool allowing affiliates to generate custom tracking URLs. |
| 87 | AllTiersRate2 | float | NO | 0 | CODE-BACKED | Override rate for all commission types at tier 2 (cross-event tier-2 rate). |
| 88 | AllTiersRate3 | float | NO | 0 | CODE-BACKED | Override rate for all commission types at tier 3. |
| 89 | AllTiersRate4 | float | NO | 0 | CODE-BACKED | Override rate for all commission types at tier 4. |
| 90 | AllTiersRate5 | float | NO | 0 | CODE-BACKED | Override rate for all commission types at tier 5. |
| 91 | DepositSlab1To | int | NO | 0 | CODE-BACKED | Upper boundary of deposit slab tier 1 (e.g., up to $1,000). |
| 92 | DepositSlab2To | int | NO | 0 | CODE-BACKED | Upper boundary of deposit slab tier 2. |
| 93 | DepositSlab3To | int | NO | 0 | CODE-BACKED | Upper boundary of deposit slab tier 3. Volume above this falls in tier 4. |
| 94 | DepositSlab1Amount | float | NO | 0 | CODE-BACKED | Commission amount/rate for deposit slab tier 1 (lowest volume). |
| 95 | DepositSlab2Amount | float | NO | 0 | CODE-BACKED | Commission amount/rate for deposit slab tier 2. |
| 96 | DepositSlab3Amount | float | NO | 0 | CODE-BACKED | Commission amount/rate for deposit slab tier 3. |
| 97 | DepositSlab4Amount | float | NO | 0 | CODE-BACKED | Commission amount/rate for deposit slab tier 4 (highest volume, uncapped). |
| 98 | SaleSlab1To | int | NO | 0 | CODE-BACKED | Upper boundary of sale slab tier 1. |
| 99 | SaleSlab2To | int | NO | 0 | CODE-BACKED | Upper boundary of sale slab tier 2. |
| 100 | SaleSlab3To | int | NO | 0 | CODE-BACKED | Upper boundary of sale slab tier 3. |
| 101 | SaleSlab1Percent | float | NO | 0 | CODE-BACKED | Commission percentage for sale slab tier 1. |
| 102 | SaleSlab2Percent | float | NO | 0 | CODE-BACKED | Commission percentage for sale slab tier 2. |
| 103 | SaleSlab3Percent | float | NO | 0 | CODE-BACKED | Commission percentage for sale slab tier 3. |
| 104 | SaleSlab4Percent | float | NO | 0 | CODE-BACKED | Commission percentage for sale slab tier 4 (highest volume). |
| 105 | CPADPercent | float | NO | 0 | CODE-BACKED | Additional percentage applied under the CPAD (CPA with deposit) model when CPAOrCPAD=1. |
| 106 | PNLSlab1To | int | NO | 0 | CODE-BACKED | Upper boundary of PnL slab tier 1. |
| 107 | PNLSlab2To | int | NO | 0 | CODE-BACKED | Upper boundary of PnL slab tier 2. |
| 108 | PNLSlab3To | int | NO | 0 | CODE-BACKED | Upper boundary of PnL slab tier 3. |
| 109 | PNLSlab1Percent | float | NO | 0 | CODE-BACKED | Commission percentage for PnL slab tier 1. |
| 110 | PNLSlab2Percent | float | NO | 0 | CODE-BACKED | Commission percentage for PnL slab tier 2. |
| 111 | PNLSlab3Percent | float | NO | 0 | CODE-BACKED | Commission percentage for PnL slab tier 3. |
| 112 | PNLSlab4Percent | float | NO | 0 | CODE-BACKED | Commission percentage for PnL slab tier 4. |
| 113 | PerPNL | bit | NO | 0 | CODE-BACKED | Enables PnL-based commissions. 1 = affiliates earn from customer profit and loss. |
| 114 | LeadPerCountry | bit | NO | 0 | CODE-BACKED | Enables country-specific lead rates. 1 = different lead commission rates per country (uses tblaff_CPACountriesToAffiliateTypeID). |
| 115 | RegistrationPerCountry | bit | NO | 0 | CODE-BACKED | Enables country-specific registration rates. 1 = different registration rates per country. |
| 116 | PerCopyTrader | bit | NO | 0 | CODE-BACKED | Enables copy trader commissions. 1 = affiliates earn when referred customers use CopyTrader. |
| 117 | CopyTraderSlab1To | int | NO | 0 | CODE-BACKED | Upper boundary of copy trader slab tier 1. |
| 118 | CopyTraderSlab2To | int | NO | 0 | CODE-BACKED | Upper boundary of copy trader slab tier 2. |
| 119 | CopyTraderSlab3To | int | NO | 0 | CODE-BACKED | Upper boundary of copy trader slab tier 3. |
| 120 | CopyTraderSlab1Amount | float | NO | 0 | CODE-BACKED | Commission amount for copy trader slab tier 1. |
| 121 | CopyTraderSlab2Amount | float | NO | 0 | CODE-BACKED | Commission amount for copy trader slab tier 2. |
| 122 | CopyTraderSlab3Amount | float | NO | 0 | CODE-BACKED | Commission amount for copy trader slab tier 3. |
| 123 | CopyTraderSlab4Amount | float | NO | 0 | CODE-BACKED | Commission amount for copy trader slab tier 4 (highest volume). |
| 124 | PerFirstPosition | bit | NO | 0 | CODE-BACKED | Enables first-position commissions. 1 = affiliates earn when referred customers open their first trading position. |
| 125 | PerFirstPositionRate | float | NO | 0 | CODE-BACKED | Commission rate for first position events. |
| 126 | FatherAffiliateTypeID | int | YES | - | CODE-BACKED | Self-referencing FK to parent affiliate type. Enables plan hierarchy/inheritance. NULL = top-level plan. |
| 127 | IsActive | bit | YES | - | CODE-BACKED | Whether this plan is available for assignment. NULL/0 = inactive/archived, 1 = active and assignable. |
| 128 | MinimumCommission | float | YES | - | CODE-BACKED | Minimum commission amount per event. Events below this threshold may not generate commissions. |
| 129 | Trace | computed | NO | - | CODE-BACKED | Computed audit column. JSON with session metadata (HostName, AppName, SUserName, SPID, DBName, ObjectName). |
| 130 | ValidFrom | datetime2(7) | NO | getutcdate() | CODE-BACKED | System-versioning period start. Hidden. |
| 131 | ValidTo | datetime2(7) | NO | '9999-12-31...' | CODE-BACKED | System-versioning period end. Hidden. |
| 132 | CommissionByOpenPosition | bit | NO | 0 | CODE-BACKED | Enables commission calculation based on open (active) positions rather than closed/completed trades. |
| 133 | IsTradeRequired | bit | NO | 0 | CODE-BACKED | Whether a customer must complete a trade before the affiliate earns commission. 1 = trade required for CPA qualification. |
| 134 | BlockTrackingLinks | tinyint | NO | 0 | CODE-BACKED | Controls whether tracking links are blocked for this affiliate type. 0 = allowed, >0 = blocked. |
| 135 | BlockCreatives | tinyint | NO | 0 | CODE-BACKED | Controls whether creative/banner assets are blocked for this affiliate type. 0 = allowed, >0 = blocked. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FatherAffiliateTypeID | dbo.tblaff_AffiliateTypes | Self-Reference | Points to parent plan in the affiliate type hierarchy. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_Affiliates | AffiliateTypeID | Implicit FK | Assigns a commission plan to each affiliate. |
| dbo.tblaff_AffiliateTypeCategories | AffiliateTypeID | Trigger-FK | Maps which banner categories are available to affiliates on this plan. |
| dbo.tblaff_Announcement_AffiliateType | AffiliateTypeID | Implicit FK | Targets announcements to affiliates on specific plans. |
| dbo.tblaff_Country | AffiliateTypeID | Implicit FK | Default affiliate type per country. |
| dbo.tblaff_CPACountriesToAffiliateTypeID | AffiliateTypeID | Implicit FK | Country-specific CPA rate overrides per plan. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies (self-referencing FK is within the same table).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table | AffiliateTypeID references this |
| dbo.tblaff_AffiliateTypeCategories | Table | AffiliateTypeID trigger-FK |
| dbo.tblaff_Announcement_AffiliateType | Table | AffiliateTypeID references this |
| dbo.tblaff_Country | Table | AffiliateTypeID references this |
| dbo.UpdateInsertAffiliateType | Stored Procedure | WRITER/MODIFIER |
| dbo.UpdateAffiliateType | Stored Procedure | MODIFIER |
| dbo.GetAffiliateTypeById | Stored Procedure | READER |
| dbo.GetSlabsPerAffiliateType | Stored Procedure | READER - retrieves slab configuration |
| dbo.GetSlabAmountsPerAffiliateType | Stored Procedure | READER - retrieves slab amounts |
| dbo.CPAPerCountrySaveDepositSlab | Stored Procedure | MODIFIER - saves country-specific CPA slabs |
| dbo.GetAffiliateTypeIdsAndCountriesByFather | Stored Procedure | READER - queries plan hierarchy |
| dbo.InsertFatherAffiliate | Stored Procedure | WRITER - creates parent affiliate type entries |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| tblaff_AffiliateTypes_PK | CLUSTERED PK | AffiliateTypeID | - | - | Active |
| AffiliateType_Covered | NONCLUSTERED | AffiliateTypeID, Description | - | - | Active |
| IX_tblaff_AffiliateTypes_FatherAffiliateTypeID | NONCLUSTERED | FatherAffiliateTypeID, IsActive | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SYSTEM_VERSIONING | Temporal | History table: History.tblaff_AffiliateTypes. Tracks all commission plan changes. |
| DF_tblaff_AffiliateTypes_Tiers | DEFAULT | Tiers = 1 (single-tier by default) |
| DF_tblaff_AffiliateTypes_PerSale | DEFAULT | PerSale = 1 (sale commissions ON by default) |
| DF_tblaff_AffiliateTypes_CookieExpiration | DEFAULT | CookieExpiration = 30 (30-day cookie by default) |
| ~100+ DEFAULT constraints | DEFAULT | All rate/amount/slab/bonus fields default to 0; all Show* flags default to 0 |

---

## 8. Sample Queries

### 8.1 List active revenue share plans
```sql
SELECT AffiliateTypeID, Description, PerDepositRate AS Tier1Rate,
       Tiers, MinimumPayout, CookieExpiration
FROM dbo.tblaff_AffiliateTypes WITH (NOLOCK)
WHERE IsActive = 1
  AND PerDeposit = 1
  AND FlatRateOrPercentOfSale = 0
ORDER BY PerDepositRate DESC
```

### 8.2 Find plans with slab-based pricing
```sql
SELECT AffiliateTypeID, Description,
       DepositSlab1To, DepositSlab2To, DepositSlab3To,
       DepositSlab1Amount, DepositSlab2Amount, DepositSlab3Amount, DepositSlab4Amount
FROM dbo.tblaff_AffiliateTypes WITH (NOLOCK)
WHERE DepositSlab1To > 0
  AND IsActive = 1
ORDER BY Description
```

### 8.3 List plan hierarchy (parent-child)
```sql
SELECT child.AffiliateTypeID, child.Description AS ChildPlan,
       parent.AffiliateTypeID AS ParentID, parent.Description AS ParentPlan
FROM dbo.tblaff_AffiliateTypes child WITH (NOLOCK)
JOIN dbo.tblaff_AffiliateTypes parent WITH (NOLOCK) ON child.FatherAffiliateTypeID = parent.AffiliateTypeID
WHERE child.IsActive = 1
ORDER BY parent.Description, child.Description
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.8/10 (Elements: 9.9/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 134 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 13 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_AffiliateTypes | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_AffiliateTypes.sql*
