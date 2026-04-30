# Customer.Bulk_UpdateAccountUserInfo

> Bulk-updates account-level user profile data (label, trade level, guru status, KYC state, etc.) for up to 2,000 users per batch via a table-valued parameter, delegating the actual writes to the BackOffice schema on the etoro database.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BulkUpdateTable (TVP input) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.Bulk_UpdateAccountUserInfo is the batch-update entry point for account-level user profile data stored in Customer.AccountUserInfo. It enables callers to update multiple users' brand labels, trade levels, Popular Investor tiers, KYC states, account types, and other account configuration in a single operation rather than issuing individual UPDATE statements.

This procedure exists to support operational bulk updates - scenarios such as regulatory migration (changing all users under a regulation), bulk Popular Investor tier recalculation, brand reassignment, or mass KYC state progression. Without it, each user would require a separate call to Customer.UpdateAccountUserInfo, which would be prohibitively slow for thousands of users.

Data flows into this procedure via a table-valued parameter (TVP) of type Customer.AccountUserInfo (UDT). The procedure validates the batch size (max 2,000 rows), copies the TVP into a local temp table (#BulkUpdateAccountUserInfo), and then delegates the actual update to dbo.Real_Bulk_UpdateAccountUserInfoRemote - a synonym pointing to [etoro].[BackOffice].[Bulk_UpdateAccountUserInfoRemote] on the etoro database. The remote procedure performs the actual merge/update against Customer.AccountUserInfo, which in turn fires the UPDATE trigger writing to History.AccountUserInfo and Sync.PendingEntityEvents (EntityType=3).

---

## 2. Business Logic

### 2.1 Batch Size Guard

**What**: Hard limit preventing oversized bulk operations from overwhelming the database.

**Columns/Parameters Involved**: `@BulkUpdateTable`

**Rules**:
- The procedure counts all rows in the TVP before processing
- If the count exceeds 2,000, a severity-16 error is raised: "Too many records, allowed 2000 records per batch."
- The entire operation is aborted - no partial updates occur
- Callers needing to update more than 2,000 users must split into multiple calls

### 2.2 Remote Delegation Pattern

**What**: The procedure does not update Customer.AccountUserInfo directly - it delegates to a remote BackOffice procedure via a synonym.

**Columns/Parameters Involved**: `@BulkUpdateTable`, temp table `#BulkUpdateAccountUserInfo`

**Rules**:
- The TVP is copied to a local temp table (#BulkUpdateAccountUserInfo) before the remote call
- The remote synonym dbo.Real_Bulk_UpdateAccountUserInfoRemote resolves to [etoro].[BackOffice].[Bulk_UpdateAccountUserInfoRemote]
- This cross-database delegation pattern is consistent across all three Bulk_Update procedures in the Customer schema

**Diagram**:
```
Caller -> [Customer.Bulk_UpdateAccountUserInfo]
              |
              +--> Validate: count <= 2000
              +--> SELECT * INTO #BulkUpdateAccountUserInfo
              +--> EXEC dbo.Real_Bulk_UpdateAccountUserInfoRemote
                      |
                      +--> (synonym) -> [etoro].[BackOffice].[Bulk_UpdateAccountUserInfoRemote]
                              |
                              +--> UPDATE Customer.AccountUserInfo
                                      |
                                      +--> UPDATE trigger -> History.AccountUserInfo
                                      +--> UPDATE trigger -> Sync.PendingEntityEvents (EntityType=3)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BulkUpdateTable | Customer.AccountUserInfo (TVP) | NO | - | CODE-BACKED | READONLY table-valued parameter containing the batch of user account updates. Each row identifies a user by GCID and provides updated values for any combination of: WhiteLabelId (brand), AccountTypeId, TradeLevelId, PendingClosureStatusId, AccountStatusId, MasterAccountCId, ManagerId, GuruStatusId (Popular Investor tier), KYCState, SubSerialID, DownloadID, ReferralID, AffiliateId. See [Customer.AccountUserInfo UDT](../User Defined Types/Customer.AccountUserInfo.md) for the full 14-column schema. Maximum 2,000 rows per call. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BulkUpdateTable | Customer.AccountUserInfo (UDT) | Parameter Type | TVP type defining the input schema for bulk account updates |
| (body) | dbo.Real_Bulk_UpdateAccountUserInfoRemote | EXEC (synonym) | Delegates actual update to [etoro].[BackOffice].[Bulk_UpdateAccountUserInfoRemote] |
| (indirect) | Customer.AccountUserInfo (Table) | Write target | The table ultimately updated by the remote procedure |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Application | Called by services performing bulk account profile updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.Bulk_UpdateAccountUserInfo (procedure)
+-- Customer.AccountUserInfo (type) - TVP parameter type
+-- dbo.Real_Bulk_UpdateAccountUserInfoRemote (synonym)
      +-- [etoro].[BackOffice].[Bulk_UpdateAccountUserInfoRemote] (remote procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.AccountUserInfo | User Defined Type | TVP parameter type for @BulkUpdateTable |
| dbo.Real_Bulk_UpdateAccountUserInfoRemote | Synonym | EXEC - delegates the actual bulk update |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (no database callers found) | - | Called from application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Batch size limit | RAISERROR (severity 16) | count(@BulkUpdateTable) must be <= 2000 or operation is aborted |

---

## 8. Sample Queries

### 8.1 Bulk update Popular Investor tiers for multiple users
```sql
DECLARE @Updates Customer.AccountUserInfo
INSERT INTO @Updates (GCID, GuruStatusId)
VALUES (12345, 3), (67890, 4), (11111, 5)
EXEC Customer.Bulk_UpdateAccountUserInfo @BulkUpdateTable = @Updates
```

### 8.2 Bulk reassign brand label for a group of users
```sql
DECLARE @Updates Customer.AccountUserInfo
INSERT INTO @Updates (GCID, WhiteLabelId)
SELECT GCID, 14  -- reassign to eToroUSA
FROM Customer.AccountUserInfo WITH (NOLOCK)
WHERE WhiteLabelId = 1 AND GCID IN (SELECT GCID FROM #MigrationList)
EXEC Customer.Bulk_UpdateAccountUserInfo @BulkUpdateTable = @Updates
```

### 8.3 Bulk update KYC state with batch size check
```sql
DECLARE @Updates Customer.AccountUserInfo
INSERT INTO @Updates (GCID, KYCState)
SELECT TOP 2000 GCID, 5
FROM Customer.AccountUserInfo WITH (NOLOCK)
WHERE KYCState = 0
EXEC Customer.Bulk_UpdateAccountUserInfo @BulkUpdateTable = @Updates
```

---

## 9. Atlassian Knowledge Sources

No directly relevant Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Customer.Bulk_UpdateAccountUserInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.Bulk_UpdateAccountUserInfo.sql*
