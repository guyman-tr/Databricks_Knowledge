# KYP.AffiliateKYPMarketingMethods

> Junction table storing the marketing methods used by an affiliate entity, as declared during KYP (Know Your Partner) compliance verification.

| Property | Value |
|----------|-------|
| **Schema** | KYP |
| **Object Type** | Table |
| **Key Identifier** | AffiliateID + MarketingMethodID (composite PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

KYP.AffiliateKYPMarketingMethods records which marketing methods an affiliate uses to drive traffic. During KYP onboarding, affiliates must declare their primary marketing channels (PPC, SEO, Social Media, Email Marketing, Media Buying). This information is used by the compliance and partnerships teams to understand the affiliate's business model and assess marketing risk.

Without this table, the platform would not know how each affiliate generates traffic. This is important for compliance (certain marketing methods may be restricted in specific jurisdictions) and for the partnerships team to provide appropriate marketing support and monitor for policy violations.

Rows are managed by `KYP.UpdateAffiliateData` using a MERGE statement on @MarketingMethodIDs. `KYP.GetAffiliateData` reads the method list. Temporal versioning tracks changes over time.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple many-to-many junction table managed via MERGE.

---

## 3. Data Overview

N/A - 116 rows. Junction table with only FK IDs. Would show (AffiliateID, MarketingMethodID) pairs.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateID | int | NO | - | CODE-BACKED | FK to KYP.Affiliate. Part of composite PK. |
| 2 | MarketingMethodID | int | NO | - | VERIFIED | FK to Dictionary.KYPMarketingMethod: 1=PPC, 2=SEO, 3=Social Media, 4=Email Marketing, 5=Media Buying. See [KYP Marketing Method](../../_glossary.md#kyp-marketing-method). Part of composite PK. |
| 3 | Trace | computed | NO | - | CODE-BACKED | Computed audit column. Inherited pattern from KYP.Affiliate. |
| 4 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | Temporal versioning row start. |
| 5 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | Temporal versioning row end. History in History.KYPAffiliateKYPMarketingMethods. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateID | KYP.Affiliate | FK | Parent affiliate's KYP record |
| MarketingMethodID | Dictionary.KYPMarketingMethod | FK | Marketing method classification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYP.GetAffiliateData | AffiliateID | SELECT (READER) | Reads marketing methods for affiliate |
| KYP.UpdateAffiliateData | AffiliateID, MarketingMethodID | MERGE (WRITER) | Synchronizes methods via MERGE |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYP.AffiliateKYPMarketingMethods (table)
├── KYP.Affiliate (table)
└── Dictionary.KYPMarketingMethod (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYP.Affiliate | Table | FK on AffiliateID |
| Dictionary.KYPMarketingMethod | Table (cross-schema) | FK on MarketingMethodID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYP.GetAffiliateData | SP | SELECT reader |
| KYP.UpdateAffiliateData | SP | MERGE writer |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_KYP_AffiliateKYPMarketingMethod | CLUSTERED PK | AffiliateID ASC, MarketingMethodID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_KYP_AffiliateKYPMarketingMethod | PRIMARY KEY | Composite (AffiliateID, MarketingMethodID) |
| FK_KYP_AffiliateKYPMarketingMethods_AffiliateID | FOREIGN KEY | AffiliateID -> KYP.Affiliate(AffiliateID) |
| FK_KYP_AffiliateKYPMarketingMethods_KYPMarketingMethodID | FOREIGN KEY | MarketingMethodID -> Dictionary.KYPMarketingMethod(MarketingMethodID) |

Temporal: SYSTEM_VERSIONING ON with History.KYPAffiliateKYPMarketingMethods.

---

## 8. Sample Queries

### 8.1 Get marketing methods for an affiliate
```sql
SELECT mm.MarketingMethodID, m.Name AS MethodName
FROM KYP.AffiliateKYPMarketingMethods mm WITH (NOLOCK)
JOIN Dictionary.KYPMarketingMethod m WITH (NOLOCK) ON mm.MarketingMethodID = m.MarketingMethodID
WHERE mm.AffiliateID = 60062
```

### 8.2 Most popular marketing methods
```sql
SELECT m.Name, COUNT(*) AS AffiliateCount
FROM KYP.AffiliateKYPMarketingMethods mm WITH (NOLOCK)
JOIN Dictionary.KYPMarketingMethod m WITH (NOLOCK) ON mm.MarketingMethodID = m.MarketingMethodID
GROUP BY m.Name
ORDER BY COUNT(*) DESC
```

### 8.3 Affiliates using a specific method
```sql
SELECT mm.AffiliateID, a.KYPStatusID
FROM KYP.AffiliateKYPMarketingMethods mm WITH (NOLOCK)
JOIN KYP.Affiliate a WITH (NOLOCK) ON mm.AffiliateID = a.AffiliateID
WHERE mm.MarketingMethodID = 1 -- PPC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 9.0/10, Logic: 2.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: KYP.AffiliateKYPMarketingMethods | Type: Table | Source: fiktivo/KYP/Tables/KYP.AffiliateKYPMarketingMethods.sql*
