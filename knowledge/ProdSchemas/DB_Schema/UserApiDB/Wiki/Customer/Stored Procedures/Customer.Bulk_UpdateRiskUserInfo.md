# Customer.Bulk_UpdateRiskUserInfo

> Bulk-updates user risk and compliance profile data (regulation, player status, verification level, document status) for up to 2,000 users per batch via a table-valued parameter, delegating writes to the BackOffice schema on the etoro database.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BulkUpdateTable (TVP input) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.Bulk_UpdateRiskUserInfo is the batch-update entry point for user risk and compliance profile data stored in Customer.RiskUserInfo. It enables callers to update multiple users' regulatory assignments, player statuses (with reasons and sub-reasons), verification levels, document verification statuses, and copy-trading suitability test statuses in a single operation.

This procedure serves critical compliance and risk management use cases: regulatory migration (e.g., moving users from one jurisdiction to another), mass player-status changes (e.g., suspending users during an investigation), bulk verification level updates after automated KYC checks, and mass copy-trading suitability reassessments.

Data flows in via a table-valued parameter (TVP) of type Customer.RiskUserInfo (UDT) containing 9 fields. The procedure validates the batch size (max 2,000 rows), copies the TVP into a local temp table (#BulkUpdateRiskUserInfo), and delegates the actual update to dbo.Real_Bulk_UpdateRiskUserInfoRemote - a synonym pointing to [etoro].[BackOffice].[Bulk_UpdateRiskUserInfoRemote]. The remote procedure updates Customer.RiskUserInfo, which fires the UPDATE trigger writing to History.RiskUserInfo and Sync.PendingEntityEvents (EntityType=4).

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

**What**: The procedure does not update Customer.RiskUserInfo directly - it delegates to a remote BackOffice procedure via synonym.

**Columns/Parameters Involved**: `@BulkUpdateTable`, temp table `#BulkUpdateRiskUserInfo`

**Rules**:
- The TVP is copied to a local temp table (#BulkUpdateRiskUserInfo) before the remote call
- The remote synonym dbo.Real_Bulk_UpdateRiskUserInfoRemote resolves to [etoro].[BackOffice].[Bulk_UpdateRiskUserInfoRemote]
- This is the same cross-database delegation pattern used by all Bulk_Update procedures

**Diagram**:
```
Caller -> [Customer.Bulk_UpdateRiskUserInfo]
              |
              +--> Validate: count <= 2000
              +--> SELECT * INTO #BulkUpdateRiskUserInfo
              +--> EXEC dbo.Real_Bulk_UpdateRiskUserInfoRemote
                      |
                      +--> (synonym) -> [etoro].[BackOffice].[Bulk_UpdateRiskUserInfoRemote]
                              |
                              +--> UPDATE Customer.RiskUserInfo
                                      |
                                      +--> UPDATE trigger -> History.RiskUserInfo
                                      +--> UPDATE trigger -> Sync.PendingEntityEvents (EntityType=4)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BulkUpdateTable | Customer.RiskUserInfo (TVP) | NO | - | CODE-BACKED | READONLY table-valued parameter containing the batch of user risk profile updates. Each row identifies a user by GCID and provides updated values for: RegulatingEntityId (regulation, FK to Dictionary.Regulation), DocumentStatus, PhoneVerificationStatus, VerificationLevel (FK to Dictionary.VerificationLevel), PlayerStatus (FK to Dictionary.PlayerStatus), CopySuitabilityTestStatus, PlayerStatusReason (FK to Dictionary.PlayerStatusReasons), PlayerStatusSubReason (FK to Dictionary.PlayerStatusSubReasons). See [Customer.RiskUserInfo UDT](../User Defined Types/Customer.RiskUserInfo.md) for the full 9-column schema. Maximum 2,000 rows per call. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BulkUpdateTable | Customer.RiskUserInfo (UDT) | Parameter Type | TVP type defining the input schema for bulk risk info updates |
| (body) | dbo.Real_Bulk_UpdateRiskUserInfoRemote | EXEC (synonym) | Delegates actual update to [etoro].[BackOffice].[Bulk_UpdateRiskUserInfoRemote] |
| (indirect) | Customer.RiskUserInfo (Table) | Write target | The table ultimately updated by the remote procedure |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Application | Called by services performing bulk risk profile updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.Bulk_UpdateRiskUserInfo (procedure)
+-- Customer.RiskUserInfo (type) - TVP parameter type
+-- dbo.Real_Bulk_UpdateRiskUserInfoRemote (synonym)
      +-- [etoro].[BackOffice].[Bulk_UpdateRiskUserInfoRemote] (remote procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.RiskUserInfo | User Defined Type | TVP parameter type for @BulkUpdateTable |
| dbo.Real_Bulk_UpdateRiskUserInfoRemote | Synonym | EXEC - delegates the actual bulk update |

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

### 8.1 Bulk update regulation assignment for migrating users
```sql
DECLARE @Updates Customer.RiskUserInfo
INSERT INTO @Updates (GCID, RegulatingEntityId)
SELECT GCID, 2  -- reassign to FCA
FROM Customer.RiskUserInfo WITH (NOLOCK)
WHERE RegulatingEntityId = 1 AND GCID IN (SELECT GCID FROM #MigrationList)
EXEC Customer.Bulk_UpdateRiskUserInfo @BulkUpdateTable = @Updates
```

### 8.2 Bulk update player status with reason
```sql
DECLARE @Updates Customer.RiskUserInfo
INSERT INTO @Updates (GCID, PlayerStatus, PlayerStatusReason, PlayerStatusSubReason)
VALUES (12345, 5, 10, 0), (67890, 5, 10, 0)
EXEC Customer.Bulk_UpdateRiskUserInfo @BulkUpdateTable = @Updates
```

### 8.3 Bulk update verification level after KYC check
```sql
DECLARE @Updates Customer.RiskUserInfo
INSERT INTO @Updates (GCID, VerificationLevel, DocumentStatus)
SELECT TOP 2000 GCID, 3, 1
FROM Customer.RiskUserInfo WITH (NOLOCK)
WHERE VerificationLevel < 3 AND GCID IN (SELECT GCID FROM #ApprovedUsers)
EXEC Customer.Bulk_UpdateRiskUserInfo @BulkUpdateTable = @Updates
```

---

## 9. Atlassian Knowledge Sources

No directly relevant Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Customer.Bulk_UpdateRiskUserInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.Bulk_UpdateRiskUserInfo.sql*
