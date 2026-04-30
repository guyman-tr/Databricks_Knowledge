# History.tblaff_AffiliateTypes

> SQL Server temporal history table storing all historical versions of affiliate type definitions, which control commission structures, rate tiers, payout rules, and feature access for each affiliate plan.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | AffiliateTypeID (int) - identifies the affiliate type across versions |
| **Partition** | No |
| **Indexes** | 1 active (clustered on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.tblaff_AffiliateTypes is the system-versioned temporal history table for dbo.tblaff_AffiliateTypes. It captures every historical version of affiliate type configurations whenever commission rates, payout rules, feature flags, or plan settings are modified. Affiliate types are the core configuration entity in the fiktivo affiliate system - they define the complete commission plan an affiliate operates under, including rates for deposits, sales, leads, registrations, clicks, copy trading, first positions, and PnL sharing.

This table is critical for audit and dispute resolution. When an affiliate claims their commission rate was different at the time of a transaction, this table provides the definitive historical record of what the affiliate type configuration looked like at any point in time. It also supports compliance requirements by preserving a complete change history of all commission structures.

Data flows in automatically via SQL Server's temporal mechanism when dbo.tblaff_AffiliateTypes is updated. The Trace column captures which application and stored procedure triggered the change. With 555 historical versions across all affiliate types, changes to commission structures are relatively infrequent but operationally significant.

---

## 2. Business Logic

### 2.1 Multi-Commission-Model Configuration

**What**: Each affiliate type defines which commission models are active (deposit, sale, lead, registration, click, CPA, PnL, copy trading, first position) and the tiered rates for each.

**Columns/Parameters Involved**: `PerDeposit`, `PerSale`, `PerLead`, `PerRegistration`, `PerClick`, `PerPNL`, `PerCopyTrader`, `PerFirstPosition`, `CPAOrCPAD`, `FlatRateOrPercentOfSale`

**Rules**:
- Each `Per*` bit flag enables/disables that commission model for this affiliate type
- When a model is enabled, the corresponding `Per*Rate` through `Per*Rate5` columns define tiered rates (Tier 1-5)
- `FlatRateOrPercentOfSale`: 0 = flat rate per event, 1 = percentage of sale amount
- `CPAOrCPAD`: 0 = CPA (Cost Per Acquisition), 1 = CPAD (Cost Per Acquisition + Deposit)
- Slab columns (DepositSlab*, SaleSlab*, PNLSlab*, CopyTraderSlab*) define volume thresholds for progressive rate tiers

### 2.2 Affiliate Type Hierarchy

**What**: Affiliate types can form a parent-child hierarchy via FatherAffiliateTypeID, enabling inheritance of settings.

**Columns/Parameters Involved**: `AffiliateTypeID`, `FatherAffiliateTypeID`, `Tiers`, `TierType`

**Rules**:
- FatherAffiliateTypeID = NULL means this is a root/standalone affiliate type
- FatherAffiliateTypeID pointing to another AffiliateTypeID creates a child relationship
- Tiers defines how many tier levels this type supports (1-5)
- TierType defines the tiering model (how rates scale with volume)

---

## 3. Data Overview

| AffiliateTypeID | Description | PerDeposit | PerSale | PerRegistration | IsActive | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|---|---|---|
| 4735 | ISA Test 8278498390 | true | true | true | NULL | 2026-02-18 09:48:09 | 2026-02-18 09:56:41 | Test affiliate type for ISA product configuration - multiple rapid versions created during automated testing |
| 4735 | ISA Test 8278498390 | true | true | true | NULL | 2026-02-18 09:47:20 | 2026-02-18 09:48:09 | Earlier version of the same test type - shows the temporal chain with ~1 minute between versions |
| 4735 | ISA Test 8278498390 | true | true | true | NULL | 2026-02-18 09:47:10 | 2026-02-18 09:47:20 | Earliest captured version - created 10 seconds before first update, illustrating rapid iteration during testing |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateTypeID | int | NO | - | CODE-BACKED | Unique identifier for the affiliate type plan. Matches dbo.tblaff_AffiliateTypes.AffiliateTypeID. Multiple history rows share the same ID, each representing a different version. |
| 2 | Description | nvarchar(100) | YES | - | CODE-BACKED | Human-readable name of the affiliate type plan (e.g., "ISA Test", "Standard CPA"). Displayed in the affiliate admin console. |
| 3 | Notes | nvarchar(255) | YES | - | CODE-BACKED | Internal notes about this affiliate type, visible only to admin users. |
| 4 | Tiers | int | NO | - | CODE-BACKED | Number of commission tier levels this affiliate type supports (1-5). Higher tiers offer better rates for higher-volume affiliates. |
| 5 | TierType | int | NO | - | CODE-BACKED | Tiering model that determines how rates scale: defines the relationship between volume thresholds and rate progression. |
| 6 | PerDeposit | bit | NO | - | CODE-BACKED | Whether this affiliate type earns commission on customer deposits. When true, PerDepositRate1-5 columns define the tiered deposit commission rates. |
| 7 | PerSale | bit | NO | - | CODE-BACKED | Whether this affiliate type earns commission on customer trades/sales. When true, PerSaleRate1-5 columns define the tiered sale commission rates. |
| 8 | PerLead | bit | NO | - | CODE-BACKED | Whether this affiliate type earns commission per lead (customer registration that meets qualification criteria). |
| 9 | PerRegistration | bit | NO | - | CODE-BACKED | Whether this affiliate type earns commission per customer registration, regardless of lead qualification. |
| 10 | PerClick | bit | NO | - | CODE-BACKED | Whether this affiliate type earns commission per click on tracking links. |
| 11 | FlatRateOrPercentOfSale | bit | NO | - | CODE-BACKED | Commission calculation mode: 0 = flat rate (fixed amount per event), 1 = percentage of the sale/deposit amount. |
| 12 | CPAOrCPAD | bit | NO | - | CODE-BACKED | CPA model variant: 0 = CPA (Cost Per Acquisition - commission on customer signup), 1 = CPAD (Cost Per Acquisition + Deposit - commission only when customer also deposits). |
| 13 | PerDepositRate | float | NO | - | CODE-BACKED | Tier 1 deposit commission rate (flat amount or percentage based on FlatRateOrPercentOfSale). |
| 14 | PerDepositRate2 | float | NO | - | CODE-BACKED | Tier 2 deposit commission rate. |
| 15 | PerDepositRate3 | float | NO | - | CODE-BACKED | Tier 3 deposit commission rate. |
| 16 | PerDepositRate4 | float | NO | - | CODE-BACKED | Tier 4 deposit commission rate. |
| 17 | PerDepositRate5 | float | NO | - | CODE-BACKED | Tier 5 deposit commission rate. |
| 18 | PerSaleRate | float | NO | - | CODE-BACKED | Tier 1 sale/trade commission rate. |
| 19 | PerSaleRate2 | float | NO | - | CODE-BACKED | Tier 2 sale commission rate. |
| 20 | PerSaleRate3 | float | NO | - | CODE-BACKED | Tier 3 sale commission rate. |
| 21 | PerSaleRate4 | float | NO | - | CODE-BACKED | Tier 4 sale commission rate. |
| 22 | PerSaleRate5 | float | NO | - | CODE-BACKED | Tier 5 sale commission rate. |
| 23 | PerLeadRate | float | NO | - | CODE-BACKED | Tier 1 lead commission rate. |
| 24 | PerLeadRate2 | float | NO | - | CODE-BACKED | Tier 2 lead commission rate. |
| 25 | PerLeadRate3 | float | NO | - | CODE-BACKED | Tier 3 lead commission rate. |
| 26 | PerLeadRate4 | float | NO | - | CODE-BACKED | Tier 4 lead commission rate. |
| 27 | PerLeadRate5 | float | NO | - | CODE-BACKED | Tier 5 lead commission rate. |
| 28 | PerRegistrationRate | float | NO | - | CODE-BACKED | Tier 1 registration commission rate. |
| 29 | PerRegistrationRate2 | float | NO | - | CODE-BACKED | Tier 2 registration commission rate. |
| 30 | PerRegistrationRate3 | float | NO | - | CODE-BACKED | Tier 3 registration commission rate. |
| 31 | PerRegistrationRate4 | float | NO | - | CODE-BACKED | Tier 4 registration commission rate. |
| 32 | PerRegistrationRate5 | float | NO | - | CODE-BACKED | Tier 5 registration commission rate. |
| 33 | PerClickRate | float | NO | - | CODE-BACKED | Tier 1 click commission rate. |
| 34 | PerClickRate2 | float | NO | - | CODE-BACKED | Tier 2 click commission rate. |
| 35 | PerClickRate3 | float | NO | - | CODE-BACKED | Tier 3 click commission rate. |
| 36 | PerClickRate4 | float | NO | - | CODE-BACKED | Tier 4 click commission rate. |
| 37 | PerClickRate5 | float | NO | - | CODE-BACKED | Tier 5 click commission rate. |
| 38 | AutomaticallyAcceptSales | bit | NO | - | CODE-BACKED | Whether sales from affiliates on this plan are automatically approved for commission without manual review. |
| 39 | AutomaticallyAcceptLeads | bit | NO | - | CODE-BACKED | Whether leads from affiliates on this plan are automatically approved without manual review. |
| 40 | ShowDepositDetail | bit | NO | - | CODE-BACKED | Whether affiliates on this plan can see detailed deposit information in their console. |
| 41 | ShowSalesDetail | bit | NO | - | CODE-BACKED | Whether affiliates can see detailed sales/trade information. |
| 42 | ShowPendingSalesCount | bit | NO | - | CODE-BACKED | Whether affiliates can see the count of pending (unprocessed) sales. |
| 43 | ShowTieredAffiliateCount | bit | NO | - | CODE-BACKED | Whether affiliates can see the count of sub-affiliates in their tier. |
| 44 | ShowTieredAffiliateDetail | bit | NO | - | CODE-BACKED | Whether affiliates can see detailed information about their sub-affiliates. |
| 45 | CookieExpiration | int | NO | - | CODE-BACKED | Number of days the affiliate tracking cookie remains valid. After expiration, new customers from clicks are no longer attributed to this affiliate. |
| 46 | MinimumPayout | float | NO | - | CODE-BACKED | Minimum commission balance required before a payout can be processed. Prevents micro-payments. |
| 47 | ShowLeadDetail | bit | NO | - | CODE-BACKED | Whether affiliates can see detailed lead information. |
| 48 | ShowPendingLeadCount | bit | NO | - | CODE-BACKED | Whether affiliates can see the count of pending leads. |
| 49 | ShowSaleOptional1 | bit | NO | - | CODE-BACKED | Whether optional sale data field 1 is visible to affiliates. |
| 50 | ShowSaleOptional2 | bit | NO | - | CODE-BACKED | Whether optional sale data field 2 is visible. |
| 51 | ShowSaleOptional3 | bit | NO | - | CODE-BACKED | Whether optional sale data field 3 is visible. |
| 52 | ShowSaleAmount | bit | NO | - | CODE-BACKED | Whether the sale amount is visible to affiliates. |
| 53 | ShowSaleOrderNumber | bit | NO | - | CODE-BACKED | Whether the sale order number is visible. |
| 54 | ShowSaleCountry | bit | NO | - | CODE-BACKED | Whether the sale country is visible. |
| 55 | ShowLeadNumber | bit | NO | - | CODE-BACKED | Whether the lead number is visible. |
| 56 | ShowLeadOptional1 | bit | NO | - | CODE-BACKED | Whether optional lead data field 1 is visible. |
| 57 | ShowLeadOptional2 | bit | NO | - | CODE-BACKED | Whether optional lead data field 2 is visible. |
| 58 | ShowLeadOptional3 | bit | NO | - | CODE-BACKED | Whether optional lead data field 3 is visible. |
| 59 | DepositCommission1BonusType | int | NO | - | CODE-BACKED | Bonus type for the first deposit commission bonus tier. Defines how the bonus is calculated. |
| 60 | DepositCommission1BonusAmount | float | NO | - | CODE-BACKED | Bonus amount for the first deposit commission bonus tier. |
| 61 | DepositCommission1BonusThreshold | float | NO | - | CODE-BACKED | Volume threshold that triggers the first deposit commission bonus. |
| 62 | DepositCommission2BonusType | int | NO | - | CODE-BACKED | Bonus type for the second deposit commission bonus tier. |
| 63 | DepositCommission2BonusAmount | float | NO | - | CODE-BACKED | Bonus amount for the second deposit commission bonus tier. |
| 64 | DepositCommission2BonusThreshold | float | NO | - | CODE-BACKED | Volume threshold for the second deposit commission bonus. |
| 65 | SaleCommission1BonusType | int | NO | - | CODE-BACKED | Bonus type for the first sale commission bonus tier. |
| 66 | SaleCommission1BonusAmount | float | NO | - | CODE-BACKED | Bonus amount for the first sale commission bonus. |
| 67 | SaleCommission1BonusThreshold | float | NO | - | CODE-BACKED | Volume threshold for the first sale commission bonus. |
| 68 | SaleCommission2BonusType | int | NO | - | CODE-BACKED | Bonus type for the second sale commission bonus tier. |
| 69 | SaleCommission2BonusAmount | float | NO | - | CODE-BACKED | Bonus amount for the second sale commission bonus. |
| 70 | SaleCommission2BonusThreshold | float | NO | - | CODE-BACKED | Volume threshold for the second sale commission bonus. |
| 71 | LeadCommission1BonusType | int | NO | - | CODE-BACKED | Bonus type for the first lead commission bonus tier. |
| 72 | LeadCommission1BonusAmount | float | NO | - | CODE-BACKED | Bonus amount for the first lead commission bonus. |
| 73 | LeadCommission1BonusThreshold | float | NO | - | CODE-BACKED | Volume threshold for the first lead commission bonus. |
| 74 | LeadCommission2BonusType | int | NO | - | CODE-BACKED | Bonus type for the second lead commission bonus tier. |
| 75 | LeadCommission2BonusAmount | float | NO | - | CODE-BACKED | Bonus amount for the second lead commission bonus. |
| 76 | LeadCommission2BonusThreshold | float | NO | - | CODE-BACKED | Volume threshold for the second lead commission bonus. |
| 77 | ClickCommission1BonusType | int | NO | - | CODE-BACKED | Bonus type for the first click commission bonus tier. |
| 78 | ClickCommission1BonusAmount | float | NO | - | CODE-BACKED | Bonus amount for the first click commission bonus. |
| 79 | ClickCommission1BonusThreshold | float | NO | - | CODE-BACKED | Volume threshold for the first click commission bonus. |
| 80 | ClickCommission2BonusType | int | NO | - | CODE-BACKED | Bonus type for the second click commission bonus tier. |
| 81 | ClickCommission2BonusAmount | float | NO | - | CODE-BACKED | Bonus amount for the second click commission bonus. |
| 82 | ClickCommission2BonusThreshold | float | NO | - | CODE-BACKED | Volume threshold for the second click commission bonus. |
| 83 | DeleteCookieAfterSale | bit | NO | - | CODE-BACKED | Whether the affiliate tracking cookie is deleted after a sale is attributed. Prevents double-counting. |
| 84 | DeleteCookieAfterLead | bit | NO | - | CODE-BACKED | Whether the tracking cookie is deleted after a lead is attributed. |
| 85 | DeleteCookieAfterClick | bit | NO | - | CODE-BACKED | Whether the tracking cookie is deleted after a click is counted. |
| 86 | ShowCreateALinkOption | bit | NO | - | CODE-BACKED | Whether affiliates can create custom tracking links in their console. |
| 87 | AllTiersRate2 | float | NO | - | CODE-BACKED | Universal tier 2 rate multiplier applied across all commission models. |
| 88 | AllTiersRate3 | float | NO | - | CODE-BACKED | Universal tier 3 rate multiplier. |
| 89 | AllTiersRate4 | float | NO | - | CODE-BACKED | Universal tier 4 rate multiplier. |
| 90 | AllTiersRate5 | float | NO | - | CODE-BACKED | Universal tier 5 rate multiplier. |
| 91 | DepositSlab1To | int | NO | - | CODE-BACKED | Upper bound of the first deposit volume slab (number of deposits). |
| 92 | DepositSlab2To | int | NO | - | CODE-BACKED | Upper bound of the second deposit volume slab. |
| 93 | DepositSlab3To | int | NO | - | CODE-BACKED | Upper bound of the third deposit volume slab. |
| 94 | DepositSlab1Amount | float | NO | - | CODE-BACKED | Commission amount for deposits within slab 1. |
| 95 | DepositSlab2Amount | float | NO | - | CODE-BACKED | Commission amount for deposits within slab 2. |
| 96 | DepositSlab3Amount | float | NO | - | CODE-BACKED | Commission amount for deposits within slab 3. |
| 97 | DepositSlab4Amount | float | NO | - | CODE-BACKED | Commission amount for deposits above slab 3 (overflow tier). |
| 98 | SaleSlab1To | int | NO | - | CODE-BACKED | Upper bound of the first sale volume slab. |
| 99 | SaleSlab2To | int | NO | - | CODE-BACKED | Upper bound of the second sale volume slab. |
| 100 | SaleSlab3To | int | NO | - | CODE-BACKED | Upper bound of the third sale volume slab. |
| 101 | SaleSlab1Percent | float | NO | - | CODE-BACKED | Commission percentage for sales within slab 1. |
| 102 | SaleSlab2Percent | float | NO | - | CODE-BACKED | Commission percentage for sales within slab 2. |
| 103 | SaleSlab3Percent | float | NO | - | CODE-BACKED | Commission percentage for sales within slab 3. |
| 104 | SaleSlab4Percent | float | NO | - | CODE-BACKED | Commission percentage for sales above slab 3. |
| 105 | CPADPercent | float | NO | - | CODE-BACKED | Percentage used in CPAD (Cost Per Acquisition + Deposit) commission calculations. |
| 106 | PNLSlab1To | int | NO | - | CODE-BACKED | Upper bound of the first PnL (revenue share) volume slab. |
| 107 | PNLSlab2To | int | NO | - | CODE-BACKED | Upper bound of the second PnL volume slab. |
| 108 | PNLSlab3To | int | NO | - | CODE-BACKED | Upper bound of the third PnL volume slab. |
| 109 | PNLSlab1Percent | float | NO | - | CODE-BACKED | Revenue share percentage for PnL within slab 1. |
| 110 | PNLSlab2Percent | float | NO | - | CODE-BACKED | Revenue share percentage for PnL within slab 2. |
| 111 | PNLSlab3Percent | float | NO | - | CODE-BACKED | Revenue share percentage for PnL within slab 3. |
| 112 | PNLSlab4Percent | float | NO | - | CODE-BACKED | Revenue share percentage for PnL above slab 3. |
| 113 | PerPNL | bit | NO | - | CODE-BACKED | Whether this affiliate type earns revenue share commission based on customer PnL (profit and loss). |
| 114 | LeadPerCountry | bit | NO | - | CODE-BACKED | Whether lead commission rates vary by the customer's country. |
| 115 | RegistrationPerCountry | bit | NO | - | CODE-BACKED | Whether registration commission rates vary by the customer's country. |
| 116 | PerCopyTrader | bit | NO | - | CODE-BACKED | Whether this affiliate type earns commission on CopyTrader activities (when referred customers copy other traders). |
| 117 | CopyTraderSlab1To | int | NO | - | CODE-BACKED | Upper bound of the first CopyTrader volume slab. |
| 118 | CopyTraderSlab2To | int | NO | - | CODE-BACKED | Upper bound of the second CopyTrader volume slab. |
| 119 | CopyTraderSlab3To | int | NO | - | CODE-BACKED | Upper bound of the third CopyTrader volume slab. |
| 120 | CopyTraderSlab1Amount | float | NO | - | CODE-BACKED | Commission amount for CopyTrader activity within slab 1. |
| 121 | CopyTraderSlab2Amount | float | NO | - | CODE-BACKED | Commission amount for CopyTrader activity within slab 2. |
| 122 | CopyTraderSlab3Amount | float | NO | - | CODE-BACKED | Commission amount for CopyTrader activity within slab 3. |
| 123 | CopyTraderSlab4Amount | float | NO | - | CODE-BACKED | Commission amount for CopyTrader activity above slab 3. |
| 124 | PerFirstPosition | bit | NO | - | CODE-BACKED | Whether this affiliate type earns commission when a referred customer opens their first trading position. |
| 125 | PerFirstPositionRate | float | NO | - | CODE-BACKED | Commission rate for first position events. |
| 126 | FatherAffiliateTypeID | int | YES | - | CODE-BACKED | Parent affiliate type ID for hierarchical type inheritance. NULL = root/standalone type. Points to another AffiliateTypeID (self-referencing). |
| 127 | IsActive | bit | YES | - | CODE-BACKED | Whether this affiliate type is currently active and can be assigned to new affiliates. NULL or false = inactive/deprecated. |
| 128 | MinimumCommission | float | YES | - | CODE-BACKED | Minimum commission amount per event. If the calculated commission is below this threshold, this minimum is used instead. |
| 129 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON session context captured when this version was created. Contains: HostName, AppName, SUserName, SPID, DBName, ObjectName (the stored procedure that triggered the change). |
| 130 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this version became active in dbo.tblaff_AffiliateTypes. Set by SQL Server temporal mechanism. |
| 131 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this version was superseded. Set by SQL Server temporal mechanism. First key in clustered index. |
| 132 | CommissionByOpenPosition | bit | NO | - | CODE-BACKED | Whether commission is calculated based on open position events rather than closed position events. |
| 133 | IsTradeRequired | bit | NO | - | CODE-BACKED | Whether the referred customer must execute at least one trade before the affiliate earns commission. |
| 134 | BlockTrackingLinks | tinyint | NO | - | CODE-BACKED | Controls blocking of affiliate tracking links: 0 = allowed, higher values = various blocking modes. |
| 135 | BlockCreatives | tinyint | NO | - | CODE-BACKED | Controls blocking of affiliate creative/banner assets: 0 = allowed, higher values = various blocking modes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateTypeID | dbo.tblaff_AffiliateTypes | Temporal History | Stores historical versions of the base table |
| FatherAffiliateTypeID | dbo.tblaff_AffiliateTypes | Self-Reference (implicit) | Parent affiliate type in the type hierarchy |

### 5.2 Referenced By (other objects point to this)

This table is accessed implicitly via temporal queries (FOR SYSTEM_TIME) on dbo.tblaff_AffiliateTypes.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.tblaff_AffiliateTypes (table)
```

This table has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_AffiliateTypes | Table | SYSTEM_VERSIONING - SQL Server automatically moves superseded row versions here |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_tblaff_AffiliateTypes | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

### 7.2 Constraints

None. Data integrity enforced on the base table (dbo.tblaff_AffiliateTypes).

Note: Uses PAGE compression.

---

## 8. Sample Queries

### 8.1 View the complete change history for a specific affiliate type
```sql
SELECT AffiliateTypeID, Description, PerDeposit, PerSale, PerLead,
       PerDepositRate, PerSaleRate, ValidFrom, ValidTo
FROM dbo.tblaff_AffiliateTypes FOR SYSTEM_TIME ALL WITH (NOLOCK)
WHERE AffiliateTypeID = 4735
ORDER BY ValidFrom
```

### 8.2 Find what commission rates were active at a specific date
```sql
SELECT AffiliateTypeID, Description,
       PerDepositRate, PerSaleRate, PerLeadRate, MinimumPayout
FROM dbo.tblaff_AffiliateTypes FOR SYSTEM_TIME AS OF '2025-06-01T00:00:00' WITH (NOLOCK)
WHERE IsActive = 1
ORDER BY AffiliateTypeID
```

### 8.3 Identify recently changed affiliate types with the triggering procedure
```sql
SELECT AffiliateTypeID, Description,
       JSON_VALUE(Trace, '$.ObjectName') AS ChangedBy,
       ValidFrom, ValidTo
FROM History.tblaff_AffiliateTypes WITH (NOLOCK)
WHERE ValidTo > DATEADD(DAY, -30, GETUTCDATE())
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 135 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.tblaff_AffiliateTypes | Type: Table | Source: fiktivo/History/Tables/History.tblaff_AffiliateTypes.sql*
