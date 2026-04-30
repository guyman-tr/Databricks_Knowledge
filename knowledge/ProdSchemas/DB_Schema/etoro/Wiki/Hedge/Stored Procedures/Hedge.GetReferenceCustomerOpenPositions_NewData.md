# Hedge.GetReferenceCustomerOpenPositions_NewData

> Returns the most recent customer open position snapshot per (HedgeServerID, InstrumentID) within a date range from the newer CustomerOpenPositions_New table, using STRING_SPLIT and temp table pattern instead of dynamic SQL RANK().

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartReferenceDate + @EndReferenceDate + @HedgeServerIDs - date window and server filter |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetReferenceCustomerOpenPositions_NewData` is a second-generation replacement for `Hedge.GetReferenceCustomerOpenPositions`. It produces the same output (customer open position aggregate snapshots for hedge cost reporting) but uses a different source table and a more robust implementation:

1. **Data source**: reads from `Hedge.CustomerOpenPositions_New` instead of the original `Hedge.CustomerOpenPositions`
2. **Server ID parsing**: uses STRING_SPLIT() to parse @HedgeServerIDs instead of dynamic SQL string concatenation
3. **Snapshot selection**: uses MAX(OccurredAt) per (HedgeServerID, InstrumentID) via temp table instead of RANK() per HedgeServerID

The semantic shift from RANK() per HedgeServerID to MAX(OccurredAt) per (HedgeServerID, InstrumentID) is important: in the original procedure, all instruments for a server share the same reference timestamp (the most recent for that server). In this version, each instrument can independently have its own most recent timestamp. This allows the snapshot to capture the latest data per instrument even when different instruments have been updated at different times.

This procedure and `Hedge.GetReferenceCustomerOpenPositions_SS` are functionally identical (byte-for-byte same SQL). They appear to have been created for different callers or testing purposes and were never differentiated. The `_SS` suffix may stand for "Same Stored procedure" or another internal designation.

---

## 2. Business Logic

### 2.1 STRING_SPLIT-Based Server ID Parsing

**What**: @HedgeServerIDs is parsed via STRING_SPLIT into a temp table (#HedgeServers) before joining. This avoids dynamic SQL string concatenation for the server filter.

**Columns/Parameters Involved**: `@HedgeServerIDs`, `#HedgeServers`

**Rules**:
- `SELECT CAST(value AS int) FROM STRING_SPLIT(@HedgeServerIDs, ',')` populates #HedgeServers
- #HedgeServers has a PRIMARY KEY on HedgeServerID for efficient lookups
- Safer than the original dynamic SQL concatenation pattern

### 2.2 Two-Pass MAX(OccurredAt) Snapshot Selection

**What**: A two-step temp table approach: first find the MAX(OccurredAt) per (HedgeServerID, InstrumentID), then fetch the full row for that timestamp.

**Columns/Parameters Involved**: `#HedgeServersInstruments`, `HedgeServerID`, `InstrumentID`, `OccurredAt`

**Rules**:
- Step 1: INSERT into #HedgeServersInstruments: `GROUP BY HedgeServerID, InstrumentID` with `MAX(OccurredAt)` in the date range
- #HedgeServersInstruments has a clustered index on (HedgeServerID, InstrumentID, OccurredAt) for efficient lookup
- Step 2: INNER JOIN Hedge.CustomerOpenPositions_New back on the exact (HedgeServerID, InstrumentID, OccurredAt) triple to fetch the full row
- Key semantic difference from original: each instrument has its OWN most-recent timestamp, not shared across all instruments for a server

**Diagram**:
```
CustomerOpenPositions_New (per-instrument snapshots):
  HedgeServerID=1, InstrumentID=1, OccurredAt=17:00, OpenedUnits=500M
  HedgeServerID=1, InstrumentID=5, OccurredAt=16:30, OpenedUnits=50M  <- different time

Step 1 - MAX per (server, instrument):
  #HedgeServersInstruments: (1, 1, 17:00), (1, 5, 16:30)

Step 2 - fetch full rows:
  Output: (1, 1, 17:00, 500M, ...) and (1, 5, 16:30, 50M, ...)

Original approach would return both at 17:00 (server-wide latest)
-> _NewData returns per-instrument latest, even if different timestamps
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartReferenceDate | datetime | NO | - | VERIFIED | Start of reference date window. Filters CustomerOpenPositions_New OccurredAt >= this value. |
| 2 | @EndReferenceDate | datetime | NO | - | VERIFIED | End of reference date window. Filters CustomerOpenPositions_New OccurredAt <= this value. |
| 3 | @HedgeServerIDs | varchar(4000) | NO | - | VERIFIED | Comma-separated list of integer HedgeServerIDs. Parsed via STRING_SPLIT into #HedgeServers temp table. Safer alternative to the dynamic SQL IN injection used by the original procedure. |

**Output columns** (same as Hedge.GetReferenceCustomerOpenPositions):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | HedgeServerID | int | NO | - | VERIFIED | Hedge server identifier. Each output row is keyed to a specific (HedgeServerID, InstrumentID) pair. |
| 5 | InstrumentID | int | NO | - | VERIFIED | Financial instrument. Each instrument has its own most-recent OccurredAt (per-instrument snapshot, not per-server). |
| 6 | OccurredAt | datetime | NO | - | VERIFIED | Timestamp of the most recent snapshot for this (HedgeServerID, InstrumentID) pair within the date window. May differ per instrument (unlike the original procedure where all instruments share one timestamp per server). |
| 7 | UnrealizedPL | decimal | YES | - | VERIFIED | Actual unrealized P&L of customer open positions for this instrument on this server. See Hedge.GetReferenceCustomerOpenPositions for full description. |
| 8 | CommissionOnOpen | decimal | YES | - | VERIFIED | Total commission collected on open positions for this instrument. See Hedge.GetReferenceCustomerOpenPositions. |
| 9 | UnrealizedZeroPL | decimal | YES | - | VERIFIED | Theoretical unrealized P&L (no spread/swap). Hedge cost baseline. See Hedge.GetReferenceCustomerOpenPositions. |
| 10 | OpenedUnits | decimal | YES | - | VERIFIED | Total customer open position units in eToro denomination for this instrument on this server. |
| 11 | PriceRateID | int | YES | - | VERIFIED | Reference price snapshot ID used for valuation. |
| 12 | NetOpenInUSD | decimal | YES | - | VERIFIED | Total net USD value of customer open positions in this instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Hedge.CustomerOpenPositions_New | SELECT | Newer customer open position time-series source. Replaces Hedge.CustomerOpenPositions. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge reporting / reconciliation | - | Caller | Newer-generation caller for customer open position reference data. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetReferenceCustomerOpenPositions_NewData (procedure)
└── Hedge.CustomerOpenPositions_New (table)
      - Newer customer position snapshot table
      - Also used by: Hedge.GetReferenceCustomerOpenPositions_SS (identical procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.CustomerOpenPositions_New | Table | Two-pass SELECT - first for MAX(OccurredAt) per instrument, then for full row retrieval |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge reporting application | External | READER - newer-generation version of customer open position reference data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Creates two temp tables per execution: #HedgeServers (PK on HedgeServerID) and #HedgeServersInstruments (clustered index on HedgeServerID, InstrumentID, OccurredAt). The clustered temp table index ensures efficient lookup in the Step 2 JOIN back to CustomerOpenPositions_New on the (HedgeServerID, InstrumentID, OccurredAt) triple.

### 7.2 Constraints

N/A for Stored Procedure. This procedure and `Hedge.GetReferenceCustomerOpenPositions_SS` are byte-for-byte identical - same DDL, same logic, same source table. The distinction between them exists only in their names and possibly in which callers reference each. If consolidation is desired, one could be deprecated in favor of the other. The DROP TABLE IF EXISTS pattern at the start ensures safe re-execution in the same session without temp table conflicts.

---

## 8. Sample Queries

### 8.1 Get customer reference open positions (new data source)
```sql
EXEC [Hedge].[GetReferenceCustomerOpenPositions_NewData]
    @StartReferenceDate = '2026-03-18 00:00:00',
    @EndReferenceDate   = '2026-03-18 23:59:59',
    @HedgeServerIDs     = '1,2,3';
```

### 8.2 Verify consistency between original and new versions
```sql
-- Original (CustomerOpenPositions, RANK per server):
EXEC [Hedge].[GetReferenceCustomerOpenPositions]
    @StartReferenceDate = '2026-03-18', @EndReferenceDate = '2026-03-19',
    @HedgeServerIDs = '1';

-- New (CustomerOpenPositions_New, MAX per instrument):
EXEC [Hedge].[GetReferenceCustomerOpenPositions_NewData]
    @StartReferenceDate = '2026-03-18', @EndReferenceDate = '2026-03-19',
    @HedgeServerIDs = '1';
-- Note: OccurredAt may differ per instrument in the new version
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 9 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetReferenceCustomerOpenPositions_NewData | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetReferenceCustomerOpenPositions_NewData.sql*
