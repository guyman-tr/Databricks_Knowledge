# dbo.UK_migration_GCID

> UK customer migration tracking table mapping GCIDs to RealCIDs with terms acceptance and migration status tracking.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | None (no PK; GCID clustered index) |
| **Partition** | No |
| **Indexes** | 2 active (clustered on GCID, nonclustered on status) |

---

## 1. Business Meaning

This table tracks the migration of UK-based eToro customers between legal entities or platform instances, likely driven by Brexit-related regulatory requirements (FCA compliance). Each row maps a Global Customer ID (GCID) to a Real Customer ID (RealCID) and tracks the customer's terms acceptance and migration status. The 400,526 rows represent a significant UK customer migration -- substantially larger than the German migration (199K rows).

The table structure closely mirrors dbo.MigrationGermany_Dor but with additional columns for terms tracking (CurrentTermsId) and an integer status code rather than a text-based MigrationStatus. The clustered index on GCID enables efficient batch lookups, while the nonclustered index on status supports queries filtering by migration state (e.g., finding all pending or failed migrations).

No stored procedures, views, or functions reference this table. Migration operations were likely performed via ad-hoc scripts. The table remains as a historical record of the UK customer migration scope and outcomes.

---

## 2. Business Logic

### 2.1 Migration Status Tracking

**What**: Each customer's migration progress is tracked via an integer status code, with an index supporting status-based filtering for batch processing.

**Columns/Parameters Involved**: `GCID`, `RealCID`, `CurrentTermsId`, `status`

**Rules**:
- GCID-to-RealCID mapping identifies the customer across entity boundaries
- CurrentTermsId tracks which version of terms and conditions the customer has accepted (or needs to accept) as part of the migration
- status column uses integer codes to track migration progress (e.g., 0=Pending, 1=Completed, etc.)
- Nonclustered index on status optimizes queries that process customers in a specific migration state

---

## 3. Data Overview

| GCID | RealCID | CurrentTermsId | status | Meaning |
|------|---------|----------------|--------|---------|
| (sample) | (int) | (int) | 0 | Customer awaiting migration -- terms not yet accepted for new UK entity |
| (sample) | (int) | (int) | 1 | Customer successfully migrated -- terms accepted, account moved to FCA-regulated entity |
| (sample) | (int) | NULL | NULL | Customer record loaded but migration not yet initiated |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | bigint | NO | - | CODE-BACKED | Global Customer ID. The platform-wide unique identifier for the UK customer being migrated. Clustered index provides efficient lookup and JOIN performance during batch migration processing. |
| 2 | RealCID | int | NO | - | CODE-BACKED | Real Customer ID. The customer's identifier in the target UK-regulated entity or system. Maps the customer's identity across entity boundaries during migration. |
| 3 | CurrentTermsId | int | YES | - | CODE-BACKED | The ID of the terms and conditions version the customer has currently accepted. NULL indicates terms have not yet been presented or accepted. Used to verify regulatory compliance during entity transfer. |
| 4 | status | int | YES | - | CODE-BACKED | Integer migration status code tracking the customer's progress through the migration workflow. Indexed for efficient batch filtering. Likely values: 0=Pending, 1=Completed, with possible error/retry states. |

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
| (clustered) | CLUSTERED | GCID | - | - | Active |
| (nonclustered) | NONCLUSTERED | status | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check migration status distribution
```sql
SELECT status, COUNT(*) AS Cnt
FROM dbo.UK_migration_GCID WITH (NOLOCK)
GROUP BY status
ORDER BY status
```

### 8.2 Find customers pending migration
```sql
SELECT GCID, RealCID, CurrentTermsId
FROM dbo.UK_migration_GCID WITH (NOLOCK)
WHERE status = 0
```

### 8.3 Look up a specific customer's migration status
```sql
SELECT GCID, RealCID, CurrentTermsId, status
FROM dbo.UK_migration_GCID WITH (NOLOCK)
WHERE GCID = 12345678
```

### 8.4 Find customers who have not accepted terms
```sql
SELECT GCID, RealCID, status
FROM dbo.UK_migration_GCID WITH (NOLOCK)
WHERE CurrentTermsId IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 5.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 2/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.UK_migration_GCID | Type: Table | Source: WalletDB/dbo/Tables/dbo.UK_migration_GCID.sql*
