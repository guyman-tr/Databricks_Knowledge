# AffiliateConfiguration.FirstPositionAssetPlanType

> Table-valued parameter type for bulk-inserting or replacing CPA first-position commission plan entries per asset type and country for an affiliate type.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateConfiguration |
| **Object Type** | User Defined Type |
| **Key Identifier** | TVP (Table-Valued Parameter) - no primary key |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateConfiguration.FirstPositionAssetPlanType is a table-valued parameter (TVP) that carries CPA (Cost Per Acquisition) first-position commission plan data from the application layer into SQL Server stored procedures. It defines the commission amounts affiliates earn when a referred customer opens their first trading position in a specific asset class, optionally segmented by country.

Without this TVP, the admin system would need to issue individual INSERT statements for each country/asset-type combination when creating or updating an affiliate type's CPA plan. The TVP enables atomic, set-based bulk operations - the entire CPA plan is passed as a single parameter and applied transactionally.

This TVP is consumed by [AffiliateAdmin.UpdateInsertAffiliateType](../../AffiliateAdmin/Stored Procedures/AffiliateAdmin.UpdateInsertAffiliateType.md) as the `@FirstPositionAssetPlan` parameter. The procedure validates that all CountryIDs exist in dbo.tblaff_Country and all PositionAssetTypeIDs exist in Dictionary.PositionAssetType, then performs a delete-and-reinsert into [AffiliateConfiguration.FirstPositionAssetPlan](../Tables/AffiliateConfiguration.FirstPositionAssetPlan.md). Changes are audit-logged with ChangedSectionID=12 (FirstPositionAssetPlan).

---

## 2. Business Logic

### 2.1 CPA First-Position Commission Configuration

**What**: Defines per-asset-type commission amounts that affiliates earn when referred customers open their first position in that asset class.

**Columns/Parameters Involved**: `CountryID`, `PositionAssetTypeID`, `MinimumCommission`, `CPAAmount`

**Rules**:
- CountryID=0 means "all countries" (global default rate)
- Country-specific entries override the global default
- PositionAssetTypeID=0 means "all asset types" (wildcard)
- MinimumCommission sets the revenue threshold the customer must generate before the CPA commission is paid
- CPAAmount is the flat commission paid to the affiliate once the threshold is met
- When MinimumCommission is NULL or 0, the CPA is paid immediately on first position open

**Diagram**:
```
Admin UI -> @FirstPositionAssetPlan TVP
              |
              v
  UpdateInsertAffiliateType
    1. Validate CountryIDs against tblaff_Country
    2. Validate PositionAssetTypeIDs against Dictionary.PositionAssetType
    3. DELETE existing plan for this AffiliateTypeID
    4. INSERT new rows from TVP into FirstPositionAssetPlan
    5. Audit log (SectionID=12)
```

---

## 3. Data Overview

N/A for User Defined Type. This is a parameter shape definition, not a persisted data store. See [AffiliateConfiguration.FirstPositionAssetPlan](../Tables/AffiliateConfiguration.FirstPositionAssetPlan.md) for live data examples.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CountryID | bigint | YES | - | CODE-BACKED | Target country for this CPA plan entry. NULL or 0 = applies to all countries (global default). Non-zero values must exist in [dbo.tblaff_Country](../../dbo/Tables/dbo.tblaff_Country.md). Validated by UpdateInsertAffiliateType against tblaff_Country before insertion. |
| 2 | PositionAssetTypeID | int | NO | - | CODE-BACKED | Asset class for which this CPA commission applies. References [Dictionary.PositionAssetType](../../Dictionary/Tables/Dictionary.PositionAssetType.md): 0=All, 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto, 11=Copy. See [Position Asset Type](../../_glossary.md#position-asset-type). Validated before insertion. |
| 3 | MinimumCommission | float | YES | - | CODE-BACKED | Revenue threshold the referred customer must generate trading this asset class before the CPA commission is paid to the affiliate. NULL or 0 = no threshold (CPA paid immediately on first position). Used in RevenuesPercentage calculation in TraderFirstAssetPosition. |
| 4 | CPAAmount | float | NO | - | CODE-BACKED | Flat CPA commission amount paid to the affiliate when the referred customer opens their first position in this asset class and meets the MinimumCommission threshold. Expressed in the platform's base currency (USD). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | dbo.tblaff_Country | Implicit | Country targeted by this CPA plan entry. Validated at runtime by consuming procedure |
| PositionAssetTypeID | Dictionary.PositionAssetType | Implicit | Asset class for commission segmentation. Validated at runtime by consuming procedure |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateAdmin.UpdateInsertAffiliateType | @FirstPositionAssetPlan | Parameter Type | TVP parameter carrying CPA plan entries for bulk insert into FirstPositionAssetPlan table |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. It is a type definition with no executable SQL.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateAdmin.UpdateInsertAffiliateType | Stored Procedure | Accepts this TVP as the @FirstPositionAssetPlan parameter for bulk CPA plan configuration |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None. Validation is performed by the consuming stored procedure (country and asset type existence checks).

---

## 8. Sample Queries

### 8.1 Declare and populate the TVP for a new CPA plan

```sql
DECLARE @plan AffiliateConfiguration.FirstPositionAssetPlanType;

INSERT INTO @plan (CountryID, PositionAssetTypeID, MinimumCommission, CPAAmount)
VALUES
  (0, 0, 10, 250),    -- Global default: all asset types, $250 CPA after $10 revenue
  (0, 10, 50, 500),   -- Global crypto: $500 CPA after $50 revenue
  (233, 5, 0, 100);   -- US stocks: $100 CPA, no minimum threshold

EXEC AffiliateAdmin.UpdateInsertAffiliateType
  @AffiliateTypeID = 0,  -- New type
  @FirstPositionAssetPlan = @plan,
  -- ... other parameters ...
```

### 8.2 Check what the TVP would look like from existing data

```sql
SELECT CountryID, PositionAssetTypeID, MinimumCommission, CPAAmount
FROM AffiliateConfiguration.FirstPositionAssetPlan WITH (NOLOCK)
WHERE AffiliateTypeID = 1932
ORDER BY CountryID, PositionAssetTypeID;
```

### 8.3 Validate TVP contents against lookup tables

```sql
DECLARE @plan AffiliateConfiguration.FirstPositionAssetPlanType;
-- (populate @plan)

-- Check for invalid countries
SELECT p.CountryID
FROM @plan p
LEFT JOIN dbo.tblaff_Country c WITH (NOLOCK) ON p.CountryID = c.CountryID
WHERE c.CountryID IS NULL AND p.CountryID <> 0;

-- Check for invalid asset types
SELECT p.PositionAssetTypeID
FROM @plan p
LEFT JOIN Dictionary.PositionAssetType a WITH (NOLOCK) ON p.PositionAssetTypeID = a.ID
WHERE a.ID IS NULL;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [CPA New Compensation Plan - DB design](https://etoro-jira.atlassian.net/wiki/x/PLACEHOLDER) | Confluence | FirstPositionAssetPlan tables created as part of CPA New Compensation Design (PART-2448). Defines the 3-table structure for first-position CPA commissions |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateConfiguration.FirstPositionAssetPlanType | Type: User Defined Type | Source: fiktivo/AffiliateConfiguration/User Defined Types/AffiliateConfiguration.FirstPositionAssetPlanType.sql*
