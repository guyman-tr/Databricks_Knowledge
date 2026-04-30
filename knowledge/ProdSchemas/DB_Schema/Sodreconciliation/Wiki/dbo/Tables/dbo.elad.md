# dbo.elad

> Test or scratch table named after a person (likely developer "Elad"). Contains a single integer column with no constraints. Not a production table.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | None (no PK) |
| **Partition** | No |
| **Indexes** | None |

---

## 1. Business Meaning

This is a minimal test or scratch table containing only a single nullable integer column (`id`). It has no primary key, no indexes, no foreign keys, and no constraints. The name "elad" is a common first name (Hebrew origin), strongly suggesting this table was created by a developer named Elad for ad-hoc testing purposes and left behind.

This table carries no business logic and is not referenced by any views, stored procedures, or other database objects in the SOD reconciliation system.

---

## 2. Business Logic

None. This table has no business logic.

---

## 3. Data Overview

N/A - Test/scratch table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | id | int | YES | - | NAME-INFERRED | Single nullable integer column. No constraints or purpose defined. |

---

## 5. Relationships

### 5.1 References To (this object points to)

None.

### 5.2 Referenced By (other objects point to this)

None.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.elad (table)
  (no dependencies)
```

### 6.1 Objects This Depends On

None.

### 6.2 Objects That Depend On This

None.

---

## 7. Technical Details

### 7.1 Indexes

None.

### 7.2 Constraints

None. No primary key, foreign keys, unique constraints, or check constraints.

---

## 8. Sample Queries

### 8.1 View all rows

```sql
SELECT id FROM dbo.elad WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources reference this table.

---

*Generated: 2026-04-11 | Quality: 3.0/10 (Elements: 4/10, Logic: 2/10, Relationships: 2/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 1/11*
*Note: This appears to be a test/scratch table named after a developer. Consider removal.*
*Object: dbo.elad | Type: Table | Source: Sodreconciliation/Sodreconciliation/dbo/Tables/dbo.elad.sql*
