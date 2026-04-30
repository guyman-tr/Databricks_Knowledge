# dbo.MigrationGermany_Dor

> Temporary migration tracking table for German customer wallet migrations, recording GCID-to-RealCID mappings and migration status.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | None (no PK; GCID indexed) |
| **Partition** | No |
| **Indexes** | 1 active (IX_MigrationGermany_Dor on GCID) |

---

## 1. Business Meaning

This table tracks the migration of German eToro customers from one legal entity or platform instance to another. Each row maps a Global Customer ID (GCID) to a Real Customer ID (RealCID), with a status column tracking migration progress. The `_Dor` suffix suggests this was created by a specific team member for a targeted migration project.

The migration was likely driven by regulatory requirements (German financial regulation, BaFin compliance) requiring customer accounts to be moved to a German-regulated entity. The table contains 199,050 rows representing the full scope of the German customer migration.

No stored procedures, views, or functions reference this table. Migration operations were likely performed via ad-hoc scripts. The table remains as a historical record of which customers were migrated.

---

## 2. Business Logic

### 2.1 Migration Status Tracking

**What**: Each customer's migration progress is tracked via a status column with a default of 'Pending'.

**Columns/Parameters Involved**: `GCID`, `MigrationStatus`

**Rules**:
- New rows default to MigrationStatus = 'Pending'
- Status progresses as the migration workflow completes (likely Pending -> Completed or similar)
- GCID is indexed for lookup performance during migration batch processing

---

## 3. Data Overview

| GCID | RealCID | MigrationStatus | Meaning |
|------|---------|-----------------|---------|
| (sample) | (int) | Pending | Customer awaiting migration from current entity to German-regulated entity |
| (sample) | (int) | (completed value) | Customer successfully migrated - GCID now maps to RealCID in the new entity |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. The platform-wide unique identifier for the customer being migrated. Indexed for batch lookup performance. |
| 2 | RealCID | int | NO | - | CODE-BACKED | Real Customer ID. The customer's identifier in the target entity or system after migration. Maps the customer's identity across entity boundaries. |
| 3 | MigrationStatus | nvarchar(20) | YES | 'Pending' | CODE-BACKED | Current migration state. Defaults to 'Pending' on insert. Tracks whether the customer's wallet data has been successfully moved to the German-regulated entity. |

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
| IX_MigrationGermany_Dor | NONCLUSTERED | GCID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (default) | DEFAULT | MigrationStatus = 'Pending' - new migration entries start in Pending state |

---

## 8. Sample Queries

### 8.1 Check migration status distribution
```sql
SELECT MigrationStatus, COUNT(*) AS Cnt
FROM dbo.MigrationGermany_Dor WITH (NOLOCK)
GROUP BY MigrationStatus
```

### 8.2 Find pending migrations
```sql
SELECT GCID, RealCID
FROM dbo.MigrationGermany_Dor WITH (NOLOCK)
WHERE MigrationStatus = 'Pending'
```

### 8.3 Look up a specific customer's migration
```sql
SELECT GCID, RealCID, MigrationStatus
FROM dbo.MigrationGermany_Dor WITH (NOLOCK)
WHERE GCID = 12345678
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 5.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 2/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.MigrationGermany_Dor | Type: Table | Source: WalletDB/dbo/Tables/dbo.MigrationGermany_Dor.sql*
