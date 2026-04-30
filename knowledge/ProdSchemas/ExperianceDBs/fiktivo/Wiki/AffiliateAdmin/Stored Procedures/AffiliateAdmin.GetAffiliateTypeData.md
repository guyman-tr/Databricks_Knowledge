# AffiliateAdmin.GetAffiliateTypeData

> Retrieves full configuration details for a single affiliate type, including commission rates, categories, country-based registration rates, and multiple plan configurations across six result sets.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 6 result sets: type details, categories, registration rates by country, first position plans, IOB plans, ISA plans |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateAdmin.GetAffiliateTypeData is a comprehensive detail-retrieval procedure that returns the full configuration profile of a single affiliate type. Affiliate types define the commission structure, allowed categories, geographic registration rates, and associated plan configurations that govern how affiliates of that type earn revenue and interact with the platform.

This procedure exists because the affiliate type edit/view screen in the admin portal needs to load all configuration dimensions for a given type in a single database call. Rather than making six separate API requests, the procedure bundles all related data into six result sets, reducing round-trip overhead and ensuring data consistency within a single transaction snapshot.

Data flow: The procedure accepts a single @AffiliateTypeID and queries six different tables/areas: (1) core type details from tblaff_AffiliateTypes including commission percentages, (2) associated categories from tblaff_AffiliateTypeCategories, (3) country-specific registration rates from tblaff_Registration2Country, (4) first position asset plan configuration from AffiliateConfiguration.FirstPositionAssetPlan, (5) IOB (Introducing Broker) plan configuration from AffiliateConfiguration.IOBPlan, and (6) ISA (Investment Service Agreement) plan configuration from AffiliateConfiguration.ISAPlan.

---

## 2. Business Logic

### 2.1 Multi-Result-Set Pattern

The procedure returns six distinct result sets in a fixed order. The consuming application must read them sequentially: type details first, then categories, then country rates, then three plan types. This pattern requires the client to use a DataReader or equivalent that advances through result sets.

### 2.2 Commission Rate Structure

Result set 1 returns the affiliate type's commission configuration from tblaff_AffiliateTypes, which defines the revenue-sharing percentages and fee structures that apply to all affiliates classified under this type.

### 2.3 Category Associations

Result set 2 returns the category mappings from tblaff_AffiliateTypeCategories, which control what product or service categories affiliates of this type are permitted to promote.

### 2.4 Country-Based Registration Rates

Result set 3 from tblaff_Registration2Country provides per-country registration rate overrides. This allows the business to offer different compensation rates based on the geographic origin of referred customers.

### 2.5 Plan Configurations

Result sets 4-6 return plan configurations from the AffiliateConfiguration schema: FirstPositionAssetPlan defines asset-based first-position fee structures, IOBPlan defines introducing broker commission plans, and ISAPlan defines investment service agreement fee schedules. These plans are linked to the affiliate type and define the financial terms for different business models.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateTypeID | int | NO | - | CODE-BACKED | Unique identifier of the affiliate type to retrieve full configuration for. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.tblaff_AffiliateTypes | Read | Result set 1: core type details and commission rates |
| SELECT | dbo.tblaff_AffiliateTypeCategories | Read | Result set 2: category associations for the type |
| SELECT | dbo.tblaff_Registration2Country | Read | Result set 3: per-country registration rate overrides |
| SELECT | AffiliateConfiguration.FirstPositionAssetPlan | Read | Result set 4: first position asset plan configuration |
| SELECT | AffiliateConfiguration.IOBPlan | Read | Result set 5: IOB (Introducing Broker) plan configuration |
| SELECT | AffiliateConfiguration.ISAPlan | Read | Result set 6: ISA (Investment Service Agreement) plan configuration |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateAdmin.GetAffiliateTypeData (procedure)
+-- dbo.tblaff_AffiliateTypes (table)
+-- dbo.tblaff_AffiliateTypeCategories (table)
+-- dbo.tblaff_Registration2Country (table)
+-- AffiliateConfiguration.FirstPositionAssetPlan (table)
+-- AffiliateConfiguration.IOBPlan (table)
+-- AffiliateConfiguration.ISAPlan (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_AffiliateTypes | Table | SELECT for core type details and commission rates |
| dbo.tblaff_AffiliateTypeCategories | Table | SELECT for category associations |
| dbo.tblaff_Registration2Country | Table | SELECT for country-based registration rates |
| AffiliateConfiguration.FirstPositionAssetPlan | Table | SELECT for first position asset plan |
| AffiliateConfiguration.IOBPlan | Table | SELECT for IOB plan |
| AffiliateConfiguration.ISAPlan | Table | SELECT for ISA plan |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get full affiliate type configuration
```sql
EXEC AffiliateAdmin.GetAffiliateTypeData @AffiliateTypeID = 3;
-- Result 1: Type details (AffiliateTypeID, Description, commission fields, IsActive, etc.)
-- Result 2: Category associations (AffiliateTypeID, CategoryID)
-- Result 3: Country registration rates (CountryID, Rate)
-- Result 4: First position asset plans
-- Result 5: IOB plans
-- Result 6: ISA plans
```

### 8.2 Manually query type details with category count
```sql
SELECT at.AffiliateTypeID, at.Description, at.IsActive,
       COUNT(atc.CategoryID) AS CategoryCount
FROM dbo.tblaff_AffiliateTypes at WITH (NOLOCK)
LEFT JOIN dbo.tblaff_AffiliateTypeCategories atc WITH (NOLOCK) ON atc.AffiliateTypeID = at.AffiliateTypeID
WHERE at.AffiliateTypeID = 3
GROUP BY at.AffiliateTypeID, at.Description, at.IsActive;
```

### 8.3 Check country registration rates for a type
```sql
SELECT r.CountryID, c.CountryName, r.Rate
FROM dbo.tblaff_Registration2Country r WITH (NOLOCK)
JOIN dbo.tblaff_Country c WITH (NOLOCK) ON c.CountryID = r.CountryID
WHERE r.AffiliateTypeID = 3
ORDER BY c.CountryName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. DDL references PART-4763, PART-4262, PART-2448, PART-5461.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 8.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetAffiliateTypeData | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetAffiliateTypeData.sql*
