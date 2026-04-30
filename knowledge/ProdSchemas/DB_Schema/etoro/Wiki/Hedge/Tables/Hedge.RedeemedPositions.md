# Hedge.RedeemedPositions

> Per-instrument, per-server snapshot of the current redeemed (partially/fully closed) position amount. One row per (InstrumentID, HedgeServerID), replaced atomically via DELETE+INSERT. PersistID (IDENTITY) acts as a version counter returned to callers for data freshness validation.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | (InstrumentID, HedgeServerID) - composite CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK only) |

---

## 1. Business Meaning

Hedge.RedeemedPositions tracks the cumulative amount of hedge positions that have been redeemed (returned/closed) per instrument per hedge server. When eToro customers close their positions, the hedge system must unwind the corresponding hedge positions with the LP. This table stores the current redeemed amount as the hedge server processes these position closures.

The table holds exactly ONE row per (InstrumentID, HedgeServerID) at any given time. Unlike an append log, each update completely replaces the prior record using a DELETE+INSERT pattern inside a transaction. The IDENTITY column `PersistID` is NOT the PK - it increments with each replacement and is returned to callers as a version/generation identifier for data correlation.

Key design differentiators from companion tables:
- No IsBuy column: redeemed amounts are direction-agnostic (magnitude of closure, not direction)
- `LastDataID` is varchar(100) (not int): allows string-based batch/correlation IDs vs integer sequence IDs in PositionsHedgeTbl
- `AmountInUnits` uses decimal(18,8): higher precision than PositionsHedgeTbl (16,6) - supports fractional unit precision for small-denomination instruments

The table is currently empty (0 rows) - either no redemptions are currently in progress, or the data was cleared as part of a refresh cycle.

---

## 2. Business Logic

### 2.1 Atomic Replace Pattern (DELETE + INSERT in Transaction)

**What**: `UpdateRedeemedPositions` always deletes the existing row and inserts a new row within a single transaction, producing a new PersistID each time.

**Columns/Parameters Involved**: All columns

**Rules**:
- Step 1 (within BEGIN TRAN): DELETE WHERE (HedgeServerID, InstrumentID) - removes any existing row
- Step 2: INSERT new record with updated AmountInUnits, LastDataID, LastUpdated
- Step 3: `SET @PersistID = scope_identity()` - captures the new IDENTITY value from the INSERT
- Step 4: COMMIT (or ROLLBACK with rethrow on error)
- The PK (InstrumentID, HedgeServerID) ensures exactly one active row per pair after the replace
- PersistID monotonically increases with each replace, acting as a generation counter
- The OUTPUT parameter @PersistID lets callers know which "version" of the data they just wrote

**Why not UPSERT?**: The DELETE+INSERT approach guarantees PersistID always increments (vs UPDATE which would not change an IDENTITY column). This allows reliable version tracking without a separate sequence or rowversion column.

**Error handling**:
- Single transaction: if @@TRANCOUNT = 1, ROLLBACK on error
- Nested transaction (@@TRANCOUNT > 1): COMMIT the inner transaction (let the outer caller handle rollback)
- THROW propagates the error to the caller in both cases

**Diagram**:
```
Hedge.UpdateRedeemedPositions(@InstrumentID, @HedgeServerID, @Units, @PersistID OUT, @LastDataID, @LastUpdated)
  BEGIN TRAN
    DELETE FROM RedeemedPositions WHERE (HedgeServerID, InstrumentID) match -> 0 or 1 row removed
    INSERT (InstrumentID, HedgeServerID, AmountInUnits, LastUpdated, LastDataID) -> new row, new PersistID
    SET @PersistID = scope_identity() -> return new IDENTITY to caller
  COMMIT
```

---

## 3. Data Overview

Table is currently empty (0 rows). When populated, there is at most one row per (InstrumentID, HedgeServerID):

| InstrumentID | HedgeServerID | AmountInUnits | LastDataID | PersistID | LastUpdated |
|---|---|---|---|---|---|
| 1 | 3 | 2500000.12345678 | 'batch-2026-03-19-08:00' | 98765 | 2026-03-19 08:00:00 |
| 5 | 3 | 750000.00000000 | 'batch-2026-03-19-08:00' | 98766 | 2026-03-19 08:00:00 |

Two instruments being redeemed by HedgeServerID=3 in the same batch cycle (same LastDataID).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | First component of composite PK. FK to Trade.Instrument (WITH CHECK). The financial instrument whose redeemed position amount is recorded. |
| 2 | HedgeServerID | int | NO | - | VERIFIED | Second component of composite PK. FK to Trade.HedgeServer (WITH CHECK). The hedge server instance tracking this redemption. Each hedge server maintains its own redeemed positions snapshot independently. |
| 3 | AmountInUnits | decimal(18,8) | NO | - | VERIFIED | The current accumulated redeemed position size in instrument units. Always positive (no direction - redeemed amounts are magnitude-only). Uses 8 decimal places (vs 6 in PositionsHedgeTbl) for higher unit precision. |
| 4 | LastUpdated | datetime | NO | - | VERIFIED | Timestamp of the last replace operation. Set by the caller (not DB-generated). |
| 5 | PersistID | bigint | NO | IDENTITY(1,1) NOT FOR REPLICATION | VERIFIED | Auto-incrementing IDENTITY column. NOT the PK - not used to identify the row, but as a generation/version counter. Increments with every DELETE+INSERT replace. Returned to callers via @PersistID OUTPUT parameter in `UpdateRedeemedPositions`. NOT FOR REPLICATION means the IDENTITY generator does not fire on replication INSERT - the replicated value is used as-is. |
| 6 | LastDataID | varchar(100) | NO | - | CODE-BACKED | Batch or correlation identifier for the data that produced this record. varchar(100) unlike the int LastDataID in Hedge.PositionsHedgeTbl - allows string-based composite IDs, GUIDs, or batch labels. Enables the hedge server to identify which data processing cycle generated the current redeemed amount. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK (explicit, WITH CHECK) | The instrument being redeemed |
| HedgeServerID | Trade.HedgeServer | FK (explicit, WITH CHECK) | The hedge server tracking the redemption |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.UpdateRedeemedPositions | InstrumentID, HedgeServerID | WRITER (atomic replace) | Only write path - DELETE+INSERT pattern, returns new PersistID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.RedeemedPositions (table)
+-- Trade.Instrument (table) [FK target]
+-- Trade.HedgeServer (table) [FK target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK target for InstrumentID |
| Trade.HedgeServer | Table | FK target for HedgeServerID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.UpdateRedeemedPositions | Stored Procedure | WRITER - atomic replace, returns PersistID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HedgeRedeemdPositions | CLUSTERED PK | InstrumentID ASC, HedgeServerID ASC | - | - | Active |

Note: PK constraint name `PK_HedgeRedeemdPositions` (typo: "Reemd" instead of "Redeemd") is the original constraint name from table creation. FILLFACTOR=95.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HedgeRedeemdPositions | PRIMARY KEY | One active row per (Instrument, HedgeServer) |
| FK_Hedge_RedeemedPositions_InstrumentID | FOREIGN KEY (WITH CHECK) | InstrumentID must exist in Trade.Instrument |
| FK_Hedge_RedeemedPositions_HedgeServerID | FOREIGN KEY (WITH CHECK) | HedgeServerID must exist in Trade.HedgeServer |

### 7.3 IDENTITY and NOT FOR REPLICATION

`PersistID BIGINT IDENTITY(1,1) NOT FOR REPLICATION` - the NOT FOR REPLICATION clause means:
- When rows are replicated FROM this table to a subscriber, the IDENTITY generator does not fire
- The replicated PersistID value is preserved exactly (not overwritten by the subscriber's own IDENTITY sequence)
- This ensures PersistID is consistent across all replicas and can be used for cross-server correlation

---

## 8. Sample Queries

### 8.1 Current redeemed positions snapshot
```sql
SELECT  rp.InstrumentID,
        rp.HedgeServerID,
        rp.AmountInUnits,
        rp.LastDataID,
        rp.PersistID,
        rp.LastUpdated
FROM    [Hedge].[RedeemedPositions] rp WITH (NOLOCK)
ORDER BY rp.HedgeServerID, rp.InstrumentID;
```

### 8.2 Compare redeemed amounts vs current position sizes
```sql
SELECT  rp.InstrumentID,
        rp.HedgeServerID,
        rp.AmountInUnits AS RedeemedUnits,
        ph.AmountInUnitsDecimal AS HeldUnits,
        ph.Redeemed AS HeldRedeemed,
        rp.LastUpdated AS RedeemedUpdated,
        ph.LastUpdated AS HeldUpdated
FROM    [Hedge].[RedeemedPositions] rp WITH (NOLOCK)
LEFT JOIN [Hedge].[PositionsHedgeTbl] ph WITH (NOLOCK)
        ON rp.InstrumentID = ph.InstrumentID
        AND rp.HedgeServerID = ph.HedgeServerID
ORDER BY rp.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Confluence search returned no relevant results for Hedge.RedeemedPositions.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.RedeemedPositions | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.RedeemedPositions.sql*
