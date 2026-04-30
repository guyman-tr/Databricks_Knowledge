# AffiliateAdmin.GetMarketingRegion

> Returns all marketing regions from the Dictionary.MarketingRegion reference table for geographic targeting configuration.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | MarketingRegionID, Name |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** GetMarketingRegion retrieves the complete list of marketing regions from `Dictionary.MarketingRegion`, returning each region's identifier and name. Marketing regions represent geographic areas used for targeting and organizing marketing activities within the affiliate platform.

**WHY:** Marketing campaigns and affiliate programs often need to be segmented by geographic region. Administrators use marketing regions to configure regional targeting for banners, campaigns, and affiliate assignments. This procedure provides the reference data for region selection dropdowns throughout the admin interface. See Marketing Region glossary for the full list of marketing region values.

**HOW:** The procedure executes a simple SELECT of MarketingRegionID and Name from `Dictionary.MarketingRegion`. No filtering or parameterization is applied.

---

## 2. Business Logic

No complex business logic. This is a direct lookup against the Dictionary.MarketingRegion reference table. The result provides the standardized set of marketing regions used across the affiliate administration platform for geographic classification.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no input parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | *(no parameters)* | - | - | - | - | This procedure accepts no parameters |

**Result Set:** MarketingRegionID (INT), Name (NVARCHAR) from `Dictionary.MarketingRegion` (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `Dictionary.MarketingRegion` | Table | SELECT MarketingRegionID, Name |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Region selection dropdowns | Application | Populates marketing region options |
| Campaign targeting configuration | Application | Geographic targeting for marketing campaigns |

---

## 6. Dependencies

### 6.0 Chain
`GetMarketingRegion` -> `Dictionary.MarketingRegion`

### 6.1 Depends On
- `Dictionary.MarketingRegion` - Reference table for marketing region definitions. See Marketing Region glossary.

### 6.2 Depend On This
No known database dependencies. Called from application layer for UI population.

---

## 7. Technical Details

### 7.1 Indexes
N/A

### 7.2 Constraints
N/A

---

## 8. Sample Queries

```sql
-- 1. Get all marketing regions
EXEC AffiliateAdmin.GetMarketingRegion;
```

```sql
-- 2. Load regions for campaign targeting configuration
EXEC AffiliateAdmin.GetMarketingRegion;
-- Use MarketingRegionID for regional targeting assignment
```

```sql
-- 3. Verify marketing region data
EXEC AffiliateAdmin.GetMarketingRegion;
-- Compare with: SELECT COUNT(*) FROM Dictionary.MarketingRegion;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4670.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetMarketingRegion | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetMarketingRegion.sql*
