# Dictionary.AttributeGroup

> Lookup table grouping user attributes into collection contexts such as the registration funnel.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | AttributeGroupID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.AttributeGroup organizes user attributes (Dictionary.Attribute) into logical groups based on the context in which they are collected. Currently the only group is "Funnel", meaning attributes captured during the user registration and onboarding funnel.

This grouping exists to support future expansion of attribute collection contexts. For example, attributes collected during a marketing campaign, a survey, or an in-app prompt could each be their own group. The group ID allows filtering and analytics by collection context.

Attribute groups are assigned when user attributes are recorded. The group tells downstream analytics systems where the attribute data originated from.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Single-value lookup. See individual element descriptions in Section 4.

---

## 3. Data Overview

| AttributeGroupID | Name | Meaning |
|---|---|---|
| 1 | Funnel | Attributes collected during the user registration and onboarding funnel - the initial "What are you interested in?" selection |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AttributeGroupID | int | NO | - | CODE-BACKED | Primary key. Collection context identifier. Currently only 1=Funnel. See [Attribute Group](_glossary.md#attribute-group). |
| 2 | Name | varchar(30) | YES | - | CODE-BACKED | Display name of the attribute collection context. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer user-attribute mapping tables | AttributeGroupID | Lookup | Groups attribute records by collection context |

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
| PK_DictionaryAttributeGroup | CLUSTERED PK | AttributeGroupID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all attribute groups
```sql
SELECT AttributeGroupID, Name
FROM Dictionary.AttributeGroup WITH (NOLOCK)
ORDER BY AttributeGroupID
```

### 8.2 Count attributes by group
```sql
SELECT ag.Name AS GroupName, COUNT(DISTINCT ua.AttributeID) AS AttributeCount
FROM Customer.UserAttributes ua WITH (NOLOCK)
JOIN Dictionary.AttributeGroup ag WITH (NOLOCK) ON ua.AttributeGroupID = ag.AttributeGroupID
GROUP BY ag.Name
```

### 8.3 Join attributes with their group
```sql
SELECT ag.Name AS GroupName, a.Name AS AttributeName
FROM Dictionary.Attribute a WITH (NOLOCK)
CROSS JOIN Dictionary.AttributeGroup ag WITH (NOLOCK)
WHERE ag.AttributeGroupID = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AttributeGroup | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.AttributeGroup.sql*
