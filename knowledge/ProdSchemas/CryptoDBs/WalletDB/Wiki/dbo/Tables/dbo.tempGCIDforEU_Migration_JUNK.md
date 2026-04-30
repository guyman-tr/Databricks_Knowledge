# dbo.tempGCIDforEU_Migration_JUNK

> Temporary GCID list for EU customer wallet migration, marked as JUNK for eventual deletion after migration completion.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | GCID (bigint, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK CLUSTERED on GCID) |

---

## 1. Business Meaning

This table holds a list of Global Customer IDs (GCIDs) targeted for an EU customer migration. The `_JUNK` suffix indicates it was intended for deletion after confirming the migration completed successfully. With 73,872 rows, it represents the scope of EU customers involved in this particular migration wave.

The PK constraint on GCID ensures each customer appears exactly once, preventing duplicate processing during migration batch operations.

No stored procedures, views, or functions reference this table. It is an orphaned migration artifact.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| GCID | Meaning |
|------|---------|
| (bigint value) | EU customer identified for wallet migration to the appropriate EU-regulated entity |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | bigint | NO | - | CODE-BACKED | Global Customer ID. Uniquely identifies an EU customer targeted for migration. PK ensures deduplication. |

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
| PK_tempGCIDforEU_Migration | CLUSTERED PK | GCID | - | - | Active |

### 7.2 Constraints

None (PK listed above).

---

## 8. Sample Queries

### 8.1 Count migration scope
```sql
SELECT COUNT(*) AS CustomerCount FROM dbo.tempGCIDforEU_Migration_JUNK WITH (NOLOCK)
```

### 8.2 Check if a customer was in the migration scope
```sql
SELECT GCID FROM dbo.tempGCIDforEU_Migration_JUNK WITH (NOLOCK) WHERE GCID = 12345678
```

### 8.3 Sample GCIDs
```sql
SELECT TOP 10 GCID FROM dbo.tempGCIDforEU_Migration_JUNK WITH (NOLOCK) ORDER BY GCID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 5.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tempGCIDforEU_Migration_JUNK | Type: Table | Source: WalletDB/dbo/Tables/dbo.tempGCIDforEU_Migration_JUNK.sql*
