# dbo.tempGCIDforEU_Migration_new_JUNK

> Updated GCID list for a subsequent EU customer wallet migration wave, marked as JUNK for eventual deletion.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | None (no PK; GCID indexed) |
| **Partition** | No |
| **Indexes** | 1 active (IX_tempGCIDforEU_Migration_new on GCID) |

---

## 1. Business Meaning

This table holds an updated list of Global Customer IDs for a subsequent wave of EU customer migrations, superseding or supplementing `dbo.tempGCIDforEU_Migration_JUNK`. With 77,832 rows (slightly more than the original's 73,872), it likely includes additional customers identified after the first migration wave. The `_new_JUNK` suffix indicates both that it replaced a previous version and is intended for deletion.

Unlike the original which has a PK constraint on GCID, this table uses a nonclustered index instead - possibly because duplicates needed to be investigated rather than prevented.

No stored procedures, views, or functions reference this table.

---

## 2. Business Logic

No complex multi-column business logic patterns detected.

---

## 3. Data Overview

| GCID | Meaning |
|------|---------|
| (int value) | EU customer identified for the updated migration wave |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. Identifies an EU customer targeted for the updated migration wave. Note: int type (vs bigint in the original table) may limit to older customer ranges. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No other objects reference this table.

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

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IX_tempGCIDforEU_Migration_new | NONCLUSTERED | GCID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Count updated migration scope
```sql
SELECT COUNT(*) AS CustomerCount FROM dbo.tempGCIDforEU_Migration_new_JUNK WITH (NOLOCK)
```

### 8.2 Find customers added in the new wave
```sql
SELECT n.GCID
FROM dbo.tempGCIDforEU_Migration_new_JUNK n WITH (NOLOCK)
LEFT JOIN dbo.tempGCIDforEU_Migration_JUNK o WITH (NOLOCK) ON o.GCID = n.GCID
WHERE o.GCID IS NULL
```

### 8.3 Check for duplicates
```sql
SELECT GCID, COUNT(*) AS Cnt
FROM dbo.tempGCIDforEU_Migration_new_JUNK WITH (NOLOCK)
GROUP BY GCID HAVING COUNT(*) > 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 5.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tempGCIDforEU_Migration_new_JUNK | Type: Table | Source: WalletDB/dbo/Tables/dbo.tempGCIDforEU_Migration_new_JUNK.sql*
