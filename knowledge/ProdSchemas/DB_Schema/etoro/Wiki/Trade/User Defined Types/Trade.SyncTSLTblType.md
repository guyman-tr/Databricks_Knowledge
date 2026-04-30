# Trade.SyncTSLTblType

> TVP used to batch-insert trailing stop-loss (TSL) sync data for positions - StopLoss, SLManualVer, NextThresHold, IsBuy - into the TSL sync table.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | PositionID (bigint) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

SyncTSLTblType carries trailing stop-loss (TSL) data for positions destined for sync. Each row represents one position's TSL state: PositionID, StopLoss (price), SLManualVer (manual version), NextThresHold (next threshold price), and IsBuy (direction). Uses [dbo].[dtPrice] for StopLoss and NextThresHold - a custom scalar type alias for decimal pricing.

The type exists to batch-insert TSL data into the sync table. Trading or sync services accumulate TSL updates per position and pass them as a TVP to Trade.InsertTSLDataToSyncTbl, avoiding multiple single-row inserts.

The type flows from services that track TSL changes, into Trade.InsertTSLDataToSyncTbl. The procedure receives the TVP as READONLY and inserts into the TSL sync target table.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Position TSL state is carried per row: PositionID + StopLoss + SLManualVer + NextThresHold + IsBuy.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Position identifier |
| 2 | StopLoss | [dbo].[dtPrice] | NO | - | CODE-BACKED | Trailing stop-loss price |
| 3 | SLManualVer | smallint | NO | - | CODE-BACKED | Manual version of stop-loss setting |
| 4 | NextThresHold | [dbo].[dtPrice] | NO | - | CODE-BACKED | Next threshold price for TSL |
| 5 | IsBuy | bit | NO | - | CODE-BACKED | True for buy, false for sell position |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InsertTSLDataToSyncTbl | @TSLInfo | Parameter (TVP) | Batch-inserts TSL sync data for positions |

---

## 6. Dependencies

### 6.0 Dependency Chain

Depends on [dbo].[dtPrice] scalar type for StopLoss and NextThresHold columns.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.dtPrice | Scalar Type | Column types for StopLoss, NextThresHold |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertTSLDataToSyncTbl | Stored Procedure | READONLY parameter for TSL sync insert |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and insert single TSL row
```sql
DECLARE @TSLInfo Trade.SyncTSLTblType;
INSERT INTO @TSLInfo (PositionID, StopLoss, SLManualVer, NextThresHold, IsBuy)
VALUES (123456, 1.2500, 1, 1.2600, 1);
EXEC Trade.InsertTSLDataToSyncTbl @TSLInfo = @TSLInfo;
```

### 8.2 Batch insert multiple TSL rows
```sql
DECLARE @TSLInfo Trade.SyncTSLTblType;
INSERT INTO @TSLInfo (PositionID, StopLoss, SLManualVer, NextThresHold, IsBuy)
VALUES (100001, 1.1000, 0, 1.1100, 1), (100002, 2.5000, 2, 2.5100, 0);
EXEC Trade.InsertTSLDataToSyncTbl @TSLInfo = @TSLInfo;
```

### 8.3 Build from query
```sql
DECLARE @TSLInfo Trade.SyncTSLTblType;
INSERT INTO @TSLInfo (PositionID, StopLoss, SLManualVer, NextThresHold, IsBuy)
SELECT PositionID, StopLoss, SLManualVer, NextThresHold, IsBuy
FROM Trade.Position WHERE InstrumentID = 12345;
EXEC Trade.InsertTSLDataToSyncTbl @TSLInfo = @TSLInfo;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 6.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 1/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SyncTSLTblType | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.SyncTSLTblType.sql*
