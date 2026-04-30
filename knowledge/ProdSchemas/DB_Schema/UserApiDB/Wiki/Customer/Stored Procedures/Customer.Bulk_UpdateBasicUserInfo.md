# Customer.Bulk_UpdateBasicUserInfo

> Bulk-updates basic user profile data (language, gender, eToro Club level) for up to 2,000 users per batch via a table-valued parameter, delegating writes to the BackOffice schema on the etoro database.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BulkUpdateTable (TVP input) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.Bulk_UpdateBasicUserInfo is the batch-update entry point for basic user profile data stored in Customer.BasicUserInfo. It enables callers to update multiple users' language preferences, gender classifications, and eToro Club membership tiers (PlayerLevelID) in a single batch operation.

This procedure exists to support operational bulk updates to basic identity data - scenarios such as language preference migration, mass player-level tier recalculation, or data correction campaigns. Without it, each user would require a separate call to Customer.UpdateBasicUserInfo.

Data flows in via a table-valued parameter (TVP) of type Customer.BasicUserInfo (UDT) containing GCID, languageId, gender, and level fields. The procedure validates the batch size (max 2,000 rows), copies the TVP into a local temp table (#BulkUpdateBasicUserInfo), and delegates the actual update to dbo.Real_Bulk_UpdateBasicUserInfoRemote - a synonym pointing to [etoro].[BackOffice].[Bulk_UpdateBasicUserInfoRemote]. The remote procedure performs the update against Customer.BasicUserInfo, which fires the UPDATE trigger writing to History.BasicUserInfo and Sync.PendingEntityEvents (EntityType=1).

---

## 2. Business Logic

### 2.1 Batch Size Guard

**What**: Hard limit preventing oversized bulk operations.

**Columns/Parameters Involved**: `@BulkUpdateTable`

**Rules**:
- The procedure counts all rows in the TVP before processing
- If the count exceeds 2,000, a severity-16 error is raised: "Too many records, allowed 2000 records per batch."
- The entire operation is aborted - no partial updates occur
- Callers needing to update more than 2,000 users must split into multiple calls

### 2.2 Remote Delegation Pattern

**What**: The procedure does not update Customer.BasicUserInfo directly - it delegates to a remote BackOffice procedure via synonym.

**Columns/Parameters Involved**: `@BulkUpdateTable`, temp table `#BulkUpdateBasicUserInfo`

**Rules**:
- The TVP is copied to a local temp table (#BulkUpdateBasicUserInfo) before the remote call
- The remote synonym dbo.Real_Bulk_UpdateBasicUserInfoRemote resolves to [etoro].[BackOffice].[Bulk_UpdateBasicUserInfoRemote]
- This is the same cross-database delegation pattern used by all Bulk_Update procedures

**Diagram**:
```
Caller -> [Customer.Bulk_UpdateBasicUserInfo]
              |
              +--> Validate: count <= 2000
              +--> SELECT * INTO #BulkUpdateBasicUserInfo
              +--> EXEC dbo.Real_Bulk_UpdateBasicUserInfoRemote
                      |
                      +--> (synonym) -> [etoro].[BackOffice].[Bulk_UpdateBasicUserInfoRemote]
                              |
                              +--> UPDATE Customer.BasicUserInfo
                                      |
                                      +--> UPDATE trigger -> History.BasicUserInfo
                                      +--> UPDATE trigger -> Sync.PendingEntityEvents (EntityType=1)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BulkUpdateTable | Customer.BasicUserInfo (TVP) | NO | - | CODE-BACKED | READONLY table-valued parameter containing the batch of basic user profile updates. Each row identifies a user by GCID and provides updated values for: languageId (preferred language, FK to Dictionary.Language), gender ('M'/'F'/'U'), level (eToro Club tier, FK to Dictionary.PlayerLevel). See [Customer.BasicUserInfo UDT](../User Defined Types/Customer.BasicUserInfo.md) for the full 4-column schema. Maximum 2,000 rows per call. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BulkUpdateTable | Customer.BasicUserInfo (UDT) | Parameter Type | TVP type defining the input schema for bulk basic info updates |
| (body) | dbo.Real_Bulk_UpdateBasicUserInfoRemote | EXEC (synonym) | Delegates actual update to [etoro].[BackOffice].[Bulk_UpdateBasicUserInfoRemote] |
| (indirect) | Customer.BasicUserInfo (Table) | Write target | The table ultimately updated by the remote procedure |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Application | Called by services performing bulk basic profile updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.Bulk_UpdateBasicUserInfo (procedure)
+-- Customer.BasicUserInfo (type) - TVP parameter type
+-- dbo.Real_Bulk_UpdateBasicUserInfoRemote (synonym)
      +-- [etoro].[BackOffice].[Bulk_UpdateBasicUserInfoRemote] (remote procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BasicUserInfo | User Defined Type | TVP parameter type for @BulkUpdateTable |
| dbo.Real_Bulk_UpdateBasicUserInfoRemote | Synonym | EXEC - delegates the actual bulk update |

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

### 8.1 Bulk update language preference for a group of users
```sql
DECLARE @Updates Customer.BasicUserInfo
INSERT INTO @Updates (GCID, languageId)
SELECT GCID, 2  -- switch to English
FROM Customer.BasicUserInfo WITH (NOLOCK)
WHERE languageId = 1 AND GCID IN (SELECT GCID FROM #MigrationList)
EXEC Customer.Bulk_UpdateBasicUserInfo @BulkUpdateTable = @Updates
```

### 8.2 Bulk update eToro Club tier
```sql
DECLARE @Updates Customer.BasicUserInfo
INSERT INTO @Updates (GCID, level)
VALUES (12345, 3), (67890, 5), (11111, 7)
EXEC Customer.Bulk_UpdateBasicUserInfo @BulkUpdateTable = @Updates
```

### 8.3 Bulk update gender classification
```sql
DECLARE @Updates Customer.BasicUserInfo
INSERT INTO @Updates (GCID, gender)
VALUES (12345, 'M'), (67890, 'F')
EXEC Customer.Bulk_UpdateBasicUserInfo @BulkUpdateTable = @Updates
```

---

## 9. Atlassian Knowledge Sources

No directly relevant Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Customer.Bulk_UpdateBasicUserInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.Bulk_UpdateBasicUserInfo.sql*
