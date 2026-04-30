# RecurringInvestment.PlanInstancesUpdateMultiple

> Batch-updates InstanceStatusID and InstanceStatusReasonID for multiple plan instances from a TVP.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PlanInstancesUpdate TVP, updates PlanInstances status columns |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure updates the status of multiple plan instances in a single operation. It sets the InstanceStatusID and InstanceStatusReasonID for each instance specified in the TVP, identified by both InstanceID and PlanID (for safety). This is used when the system needs to transition multiple instances to a new status simultaneously, such as marking them as skipped, cancelled, or completed.

Without this procedure, each instance status update would require a separate database call, resulting in poor performance when processing batch operations. The TVP approach enables efficient bulk updates. Created per Nilly (1/1/25).

The procedure uses SET NOCOUNT ON for performance and joins on both InstanceID and PlanID to ensure correct matching.

---

## 2. Business Logic

### 2.1 Batch Status Update

**What**: Updates InstanceStatusID and InstanceStatusReasonID for multiple instances from a TVP.

**Columns/Parameters Involved**: `@PlanInstancesUpdate` (PlanInstancesTypeUpdateStatus TVP), `InstanceStatusID`, `InstanceStatusReasonID`

**Rules**:
- UPDATE joins PlanInstances to TVP on both InstanceID AND PlanID
- Only InstanceStatusID and InstanceStatusReasonID are updated (no other columns)
- SET NOCOUNT ON suppresses row count messages for performance
- No transaction wrapper (unlike write SPs that modify multiple tables)
- The dual-key join (InstanceID + PlanID) provides an extra safety check

**Diagram**:
```
@PlanInstancesUpdate TVP:
  | InstanceID | PlanID | InstanceStatusID | InstanceStatusReasonID |
  |    5001    |  1001  |        3         |          204           |  (Skipped, SoftDecline)
  |    5002    |  1002  |        2         |          300           |  (Cancelled, PlanCancelled)
  |    5003    |  1001  |        1         |          103           |  (Success, OpenPositionSuccess)
        |
        v
  UPDATE PlanInstances SET InstanceStatusID, InstanceStatusReasonID
  WHERE InstanceID + PlanID match
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PlanInstancesUpdate | RecurringInvestment.PlanInstancesTypeUpdateStatus (TVP) | NO | - | VERIFIED | Table-valued parameter containing InstanceID, PlanID, InstanceStatusID, and InstanceStatusReasonID for batch update. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.PlanInstances | Write (UPDATE) | Updates status columns |
| @PlanInstancesUpdate | RecurringInvestment.PlanInstancesTypeUpdateStatus | TVP | Input type for batch updates |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Instance Status Update Service | - | EXEC | Batch-updates instance statuses |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlanInstancesUpdateMultiple (procedure)
├── RecurringInvestment.PlanInstances (table)
└── RecurringInvestment.PlanInstancesTypeUpdateStatus (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | UPDATE via TVP JOIN |
| RecurringInvestment.PlanInstancesTypeUpdateStatus | User Defined Type | TVP parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Instance Status Update Service | Application | Batch status transitions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- SET NOCOUNT ON for performance
- TVP is READONLY
- JOIN on both InstanceID AND PlanID for safety

---

## 8. Sample Queries

### 8.1 Batch-update instance statuses
```sql
DECLARE @TVP RecurringInvestment.PlanInstancesTypeUpdateStatus
INSERT INTO @TVP (InstanceID, PlanID, InstanceStatusID, InstanceStatusReasonID)
VALUES (5001, 1001, 3, 204), (5002, 1002, 2, 300)
EXEC [RecurringInvestment].[PlanInstancesUpdateMultiple] @PlanInstancesUpdate = @TVP
```

### 8.2 Verify updates were applied
```sql
SELECT InstanceID, PlanID, InstanceStatusID, InstanceStatusReasonID
FROM [RecurringInvestment].[PlanInstances] WITH (NOLOCK)
WHERE InstanceID IN (5001, 5002)
```

### 8.3 Check instance status distribution
```sql
SELECT InstanceStatusID, COUNT(*) AS Cnt
FROM [RecurringInvestment].[PlanInstances] WITH (NOLOCK)
WHERE InstanceStatusID IS NOT NULL
GROUP BY InstanceStatusID
ORDER BY InstanceStatusID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | Instance status definitions and lifecycle |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Batch processing architecture |

---

*Generated: 2026-04-13 | Quality: 9.0/10*
*Object: RecurringInvestment.PlanInstancesUpdateMultiple | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlanInstancesUpdateMultiple.sql*
