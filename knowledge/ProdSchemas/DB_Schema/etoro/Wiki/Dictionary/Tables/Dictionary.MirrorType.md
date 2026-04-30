# Dictionary.MirrorType

> Lookup table defining the 4 types of CopyTrading (mirror) relationships on the eToro platform.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | MirrorTypeID (INT, CLUSTERED PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.MirrorType classifies the four kinds of CopyTrading relationships that can exist between users on eToro. CopyTrading (internally called "mirror") is eToro's signature social trading feature where one user automatically replicates another user's trades.

This classification determines the business rules, fee structures, and operational behavior of the copy relationship. Regular mirrors are the standard product; CopyMe is a legacy variant; Social Index mirrors track algorithmically-generated portfolios; Fund mirrors copy managed fund strategies.

MirrorTypeID is stored in the mirror relationship records and is referenced by Trade procedures handling copy-trade execution, alignment, and redeem operations.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| MirrorTypeID | MirrorTypeName | Description | Meaning |
|---|---|---|---|
| 1 | Regular | mirror | The standard CopyTrading product — a user allocates funds to copy another user's trades proportionally. The primary social trading feature generating most copy volume. |
| 2 | CopyMe | CopyMe mirror | Legacy variant of the copy relationship — functionally similar to Regular. Historical artifact from an earlier product iteration. |
| 3 | Social Index | Social Index mirror | Automated copy of a social-index strategy — an algorithmically-composed portfolio based on social signals and user rankings. |
| 4 | Fund | Fund mirror | Copy relationship with a managed fund — a professionally-managed portfolio where the fund manager makes allocation decisions. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MirrorTypeID | int | NO | - | CODE-BACKED | Primary key identifying the copy relationship type. 1=Regular (standard copy), 2=CopyMe (legacy), 3=Social Index (algorithmic), 4=Fund (managed). See [Mirror Type](_glossary.md#mirror-type). (Dictionary.MirrorType) |
| 2 | MirrorTypeName | varchar(40) | NO | - | CODE-BACKED | Short code name used in code branching and API responses. |
| 3 | Description | varchar(35) | YES | - | CODE-BACKED | Human-readable description for display. More descriptive than MirrorTypeName. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade mirror tables | MirrorTypeID | Implicit Lookup | Classifies each copy relationship |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade mirror tables | Table | Stores MirrorTypeID per copy relationship |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryMirrorType | CLUSTERED PK | MirrorTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DictionaryMirrorType | PRIMARY KEY | Unique mirror type identifier |

---

## 8. Sample Queries

### 8.1 List all mirror types
```sql
SELECT MirrorTypeID, MirrorTypeName, Description
FROM [Dictionary].[MirrorType] WITH (NOLOCK) ORDER BY MirrorTypeID;
```

### 8.2 Count active copy relationships by type
```sql
SELECT mt.MirrorTypeName, COUNT(*) AS ActiveCopies
FROM [Trade].[Mirror] m WITH (NOLOCK)
JOIN [Dictionary].[MirrorType] mt WITH (NOLOCK) ON m.MirrorTypeID = mt.MirrorTypeID
WHERE m.StatusID = 0 GROUP BY mt.MirrorTypeName ORDER BY ActiveCopies DESC;
```

### 8.3 Find all fund-type copy relationships
```sql
SELECT m.* FROM [Trade].[Mirror] m WITH (NOLOCK)
WHERE m.MirrorTypeID = 4 ORDER BY m.StartDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to Dictionary.MirrorType.

---

*Generated: 2026-03-13 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.MirrorType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.MirrorType.sql*
