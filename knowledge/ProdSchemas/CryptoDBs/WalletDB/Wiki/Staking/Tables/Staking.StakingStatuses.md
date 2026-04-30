# Staking.StakingStatuses

> Event table recording every status transition in a staking operation's lifecycle, linking each state change to its parent staking record and the corresponding dictionary status.

| Property | Value |
|----------|-------|
| **Schema** | Staking |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Staking.StakingStatuses is the event-sourced audit log for staking operation state transitions. Each row records a single status change for a staking operation - when it entered Pending, when it Completed or Failed, and optionally any detail JSON. Every staking operation created by `Staking.InsertStaking` simultaneously gets its first Pending (1) status row here, and subsequent transitions are written by `Staking.InsertStakingStatus`.

Without this table, there would be no lifecycle tracking for staking operations. It enables determining the current state of any staking (via the latest row per StakingId), historical audit of state changes, and filtering operations by their terminal status. `Staking.GetStakingTotals` joins to this table to filter only Completed (3) operations when calculating totals.

The Staking.StakingData view uses a ROW_NUMBER() OVER (PARTITION BY StakingId ORDER BY Occurred DESC) pattern to extract the latest status per staking record for reporting. Cross-schema functions Wallet.GetStakingTransactionList and GetStakingTransactionListV2 also join here for status resolution. Note: the DetailsJson column exists for extensibility but is currently unused (always NULL across all 4,419 rows).

---

## 2. Business Logic

### 2.1 Event-Sourced Status Pattern

**What**: Status changes are append-only events, never updated in place, enabling full audit trail.

**Columns/Parameters Involved**: `StakingId`, `StakingStatusId`, `Occurred`

**Rules**:
- Each staking operation always has at least 2 status rows: Pending (1) + a terminal status
- Terminal statuses: Completed (3) for success, Failed (2) for error
- 57 operations have 3+ rows (Pending + Failed + Completed), indicating retry-and-succeed patterns
- The "current" status is always the row with the highest Occurred for a given StakingId
- InsertStaking creates the initial Pending status atomically with the staking record in a single transaction
- InsertStakingStatus adds subsequent status transitions, looking up the staking record by CorrelationId

**Diagram**:
```
StakingId=2181 event timeline:
  [Id=4418] Pending   @ 2023-04-05 19:36:42   (created by InsertStaking)
  [Id=4419] Completed @ 2023-04-05 19:40:43   (created by InsertStakingStatus)
            ^-- 4 min processing time
```

### 2.2 Status Distribution (Current State)

**What**: The vast majority of staking operations reach Completed status successfully.

**Columns/Parameters Involved**: `StakingStatusId`

**Rules**:
- 2,181 Pending entries (one per staking operation - always the first status)
- 2,122 Completed entries (97.3% success rate among terminal statuses)
- 116 Failed entries (5.3% of operations encountered at least one failure)
- GetStakingTotals uses WHERE StakingStatusId=3 to include only Completed operations in amount summation

---

## 3. Data Overview

| Id | StakingId | StakingStatusId | StatusName | Occurred | Meaning |
|----|-----------|-----------------|------------|----------|---------|
| 4418 | 2181 | 1 | Pending | 2023-04-05 19:36:42 | Initial status created atomically with staking record by InsertStaking - staking operation submitted |
| 4419 | 2181 | 3 | Completed | 2023-04-05 19:40:43 | Terminal success status - ETH successfully delegated to staking pool after ~4 min blockchain processing |
| 4416 | 2180 | 1 | Pending | 2023-04-04 10:19:59 | Another staking initiated - shows paired Pending/Completed pattern typical of all operations |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing surrogate key. Monotonically increasing, used to establish event ordering when Occurred timestamps collide. |
| 2 | StakingId | bigint | NO | - | VERIFIED | The staking operation this status event belongs to. FK to Staking.Staking.Id. Each staking operation has 2+ status rows (Pending + terminal). Used by StakingData view's ROW_NUMBER() PARTITION for latest-status extraction. |
| 3 | StakingStatusId | tinyint | NO | - | VERIFIED | The status being applied. FK to Dictionary.StakingStatuses.Id: 1=Pending, 2=Failed, 3=Completed. See [Staking Status](../../_glossary.md#staking-status). Filtered by GetStakingTotals (WHERE StakingStatusId=3) for completed-only aggregation. |
| 4 | DetailsJson | varchar(max) | YES | - | CODE-BACKED | Optional JSON payload for status-specific details (e.g., error messages for Failed status). Currently unused - all 4,419 rows have NULL. Column exists for extensibility. |
| 5 | Occurred | datetime2(7) | NO | getutcdate() | VERIFIED | Timestamp of this status transition. Defaults to UTC now. Used by StakingData view to determine the latest status per staking (ORDER BY Occurred DESC in ROW_NUMBER window). The time difference between Pending and Completed Occurred values indicates blockchain processing duration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| StakingId | Staking.Staking | FK | Links this status event to the parent staking operation |
| StakingStatusId | Dictionary.StakingStatuses | FK | Resolves the status ID to its canonical name (Pending/Failed/Completed) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Staking.StakingData | StakingId | JOIN | View extracts latest status per staking via ROW_NUMBER pattern |
| Wallet.GetStakingTransactionList | StakingId | JOIN | Function joins for status resolution in transaction list |
| Wallet.GetStakingTransactionListV2 | StakingId | JOIN | V2 function, same pattern |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Staking.StakingStatuses (table)
  (no code-level dependencies - leaf node)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Staking.Staking | Table | FK target for StakingId |
| Dictionary.StakingStatuses | Table | FK target for StakingStatusId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Staking.StakingData | View | JOIN + ROW_NUMBER to extract latest status per staking |
| Staking.GetStakingTotals | Stored Procedure | READER - filters StakingStatusId=3 for completed-only totals |
| Staking.InsertStaking | Stored Procedure | WRITER - creates initial Pending status with the staking record |
| Staking.InsertStakingStatus | Stored Procedure | WRITER - creates subsequent status transitions |
| Wallet.GetStakingTransactionList | Function | READER - joins for status in transaction list |
| Wallet.GetStakingTransactionListV2 | Function | READER - V2 of transaction list |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PaymentStatuses | CLUSTERED PK | Id ASC | - | - | Active |

Note: The PK constraint is named `PK_PaymentStatuses` (likely a copy-paste artifact from the Wallet.PaymentStatuses table DDL).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_PaymentStatuses | PRIMARY KEY | Clustered on Id, PAGE compression |
| DF_Staking_StakingStatuses__Occurred | DEFAULT | getutcdate() for Occurred |
| FK_Staking_StakingStatuses_StakingId__Staking_Staking_Id | FOREIGN KEY | StakingId -> Staking.Staking.Id |
| FK_Staking_StakingStatuses_StakingStatusId__Dictionary_StakingStatuses_Id | FOREIGN KEY | StakingStatusId -> Dictionary.StakingStatuses.Id |

---

## 8. Sample Queries

### 8.1 Get the current status of a staking operation
```sql
SELECT TOP 1 ss.StakingStatusId, ds.Name AS StatusName, ss.Occurred, ss.DetailsJson
FROM Staking.StakingStatuses ss WITH (NOLOCK)
INNER JOIN Dictionary.StakingStatuses ds WITH (NOLOCK) ON ds.Id = ss.StakingStatusId
WHERE ss.StakingId = @StakingId
ORDER BY ss.Occurred DESC
```

### 8.2 Full status history for a staking operation
```sql
SELECT ss.Id, ds.Name AS Status, ss.Occurred, ss.DetailsJson
FROM Staking.StakingStatuses ss WITH (NOLOCK)
INNER JOIN Dictionary.StakingStatuses ds WITH (NOLOCK) ON ds.Id = ss.StakingStatusId
WHERE ss.StakingId = @StakingId
ORDER BY ss.Occurred ASC
```

### 8.3 Find staking operations still in Pending (no terminal status)
```sql
SELECT s.Id AS StakingId, s.CorrelationId, s.Amount, s.Occurred
FROM Staking.Staking s WITH (NOLOCK)
WHERE NOT EXISTS (
    SELECT 1 FROM Staking.StakingStatuses ss WITH (NOLOCK)
    WHERE ss.StakingId = s.Id AND ss.StakingStatusId IN (2, 3)
)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Staking](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/2022637656/Staking) | Confluence | Staking operations follow Pending->Completed/Failed lifecycle; eToro manages the entire process on behalf of users |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Staking.StakingStatuses | Type: Table | Source: WalletDB/Staking/Tables/Staking.StakingStatuses.sql*
