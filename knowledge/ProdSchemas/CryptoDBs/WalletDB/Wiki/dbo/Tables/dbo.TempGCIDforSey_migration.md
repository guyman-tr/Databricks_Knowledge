# dbo.TempGCIDforSey_migration

> Temporary migration table holding deduplicated GCIDs for Seychelles customer migration, with a primary key ensuring uniqueness.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | PK_TempGCIDforSey_migration (GCID) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered on GCID) |

---

## 1. Business Meaning

This table contains a deduplicated list of Global Customer IDs (GCIDs) for customers being migrated to or from the Seychelles-regulated eToro entity. The 77,881 rows represent the scope of the Seychelles migration. Unlike the Singapore and Switzerland negative consent tables, this table has a PRIMARY KEY on GCID, enforcing uniqueness and providing clustered index performance for lookups.

The `Sey` abbreviation refers to Seychelles (eToro has a Seychelles-regulated entity). This migration likely involved moving customer accounts between regulatory jurisdictions. The PK constraint suggests this table was used in JOIN operations during the migration process where deduplication was critical.

No stored procedures, views, or functions reference this table. Migration operations were likely performed via ad-hoc scripts. The table remains as a historical record of which customers were in scope for the Seychelles migration.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The table is a simple deduplicated GCID list. The PRIMARY KEY on GCID enforces that each customer appears exactly once in the migration scope. See individual element descriptions in Section 4.

---

## 3. Data Overview

| GCID | Meaning |
|------|---------|
| (sample int) | Customer included in Seychelles migration -- unique entry guaranteed by PK |
| (sample int) | Another customer in the Seychelles migration scope |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. The platform-wide unique identifier for a customer in the Seychelles migration. Primary key ensures each GCID appears exactly once. Clustered index provides efficient lookup and JOIN performance during migration processing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (no FK constraints).

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
| PK_TempGCIDforSey_migration | CLUSTERED (PK) | GCID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TempGCIDforSey_migration | PRIMARY KEY | Clustered PK on GCID -- ensures each customer appears only once in the migration list |

---

## 8. Sample Queries

### 8.1 Count Seychelles migration customers
```sql
SELECT COUNT(*) AS CustomerCount
FROM dbo.TempGCIDforSey_migration WITH (NOLOCK)
```

### 8.2 Check if a specific customer is in migration scope
```sql
SELECT GCID
FROM dbo.TempGCIDforSey_migration WITH (NOLOCK)
WHERE GCID = 12345678
```

### 8.3 Join with customer wallets to find affected wallets
```sql
SELECT t.GCID, cw.WalletId
FROM dbo.TempGCIDforSey_migration t WITH (NOLOCK)
INNER JOIN Wallet.CustomerWallets cw WITH (NOLOCK) ON cw.Gcid = t.GCID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 5.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.TempGCIDforSey_migration | Type: Table | Source: WalletDB/dbo/Tables/dbo.TempGCIDforSey_migration.sql*
