# Trade.GetCESQuery

> Retrieves current hedge exposure data for all hedge servers and instruments below ID 1000, and generates a new exposure snapshot ID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns hedge exposure data and SCOPE_IDENTITY() for new snapshot ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure supports the CES (Current Exposure Snapshot) system by retrieving real-time hedge exposure data. Hedge exposure tracks the net position the platform has with hedge providers for each instrument across all hedge servers. This data is critical for the risk management team to monitor whether the platform's exposure is properly hedged.

The procedure exists to capture a point-in-time exposure snapshot. Each execution creates a new ExposureID in `Trade.ExposureIDs` (auto-increment identity table) and returns the current exposure alongside the new snapshot ID. This enables tracking exposure over time and correlating snapshots with market conditions.

Data flows from `Trade.GetExposuresForAllHedgeServers` (a view that aggregates exposure data), filtered by ProviderID and InstrumentID < 1000 (legacy instruments). The procedure also INSERTs a new default row into `Trade.ExposureIDs` and returns SCOPE_IDENTITY() as the snapshot identifier.

---

## 2. Business Logic

### 2.1 Exposure Snapshot Creation

**What**: Each execution creates a new exposure snapshot and returns its ID.

**Columns/Parameters Involved**: `Trade.ExposureIDs`, `SCOPE_IDENTITY()`

**Rules**:
- `INSERT INTO Trade.ExposureIDs DEFAULT VALUES` creates a new snapshot row
- `RETURN (SCOPE_IDENTITY())` returns the auto-generated snapshot ID
- This allows the caller to associate the exposure data with a specific point in time

### 2.2 Instrument Filter

**What**: Only includes instruments with ID below 1000.

**Columns/Parameters Involved**: `InstrumentID`

**Rules**:
- `WHERE InstrumentID < 1000` - legacy filter for original instruments
- Combined with `ProviderID = @ProviderID` (defaults to 1)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderID | INT | YES | 1 | CODE-BACKED | Hedge provider ID to filter exposures. Defaults to 1 (primary provider). |
| 2 | HedgeServerID | INT | NO | - | CODE-BACKED | Identifier of the hedge server. Each server manages a subset of instrument hedging. |
| 3 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument being hedged. Only instruments with ID < 1000 are included. |
| 4 | OpenedBuy | DECIMAL | YES | - | CODE-BACKED | Total buy/long exposure currently open for this instrument on this hedge server. |
| 5 | OpenedSell | DECIMAL | YES | - | CODE-BACKED | Total sell/short exposure currently open for this instrument on this hedge server. |
| 6 | Hedged | DECIMAL | YES | - | CODE-BACKED | Amount currently hedged with the provider. Should offset the open exposure. |
| 7 | Requested | DECIMAL | YES | - | CODE-BACKED | Amount of hedge currently requested but not yet confirmed by the provider. |
| 8 | RETURN VALUE | INT | NO | - | CODE-BACKED | SCOPE_IDENTITY() from Trade.ExposureIDs. The new snapshot identifier for this exposure capture. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.GetExposuresForAllHedgeServers | SELECT FROM | View aggregating exposure data across all hedge servers |
| (body) | Trade.ExposureIDs | INSERT INTO | Identity table for exposure snapshot tracking |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCESQuery (procedure)
+-- Trade.GetExposuresForAllHedgeServers (view)
+-- Trade.ExposureIDs (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetExposuresForAllHedgeServers | View | SELECT FROM - exposure data |
| Trade.ExposureIDs | Table | INSERT INTO - snapshot ID generation |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

Note: This procedure performs a WRITE operation (INSERT INTO Trade.ExposureIDs). It is not a pure reader despite the "Get" prefix.

---

## 8. Sample Queries

### 8.1 Execute with default provider
```sql
DECLARE @SnapshotID INT;
EXEC @SnapshotID = Trade.GetCESQuery;
SELECT @SnapshotID AS NewSnapshotID;
```

### 8.2 Execute with specific provider
```sql
DECLARE @SnapshotID INT;
EXEC @SnapshotID = Trade.GetCESQuery @ProviderID = 2;
SELECT @SnapshotID AS NewSnapshotID;
```

### 8.3 View exposure data directly
```sql
SELECT  HedgeServerID, InstrumentID, OpenedBuy, OpenedSell, Hedged, Requested
FROM    Trade.GetExposuresForAllHedgeServers WITH (NOLOCK)
WHERE   ProviderID = 1 AND InstrumentID < 1000
ORDER BY InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.8/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCESQuery | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCESQuery.sql*
