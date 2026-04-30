# AffiliateAdmin.GetAffiliatesAndBlockedCountries

> Retrieves the list of blocked countries for a specific affiliate from the Affiliate.BlockedCountries table.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns AffiliateID + CountryID rows from BlockedCountries |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateAdmin.GetAffiliatesAndBlockedCountries retrieves the list of countries that are blocked for a given affiliate. Blocked countries represent geographic restrictions where the affiliate is not permitted to operate, drive traffic, or earn commissions. This is a regulatory and compliance mechanism that ensures affiliates only promote services in jurisdictions where the business is licensed to operate.

This procedure exists because the affiliate detail/edit screen in the admin portal needs to display and manage the list of blocked countries for each affiliate. Country blocking is a critical compliance feature that varies per affiliate based on their license, geographic focus, and regulatory requirements.

Data flow: The procedure accepts an optional @AffiliateID parameter and queries Affiliate.BlockedCountries to return all AffiliateID and CountryID pairs for the specified affiliate. When @AffiliateID is NULL, the behavior may return blocked countries for all affiliates, supporting batch reporting scenarios.

---

## 2. Business Logic

### 2.1 Optional Affiliate Filtering

The @AffiliateID parameter defaults to NULL. When a specific ID is provided, only blocked countries for that affiliate are returned. When NULL, the procedure may return blocked country records across all affiliates, enabling administrative reporting on geographic restrictions.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | int | YES | NULL | CODE-BACKED | Affiliate to retrieve blocked countries for. NULL may return all affiliates' blocked countries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | Affiliate.BlockedCountries | Read | Reads blocked country assignments for the specified affiliate |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateAdmin.GetAffiliatesAndBlockedCountries (procedure)
+-- Affiliate.BlockedCountries (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Affiliate.BlockedCountries | Table | SELECT for AffiliateID and CountryID pairs |

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

### 8.1 Get blocked countries for a specific affiliate
```sql
EXEC AffiliateAdmin.GetAffiliatesAndBlockedCountries @AffiliateID = 1001;
-- Returns: AffiliateID, CountryID for each blocked country
```

### 8.2 Get all blocked country assignments
```sql
EXEC AffiliateAdmin.GetAffiliatesAndBlockedCountries @AffiliateID = NULL;
-- Returns: all AffiliateID + CountryID blocked pairs across all affiliates
```

### 8.3 Manually query blocked countries with country names
```sql
SELECT bc.AffiliateID, bc.CountryID, c.CountryName
FROM Affiliate.BlockedCountries bc WITH (NOLOCK)
JOIN dbo.tblaff_Country c WITH (NOLOCK) ON c.CountryID = bc.CountryID
WHERE bc.AffiliateID = 1001
ORDER BY c.CountryName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. DDL references PART-2714.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 3.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetAffiliatesAndBlockedCountries | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetAffiliatesAndBlockedCountries.sql*
