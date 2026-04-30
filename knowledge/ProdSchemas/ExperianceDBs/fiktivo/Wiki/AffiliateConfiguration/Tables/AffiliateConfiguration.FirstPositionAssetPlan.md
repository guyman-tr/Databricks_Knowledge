# AffiliateConfiguration.FirstPositionAssetPlan

> Configuration table defining CPA (Cost Per Acquisition) commission amounts affiliates earn when referred customers open their first trading position, segmented by affiliate type, country, and asset class.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateConfiguration |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (1 clustered PK, 1 unique NC on AffiliateTypeID+CountryID+PositionAssetTypeID) |

---

## 1. Business Meaning

AffiliateConfiguration.FirstPositionAssetPlan is the central configuration table for first-position CPA commissions in the affiliate platform. Each row defines the CPA amount an affiliate earns when a customer they referred opens their first trading position in a specific asset class (Forex, Stocks, Crypto, etc.), optionally segmented by country. This enables the business to offer different CPA rates for high-value markets (e.g., higher CPA for US stock trades vs. global default).

Without this table, the platform could not implement asset-class-segmented CPA plans. The original CPA model was a flat per-affiliate-type rate; this table was created as part of the CPA New Compensation Design (PART-2448, Dec 2023) to allow granular, multi-dimensional CPA configuration. It works in conjunction with [AffiliateConfiguration.TraderFirstAssetPosition](AffiliateConfiguration.TraderFirstAssetPosition.md), which tracks actual customer first-position events and revenue progress toward MinimumCommission thresholds.

Plan entries are created and updated by admin users via [AffiliateAdmin.UpdateInsertAffiliateType](../../AffiliateAdmin/Stored Procedures/AffiliateAdmin.UpdateInsertAffiliateType.md) using the [FirstPositionAssetPlanType TVP](../User Defined Types/AffiliateConfiguration.FirstPositionAssetPlanType.md). The procedure performs a delete-and-reinsert pattern, replacing the entire plan atomically. The table is read by commission pipeline procedures (GetAffiliateTypeDataByAffiliateTypeId, GetCreditTriggeredEvents) to determine CPA eligibility and amounts. The table is system-versioned with history in History.FirstPositionAssetPlan for audit compliance.

---

## 2. Business Logic

### 2.1 Multi-Dimensional CPA Configuration

**What**: CPA rates are configurable along three dimensions: affiliate type, country, and asset class.

**Columns/Parameters Involved**: `AffiliateTypeID`, `CountryID`, `PositionAssetTypeID`, `CPAAmount`

**Rules**:
- CountryID=0 + PositionAssetTypeID=0 = global default for this affiliate type (applies to all countries, all asset classes)
- CountryID=0 + PositionAssetTypeID>0 = global rate for a specific asset class
- CountryID>0 + PositionAssetTypeID=0 = country-specific rate for all asset classes
- CountryID>0 + PositionAssetTypeID>0 = fully specific rate (e.g., France + Copy trading = $220)
- The unique index on (AffiliateTypeID, CountryID, PositionAssetTypeID) prevents duplicate entries

**Diagram**:
```
CPA Plan Resolution (most specific wins):
  AffiliateTypeID + CountryID + AssetTypeID
       |               |            |
       v               v            v
  [Affiliate Plan] x [Country] x [Asset Class]

Examples for AffiliateType 4770:
  (0, 0)     -> Global default (all countries, all assets)
  (0, 11)    -> Global Copy trading rate
  (74, 11)   -> France Copy trading = $220
  (101, 5)   -> Israel Stocks = $250
  (219, 5)   -> US Stocks = $250
```

### 2.2 Minimum Commission Threshold

**What**: Optionally requires referred customers to generate a minimum revenue before the CPA commission is paid.

**Columns/Parameters Involved**: `MinimumCommission`, `CPAAmount`

**Rules**:
- When MinimumCommission is NULL or 0: CPA is paid immediately upon first position open
- When MinimumCommission > 0: CPA is deferred until the customer generates sufficient trading revenue
- Revenue tracking happens in TraderFirstAssetPosition.TotalRevenue and its computed RevenuesPercentage column
- The RevenuesPercentage formula: `(TotalRevenue / MinimumCommission) * 100`, capped at 100%
- Once RevenuesPercentage reaches 100%, the CPA is eligible for payout

### 2.3 Atomic Plan Replacement

**What**: Plan updates follow a delete-and-reinsert pattern to ensure plan consistency.

**Columns/Parameters Involved**: All columns via TVP

**Rules**:
- UpdateInsertAffiliateType compares old and new plan states using STRING_AGG
- If the plan has changed: all existing rows for the AffiliateTypeID are deleted, then new rows are inserted from the TVP
- Country IDs are validated against tblaff_Country before insertion (RAISERROR on invalid)
- Asset type IDs are validated against Dictionary.PositionAssetType before insertion (RAISERROR on invalid)
- All changes are audit-logged with ChangedSectionID=12 (FirstPositionAssetPlan) in the AuditLog

---

## 3. Data Overview

| ID | AffiliateTypeID | CountryID | AssetType | MinimumCommission | CPAAmount | Meaning |
|---|---|---|---|---|---|---|
| 2 | 1932 | 0 (All) | 0 (All) | 0 | 700 | Global default for a test affiliate type: $700 CPA paid immediately on any first position, regardless of country or asset class |
| 5 | 16 | 0 (All) | 0 (All) | 10 | 250 | DCPA $250 plan: customer must generate $10 revenue before the $250 CPA is paid. Applies globally to all asset types |
| 9 | 21 | 0 (All) | 0 (All) | NULL | 200 | Default DCPA $200 plan: no minimum threshold, $200 CPA paid on first position. NULL MinimumCommission = immediate payout |
| 3874 | 4770 | 101 (Israel) | 5 (Stocks) | NULL | 250 | Country+asset-specific entry: $250 CPA for Israeli customers opening their first stock position. Highest specificity level |
| 3870 | 4770 | 74 (France) | 11 (Copy) | NULL | 220 | Country+asset-specific entry: $220 CPA for French customers whose first position is a CopyTrader position |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY | NO | - | CODE-BACKED | Surrogate primary key, auto-incremented. Not used as a business identifier - the unique business key is (AffiliateTypeID, CountryID, PositionAssetTypeID). |
| 2 | AffiliateTypeID | int | NO | - | CODE-BACKED | Commission plan template this CPA entry belongs to. Implicit FK to [dbo.tblaff_AffiliateTypes](../../dbo/Tables/dbo.tblaff_AffiliateTypes.md). Each affiliate type can have multiple CPA entries covering different country/asset combinations. Part of unique index UIX_FirstPositionAssetPlan. |
| 3 | CountryID | bigint | YES | - | CODE-BACKED | Target country for this CPA rate. Implicit FK to [dbo.tblaff_Country](../../dbo/Tables/dbo.tblaff_Country.md). 0 = all countries (global default). NULL treated as 0. Country-specific entries (CountryID>0) override the global default. Validated by UpdateInsertAffiliateType against tblaff_Country. Part of unique index. |
| 4 | PositionAssetTypeID | int | NO | - | VERIFIED | Asset class for this CPA rate. Implicit FK to [Dictionary.PositionAssetType](../../Dictionary/Tables/Dictionary.PositionAssetType.md): 0=All, 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto, 11=Copy. See [Position Asset Type](../../_glossary.md#position-asset-type). Validated by procedure. Part of unique index. |
| 5 | MinimumCommission | float | YES | - | CODE-BACKED | Revenue threshold the referred customer must generate in this asset class before the CPA commission is paid. NULL or 0 = no threshold (CPA paid immediately on first position). Feeds into TraderFirstAssetPosition.RevenuesPercentage calculation: (TotalRevenue/MinimumCommission)*100. |
| 6 | CPAAmount | float | NO | - | CODE-BACKED | Flat CPA commission paid to the affiliate once the customer opens their first position in this asset class (and meets MinimumCommission threshold if set). Expressed in the platform's base currency (USD). Live range: $0-$700. |
| 7 | DateModified | datetime | NO | - | CODE-BACKED | Timestamp of the last update to this plan entry (UTC). Set to GETUTCDATE() on insert by UpdateInsertAffiliateType. Used by GetCreditTriggeredEvents as MAX(DateModified) to determine commission eligibility recalculation timing. |
| 8 | Trace | computed | NO | - | CODE-BACKED | Computed audit column (not persisted). JSON string recording the connection context: HostName, AppName, SUserName, SPID, DBName, ObjectName. Formula: `CONCAT('{"HostName":"', HOST_NAME(), '","AppName":"', APP_NAME(), ...}')`. Enables tracing which application/user made the change. |
| 9 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | System-versioning period start. Automatically set by SQL Server temporal table mechanism. Marks when this row version became current. |
| 10 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | System-versioning period end. Automatically set when the row is updated or deleted. Default: 9999-12-31 (current version). Previous versions are moved to History.FirstPositionAssetPlan. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateTypeID | dbo.tblaff_AffiliateTypes | Implicit FK | Commission plan template this CPA entry belongs to. Validated by consuming procedures |
| CountryID | dbo.tblaff_Country | Implicit FK | Target country for geo-segmented CPA rates. 0=all countries |
| PositionAssetTypeID | Dictionary.PositionAssetType | Implicit FK | Asset class for asset-segmented CPA rates. 0=all assets |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateConfiguration.TraderFirstAssetPosition | Conceptual | Business Link | Tracks actual customer first positions and revenue against MinimumCommission thresholds defined here |
| AffiliateAdmin.UpdateInsertAffiliateType | Direct INSERT/DELETE | WRITER | Creates and replaces plan entries using FirstPositionAssetPlanType TVP |
| AffiliateAdmin.GetAffiliateTypeData | Direct SELECT | READER | Reads plan for admin UI display |
| AffiliateCommission.GetAffiliateTypeDataByAffiliateTypeId | Direct SELECT | READER | Reads plan for commission pipeline processing |
| AffiliateCommission.GetAffiliateTypeDataByAffiliateId | Direct SELECT | READER | Reads plan for commission pipeline processing by affiliate |
| AffiliateCommission.GetCreditTriggeredEvents | MAX(DateModified) | READER | Uses latest modification date as input to commission eligibility recalculation |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies. Tables are always leaf nodes.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateAdmin.UpdateInsertAffiliateType | Stored Procedure | WRITER - INSERT/DELETE plan entries |
| AffiliateAdmin.GetAffiliateTypeData | Stored Procedure | READER - displays plan in admin UI |
| AffiliateCommission.GetAffiliateTypeDataByAffiliateTypeId | Stored Procedure | READER - commission pipeline |
| AffiliateCommission.GetAffiliateTypeDataByAffiliateId | Stored Procedure | READER - commission pipeline |
| AffiliateCommission.GetCreditTriggeredEvents | Stored Procedure | READER - MAX(DateModified) for eligibility |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FirstPositionAsset_ID | CLUSTERED | ID ASC | - | - | Active |
| UIX_FirstPositionAssetPlan | UNIQUE NC | AffiliateTypeID ASC, CountryID ASC, PositionAssetTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_FirstPositionAsset_ID | PRIMARY KEY | Clustered on ID. Surrogate key for row identity |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.FirstPositionAssetPlan. Tracks all changes for audit compliance |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | (ValidFrom, ValidTo) - automatic versioning period |

---

## 8. Sample Queries

### 8.1 View the full CPA plan for a specific affiliate type with resolved names

```sql
SELECT fp.ID, fp.AffiliateTypeID, at.Description AS PlanName,
       fp.CountryID, CASE WHEN fp.CountryID = 0 THEN 'All Countries' ELSE c.Name END AS Country,
       fp.PositionAssetTypeID, pat.Name AS AssetType,
       fp.MinimumCommission, fp.CPAAmount, fp.DateModified
FROM AffiliateConfiguration.FirstPositionAssetPlan fp WITH (NOLOCK)
LEFT JOIN dbo.tblaff_AffiliateTypes at WITH (NOLOCK) ON fp.AffiliateTypeID = at.AffiliateTypeID
LEFT JOIN dbo.tblaff_Country c WITH (NOLOCK) ON fp.CountryID = c.CountryID
LEFT JOIN Dictionary.PositionAssetType pat WITH (NOLOCK) ON fp.PositionAssetTypeID = pat.ID
WHERE fp.AffiliateTypeID = 4770
ORDER BY fp.CountryID, fp.PositionAssetTypeID;
```

### 8.2 Find affiliate types with country-specific CPA rates

```sql
SELECT fp.AffiliateTypeID, at.Description, COUNT(DISTINCT fp.CountryID) AS Countries,
       COUNT(*) AS TotalEntries
FROM AffiliateConfiguration.FirstPositionAssetPlan fp WITH (NOLOCK)
INNER JOIN dbo.tblaff_AffiliateTypes at WITH (NOLOCK) ON fp.AffiliateTypeID = at.AffiliateTypeID
WHERE fp.CountryID > 0
GROUP BY fp.AffiliateTypeID, at.Description
ORDER BY Countries DESC;
```

### 8.3 View temporal history of plan changes for audit

```sql
SELECT ID, AffiliateTypeID, CountryID, PositionAssetTypeID,
       MinimumCommission, CPAAmount, DateModified, ValidFrom, ValidTo
FROM AffiliateConfiguration.FirstPositionAssetPlan
FOR SYSTEM_TIME ALL
WHERE AffiliateTypeID = 16
ORDER BY ValidFrom DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [CPA New Compensation Plan - DB design](https://etoro-jira.atlassian.net/wiki/x/PLACEHOLDER) | Confluence | Table created as part of CPA New Compensation Design. Three new tables: FirstPositionAssetPlan, TraderFirstAssetPosition, Dictionary.PositionAssetType. Asset class mapping from incoming events to PositionAssetType categories. Airdrop events are ignored. |

PART-2448 (Jira): CPA New Compensation Design - original creation ticket (Dec 2023).
PART-4262 (Jira): Referenced in UpdateInsertAffiliateType updates (Apr 2025).

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateConfiguration.FirstPositionAssetPlan | Type: Table | Source: fiktivo/AffiliateConfiguration/Tables/AffiliateConfiguration.FirstPositionAssetPlan.sql*
