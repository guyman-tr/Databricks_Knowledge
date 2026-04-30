# dbo.GetAffiliateById

> Returns full affiliate profile details joined to affiliate type and group information by integer AffiliateID, plus a second result set of blocked countries for that affiliate.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | AffiliateID (integer primary key lookup) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the standard affiliate profile lookup by numeric ID. It is the most commonly called affiliate fetch operation in the platform, used by any component that already holds an AffiliateID and needs to hydrate the full affiliate object (profile, commission plan, group, manager). It returns the same rich field set as GetAffiliateByAzureObjectId but is keyed on the internal integer ID rather than the Azure AD GUID. A second result set returns the list of blocked country IDs for the affiliate, consumed by the application for market restrictions. The procedure shares the same evolutionary history as GetAffiliateByAzureObjectId (PART-5531, PART-3422, PART-3147, PART-2028, ONBRD-5948).

---

## 2. Business Logic

- Two result sets returned in sequence:
  1. Full affiliate profile: LEFT JOINs tblaff_AffiliateTypes, AffiliateAdmin.AffiliatesGroups, AffiliateAdmin.Users. WebSiteURL assembled via STRING_AGG from Affiliate.tblaff_AffiliateURLs.
  2. Blocked countries: SELECT CountryID FROM Affiliate.BlockedCountries WHERE AffiliateID = @Id.
- All joins use NOLOCK for read performance.
- AffiliateAdmin.AffiliatesGroups join uses the new schema introduced in PART-5531 (Feb 2026).
- PART-3147 (Jul 2024): WHERE clause was modified to fetch any exact AffiliateID (no range condition).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @Id | INT | IN | (required) | High | Integer primary key of the affiliate to retrieve |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT (primary) | dbo.tblaff_Affiliates | Read | Core affiliate record |
| LEFT JOIN | dbo.tblaff_AffiliateTypes | Read | Commission plan and type flags |
| LEFT JOIN | AffiliateAdmin.AffiliatesGroups | Read | Group name and manager user ID |
| LEFT JOIN | AffiliateAdmin.Users | Read | Manager name and email |
| Subquery | Affiliate.tblaff_AffiliateURLs | Read | Concatenated website URLs |
| SELECT (secondary) | Affiliate.BlockedCountries | Read | Countries blocked for this affiliate |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAffiliateById
  ├── dbo.tblaff_Affiliates              (READ)
  ├── dbo.tblaff_AffiliateTypes          (READ)
  ├── AffiliateAdmin.AffiliatesGroups    (READ)
  ├── AffiliateAdmin.Users               (READ)
  ├── Affiliate.tblaff_AffiliateURLs     (READ)
  └── Affiliate.BlockedCountries         (READ)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.tblaff_Affiliates | Table | Primary affiliate record |
| dbo.tblaff_AffiliateTypes | Table | Commission plan details |
| AffiliateAdmin.AffiliatesGroups | Table | Affiliate group name and manager |
| AffiliateAdmin.Users | Table | Manager user profile |
| Affiliate.tblaff_AffiliateURLs | Table | Affiliate website URLs |
| Affiliate.BlockedCountries | Table | Country block list per affiliate |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes
N/A for stored procedure.

### 7.2 Constraints
N/A for stored procedure.

---

## 8. Sample Queries

```sql
-- Retrieve a specific affiliate by ID
EXEC dbo.GetAffiliateById @Id = 12345;

-- Retrieve the root/admin affiliate
EXEC dbo.GetAffiliateById @Id = 1;

-- Check blocked countries for a given affiliate (second result set)
EXEC dbo.GetAffiliateById @Id = 56663;
-- Second result set: SELECT CountryID FROM Affiliate.BlockedCountries WHERE AffiliateID = 56663
```

---

## 9. Atlassian Knowledge Sources

- PART-5531 - Gil Haba, 08/02/2026: Migrated to new AffiliateAdmin.AffiliatesGroups table.
- PART-3422 - Gil Haba, 14/10/2024: Renamed AccountActivated to AccountStatus.
- PART-3147 - Gil Haba, 06/07/2024: WHERE clause modified to fetch any exact AffiliateID.
- PART-2714 - Gil Haba, 01/05/2024: Add fetch of CountryID before return.
- PART-2028 - Noga Rozen, 11/09/2023: Use AffiliateURLs from dedicated table.
- ONBRD-5948 - Gil Haba / Noga Rozen, 06/03/2022: Add promoted countries to Affiliate registration.

---

*Generated: 2026-04-12 | Quality: 8.4/10*
*Object: dbo.GetAffiliateById | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetAffiliateById.sql*
