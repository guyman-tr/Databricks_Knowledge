# Staking.InsertStakingStatus

> Adds a new status transition event to a staking operation, looked up by CorrelationId.

| Property | Value |
|----------|-------|
| **Schema** | Staking |
| **Object Type** | Stored Procedure |
| **Key Identifier** | WRITER for Staking.StakingStatuses |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure transitions a staking operation to a new status (typically from Pending to Completed or Failed). It locates the staking record by CorrelationId (not by StakingId directly) and inserts a new row in Staking.StakingStatuses with the specified status.

Called by the staking service when blockchain confirmation is received (Completed) or when an error occurs (Failed). The CorrelationId-based lookup is consistent with how the application service tracks staking operations.

---

## 2. Business Logic

### 2.1 Status Transition via CorrelationId

**What**: Adds a status event to a staking operation using the CorrelationId as the lookup key.

**Columns/Parameters Involved**: `@CorrelationId`, `@StakingStatusId`

**Rules**:
- Looks up Staking.Staking.Id WHERE CorrelationId = @CorrelationId
- Inserts into StakingStatuses (StakingId, StakingStatusId) using the resolved Id
- No validation that the status transition is valid (e.g., does not check that current status is Pending before setting Completed)
- If CorrelationId is not found, the INSERT produces no rows (silent no-op)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | uniqueidentifier (IN) | NO | - | VERIFIED | The idempotency key of the staking operation to transition. Used to look up Staking.Staking.Id. |
| 2 | @StakingStatusId | tinyint (IN) | NO | - | VERIFIED | The new status to apply. Values: 1=Pending, 2=Failed, 3=Completed. FK to Dictionary.StakingStatuses.Id. See [Staking Status](../../_glossary.md#staking-status). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Staking.Staking | SELECT | Looks up StakingId by CorrelationId |
| - | Staking.StakingStatuses | INSERT | Creates the new status event row |

### 5.2 Referenced By (other objects point to this)

Called by the staking service for status transitions.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Staking.InsertStakingStatus (procedure)
+-- Staking.Staking (table)
+-- Staking.StakingStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Staking.Staking | Table | SELECT - CorrelationId to Id lookup |
| Staking.StakingStatuses | Table | INSERT - creates status event |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Transition a staking to Completed
```sql
EXEC Staking.InsertStakingStatus
    @CorrelationId = 'A2397984-2E2F-4BEB-9CCB-CF93D206F8DC',
    @StakingStatusId = 3
```

### 8.2 Verify the status was applied
```sql
SELECT ss.StakingStatusId, ds.Name, ss.Occurred
FROM Staking.StakingStatuses ss WITH (NOLOCK)
INNER JOIN Dictionary.StakingStatuses ds WITH (NOLOCK) ON ds.Id = ss.StakingStatusId
INNER JOIN Staking.Staking s WITH (NOLOCK) ON s.Id = ss.StakingId
WHERE s.CorrelationId = 'A2397984-2E2F-4BEB-9CCB-CF93D206F8DC'
ORDER BY ss.Occurred DESC
```

### 8.3 Find stakings in a specific status
```sql
SELECT s.Id, s.CorrelationId, s.Amount, ds.Name AS LatestStatus
FROM Staking.Staking s WITH (NOLOCK)
CROSS APPLY (
    SELECT TOP 1 ss.StakingStatusId
    FROM Staking.StakingStatuses ss WITH (NOLOCK)
    WHERE ss.StakingId = s.Id ORDER BY ss.Occurred DESC
) latest
INNER JOIN Dictionary.StakingStatuses ds WITH (NOLOCK) ON ds.Id = latest.StakingStatusId
WHERE ds.Name = 'Pending'
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Staking](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/2022637656/Staking) | Confluence | Staking follows Pending->Completed/Failed lifecycle |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Staking.InsertStakingStatus | Type: Stored Procedure | Source: WalletDB/Staking/Stored Procedures/Staking.InsertStakingStatus.sql*
