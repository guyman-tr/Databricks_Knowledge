# Dictionary.Attribute

> Lookup table defining user interest and activity attributes used for segmentation, marketing, and onboarding funnel tracking.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | AttributeID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.Attribute defines product-category attributes that describe a user's trading interests or activity areas on the eToro platform. These attributes are used to segment users based on which product categories they have shown interest in or engaged with during the onboarding funnel and beyond.

This table supports marketing segmentation and personalized onboarding flows. By tracking which attributes a user has (e.g., interested in Stocks, Crypto, Copy Trading), the platform can tailor content, recommendations, and promotional communications. It also enables funnel analytics to understand which product categories drive user acquisition.

Attributes are assigned to users during the registration funnel based on their selections (e.g., "What are you interested in trading?"). They are grouped by Dictionary.AttributeGroup which defines the context of collection (currently only "Funnel").

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| AttributeID | Name | Meaning |
|---|---|---|
| 1 | Stocks | User expressed interest in or has activity in stock/equity trading |
| 2 | Crypto | User expressed interest in or has activity in cryptocurrency trading |
| 3 | Copy Trader | User expressed interest in copy trading - following and automatically replicating other traders' positions |
| 4 | Copy Portfolio | User expressed interest in thematic investment portfolios (Smart Portfolios) managed by eToro |
| 5 | CFD | User expressed interest in Contract for Difference trading (leveraged derivatives) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AttributeID | int | NO | - | CODE-BACKED | Primary key. Product category identifier: 1=Stocks, 2=Crypto, 3=Copy Trader, 4=Copy Portfolio, 5=CFD. See [Attribute](_glossary.md#attribute). |
| 2 | Name | varchar(30) | YES | - | CODE-BACKED | Display name of the product category attribute. Used in UI and analytics reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer user-attribute mapping tables | AttributeID | Lookup | Links users to their product interest attributes |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema. Referenced by Customer schema attribute mapping tables.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryAttribute | CLUSTERED PK | AttributeID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all attributes
```sql
SELECT AttributeID, Name
FROM Dictionary.Attribute WITH (NOLOCK)
ORDER BY AttributeID
```

### 8.2 Find users interested in crypto
```sql
SELECT ua.CustomerID
FROM Customer.UserAttributes ua WITH (NOLOCK)
JOIN Dictionary.Attribute a WITH (NOLOCK) ON ua.AttributeID = a.AttributeID
WHERE a.Name = 'Crypto'
```

### 8.3 Attribute distribution across users
```sql
SELECT a.Name, COUNT(*) AS UserCount
FROM Customer.UserAttributes ua WITH (NOLOCK)
JOIN Dictionary.Attribute a WITH (NOLOCK) ON ua.AttributeID = a.AttributeID
GROUP BY a.Name
ORDER BY UserCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Attribute | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.Attribute.sql*
