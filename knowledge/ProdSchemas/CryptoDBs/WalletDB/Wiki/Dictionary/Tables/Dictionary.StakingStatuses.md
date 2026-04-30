# Dictionary.StakingStatuses

> Lookup table defining the lifecycle statuses for crypto staking transfer operations in the WalletDB system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.StakingStatuses defines the three possible states of a staking transfer operation - the movement of a user's crypto assets into a staking pool where they earn Proof-of-Stake (PoS) rewards. eToro supports staking for ADA, TRX, SOL, ETH, POL, NEAR, DOT, ATOM, SUI, and AVAX, and executes the staking process on behalf of its users automatically.

Without this table, the system would have no canonical reference for staking operation outcomes. The Staking.StakingStatuses event table uses this dictionary to record each state transition, and views like Staking.StakingData resolve numeric status IDs to human-readable names for reporting and back-office display.

This is a static reference table seeded at deployment. Rows are never inserted or modified at runtime. The three values represent a simple terminal state machine: every staking operation begins as Pending (1), then resolves to either Completed (3) on success or Failed (2) on error. The Staking.InsertStaking procedure sets the initial status to 1 (Pending) when creating a new staking record, and Staking.InsertStakingStatus transitions it to the final state.

---

## 2. Business Logic

### 2.1 Staking Lifecycle State Machine

**What**: Every staking transfer follows a three-state lifecycle from initiation to resolution.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- A staking operation always starts as Pending (1) when Staking.InsertStaking creates the initial record
- The operation transitions to exactly one terminal state: Completed (3) if the blockchain confirms the stake, or Failed (2) if the operation encounters an error
- Staking.InsertStakingStatus writes a new row in Staking.StakingStatuses (the event table) for each transition, referencing this dictionary
- Staking.GetStakingTotals filters only Completed (StakingStatusId=3) records when summing total staked amounts

**Diagram**:
```
  [Pending (1)] ----success----> [Completed (3)]
       |
       +----------failure----> [Failed (2)]
```

---

## 3. Data Overview

| Id | Name | Meaning |
|----|------|---------|
| 1 | Pending | Staking transfer initiated by the system on behalf of the user. Awaiting blockchain confirmation or internal processing completion. This is always the first status recorded when Staking.InsertStaking creates a new staking operation. |
| 2 | Failed | Staking operation could not be completed - blockchain rejection, insufficient balance, or internal error. Terminal state; the staked amount is not locked. |
| 3 | Completed | Assets successfully transferred to the staking pool and locked for PoS reward generation. Used by Staking.GetStakingTotals as the filter for calculating total staked amounts per wallet. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | VERIFIED | Unique identifier for the staking status. Values: 1=Pending, 2=Failed, 3=Completed. Referenced by Staking.StakingStatuses.StakingStatusId via explicit FK. See [Staking Status](../../_glossary.md#staking-status) for full business definitions. |
| 2 | Name | varchar(64) | NO | - | VERIFIED | Human-readable label for the staking status. Resolved via JOIN in Staking.StakingData view and Wallet.GetStakingTransactionList/V2 functions to display status names in reporting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Staking.StakingStatuses | StakingStatusId | FK | Event table recording staking state transitions; each row references this dictionary for the status applied |
| Staking.StakingData | StakingStatusId | JOIN | View resolves status IDs to Names for BI/back-office reporting via LEFT JOIN to this dictionary |
| Wallet.GetStakingTransactionList | StakingStatusId | JOIN | Function joins to this dictionary to include status name in staking transaction result sets |
| Wallet.GetStakingTransactionListV2 | StakingStatusId | JOIN | V2 of the function, same JOIN pattern as V1 |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Staking.StakingStatuses | Table | FK constraint on StakingStatusId referencing Dictionary.StakingStatuses.Id |
| Staking.StakingData | View | LEFT JOIN to resolve StakingStatusId to Name for display |
| Wallet.GetStakingTransactionList | Function | JOIN to resolve status names in transaction list output |
| Wallet.GetStakingTransactionListV2 | Function | JOIN to resolve status names in V2 transaction list output |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_StakingStatuses | CLUSTERED PK | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_StakingStatuses | PRIMARY KEY | Ensures each staking status has a unique tinyint identifier |

---

## 8. Sample Queries

### 8.1 List all staking statuses
```sql
SELECT Id, Name
FROM Dictionary.StakingStatuses WITH (NOLOCK)
ORDER BY Id
```

### 8.2 Get the latest status for each staking operation
```sql
SELECT s.Id AS StakingId,
       s.CorrelationId,
       ds.Name AS CurrentStatus,
       ss.Occurred AS StatusDate
FROM Staking.Staking s WITH (NOLOCK)
INNER JOIN (
    SELECT StakingId, StakingStatusId, Occurred,
           ROW_NUMBER() OVER (PARTITION BY StakingId ORDER BY Occurred DESC) AS rn
    FROM Staking.StakingStatuses WITH (NOLOCK)
) ss ON ss.StakingId = s.Id AND ss.rn = 1
INNER JOIN Dictionary.StakingStatuses ds WITH (NOLOCK) ON ds.Id = ss.StakingStatusId
```

### 8.3 Count staking operations by status
```sql
SELECT ds.Name AS StatusName, COUNT(*) AS OperationCount
FROM Staking.StakingStatuses ss WITH (NOLOCK)
INNER JOIN Dictionary.StakingStatuses ds WITH (NOLOCK) ON ds.Id = ss.StakingStatusId
INNER JOIN (
    SELECT StakingId, MAX(Id) AS LatestStatusId
    FROM Staking.StakingStatuses WITH (NOLOCK)
    GROUP BY StakingId
) latest ON latest.LatestStatusId = ss.Id
GROUP BY ds.Name
ORDER BY OperationCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Staking](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/2022637656/Staking) | Confluence | Staking is PoS-based reward mechanism; eToro executes on behalf of users; supports ADA, TRX, SOL, ETH, POL, NEAR, DOT, ATOM, SUI, AVAX; rewards distributed monthly as position airdrops or cash compensation; eligibility requires real (non-CFD) positions with intro day waiting period |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.3/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.StakingStatuses | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.StakingStatuses.sql*
