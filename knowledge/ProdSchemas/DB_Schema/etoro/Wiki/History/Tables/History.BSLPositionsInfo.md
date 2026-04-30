# History.BSLPositionsInfo

> Active BSL position tracking table recording which specific positions were evaluated for each customer in each BSL execution run, enabling per-position equity audit reconstruction.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (ExecutionID, CID, PositionID, Occurred) - composite PK CLUSTERED |
| **Partition** | Yes - EndMonth scheme, partitioned on Occurred |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.BSLPositionsInfo records the exact set of positions evaluated for each customer during each Balance Stop Loss (BSL) execution run. While History.BSLCurrencyPriceSnapShots captures instrument prices and History.BSLDataForAllUsers captures per-customer equity totals, this table provides the position-level detail: exactly which positions contributed to a customer's equity calculation in a given BSL run.

For each BSL execution (ExecutionID), each customer's active positions are recorded with the price rate used for that position's equity calculation. This enables full audit traceability: if a BSL warning or account closure is disputed, analysts can retrieve the exact positions included in the calculation and verify the equity using the price rates from History.BSLCurrencyPriceSnapShots.

This is an **active, continuously-written** table. The synonym `dbo.RW_BSLPositionsInfo` points to this table on [AO-REAL-DB] (Always On secondary) for read-scale access. History.BSLPositionsInfoPartition is a companion shard with identical structure.

---

## 2. Business Logic

### 2.1 Position Set per BSL Execution

**What**: Each row records one position included in one customer's BSL equity calculation.

**Columns/Parameters Involved**: `ExecutionID`, `CID`, `PositionID`, `PriceRateID`, `Occurred`

**Rules**:
- One row per (ExecutionID, CID, PositionID) - unique within each BSL run
- All rows for a customer in one execution have the same Occurred timestamp (batch inserted at run time)
- PriceRateID links to the specific price rate used for this position's equity calculation, which resolves to a row in History.BSLCurrencyPriceSnapShots
- A customer's total unrealized equity = sum of position PnL across all their rows for this ExecutionID
- Trade.InsertBSLMessagesIntoQueue and Trade.CheckBSL use this data for position-level equity breakdown

---

## 3. Data Overview

| ExecutionID | CID | PositionID | PriceRateID | Occurred | Meaning |
|------------|-----|-----------|------------|----------|---------|
| (bigint) | (int) | (bigint) | (bigint) | (datetime) | One active position contributing to a customer's equity check in a BSL run. All positions for the same customer+execution have the same Occurred timestamp. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID whose account this position belongs to. Groups all positions evaluated for a customer in one BSL run. |
| 2 | ExecutionID | bigint | NO | - | VERIFIED | BSL execution run identifier. Links to History.BSLDataForAllUsers.ExecutionID and Trade.ManageBSL. Groups all positions across all customers for a single BSL cycle. bigint for high run volume. |
| 3 | PositionID | bigint | NO | - | VERIFIED | The specific open position included in the equity calculation. bigint to match trade position table key type. Implicit FK to Trade.PositionTbl/History.Position_Active. |
| 4 | PriceRateID | bigint | NO | - | CODE-BACKED | The price rate used for this position's equity calculation. Resolves to a row in History.BSLCurrencyPriceSnapShots (same ExecutionID). Enables per-position equity reconstruction by joining with the price snapshot. |
| 5 | Occurred | datetime | NO | getdate() | CODE-BACKED | Server timestamp when this BSL position record was created. Default = getdate() (local server time). PK component and EndMonth partition key. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | History.BSLDataForAllUsers | Implicit | Per-customer equity total for same ExecutionID. |
| ExecutionID | Trade.ManageBSL | Implicit | BSL execution that generated these position records. |
| PositionID | Trade.PositionTbl / History.Position_Active | Implicit | The open position being evaluated. |
| PriceRateID | History.BSLCurrencyPriceSnapShots | Implicit | Price used for this position's equity calculation at this execution. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InsertBSLMessagesIntoQueue | ExecutionID, CID | Writer | Writes position set for each BSL run. |
| Trade.CheckBSL | ExecutionID, CID | Writer/Reader | Manages BSL execution and reads position data for verification. |
| dbo.RW_BSLPositionsInfo | (synonym) | Linked Server | Synonym on AO-REAL-DB pointing to this table for read-scale access. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BSLPositionsInfo (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertBSLMessagesIntoQueue | Stored Procedure | Writer - records positions in each BSL run |
| Trade.CheckBSL | Stored Procedure | Writer/Reader - BSL execution and verification |
| dbo.RW_BSLPositionsInfo | Synonym | Linked server alias for AO secondary access |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryBSLPositionsInfoNEW | CLUSTERED PK | ExecutionID ASC, CID ASC, PositionID ASC, Occurred ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryBSLPositionsInfoNEW | PRIMARY KEY CLUSTERED | (ExecutionID, CID, PositionID, Occurred), FILLFACTOR=95, DATA_COMPRESSION=PAGE |
| DF_BSLPositionsInfo | DEFAULT | Occurred = getdate() |

---

## 8. Sample Queries

### 8.1 Get all positions included in a customer's BSL evaluation
```sql
SELECT pi.ExecutionID, pi.PositionID, pi.PriceRateID, pi.Occurred
FROM History.BSLPositionsInfo pi WITH (NOLOCK)
WHERE pi.CID = 12345678
  AND pi.ExecutionID = 98765
ORDER BY pi.PositionID;
```

### 8.2 Reconstruct equity for a customer using position data and price snapshots
```sql
SELECT
    pi.PositionID,
    pi.PriceRateID,
    ps.InstrumentID,
    ps.Bid,
    ps.Ask
FROM History.BSLPositionsInfo pi WITH (NOLOCK)
INNER JOIN History.BSLCurrencyPriceSnapShots ps WITH (NOLOCK)
    ON pi.PriceRateID = ps.PriceRateID
    AND pi.ExecutionID = ps.ExecutionID
WHERE pi.CID = 12345678
  AND pi.ExecutionID = 98765;
```

### 8.3 Count positions per customer for a given BSL run
```sql
SELECT pi.CID, COUNT(pi.PositionID) AS PositionCount
FROM History.BSLPositionsInfo pi WITH (NOLOCK)
WHERE pi.ExecutionID = 98765
GROUP BY pi.CID
ORDER BY PositionCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BSLPositionsInfo | Type: Table | Source: etoro/etoro/History/Tables/History.BSLPositionsInfo.sql*
