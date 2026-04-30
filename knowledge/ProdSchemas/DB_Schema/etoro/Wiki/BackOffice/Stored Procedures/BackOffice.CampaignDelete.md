# BackOffice.CampaignDelete

> Deletes a campaign from BackOffice.Campaign after validating it has no linked bonus types, no issued credits, and no assigned customers; also deletes associated SQL Server Agent jobs if they exist.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CampaignID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the guarded deletion path for BackOffice.Campaign. Campaigns cannot simply be deleted - they may have bonus types linked, credits already issued to customers, or customers currently assigned to them. Deleting a campaign in any of these states would create orphaned references and break the audit trail. CampaignDelete enforces all three pre-conditions, blocking deletion with specific error codes if any are violated.

Beyond just deleting the campaign record, this procedure also cleans up the associated SQL Server Agent jobs (StartJobID, EndJobID from BackOffice.Campaign). Campaigns can have scheduled jobs for automated activation and deactivation - these must be removed from msdb when the campaign is deleted. The OUTPUT clause captures the deleted job IDs, and sp_delete_job is called for each non-NULL job that still exists in msdb.

Typical deletion workflow: BonusUnLinkFromCampaign (remove bonus links) -> CampaignClear (clear customer assignments) -> CampaignDelete.

---

## 2. Business Logic

### 2.1 Three Deletion Guards

**What**: Three existence checks block deletion if any dependent data exists.

**Tables Involved**: `BackOffice.CampaignToBonusType`, `History.Credit`, `History.ActiveCreditRecentMemoryBucket`, `Customer.Customer`

**Rules**:
- **Guard 1**: EXISTS in BackOffice.CampaignToBonusType WHERE CampaignID = @CampaignID -> RAISERROR(60023) "the campaign linked to bonus". Call BonusUnLinkFromCampaign for each link first.
- **Guard 2**: EXISTS in History.Credit OR History.ActiveCreditRecentMemoryBucket WHERE CampaignID = @CampaignID -> RAISERROR(60023) "the campaign was used". Campaigns with issued credits can NEVER be deleted (history is immutable).
- **Guard 3**: EXISTS in Customer.Customer WHERE CampaignID = @CampaignID -> RAISERROR(60023) "the campaign assigned to customer(s)". Call CampaignClear first to dissociate customers.
- History.ActiveCreditRecentMemoryBucket is an in-memory table (Shay Oren, 03/01/2021) - checked alongside History.Credit for recent/fast credits.

### 2.2 Campaign Deletion with SQL Agent Job Cleanup

**What**: DELETE from BackOffice.Campaign, capturing any associated SQL Agent job IDs for cleanup.

**Rules**:
- DELETE with OUTPUT DELETED.StartJobID, DELETED.EndJobID -> @JobList table variable
- If DELETE fails (@@ERROR != 0) -> RAISERROR(60000) + RETURN 60000
- After successful DELETE: check @JobList for non-NULL StartJobID and EndJobID
- For each non-NULL job ID: verify job still EXISTS in msdb.dbo.sysjobs (avoids sp_delete_job error on already-deleted jobs)
- If job exists: EXECUTE msdb.dbo.sp_delete_job @job_id = job_id (removes the SQL Agent job)
- This cleanup removes both the campaign START job and the campaign END job

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CampaignID | INTEGER | NO | - | VERIFIED | PK of the campaign to delete. All three guards check this ID before allowing deletion. |

**Return Value:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | RETURN | INT | NO | - | CODE-BACKED | 0=success, 60023=guard failure (linked bonus/used campaign/assigned customers), 60000=unexpected DELETE error. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CampaignID | BackOffice.CampaignToBonusType | Guard check | Guard 1: blocks if bonus types still linked |
| @CampaignID | History.Credit | Guard check | Guard 2a: blocks if credits were issued under this campaign |
| @CampaignID | History.ActiveCreditRecentMemoryBucket | Guard check | Guard 2b: also checks in-memory table for recent credits |
| @CampaignID | Customer.Customer | Guard check | Guard 3: blocks if customers are still assigned |
| @CampaignID | BackOffice.Campaign | DELETER | DELETE target - removes the campaign record |
| StartJobID, EndJobID | msdb.dbo.sp_delete_job | System call | Deletes associated SQL Agent jobs if they exist |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application layer | - | Caller | Called as the final step in campaign deletion workflow |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CampaignDelete (procedure)
|- BackOffice.CampaignToBonusType (table) [Guard check - must be empty]
|- History.Credit (table) [Guard check - must have no rows for this campaign]
|- History.ActiveCreditRecentMemoryBucket (in-memory table) [Guard check - must be empty]
|- Customer.Customer (table) [Guard check - must have no customers assigned]
|- BackOffice.Campaign (table) [DELETE target; OUTPUT StartJobID/EndJobID]
+-- msdb.dbo.sp_delete_job (system SP) [conditionally called to clean up SQL Agent jobs]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CampaignToBonusType | Table | Guard 1: EXISTS check before allowing DELETE |
| History.Credit | Table (cross-schema) | Guard 2a: EXISTS check for issued credits |
| History.ActiveCreditRecentMemoryBucket | In-memory Table (cross-schema) | Guard 2b: EXISTS check for recent in-memory credits |
| Customer.Customer | Table (cross-schema) | Guard 3: EXISTS check for assigned customers |
| BackOffice.Campaign | Table | DELETE target; OUTPUT captures job IDs |
| msdb.dbo.sp_delete_job | System Stored Procedure | Cleanup of SQL Agent start/end jobs if they exist |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application layer | External | Final step in campaign deletion workflow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row-count messages |
| Guard 1 (60023) | Referential Integrity | Campaign with linked bonus types cannot be deleted; call BonusUnLinkFromCampaign first |
| Guard 2 (60023) | Immutable history | Campaigns with issued credits can never be deleted - the credit history is permanent |
| Guard 3 (60023) | Data integrity | Campaigns assigned to customers cannot be deleted; call CampaignClear first |
| OUTPUT clause | Design | Captures deleted StartJobID and EndJobID for SQL Agent cleanup |
| msdb.sysjobs check | Safety | Verifies job existence in msdb before calling sp_delete_job to avoid errors on already-deleted jobs |
| In-memory table check | History (2021) | Shay Oren 03/01/2021 added ActiveCreditRecentMemoryBucket check alongside History.Credit |

---

## 8. Sample Queries

### 8.1 Full campaign deletion workflow

```sql
-- Step 1: Check guards before attempting deletion
SELECT COUNT(*) AS BonusLinks FROM BackOffice.CampaignToBonusType WHERE CampaignID = 5001
SELECT COUNT(*) AS IssuedCredits FROM History.Credit WHERE CampaignID = 5001
SELECT COUNT(*) AS AssignedCustomers FROM Customer.Customer WHERE CampaignID = 5001

-- Step 2: Remove bonus links (if guard 1 fails)
-- EXEC BackOffice.BonusUnLinkFromCampaign @CampaignID = 5001, @BonusTypeID = 7

-- Step 3: Clear customer assignments (if guard 3 fails)
-- EXEC BackOffice.CampaignClear @CampaignID = 5001

-- Step 4: Delete (will fail with 60023 if campaign was ever used - credits exist)
DECLARE @rc INT
EXEC @rc = BackOffice.CampaignDelete @CampaignID = 5001
IF @rc = 60023
    PRINT 'Cannot delete: campaign has dependencies'
```

### 8.2 Check if a campaign has associated SQL Agent jobs

```sql
SELECT CampaignID, Code, StartJobID, EndJobID
FROM BackOffice.Campaign WITH (NOLOCK)
WHERE CampaignID = 5001
  AND (StartJobID IS NOT NULL OR EndJobID IS NOT NULL)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.3/10 (Elements: 9/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CampaignDelete | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CampaignDelete.sql*
