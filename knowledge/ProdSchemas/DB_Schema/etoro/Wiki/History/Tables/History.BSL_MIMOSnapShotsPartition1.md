# History.BSL_MIMOSnapShotsPartition1

> Shard 1 of the BSL MIMO (Balance Stop Loss Multi-Instrument Multi-Order) equity snapshot series, structurally identical to History.BSL_MIMOSnapShotsPartition but without an IDENTITY column - IDs are supplied externally by the routing system.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (ID, Occurred) - composite PK CLUSTERED |
| **Partition** | Yes - EndMonth scheme, partitioned on Occurred |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.BSL_MIMOSnapShotsPartition1 is one of the horizontal shards in the BSL MIMO snapshot series, alongside History.BSL_MIMOSnapShotsOld and History.BSL_MIMOSnapShotsPartition. All three tables store point-in-time snapshots of MIMO (Multi-Instrument Multi-Order) credit calculations captured during Balance Stop Loss (BSL) equity monitoring runs.

The "Partition1" name indicates this is the second generation partition shard (shard index 1 in a 0-based scheme, or generation 1 following "Partition"). Unlike the Old and Partition tables which have IDENTITY columns, this table has plain bigint ID - IDs are provided by the inserting process, enabling multi-table routing where IDs can be allocated from a shared sequence and distributed across shards without identity conflicts.

The BSL MIMO snapshot series collectively stores all historical equity check data for eToro's account-level risk management system. See [History.BSL_MIMOSnapShotsPartition](History.BSL_MIMOSnapShotsPartition.md) for the full BSL system description.

---

## 2. Business Logic

### 2.1 BSL Snapshot Pattern (Shard)

See [History.BSL_MIMOSnapShotsPartition](History.BSL_MIMOSnapShotsPartition.md) Section 2.1 for the full BSL execution snapshot pattern - identical logic applies to all shards.

**Key distinction from other shards**: No IDENTITY column - the routing/orchestration layer assigns the ID before inserting, which is the mechanism that enables cross-shard ID uniqueness.

---

## 3. Data Overview

| ID | MimoCreditID | PositionID | Bid | Ask | Occurred | Meaning |
|----|-------------|-----------|-----|-----|----------|---------|
| (partition shard) | - | - | - | - | - | Rows contain BSL MIMO snapshots routed to this specific shard. Identical row semantics to History.BSL_MIMOSnapShotsPartition. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | - | CODE-BACKED | Externally-supplied surrogate key. Unlike the Old/Partition shards, no IDENTITY - the calling process assigns this value. Enables cross-shard ID coordination from a shared sequence. PK component with Occurred. |
| 2 | MimoCreditID | bigint | NO | - | CODE-BACKED | MIMO credit calculation active for this position at snapshot time. Same semantics as History.BSL_MIMOSnapShotsPartition.MimoCreditID. |
| 3 | BSLChangeCreditID | bigint | NO | - | CODE-BACKED | Credit change event that triggered this snapshot. Same semantics as History.BSL_MIMOSnapShotsPartition.BSLChangeCreditID. |
| 4 | PositionID | int | NO | - | CODE-BACKED | Trading position evaluated in this BSL snapshot. Same semantics as History.BSL_MIMOSnapShotsPartition.PositionID. |
| 5 | PriceRateID | bigint | NO | - | CODE-BACKED | Price rate used for equity calculation. Same semantics as History.BSL_MIMOSnapShotsPartition.PriceRateID. |
| 6 | Bid | decimal(16,8) | NO | - | CODE-BACKED | Instrument bid price at snapshot time. Same semantics as History.BSL_MIMOSnapShotsPartition.Bid. |
| 7 | Ask | decimal(16,8) | NO | - | CODE-BACKED | Instrument ask price at snapshot time. Same semantics as History.BSL_MIMOSnapShotsPartition.Ask. |
| 8 | Occurred | datetime | NO | getdate() | CODE-BACKED | Server timestamp when snapshot was recorded. Default = getdate(). PK component and EndMonth partition key. Same semantics as History.BSL_MIMOSnapShotsPartition.Occurred. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MimoCreditID | History.ActiveCredit (CreditID) | Implicit | MIMO credit event active at snapshot time |
| PositionID | Trade.PositionTbl / History.Position | Implicit | Position evaluated in this BSL snapshot |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. This shard is part of the BSL MIMO series routed by the BSL orchestration logic.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BSL_MIMOSnapShotsPartition1 (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

Not analyzed in this phase. Routing to this shard is managed by the BSL execution system.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryBSLMIMOSnapShots_new1 | CLUSTERED PK | ID ASC, Occurred ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryBSLMIMOSnapShots_new1 | PRIMARY KEY CLUSTERED | (ID, Occurred) composite, FILLFACTOR=95 |
| DF_BSL_MIMOSnapShotsNEW1 | DEFAULT | Occurred = getdate() |

---

## 8. Sample Queries

### 8.1 Get MIMO snapshots from shard 1
```sql
SELECT ID, MimoCreditID, BSLChangeCreditID, PositionID, PriceRateID, Bid, Ask, Occurred
FROM History.BSL_MIMOSnapShotsPartition1 WITH (NOLOCK)
WHERE PositionID = 12345678
ORDER BY Occurred DESC;
```

### 8.2 Check data range in this shard
```sql
SELECT COUNT(*) AS RowCount, MIN(Occurred) AS Earliest, MAX(Occurred) AS Latest
FROM History.BSL_MIMOSnapShotsPartition1 WITH (NOLOCK);
```

### 8.3 Cross-shard lookup - find which shard holds a specific MIMO credit
```sql
-- Check all three shards for a specific MimoCreditID
SELECT 'Old' AS Shard, ID, PositionID, Bid, Ask, Occurred
FROM History.BSL_MIMOSnapShotsOld WITH (NOLOCK) WHERE MimoCreditID = 123456789
UNION ALL
SELECT 'Partition', ID, PositionID, Bid, Ask, Occurred
FROM History.BSL_MIMOSnapShotsPartition WITH (NOLOCK) WHERE MimoCreditID = 123456789
UNION ALL
SELECT 'Partition1', ID, PositionID, Bid, Ask, Occurred
FROM History.BSL_MIMOSnapShotsPartition1 WITH (NOLOCK) WHERE MimoCreditID = 123456789
ORDER BY Occurred ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.0/10 (Elements: 9.0/10, Logic: 7.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BSL_MIMOSnapShotsPartition1 | Type: Table | Source: etoro/etoro/History/Tables/History.BSL_MIMOSnapShotsPartition1.sql*
