# dbo.Test

> Development/testing table storing ApexID-to-GCID mappings, likely used for batch testing or data migration validation.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | No PK (heap table) |
| **Partition** | No |
| **Indexes** | None |

---

## 1. Business Meaning

dbo.Test is a development/testing table that stores ApexID-to-GCID pairs. It has no primary key, no indexes, and no constraints, indicating it is used for ad-hoc operations such as batch testing, data migration validation, or temporary data staging. The table currently contains ~127,620 rows.

This table is not part of the production business logic flow. It appears to be a utility table used by developers or DBAs for testing or bulk operations. The column structure mirrors the key columns of Apex.ApexData (ApexID + GCID).

---

## 2. Business Logic

No business logic. This is a utility/staging table with no constraints or relationships.

---

## 3. Data Overview

The table contains ~127,620 rows of ApexID-GCID pairs. No sample shown as this is a test/utility table with no defined business meaning per row.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ApexID | varchar(8) | NO | - | NAME-INFERRED | Apex Clearing account identifier. Same format as Apex.ApexData.ApexID. No PK constraint - duplicates are possible. |
| 2 | GCID | int | NO | - | NAME-INFERRED | Global Customer ID. Same as used across all Apex schema tables. No FK constraint. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (no FKs).

### 5.2 Referenced By (other objects point to this)

No objects reference this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

None. This is a heap table (no clustered index).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check row count

```sql
SELECT COUNT(*) FROM dbo.Test WITH (NOLOCK);
```

### 8.2 Find a specific GCID

```sql
SELECT ApexID, GCID FROM dbo.Test WITH (NOLOCK) WHERE GCID = 12345;
```

### 8.3 Cross-reference with ApexData

```sql
SELECT t.ApexID, t.GCID, d.StatusID
FROM dbo.Test t WITH (NOLOCK)
INNER JOIN Apex.ApexData d WITH (NOLOCK) ON d.GCID = t.GCID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 7.5/10 (Elements: 7/10, Logic: 2/10, Relationships: 2/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.Test | Type: Table | Source: USABroker/dbo/Tables/dbo.Test.sql*
