# BackOffice.UpdateBackOfficeAffiliateTableForMissingRecords

> Backfill procedure that syncs new affiliates from the external affiliate management system (fiktivo) into BackOffice.Affiliate, inserting only records not yet present.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - maintenance/sync job |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.UpdateBackOfficeAffiliateTableForMissingRecords` is a data synchronization procedure that closes the gap between the external affiliate management system and eToro's internal affiliate registry. The external system (`fiktivo.dbo.tblaff_Affiliates`, accessed via the `fiktivo_tblaff_Affiliates` synonym) is the authoritative source for affiliate enrollment - when a new affiliate partner signs up, their record appears in fiktivo first. This SP is the bridge that brings those new affiliates into `BackOffice.Affiliate`.

The procedure exists because `BackOffice.Affiliate` must contain a row for every affiliate before back-office operations (spread group assignment, tier management, CRM sync via `AffiliateEdit`) can be performed. Without this backfill, newly enrolled affiliates would be missing from the internal registry and back-office managers could not manage them.

The SP performs a set-based NOT EXISTS insert: all AffiliateIDs in the external system that are absent from `BackOffice.Affiliate` are inserted in a single statement with default values (AffiliateStatusID=1 Normal, SpreadGroupID=0, ManagerID=NULL). Inserted AffiliateIDs are returned to the caller via the OUTPUT clause. The SP is typically run as a scheduled maintenance job or triggered manually by a back-office administrator when new affiliates are expected.

---

## 2. Business Logic

### 2.1 Gap-Fill Insert from External Affiliate Source

**What**: Identifies affiliates present in the external fiktivo system but absent from BackOffice.Affiliate, and inserts them with initial default settings.

**Columns Involved**: `BackOffice.Affiliate.AffiliateID`, `AffiliateStatusID`, `SpreadGroupID`, `ManagerID`

**Rules**:
- Source: `fiktivo_tblaff_Affiliates` (synonym for `fiktivo.dbo.tblaff_Affiliates`), the external affiliate management platform.
- Condition: `AffiliateID NOT IN (SELECT AffiliateID FROM BackOffice.Affiliate)` - only inserts new records, never updates existing ones.
- Inserted defaults: `AffiliateStatusID=1` (Normal tier), `SpreadGroupID=0` (default spread), `ManagerID=NULL` (unassigned).
- Idempotent: safe to run multiple times - duplicate runs produce no new inserts once affiliates are already present.
- OUTPUT clause: inserted `AffiliateID` values are returned to the caller as a result set (original table variable `@InsertedAffiliates` was commented out in favor of a direct result set output).

**Diagram**:
```
fiktivo_tblaff_Affiliates (external source)
         |
         | SELECT AffiliateID
         | WHERE NOT IN BackOffice.Affiliate
         v
BackOffice.Affiliate <-- INSERT (AffiliateStatusID=1, SpreadGroupID=0, ManagerID=NULL)
         |
         | OUTPUT Inserted.AffiliateID -> result set returned to caller
```

### 2.2 Affiliate Lifecycle: Initial Population

**What**: This SP is the first step in the affiliate lifecycle - it creates the record that all subsequent back-office operations depend on.

**Rules**:
- After a successful insert, the affiliate can be configured via `BackOffice.AffiliateEdit` (tier changes, custom spread groups, CRM sync).
- Before this SP runs, `BackOffice.AffiliateEdit` cannot create a CRM record for the new affiliate.
- The initial `AffiliateStatusID=1` (Normal) is the correct business default for a newly enrolled affiliate.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | - | This procedure takes no input. It operates as a full-table sync based on set difference. |

**Output**:
- Result set of inserted `AffiliateID` values (int), one row per newly inserted affiliate. Empty result set if no new affiliates were found.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateID (source) | fiktivo_tblaff_Affiliates (synonym: fiktivo.dbo.tblaff_Affiliates) | External source | Provides the list of affiliate IDs to sync from the external affiliate platform |
| AffiliateID (target) | [BackOffice.Affiliate](../Tables/BackOffice.Affiliate.md) | INSERT target | Inserts new affiliate rows not yet present in the internal registry |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Scheduled maintenance job | - | Caller | Executed periodically to keep BackOffice.Affiliate in sync with the external affiliate system |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.UpdateBackOfficeAffiliateTableForMissingRecords (procedure)
+-- BackOffice.Affiliate (table) [INSERT target + NOT IN subquery]
|     +-- Dictionary.AffiliateStatus (table) [FK: AffiliateStatusID]
|     +-- Trade.SpreadGroup (table) [FK: SpreadGroupID]
|     +-- BackOffice.Manager (table) [FK: ManagerID]
+-- fiktivo_tblaff_Affiliates (synonym -> fiktivo.dbo.tblaff_Affiliates) [external source]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [BackOffice.Affiliate](../Tables/BackOffice.Affiliate.md) | Table | INSERT target; also used in NOT IN subquery to detect missing records |
| fiktivo_tblaff_Affiliates | Synonym (external linked server) | Source of affiliate IDs to sync from fiktivo.dbo.tblaff_Affiliates |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No direct dependents found in repo. | - | Invoked by scheduled maintenance jobs or manual back-office administration. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. The INSERT respects BackOffice.Affiliate FK constraints: inserted AffiliateStatusID=1 and SpreadGroupID=0 must exist in Dictionary.AffiliateStatus and Trade.SpreadGroup respectively.

---

## 8. Sample Queries

### 8.1 Execute the affiliate backfill sync

```sql
-- Run to sync new affiliates from fiktivo into BackOffice.Affiliate
-- Returns AffiliateIDs of newly inserted records (empty if no new affiliates)
EXEC BackOffice.UpdateBackOfficeAffiliateTableForMissingRecords;
```

### 8.2 Check for pending affiliates before running (preview)

```sql
-- Preview: affiliates in fiktivo not yet in BackOffice.Affiliate
SELECT f.AffiliateID
FROM fiktivo_tblaff_Affiliates f WITH (NOLOCK)
WHERE f.AffiliateID NOT IN (SELECT AffiliateID FROM BackOffice.Affiliate WITH (NOLOCK));
```

### 8.3 Verify results after sync

```sql
-- Confirm new affiliates were inserted with correct defaults
SELECT TOP 10 a.AffiliateID, a.AffiliateStatusID, a.SpreadGroupID, a.ManagerID
FROM BackOffice.Affiliate a WITH (NOLOCK)
ORDER BY a.AffiliateID DESC;
-- Expect AffiliateStatusID=1, SpreadGroupID=0, ManagerID=NULL for newly inserted rows
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found directly for this procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Dependency Inheritance, Caller Scan, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.UpdateBackOfficeAffiliateTableForMissingRecords | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.UpdateBackOfficeAffiliateTableForMissingRecords.sql*
