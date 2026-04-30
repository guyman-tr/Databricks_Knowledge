# dbo.GetAffiliateByAzureObjectId

> Returns full affiliate profile details joined to affiliate type and group information by Azure Active Directory object ID, plus a second result set of blocked countries for that affiliate.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | AzureObjectId (Azure AD identity lookup) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the primary SSO-based affiliate lookup. When a user authenticates via Azure Active Directory, the application resolves the affiliate record by matching the AzureObjectId field rather than a username or password. It returns the complete affiliate profile (contact details, commission plan, group membership, manager info) in one query, followed by a second result set containing the list of country IDs that are blocked for this affiliate. The blocked countries list is consumed by the application to restrict certain features or markets. The procedure was incrementally updated through multiple PART tickets (PART-5531, PART-3422, PART-3147, PART-2028, ONBRD-5948) reflecting the evolution of affiliate data models.

---

## 2. Business Logic

- Two result sets are returned in sequence:
  1. Full affiliate profile: LEFT JOINs tblaff_AffiliateTypes, AffiliateAdmin.AffiliatesGroups, and AffiliateAdmin.Users to enrich the affiliate row. WebSiteURL is assembled from Affiliate.tblaff_AffiliateURLs using STRING_AGG ordered by WebSiteURLOrdID.
  2. Blocked countries: a simple join between Affiliate.BlockedCountries and tblaff_Affiliates filtered to the same AzureObjectId.
- All joins use NOLOCK to avoid blocking reads.
- AffiliatesGroups lookup was migrated from the old tblaff_AffiliatesGroups to the new AffiliateAdmin.AffiliatesGroups table (PART-5531, Feb 2026).
- AccountStatus column was renamed from AccountActivated (PART-3422, Oct 2024).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @AzureObjectId | UNIQUEIDENTIFIER | IN | (required) | High | Azure AD object GUID used to identify the affiliate |

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
dbo.GetAffiliateByAzureObjectId
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
-- Look up affiliate by Azure AD object ID (SSO login flow)
EXEC dbo.GetAffiliateByAzureObjectId
    @AzureObjectId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

-- Retrieve blocked countries only (second result set)
-- Callers typically consume both result sets; to inspect manually:
EXEC dbo.GetAffiliateByAzureObjectId
    @AzureObjectId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
-- Second result set contains CountryID rows from Affiliate.BlockedCountries

-- Lookup with a known test affiliate Azure ID
EXEC dbo.GetAffiliateByAzureObjectId
    @AzureObjectId = '00000000-0000-0000-0000-000000000001';
```

---

## 9. Atlassian Knowledge Sources

- PART-5531 - Gil Haba, 08/02/2026: Migrated to new AffiliateAdmin.AffiliatesGroups table.
- PART-3422 - Gil Haba, 14/10/2024: Renamed AccountActivated to AccountStatus.
- PART-3147 - Gil Haba, 06/07/2024: Added select from Affiliate.BlockedCountries.
- PART-2028 - Noga Rozen, 11/09/2023: Write Affiliate URLs to dedicated table.
- ONBRD-5948 - Gil Haba / Noga Rozen, 06/03/2022: Add promoted countries to Affiliate registration.

---

*Generated: 2026-04-12 | Quality: 8.4/10*
*Object: dbo.GetAffiliateByAzureObjectId | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetAffiliateByAzureObjectId.sql*
