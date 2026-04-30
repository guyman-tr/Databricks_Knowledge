# dbo.qry_aff_AffiliateEmailsWithType

> Simple lookup view joining affiliates with their affiliate type description, providing a quick reference for affiliate email addresses with their program type classification.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base tables: dbo.tblaff_Affiliates + dbo.tblaff_AffiliateTypes |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.qry_aff_AffiliateEmailsWithType is a simple denormalization view that joins tblaff_Affiliates with tblaff_AffiliateTypes to provide affiliate email addresses alongside their program type description (e.g., "RevShare 25% (default)"). Used for email communication workflows where the affiliate type determines the message content or targeting criteria.

The RIGHT OUTER JOIN ensures all affiliates appear even if they have no assigned AffiliateTypeID.

---

## 2. Business Logic

No complex business logic. Simple JOIN for email + type lookups.

---

## 3. Data Overview

| Description | AffiliateID | Email | Meaning |
|---|---|---|---|
| RevShare 25% (default) | 13546 | aa@aa.aa | Affiliate on the default 25% revenue share plan. Test email address. |
| RevShare 25% (default) | 13547 | aa@aa.aa | Another affiliate on the same default plan. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Description | nvarchar | YES | - | VERIFIED | Affiliate type description from tblaff_AffiliateTypes. E.g., "RevShare 25% (default)". NULL if no type assigned. |
| 2 | AffiliateID | int | NO | - | VERIFIED | Affiliate identifier from tblaff_Affiliates. |
| 3 | Email | nvarchar(255) | YES | - | VERIFIED | Affiliate's email address from tblaff_Affiliates. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateID, Email | dbo.tblaff_Affiliates | Base table (RIGHT OUTER JOIN) | Affiliate data - all affiliates included |
| Description | dbo.tblaff_AffiliateTypes | Joined table | Affiliate type description via AffiliateTypeID |

### 5.2 Referenced By (other objects point to this)

No dependents found in SSDT.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.qry_aff_AffiliateEmailsWithType (view)
  +-- dbo.tblaff_Affiliates (table)
  +-- dbo.tblaff_AffiliateTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table | RIGHT OUTER JOIN - all affiliates |
| dbo.tblaff_AffiliateTypes | Table | JOIN for type description |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

N/A for view.

---

## 8. Sample Queries

### 8.1 Affiliate emails by type
```sql
SELECT Description, AffiliateID, Email
FROM dbo.qry_aff_AffiliateEmailsWithType WITH (NOLOCK)
WHERE Email IS NOT NULL AND Email <> ''
ORDER BY Description, AffiliateID
```

### 8.2 Count affiliates per type
```sql
SELECT Description, COUNT(*) AS AffiliateCount
FROM dbo.qry_aff_AffiliateEmailsWithType WITH (NOLOCK)
GROUP BY Description
ORDER BY AffiliateCount DESC
```

### 8.3 Affiliates without a type
```sql
SELECT AffiliateID, Email
FROM dbo.qry_aff_AffiliateEmailsWithType WITH (NOLOCK)
WHERE Description IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.qry_aff_AffiliateEmailsWithType | Type: View | Source: fiktivo/dbo/Views/dbo.qry_aff_AffiliateEmailsWithType.sql*
