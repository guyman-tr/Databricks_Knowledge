# Dictionary.Label

> Reference table defining white-label brand configurations for the eToro multi-brand platform architecture.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | LabelID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.Label defines the white-label brand identities available on the eToro platform. Each label represents a distinct brand with its own URL, logo, and cashier (payment page) branding. This supports eToro's multi-brand architecture where the same platform technology serves multiple brand identities, including the main eToro brand and various partner/regional brands.

This table exists to decouple brand presentation from platform functionality. Each user is assigned a LabelID at registration that determines which brand experience they see - logo, URLs, payment pages, and potentially different terms of service. Historical partner brands (RetailFX, JCLyons, ICMarkets, etc.) demonstrate the platform's white-label heritage.

LabelID is assigned during user registration based on the registration URL, referral source, or regulatory entity. It is stored on the user record and referenced throughout the platform for brand-specific rendering. Most active users today have LabelID 0 or 1 (both eToro).

---

## 2. Business Logic

### 2.1 Multi-Brand Architecture

**What**: White-label platform serving multiple brand identities from a single codebase.

**Columns/Parameters Involved**: `LabelID`, `Name`, `URL`, `CashierLogoURL`

**Rules**:
- LabelID 0 and 1 are both "eToro" (legacy duplication from early platform architecture)
- LabelID 14 is eToroUSA (separate US brand)
- Many labels (10-26) are historical partner brands, some likely inactive
- CashierLogoURL points to CDN-hosted brand logos for payment pages
- URL is the primary web address for the brand

---

## 3. Data Overview

| LabelID | Name | Meaning |
|---|---|---|
| 0 | eToro | Primary eToro brand (original label ID) |
| 1 | eToro | Primary eToro brand (duplicate - legacy from platform migration) |
| 2 | RetailFX | Historical RetailFX partner brand - eToro's original B2B white-label product |
| 14 | eToroUSA | US-specific brand for FinCEN/FINRA-regulated US operations |
| 27 | eToro-Partners | Partner/affiliate management label |

*5 of 25 rows shown - selected to represent major brand categories.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LabelID | int | NO | - | CODE-BACKED | Primary key. Brand identifier assigned to users at registration. 0/1=eToro (main), 2=RetailFX, 14=eToroUSA, others=partner brands. See [Label](_glossary.md#label). |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Brand display name. Multiple LabelIDs may share the same Name (e.g., 0 and 1 are both "eToro"). |
| 3 | URL | varchar(300) | YES | - | CODE-BACKED | Primary website URL for the brand. NULL for internal/deprecated brands. |
| 4 | CashierLogoURL | varchar(300) | YES | - | CODE-BACKED | CDN URL for the brand logo displayed on payment/cashier pages. NULL for brands without custom payment pages. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer user tables | LabelID | Lookup | Stores the brand identity for each user |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Label | CLUSTERED PK | LabelID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all labels with URLs
```sql
SELECT LabelID, Name, URL, CashierLogoURL
FROM Dictionary.Label WITH (NOLOCK)
ORDER BY LabelID
```

### 8.2 Find users by brand
```sql
SELECT l.Name AS Brand, COUNT(*) AS UserCount
FROM Customer.Users u WITH (NOLOCK)
JOIN Dictionary.Label l WITH (NOLOCK) ON u.LabelID = l.LabelID
GROUP BY l.Name
ORDER BY UserCount DESC
```

### 8.3 Get brand details for a user
```sql
SELECT u.CustomerID, l.Name AS Brand, l.URL, l.CashierLogoURL
FROM Customer.Users u WITH (NOLOCK)
JOIN Dictionary.Label l WITH (NOLOCK) ON u.LabelID = l.LabelID
WHERE u.CustomerID = @CustomerID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Label | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.Label.sql*
