# Hedge.GetCustomerClosedPositionsData_NewData

> Delta-calculation procedure that returns incremental customer closed position data since a reference date, using OUTER APPLY to subtract a reference-point snapshot from the latest snapshot in a cumulative snapshot table. IMPORTANT: The target table Hedge.CustomerClosedPositions_New does not exist in the database or SSDT - this procedure will fail at runtime.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ReferenceDate (required), @HedgeServers (required, comma-separated IDs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the improved successor to `Hedge.GetCustomerClosedPositionsData`. While the original procedure reads from a running-log table (`Hedge.CustomerClosedPositions`) and filters by date range, this procedure reads from `Hedge.CustomerClosedPositions_New` - a **cumulative snapshot table** where each row represents a running total at a point in time.

The delta calculation pattern:
- **`ref`**: the most recent snapshot at or before `@ReferenceDate` - this is the "starting point"
- **`final`**: the most recent snapshot overall (latest state) - this is the "ending point"
- **Result**: `final - ref` = the increment since the reference date

This is more efficient for high-frequency calls than a date-range filter because it requires only two TOP 1 lookups per (HedgeServerID, InstrumentID) pair rather than scanning all rows in a date range.

The SP also improves on the predecessor by replacing the dynamic SQL pattern with `STRING_SPLIT(@HedgeServers, ',')`, eliminating the SQL injection vulnerability.

**Critical issue**: `Hedge.CustomerClosedPositions_New` does not exist in the database or SSDT. Executing this procedure will fail with "Invalid object name 'Hedge.CustomerClosedPositions_New'".

---

## 2. Business Logic

### 2.1 STRING_SPLIT-Based Server Parsing (Safe)

**What**: @HedgeServers is parsed via STRING_SPLIT into a temp table - a safe alternative to the dynamic SQL approach used in the predecessor procedure.

**Columns/Parameters Involved**: `@HedgeServers`, `#HedgeServers`

**Rules**:
- `STRING_SPLIT(@HedgeServers, ',')` parses the comma-separated list into rows
- Results inserted into `#HedgeServers (HedgeServerID int PRIMARY KEY)` - duplicate server IDs are rejected
- `CAST(value AS int)` converts string tokens to integers
- No SQL injection risk - @HedgeServers is never concatenated into dynamic SQL

### 2.2 Active Server/Instrument Discovery

**What**: Identifies all (HedgeServerID, InstrumentID) pairs that have data for the specified servers, along with the latest OccurredAt for each.

**Columns/Parameters Involved**: `#HedgeServersInstruments`, `HedgeServerID`, `InstrumentID`, `OccurredAt`

**Rules**:
- INNER JOIN #HedgeServers with Hedge.CustomerClosedPositions_New on HedgeServerID
- GROUP BY (HedgeServerID, InstrumentID) to find all distinct instrument pairs
- MAX(OccurredAt) per group stored for reference (used implicitly by the OUTER APPLY ordering)
- Clustered index on #HedgeServersInstruments (HedgeServerID, InstrumentID, OccurredAt) for efficient lookup

### 2.3 Delta Calculation via Dual OUTER APPLY

**What**: For each (HedgeServerID, InstrumentID) pair, retrieves the reference-point snapshot and the latest snapshot, then returns the difference.

**Columns/Parameters Involved**: `ref` (OUTER APPLY), `final` (OUTER APPLY), `@ReferenceDate`

**Rules**:
- **`ref` (reference snapshot)**: `TOP 1 ... WHERE OccurredAt <= @ReferenceDate ORDER BY OccurredAt DESC` - the most recent cumulative snapshot at or before the reference date
- **`final` (latest snapshot)**: `TOP 1 ... ORDER BY OccurredAt DESC` - the most recent cumulative snapshot overall
- **Delta formula**: `ISNULL(final.value, 0) - ISNULL(ref.value, 0)` for each metric column
- Both APPLYs are OUTER APPLY: if ref is NULL (no data before @ReferenceDate), baseline is treated as 0; if final is NULL (no data at all), delta is 0-0=0
- Result: incremental activity since @ReferenceDate
- `OccurredAt` in output = `final.OccurredAt` (the most recent row's timestamp, not a range)
- `HedgeServerID` and `InstrumentID` use ISNULL(ref, final) to handle the case where ref is NULL

**Diagram**:
```
Cumulative snapshot table (CustomerClosedPositions_New):
  t0          t1          t2          t3 (latest)
  [snap0]     [snap1]     [snap2]     [snap3]
              ^                        ^
          @ReferenceDate             NOW
          ref = snap1               final = snap3

  Delta = snap3 - snap1 (new activity since @ReferenceDate)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ReferenceDate | datetime | NO | - | CODE-BACKED | Required. The baseline point in time. The procedure returns the delta between the most recent snapshot before this date and the latest snapshot. |
| 2 | @HedgeServers | varchar(300) | NO | - | CODE-BACKED | Required. Comma-separated list of HedgeServerIDs (e.g., "1,3,5,6"). Parsed via STRING_SPLIT - safe, no SQL injection risk. Duplicates removed by #HedgeServers PRIMARY KEY. |

**Output Columns** (when target table exists):

| Column | Description |
|--------|-------------|
| HedgeServerID | The hedge server. ISNULL(ref.HedgeServerID, final.HedgeServerID) - always populated. |
| InstrumentID | The trading instrument. ISNULL(ref.InstrumentID, final.InstrumentID) - always populated. |
| NetPL | Delta net P&L: final.NetPL - ref.NetPL. Incremental customer net profit/loss since @ReferenceDate. |
| CommissionOnClose | Delta commissions: final.CommissionOnClose - ref.CommissionOnClose. New commissions since @ReferenceDate. |
| ExecutionVolumeInUSD | Delta execution volume (USD): final.ExecutionVolumeInUSD - ref.ExecutionVolumeInUSD. New volume since @ReferenceDate. |
| ZeroPL | Delta ZeroPL: final.ZeroPL - ref.ZeroPL. Incremental zero-P&L positions since @ReferenceDate. |
| OccurredAt | final.OccurredAt - timestamp of the most recent snapshot used as the "final" value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Hedge.CustomerClosedPositions_New | Direct read (x2 OUTER APPLYs + 1 JOIN) | Cumulative snapshot table - TARGET TABLE DOES NOT EXIST |

### 5.2 Referenced By (other objects point to this)

No SQL-level callers found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetCustomerClosedPositionsData_NewData (procedure)
└── Hedge.CustomerClosedPositions_New (table) - DOES NOT EXIST (not in SSDT or database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.CustomerClosedPositions_New | Table | JOIN + 2x OUTER APPLY - TABLE DOES NOT EXIST. Procedure will fail at runtime. |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Target table missing | CRITICAL | Hedge.CustomerClosedPositions_New does not exist in SSDT or database. Executing this procedure will throw "Invalid object name 'Hedge.CustomerClosedPositions_New'". |
| STRING_SPLIT (safe) | Security | @HedgeServers parsed via STRING_SPLIT - no SQL injection risk. Improved over GetCustomerClosedPositionsData predecessor. |
| OUTER APPLY NULL handling | Design | ISNULL(x, 0) on all delta values - missing reference or final rows treated as 0 baseline |
| Cumulative snapshot model | Design | CustomerClosedPositions_New is expected to be a cumulative snapshot table, not a running event log - delta = final - ref |
| DROP TABLE IF EXISTS | Safety | #HedgeServers and #HedgeServersInstruments are cleaned up at procedure start to avoid conflicts on re-execution |

---

## 8. Sample Queries

### 8.1 Equivalent delta query when table exists

```sql
-- Step 1: Find active server/instrument pairs and latest timestamps
SELECT a.HedgeServerID, b.InstrumentID, MAX(b.OccurredAt) AS MaxOccurredAt
INTO #ActivePairs
FROM (SELECT HedgeServerID FROM STRING_SPLIT('1,3,5', ',') CROSS APPLY (SELECT CAST(value AS int) AS HedgeServerID) x) a
INNER JOIN Hedge.CustomerClosedPositions_New b WITH (NOLOCK) ON a.HedgeServerID = b.HedgeServerID
GROUP BY a.HedgeServerID, b.InstrumentID

-- Step 2: Get delta (final - reference)
SELECT ISNULL(ref.HedgeServerID, fin.HedgeServerID) AS HedgeServerID,
       ISNULL(ref.InstrumentID, fin.InstrumentID) AS InstrumentID,
       ISNULL(fin.NetPL, 0) - ISNULL(ref.NetPL, 0) AS NetPL,
       ISNULL(fin.CommissionOnClose, 0) - ISNULL(ref.CommissionOnClose, 0) AS CommissionOnClose
FROM #ActivePairs ap
OUTER APPLY (SELECT TOP 1 * FROM Hedge.CustomerClosedPositions_New WITH (NOLOCK)
             WHERE HedgeServerID = ap.HedgeServerID AND InstrumentID = ap.InstrumentID
               AND OccurredAt <= '2026-01-01' ORDER BY OccurredAt DESC) ref
OUTER APPLY (SELECT TOP 1 * FROM Hedge.CustomerClosedPositions_New WITH (NOLOCK)
             WHERE HedgeServerID = ap.HedgeServerID AND InstrumentID = ap.InstrumentID
             ORDER BY OccurredAt DESC) fin
```

### 8.2 Check if CustomerClosedPositions_New table exists

```sql
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'Hedge'
  AND TABLE_NAME IN ('CustomerClosedPositions', 'CustomerClosedPositions_New')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.0/10 (Elements: 8/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*KNOWN ISSUE: Hedge.CustomerClosedPositions_New does not exist in SSDT or database. Procedure fails at runtime.*
*Object: Hedge.GetCustomerClosedPositionsData_NewData | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetCustomerClosedPositionsData_NewData.sql*
