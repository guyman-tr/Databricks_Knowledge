# History.BSLPositionsInfoPartition

> Partition shard for BSL position tracking data, structurally identical to History.BSLPositionsInfo - records which positions were evaluated per customer per BSL execution run.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (ExecutionID, CID, PositionID, Occurred) - composite PK CLUSTERED |
| **Partition** | Yes - EndMonth scheme, partitioned on Occurred |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.BSLPositionsInfoPartition is a companion shard to History.BSLPositionsInfo. Both tables record the exact set of positions evaluated for each customer during each BSL execution run. The "Partition" suffix indicates this is a separate generation/shard in the same series - used for a different time period or data range, routing specific records away from the primary BSLPositionsInfo table.

All semantics are identical to History.BSLPositionsInfo. See that table's documentation for the full business meaning, BSL system description, and data flow explanation.

---

## 2. Business Logic

See [History.BSLPositionsInfo](History.BSLPositionsInfo.md) - all business logic is identical.

The only structural difference is the PK constraint name (PK_HistoryBSLPositionsInfoNEWPartition vs PK_HistoryBSLPositionsInfoNEW) and the absence of the `DF_BSLPositionsInfo` DEFAULT constraint on Occurred (no DEFAULT defined in this table - Occurred must be provided explicitly).

---

## 3. Data Overview

| ExecutionID | CID | PositionID | PriceRateID | Occurred | Meaning |
|------------|-----|-----------|------------|----------|---------|
| (bigint) | (int) | (bigint) | (bigint) | (datetime) | One active position contributing to a customer's equity check in a BSL run. Same row semantics as History.BSLPositionsInfo. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID. Same semantics as History.BSLPositionsInfo.CID. |
| 2 | ExecutionID | bigint | NO | - | VERIFIED | BSL execution run identifier. Same semantics as History.BSLPositionsInfo.ExecutionID. |
| 3 | PositionID | bigint | NO | - | VERIFIED | Open position included in BSL equity calculation. Same semantics as History.BSLPositionsInfo.PositionID. |
| 4 | PriceRateID | bigint | NO | - | CODE-BACKED | Price rate used for this position's equity calculation. Same semantics as History.BSLPositionsInfo.PriceRateID. |
| 5 | Occurred | datetime | NO | - | CODE-BACKED | Timestamp when this record was created. No DEFAULT defined - must be provided explicitly (vs getdate() default in BSLPositionsInfo). EndMonth partition key. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | History.BSLDataForAllUsers | Implicit | Per-customer equity total for same ExecutionID. |
| PositionID | Trade.PositionTbl / History.Position_Active | Implicit | The open position being evaluated. |
| PriceRateID | History.BSLCurrencyPriceSnapShots | Implicit | Price at execution time for this position. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Routing to this shard is managed by the BSL execution system.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BSLPositionsInfoPartition (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

Not analyzed in this phase. Part of BSLPositionsInfo shard series.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryBSLPositionsInfoNEWPartition | CLUSTERED PK | ExecutionID ASC, CID ASC, PositionID ASC, Occurred ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryBSLPositionsInfoNEWPartition | PRIMARY KEY CLUSTERED | (ExecutionID, CID, PositionID, Occurred), FILLFACTOR=95, DATA_COMPRESSION=PAGE |

---

## 8. Sample Queries

### 8.1 Get all positions in this shard for a customer's BSL evaluation
```sql
SELECT pi.ExecutionID, pi.PositionID, pi.PriceRateID, pi.Occurred
FROM History.BSLPositionsInfoPartition pi WITH (NOLOCK)
WHERE pi.CID = 12345678
ORDER BY pi.Occurred DESC;
```

### 8.2 Cross-shard lookup for a specific execution
```sql
-- Check both shards when the routing is not known
SELECT 'BSLPositionsInfo' AS Shard, ExecutionID, CID, PositionID, Occurred
FROM History.BSLPositionsInfo WITH (NOLOCK) WHERE ExecutionID = 98765 AND CID = 12345678
UNION ALL
SELECT 'Partition', ExecutionID, CID, PositionID, Occurred
FROM History.BSLPositionsInfoPartition WITH (NOLOCK) WHERE ExecutionID = 98765 AND CID = 12345678
ORDER BY Occurred ASC;
```

### 8.3 Check data range in this shard
```sql
SELECT COUNT(*) AS RowCount, MIN(Occurred) AS Earliest, MAX(Occurred) AS Latest
FROM History.BSLPositionsInfoPartition WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 active (routing shard) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BSLPositionsInfoPartition | Type: Table | Source: etoro/etoro/History/Tables/History.BSLPositionsInfoPartition.sql*
