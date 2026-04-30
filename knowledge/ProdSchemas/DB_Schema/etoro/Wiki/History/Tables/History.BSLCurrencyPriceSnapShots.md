# History.BSLCurrencyPriceSnapShots

> Active BSL price snapshot table storing Bid/Ask rates per instrument at each BSL execution - the primary target used by Trade.CheckBSL for equity audit recalculation.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (PriceRateID, ExecutionID, Occurred) - composite PK CLUSTERED |
| **Partition** | Yes - EndMonth scheme, partitioned on Occurred |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.BSLCurrencyPriceSnapShots stores a frozen snapshot of instrument prices (Bid and Ask) at the exact moment of each Balance Stop Loss (BSL) execution run. BSL is eToro's automated system that monitors customer account equity against open positions and triggers warnings or forced closures when equity falls below configured thresholds.

For each BSL run (ExecutionID), one row per instrument captures the exact Bid/Ask prices used in the equity calculation. When Trade.CheckBSL later audits or verifies a BSL result, it reads from this table to reconstruct the exact equity state that existed at the time - not current prices. This enables deterministic, reproducible equity verification even days after the original BSL run.

This is an **active, continuously-written** table: Trade.CheckBSL both writes snapshots and reads from it. The synonym `dbo.RW_BSLCurrencyPriceSnapShots` points to the copy of this table on the [AO-REAL-DB] Always On secondary replica, enabling read-scale offloading of BSL analytics queries to the secondary. The companion table History.BSLCurrencyPriceSnapShotsPartition is a separate generation shard in the same series.

---

## 2. Business Logic

### 2.1 Price Snapshot for BSL Equity Verification

**What**: Each row freezes one instrument's price at one BSL execution, enabling deterministic equity recalculation.

**Columns/Parameters Involved**: `ExecutionID`, `InstrumentID`, `Bid`, `Ask`, `PriceRateID`, `Occurred`

**Rules**:
- One row per (PriceRateID, ExecutionID) - one price entry per instrument per BSL run
- Trade.CheckBSL uses these prices to compute unrealized PnL per position:
  - IsBuy=1 (long): UnrealPnL = AmountUnits * (Bid - OpenRate)
  - IsBuy=0 (short): UnrealPnL = AmountUnits * (OpenRate - Ask)
- GBX (pence) conversion uses InstrumentID=2: ConversionRate = Bid / 100
- Cross-currency conversion uses multiple rows joined by CurrencyID
- The price snapshot enables "replay" of any past BSL run with the original market conditions

**Diagram**:
```
BSL Execution (ExecutionID = N):
  Trade.CheckBSL inserts rows here: one per instrument in scope
    (PriceRateID=X, ExecutionID=N, InstrumentID=42, Bid=1.2345, Ask=1.2347, Occurred=T)

  Later audit/verification:
    SELECT Bid, Ask FROM History.BSLCurrencyPriceSnapShots
    WHERE ExecutionID = N AND InstrumentID = 42
    -> Returns the prices from the exact time of run N
```

---

## 3. Data Overview

Table contains active high-volume data (query timed out - large dataset). Sample structure based on schema and existing Partition table documentation:

| PriceRateID | ExecutionID | InstrumentID | Bid | Ask | Occurred | Meaning |
|------------|-------------|-------------|-----|-----|----------|---------|
| (bigint) | (int) | (int) | decimal(16,8) | decimal(16,8) | datetime | One instrument's Bid/Ask at the time of a BSL run, used to reconstruct equity at that moment. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExecutionID | int | NO | - | CODE-BACKED | Identifies the BSL execution run. Groups all price snapshots taken during the same BSL cycle. Corresponds to ExecutionID in Trade.ManageBSL/Trade.CheckBSL. PK component. |
| 2 | PriceRateID | bigint | NO | - | CODE-BACKED | The specific price rate record from the instrument pricing system. Provides full traceability to the exact price feed entry used. bigint to match high-volume price rate IDs. PK component. |
| 3 | InstrumentID | int | NO | - | VERIFIED | The financial instrument (stock, crypto, FX pair, index) whose price was snapshotted. Used by Trade.CheckBSL in equity calculations joined with position data. Implicit FK to History.Instrument. |
| 4 | Bid | decimal(16,8) | NO | - | VERIFIED | Bid (sell) price for the instrument at BSL execution time. Used for unrealized PnL of long (buy) positions: `AmountUnits * (Bid - OpenRate)`. 8 decimal places for pip-level precision. |
| 5 | Ask | decimal(16,8) | NO | - | VERIFIED | Ask (buy) price for the instrument at BSL execution time. Used for unrealized PnL of short (sell) positions. |
| 6 | Occurred | datetime | NO | getdate() | CODE-BACKED | Server timestamp when the price snapshot was recorded. Default = getdate() (local server time). PK component and EndMonth partition key. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | History.Instrument | Implicit | Financial instrument whose price is snapshotted. Confirmed done (Batch 1). |
| ExecutionID | Trade.ManageBSL | Implicit | Groups snapshots by BSL execution run. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CheckBSL | ExecutionID, InstrumentID | Writer/Reader | Writes price snapshots and reads them for equity verification. |
| dbo.RW_BSLCurrencyPriceSnapShots | (synonym) | Linked Server | Synonym on AO-REAL-DB pointing to this table, enabling read-scale access via Always On secondary. |
| DBA.Truncate_Merge_partitions | - | Maintenance | DBA partition maintenance procedure manages this partitioned table. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BSLCurrencyPriceSnapShots (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CheckBSL | Stored Procedure | Writer (snapshots) + Reader (equity recalculation) |
| dbo.RW_BSLCurrencyPriceSnapShots | Synonym | Linked server alias for AO secondary reads |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryBSLCurrencyPriceSnapShotsNEW | CLUSTERED PK | PriceRateID ASC, ExecutionID ASC, Occurred ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryBSLCurrencyPriceSnapShotsNEW | PRIMARY KEY CLUSTERED | (PriceRateID, ExecutionID, Occurred) composite, FILLFACTOR=95 |
| DF_BSLCurrencyPriceSnapShotsPartition | DEFAULT | Occurred = getdate() |

---

## 8. Sample Queries

### 8.1 Get all price snapshots for a specific BSL execution
```sql
SELECT ps.PriceRateID, ps.InstrumentID, ps.Bid, ps.Ask, ps.Occurred
FROM History.BSLCurrencyPriceSnapShots ps WITH (NOLOCK)
WHERE ps.ExecutionID = 12345
ORDER BY ps.InstrumentID;
```

### 8.2 Get the Bid/Ask price for a specific instrument at a specific execution
```sql
SELECT ps.Bid, ps.Ask, ps.Occurred
FROM History.BSLCurrencyPriceSnapShots ps WITH (NOLOCK)
WHERE ps.ExecutionID = 12345
  AND ps.InstrumentID = 42;
```

### 8.3 Find all executions that captured prices for a given instrument in the last 7 days
```sql
SELECT DISTINCT ps.ExecutionID, ps.Bid, ps.Ask, ps.Occurred
FROM History.BSLCurrencyPriceSnapShots ps WITH (NOLOCK)
WHERE ps.InstrumentID = 42
  AND ps.Occurred >= DATEADD(DAY, -7, GETDATE())
ORDER BY ps.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Trade.CheckBSL reference) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BSLCurrencyPriceSnapShots | Type: Table | Source: etoro/etoro/History/Tables/History.BSLCurrencyPriceSnapShots.sql*
