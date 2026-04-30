# AffiliateAdmin.UpdateRegistrationRateCountry

> Replaces country-specific registration commission rates for an affiliate type using a DELETE-then-INSERT pattern on tblaff_Registration2Country.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Rows affected in tblaff_Registration2Country |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** UpdateRegistrationRateCountry replaces the complete set of country-specific registration commission rates for a given affiliate type. It deletes all existing country rate mappings for the specified AffiliateTypeID from `tblaff_Registration2Country` and inserts the new set of rates provided via the @RegistrationRateCountry table-valued parameter of type `AffiliateConfiguration.RegistrationCountryRateType`.

**WHY:** Different countries may warrant different registration commission rates based on market value, regulatory requirements, or strategic priorities. For example, registrations from high-value markets might earn higher commissions than those from emerging markets. This country-level rate configuration enables fine-grained control over affiliate compensation at the geographic level. The full-replacement pattern ensures consistency -- the entire rate schedule is saved as a unit.

**HOW:** The procedure performs a DELETE of all existing rows in `tblaff_Registration2Country` where AffiliateTypeID matches the input parameter. It then INSERTs new rows from the @RegistrationRateCountry TVP, which contains (CountryID, Rate) pairs to be associated with the given AffiliateTypeID. This DELETE-then-INSERT pattern is simpler than MERGE for rate schedules where the entire set is always provided by the application.

---

## 2. Business Logic

### 2.1 Full Replacement Pattern
The procedure uses DELETE-then-INSERT rather than MERGE. This means the complete set of country rates must be provided each time, even if only one rate is changing. This simplifies the logic and matches the UI behavior where the entire rate grid is submitted as a unit.

### 2.2 Country-Rate Mapping
Each row in the TVP represents a (CountryID, Rate) pair. The Rate value defines the registration commission amount for that specific country when an affiliate of this type generates a registration.

### 2.3 Custom Table Type
The @RegistrationRateCountry parameter uses `AffiliateConfiguration.RegistrationCountryRateType`, a custom table type designed specifically for this procedure. This type carries the country ID and rate value needed for the mapping.

### 2.4 No Audit Logging
This procedure does not perform explicit audit logging. Country rate changes are typically logged at the parent level by `UpdateInsertAffiliateType`, which calls this procedure as part of the affiliate type save operation.

### 2.5 Empty Rate Set Support
If @RegistrationRateCountry is empty, the procedure effectively removes all country-specific rates for the affiliate type, reverting to the default registration rate defined on the affiliate type itself.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateTypeID | INT | No | - | CODE-BACKED | The affiliate type whose country rates are being replaced |
| 2 | @RegistrationRateCountry | AffiliateConfiguration.RegistrationCountryRateType READONLY | No | - | CODE-BACKED | TVP containing (CountryID, Rate) pairs for country-specific registration rates |

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `dbo.tblaff_Registration2Country` | Table | DELETE existing + INSERT new country rate mappings |
| `AffiliateConfiguration.RegistrationCountryRateType` | User-Defined Table Type | Input parameter type for country rate pairs |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| `AffiliateAdmin.UpdateInsertAffiliateType` | Stored Procedure | Called to set country rates after upserting type |
| Affiliate type configuration screen | Application | Country-specific rate grid save |

---

## 6. Dependencies

### 6.0 Chain
`UpdateRegistrationRateCountry` -> DELETE `tblaff_Registration2Country` (for AffiliateTypeID) -> INSERT from @RegistrationRateCountry

### 6.1 Depends On
- `dbo.tblaff_Registration2Country` - Target table for country-specific registration rates
- `AffiliateConfiguration.RegistrationCountryRateType` - User-defined table type for country rate input

### 6.2 Depend On This
Called by `AffiliateAdmin.UpdateInsertAffiliateType` as part of the composite affiliate type save operation.

---

## 7. Technical Details

### 7.1 Indexes
N/A

### 7.2 Constraints
N/A

---

## 8. Sample Queries

```sql
-- 1. Set country-specific registration rates for affiliate type 5
DECLARE @Rates AffiliateConfiguration.RegistrationCountryRateType;
INSERT INTO @Rates (CountryID, Rate) VALUES
    (1, 50.00),   -- US: $50 per registration
    (2, 40.00),   -- UK: $40 per registration
    (3, 30.00);   -- DE: $30 per registration
EXEC AffiliateAdmin.UpdateRegistrationRateCountry
    @AffiliateTypeID = 5,
    @RegistrationRateCountry = @Rates;
```

```sql
-- 2. Remove all country-specific rates (revert to default)
DECLARE @EmptyRates AffiliateConfiguration.RegistrationCountryRateType;
EXEC AffiliateAdmin.UpdateRegistrationRateCountry
    @AffiliateTypeID = 5,
    @RegistrationRateCountry = @EmptyRates;
```

```sql
-- 3. Update rates and verify the result
DECLARE @Rates AffiliateConfiguration.RegistrationCountryRateType;
INSERT INTO @Rates (CountryID, Rate) VALUES (1, 55.00), (2, 45.00);
EXEC AffiliateAdmin.UpdateRegistrationRateCountry
    @AffiliateTypeID = 3,
    @RegistrationRateCountry = @Rates;
-- Verify:
SELECT * FROM dbo.tblaff_Registration2Country WHERE AffiliateTypeID = 3;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL references: PART-4262, PART-2448.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.UpdateRegistrationRateCountry | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.UpdateRegistrationRateCountry.sql*
