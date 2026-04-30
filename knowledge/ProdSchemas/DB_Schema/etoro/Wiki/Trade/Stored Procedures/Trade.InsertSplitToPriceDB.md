# Trade.InsertSplitToPriceDB

> Syncs a stock-split ratio record from the etoro History schema to the remote Price database by deleting all existing split ratios for the affected instrument and reinserting them from the canonical source.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @SplitID - ID of the split record in History.SplitRatio |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertSplitToPriceDB is the data-sync procedure that propagates stock split ratio data from the eToro trading database to the Price database (remote server `AO-PRICE-LSN-RW`, Price catalog). The Price database is a separate service used for real-time and historical pricing calculations. When a stock split is processed, the split ratio (the factor by which the price and position sizes are adjusted) must be available in both the trade DB and the pricing service. This procedure ensures the pricing side stays in sync.

Without this procedure, the Price DB would operate with stale or missing split ratio data, causing incorrect price adjustments and potentially wrong position valuations during split events. The History.SplitRatio table is the authoritative master of split events; this procedure replicates a specific instrument's complete set of splits to the Price DB side.

Data flow: When a new split record is entered or modified in History.SplitRatio, this procedure is called with the @SplitID of the new/changed record. It resolves the InstrumentID, then replaces ALL PriceSplitRatio rows for that instrument in the Price DB with the current data from History.SplitRatio. The operation is transactional - DELETE and INSERT are in a single transaction with rollback on failure.

---

## 2. Business Logic

### 2.1 Full Replace (Delete + Insert) Sync Pattern

**What**: The procedure does NOT upsert individual rows - it replaces the complete split ratio dataset for an instrument in the Price DB on every call.

**Columns/Parameters Involved**: `@SplitID`, `@InstrumentID` (internal)

**Rules**:
- The @SplitID is used only to identify which instrument to resync - the procedure resyncs ALL splits for that instrument, not just the one split record identified by @SplitID.
- DELETE first, then INSERT all: guarantees no orphaned or stale splits in PriceDB for the instrument.
- If History.SplitRatio has no rows for the instrument after the DELETE, RAISERROR is raised and the transaction is rolled back (PriceDB returns to pre-delete state).
- XACT_ABORT ON ensures any error automatically rolls back the transaction, even without the explicit ROLLBACK in the CATCH block.

**Diagram**:
```
@SplitID
    |
    v
SELECT InstrumentID FROM History.SplitRatio WHERE ID = @SplitID
    |
    v
BEGIN TRAN
    |
    +-> DELETE FROM dbo.PriceSplitRatio (->AO-PRICE-LSN-RW.Price.History.SplitRatio)
    |       WHERE InstrumentID = @InstrumentID
    |
    +-> INSERT INTO dbo.PriceSplitRatio
    |       SELECT (12 columns) FROM History.SplitRatio
    |       WHERE InstrumentID = @InstrumentID
    |
    +-> IF @@ROWCOUNT = 0 -> RAISERROR -> ROLLBACK (no splits for instrument)
    |
COMMIT
```

### 2.2 Column Subset Sync

**What**: The procedure syncs a specific subset of columns from History.SplitRatio to the Price DB. Not all columns are transferred.

**Columns/Parameters Involved**: ID, InstrumentID, MinDate, MaxDate, PriceRatio, AmountRatio, IsCompletedOpenPositions, IsCompletedClosePositions, IsCompletedOpenOrders, IsCompletedCloseOrders, PriceRatioUnAdjusted, AmountRatioUnAdjusted

**Rules**:
- Columns transferred are those needed by the pricing engine: the date range, the adjustment ratios, the completion flags (so the Price DB knows which positions/orders have been adjusted), and the unadjusted ratio baselines.
- Columns NOT transferred include: IsNotificationSent, IsCurrencyPriceChanged, IsRedisUpdated, temporal system columns (SysStartTime/SysEndTime), audit columns (DbLoginName, AppLoginName, HostName), and the high-precision ratio variants (PriceRatioUnAdjustedFull, AmountRatioUnAdjustedFull).
- History.SplitRatio has a check constraint ensuring InstrumentID > 1000 (splits only apply to stocks with IDs above 1000).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SplitID | int | NO | - | CODE-BACKED | ID of the split record in History.SplitRatio that triggered this sync call. Used only to resolve the InstrumentID - the procedure then resyncs ALL splits for that instrument, not just this one row. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SplitID lookup | History.SplitRatio | Reader | Resolves InstrumentID from the split ID; then reads all splits for that instrument as the INSERT source. |
| DELETE + INSERT target | dbo.PriceSplitRatio (synonym -> AO-PRICE-LSN-RW.Price.History.SplitRatio) | Writer (Delete+Insert) | Remote Price DB table. Receives the full sync of split data via linked server synonym. |

### 5.2 Referenced By (other objects point to this)

Not discovered in SQL codebase - called from external tooling or permissions-granted BI admin accounts (PROD_BIadmins.sql references it for EXECUTE permission grant).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertSplitToPriceDB (procedure)
├── History.SplitRatio (table) - reads split ratios; source for INSERT
└── dbo.PriceSplitRatio (synonym -> AO-PRICE-LSN-RW.Price.History.SplitRatio) - DELETE + INSERT target in remote Price DB
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.SplitRatio | Table | Reads InstrumentID and all split rows for the instrument; source for the INSERT into PriceDB |
| dbo.PriceSplitRatio | Synonym | DELETE target (purge existing splits for instrument) and INSERT target (write new splits). Points to AO-PRICE-LSN-RW.Price.History.SplitRatio via linked server |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins (permissions) | Security | EXECUTE permission granted to BI admin role |
| External tooling / split processing pipeline | External | Calls this procedure after inserting/modifying a split in History.SplitRatio |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET XACT_ABORT ON | Session setting | Any statement error immediately rolls back the transaction - no partial commits possible |
| RAISERROR on 0 rows | Runtime guard | If no rows are found in History.SplitRatio for the instrument, the procedure raises a severity-16 error and rolls back, preventing an empty PriceSplitRatio state for the instrument |

---

## 8. Sample Queries

### 8.1 Sync splits for a specific split record

```sql
-- Syncs ALL splits for the instrument identified by SplitID = 1234
EXEC Trade.InsertSplitToPriceDB @SplitID = 1234;
```

### 8.2 Find which instrument a split ID belongs to before syncing

```sql
SELECT
    sr.ID,
    sr.InstrumentID,
    sr.MinDate,
    sr.MaxDate,
    sr.PriceRatio,
    sr.AmountRatio
FROM History.SplitRatio sr WITH (NOLOCK)
WHERE sr.ID = 1234;
```

### 8.3 Verify current split ratio state in History for an instrument

```sql
SELECT
    sr.ID,
    sr.InstrumentID,
    sr.MinDate,
    sr.MaxDate,
    sr.PriceRatio,
    sr.AmountRatio,
    sr.IsCompletedOpenPositions,
    sr.IsCompletedClosePositions,
    sr.IsCompletedOpenOrders,
    sr.IsCompletedCloseOrders,
    sr.PriceRatioUnAdjusted,
    sr.AmountRatioUnAdjusted
FROM History.SplitRatio sr WITH (NOLOCK)
WHERE sr.InstrumentID = @InstrumentID
ORDER BY sr.MinDate;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.InsertSplitToPriceDB | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertSplitToPriceDB.sql*
