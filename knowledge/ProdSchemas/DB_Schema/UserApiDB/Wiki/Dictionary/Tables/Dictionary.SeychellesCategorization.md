# Dictionary.SeychellesCategorization

> Lookup table defining client categorization levels under FSA Seychelles regulation.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | SeychellesCategorizationID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.SeychellesCategorization defines client classification categories specific to the Financial Services Authority (FSA) of Seychelles. Similar in concept to MiFID categorization for EU users, this classification determines product access and regulatory protections for Seychelles-regulated users.

Users under FSA Seychelles regulation (RegulationID=9) are categorized to determine their access level. Basic clients have standard access, Advanced clients may access additional products or higher leverage, and Pending indicates assessment in progress. NotInFlow means the user is not subject to the Seychelles categorization process.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| SeychellesCategorizationID | Name | Meaning |
|---|---|---|
| 0 | Basic | Standard client categorization under FSA Seychelles - default product access |
| 1 | Pending | Categorization assessment in progress - treated as Basic until determined |
| 2 | Advanced | Advanced categorization - broader product access and/or higher leverage |
| 3 | NotInFlow | User not subject to Seychelles categorization - either different regulation or exempt |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SeychellesCategorizationID | int | NO | - | CODE-BACKED | Primary key. Classification: 0=Basic, 1=Pending, 2=Advanced, 3=NotInFlow. See [Seychelles Categorization](_glossary.md#seychelles-categorization). |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Category display name. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.RiskUserInfo | SeychellesCategorizationID | Lookup | Stores user's Seychelles classification |

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
| PK_SeychellesCategorization | CLUSTERED PK | SeychellesCategorizationID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all categories
```sql
SELECT SeychellesCategorizationID, Name FROM Dictionary.SeychellesCategorization WITH (NOLOCK) ORDER BY SeychellesCategorizationID
```

### 8.2 Find Seychelles-regulated users by category
```sql
SELECT sc.Name, COUNT(*) AS UserCount
FROM Customer.RiskUserInfo r WITH (NOLOCK)
JOIN Dictionary.SeychellesCategorization sc WITH (NOLOCK) ON r.SeychellesCategorizationID = sc.SeychellesCategorizationID
WHERE r.SeychellesCategorizationID IS NOT NULL AND r.SeychellesCategorizationID <> 3
GROUP BY sc.Name
```

### 8.3 Get a user's Seychelles classification
```sql
SELECT r.CustomerID, sc.Name AS Classification
FROM Customer.RiskUserInfo r WITH (NOLOCK)
JOIN Dictionary.SeychellesCategorization sc WITH (NOLOCK) ON r.SeychellesCategorizationID = sc.SeychellesCategorizationID
WHERE r.CustomerID = @CustomerID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.SeychellesCategorization | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.SeychellesCategorization.sql*
