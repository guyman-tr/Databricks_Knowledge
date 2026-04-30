# History.BSLCurrencyPriceSnapShotsPartition

> Balance Stop Loss currency price snapshot table storing Bid/Ask rates per instrument at the time of each BSL execution run; used to reconstruct exact equity values during BSL audits and verification.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (PriceRateID, ExecutionID, Occurred) - composite PK CLUSTERED |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.BSLCurrencyPriceSnapShotsPartition stores a snapshot of instrument prices (Bid and Ask) at the exact moment of each Balance Stop Loss (BSL) execution run. BSL is eToro's automated equity monitoring system that periodically checks whether customer account equity has fallen below predefined thresholds.

To accurately verify BSL results - for example, when Trade.CheckBSL audits whether the equity warning was correct - the system needs the prices that were in effect at the time of the check, not current prices. This table provides that frozen price state. For every BSL run (ExecutionID), one row per instrument (InstrumentID, PriceRateID) captures the Bid/Ask at that moment.

The "Partition" suffix indicates this replaced History.BSLCurrencyPriceSnapShots as part of a partition-based re-architecture. Trade.CheckBSL explicitly queries History.BSLCurrencyPriceSnapShots (the older non-partition name) for its calculations.

---

## 2. Business Logic

### 2.1 Price Snapshot for BSL Equity Verification

**What**: Each row freezes one instrument's price at one BSL execution, enabling deterministic equity recalculation.

**Columns/Parameters Involved**: `ExecutionID`, `InstrumentID`, `Bid`, `Ask`, `PriceRateID`

**Rules**:
- One row per (PriceRateID, ExecutionID) - one price point per instrument per BSL run
- Trade.CheckBSL uses these prices to compute unrealized PnL: `IsBuy=1 -> uses Bid; IsBuy=0 -> uses Ask`
- GBX (pence) conversion: `@GBX_ConversionRate = Bid/100 FROM prices WHERE InstrumentID = 2`
- Cross-currency conversion is handled using multiple rows from this table joined by currency ID
- The table effectively allows "replay" of BSL equity calculations at any past execution time

---

## 3. Data Overview

The table is empty (0 rows).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExecutionID | int | NO | - | CODE-BACKED | Identifies the BSL execution run. Groups all price snapshots taken during the same BSL check cycle. Corresponds to ExecutionID in Trade.ManageBSL. PK component. |
| 2 | PriceRateID | bigint | NO | - | CODE-BACKED | References the specific price rate record from the instrument pricing system. Provides traceability to the exact price feed entry used. PK component. |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | The financial instrument (stock, crypto, FX pair, index) whose price was snapshotted. Used to join with position data during equity verification. Implicit FK to Trade.Instrument. |
| 4 | Bid | decimal(16,8) | NO | - | CODE-BACKED | Bid (sell) price for the instrument at the BSL execution time. Used for unrealized PnL of long (buy) positions: `UnrealPnL = AmountUnits * (Bid - InitForexRate)`. 8 decimal precision. |
| 5 | Ask | decimal(16,8) | NO | - | CODE-BACKED | Ask (buy) price for the instrument at the BSL execution time. Used for unrealized PnL of short (sell) positions. |
| 6 | Occurred | datetime | NO | getdate() | CODE-BACKED | Server timestamp when the price snapshot was recorded. PK component. Default = getdate(). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ExecutionID | Trade.ManageBSL | Implicit | BSL execution run that captured these prices |
| InstrumentID | Trade.Instrument | Implicit | Instrument whose prices are snapshotted |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CheckBSL | ExecutionID | Reader | Joins on InstrumentID to get Bid/Ask for PnL recalculation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BSLCurrencyPriceSnapShotsPartition (table)
```

---

### 6.1 Objects This Depends On

No hard dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CheckBSL | Stored Procedure | Reads price snapshots to recalculate unrealized PnL for BSL verification |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryBSLCurrencyPriceSnapShotsNEWPartition | CLUSTERED PK | PriceRateID ASC, ExecutionID ASC, Occurred ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryBSLCurrencyPriceSnapShotsNEWPartition | PRIMARY KEY | (PriceRateID, ExecutionID, Occurred) |
| DF_BSLCurrencyPriceSnapShotsPartitionPartition | DEFAULT | Occurred = getdate() |

---

## 8. Sample Queries

### 8.1 Get all price snapshots for a BSL execution
```sql
SELECT ExecutionID, InstrumentID, PriceRateID, Bid, Ask, Occurred
FROM [History].[BSLCurrencyPriceSnapShotsPartition] WITH (NOLOCK)
WHERE ExecutionID = @ExecutionID
ORDER BY InstrumentID
```

### 8.2 Check row count
```sql
SELECT COUNT(*) AS RowCount FROM [History].[BSLCurrencyPriceSnapShotsPartition] WITH (NOLOCK)
```

### 8.3 Find price history for a specific instrument across BSL runs
```sql
SELECT ExecutionID, Bid, Ask, Occurred
FROM [History].[BSLCurrencyPriceSnapShotsPartition] WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
ORDER BY Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.3/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BSLCurrencyPriceSnapShotsPartition | Type: Table | Source: etoro/etoro/History/Tables/History.BSLCurrencyPriceSnapShotsPartition.sql*
