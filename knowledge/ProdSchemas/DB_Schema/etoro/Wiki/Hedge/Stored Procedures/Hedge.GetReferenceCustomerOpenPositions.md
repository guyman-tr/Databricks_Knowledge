# Hedge.GetReferenceCustomerOpenPositions

> Returns the most recent customer open position aggregate snapshot per hedge server within a date range, providing the customer-side P&L and position data for hedge cost reconciliation.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartReferenceDate + @EndReferenceDate + @HedgeServerIDs - date window and server filter |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetReferenceCustomerOpenPositions` is the customer-side counterpart to `Hedge.GetReferenceAccountOpenPositions`. Where the account procedures return LP hedge account data, this procedure returns aggregate customer position data from `Hedge.CustomerOpenPositions` - what eToro's customers collectively hold in open positions per hedge server, and the associated P&L metrics.

This procedure is a core input to the HedgeCost calculation: hedge cost is computed as the difference between what eToro's customer book earns/loses (from this procedure) and what the LP hedge account earns/loses (from GetReferenceAccountOpenPositions). The `UnrealizedZeroPL` column is particularly significant - it represents what eToro's P&L would be if there were no spread or rollover charges, serving as the theoretical "fair value" baseline from which hedge cost is computed.

The RANK() window function selects the most recent snapshot per HedgeServerID within the date window. Note: unlike GetReferenceAccountStatus (which uses ROW_NUMBER()), this procedure uses RANK() - meaning multiple rows with the same OccurredAt for the same HedgeServerID can all be RowNum=1. This is intentional: the customer snapshot is per (HedgeServerID, InstrumentID), so the most recent timestamp for a server can have multiple instrument rows.

This is the **original** version reading from `Hedge.CustomerOpenPositions`. The newer versions (`_NewData` and `_SS` variants) read from `Hedge.CustomerOpenPositions_New` and use a different approach with temp tables and STRING_SPLIT.

---

## 2. Business Logic

### 2.1 Most-Recent Customer Snapshot Selection via RANK()

**What**: A CTE applies RANK() partitioned by HedgeServerID to select the most recent OccurredAt within the date window. Returns all InstrumentID rows at that most-recent timestamp.

**Columns/Parameters Involved**: `HedgeServerID`, `InstrumentID`, `OccurredAt`, `RowNum`

**Rules**:
- RANK() OVER (PARTITION BY HedgeServerID ORDER BY OccurredAt DESC): partitions by server, ranks by snapshot time descending
- RowNum=1 includes ALL instrument rows at the most recent OccurredAt timestamp for each HedgeServerID
- Partitioned by HedgeServerID only (not by InstrumentID) - all instruments for a server share the same reference snapshot timestamp
- This ensures the returned snapshot is internally consistent: all returned rows for a given HedgeServerID reflect the same point in time, not a mix of timestamps per instrument

**Diagram**:
```
CustomerOpenPositions (time-series, per-instrument per-server):
  HedgeServerID=1, InstrumentID=1,  OccurredAt=17:00, OpenedUnits=500M, UnrealizedZeroPL=25000
  HedgeServerID=1, InstrumentID=5,  OccurredAt=17:00, OpenedUnits=50M,  UnrealizedZeroPL=3000
  HedgeServerID=1, InstrumentID=1,  OccurredAt=12:00, OpenedUnits=490M, UnrealizedZeroPL=24000
  HedgeServerID=1, InstrumentID=5,  OccurredAt=12:00, OpenedUnits=48M,  UnrealizedZeroPL=2900

RANK() OVER PARTITION BY HedgeServerID=1 ORDER BY OccurredAt DESC:
  17:00 rows -> RowNum=1 (all instruments at 17:00 for server 1)
  12:00 rows -> RowNum=3 (2 instruments, ranked 3rd)

Output: Both 17:00 rows (InstrumentID=1 and InstrumentID=5) at the reference snapshot
```

### 2.2 UnrealizedZeroPL as Hedge Cost Baseline

**What**: `UnrealizedZeroPL` is the theoretical P&L eToro's customers would have if prices moved from their entry rates to current rates with no spread/swap charges. It represents the "perfect hedge" benchmark.

**Columns/Parameters Involved**: `UnrealizedZeroPL`, `UnrealizedPL`

**Rules**:
- Hedge Cost Unrealized = CustomerUnrealizedZeroPL - AccountUnrealizedNetPL (from LP account)
- A positive hedge cost means customers gained more than the LP account - eToro absorbs the difference
- CommissionOnOpen captures trading fees collected at position open

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartReferenceDate | datetime | NO | - | VERIFIED | Start of the reference date window (inclusive). Filters CustomerOpenPositions to OccurredAt >= this value. Safely parameterized in sp_executesql. |
| 2 | @EndReferenceDate | datetime | NO | - | VERIFIED | End of the reference date window (inclusive). Filters CustomerOpenPositions to OccurredAt <= this value. Safely parameterized in sp_executesql. |
| 3 | @HedgeServerIDs | varchar(4000) | NO | - | VERIFIED | Comma-separated list of integer HedgeServerIDs (e.g., '1,2,3'). Injected directly into IN clause of dynamic SQL. Same convention as GetReferenceAccountOpenPositions. |

**Output columns** (from Hedge.CustomerOpenPositions):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | HedgeServerID | int | NO | - | VERIFIED | The hedge server that recorded this customer position snapshot. Partition key for RANK(). All rows for a given HedgeServerID share the same reference OccurredAt timestamp. |
| 5 | InstrumentID | int | NO | - | VERIFIED | The financial instrument. Multiple InstrumentID rows are returned per HedgeServerID - one per instrument in the customer book at the reference timestamp. |
| 6 | OccurredAt | datetime | NO | - | VERIFIED | Timestamp of the customer position snapshot. Most recent value within the date window for each HedgeServerID. All instruments for a server share this timestamp (consistent snapshot). |
| 7 | UnrealizedPL | decimal | YES | - | VERIFIED | Actual unrealized P&L of all eToro customers' open positions in this instrument on this server. Includes spread and swap effects. Used in hedge cost computation. |
| 8 | CommissionOnOpen | decimal | YES | - | VERIFIED | Total commission collected from customers when opening the positions captured in this snapshot. Represents fee revenue associated with the customer book at this point in time. |
| 9 | UnrealizedZeroPL | decimal | YES | - | VERIFIED | Theoretical unrealized P&L if no spread/swap were charged. The "fair value" baseline. Hedge cost unrealized = UnrealizedZeroPL - LP AccountUnrealizedNetPL. The difference measures how well the hedge covers the customer book. |
| 10 | OpenedUnits | decimal | YES | - | VERIFIED | Total eToro internal units of customer open positions in this instrument on this server. Parallel to HedgedUnits in the account procedures; used to verify the hedge covers the customer exposure. |
| 11 | PriceRateID | int | YES | - | VERIFIED | Reference to the price snapshot used for valuation. Links to the rate record used to compute UnrealizedPL, UnrealizedZeroPL, and NetOpenInUSD. |
| 12 | NetOpenInUSD | decimal | YES | - | VERIFIED | Total net USD value of all customer open positions in this instrument at snapshot time. Used for absolute size comparison against the LP account NetHedgedInUSD. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Hedge.CustomerOpenPositions | SELECT (dynamic SQL) | Time-series source of customer aggregate open position snapshots (original/legacy table). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge reporting / reconciliation | - | Caller | Called during HedgeCost reporting to get customer-side reference data paired with LP account data. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetReferenceCustomerOpenPositions (procedure)
└── Hedge.CustomerOpenPositions (table)
      - Older/original customer position snapshot table
      - Newer equivalent: Hedge.CustomerOpenPositions_New
        (used by _NewData and _SS variants)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.CustomerOpenPositions | Table | Dynamic SQL SELECT - source of customer aggregate open position time-series snapshots (original table) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge reporting application | External | READER - paired with GetReferenceAccountOpenPositions to compute hedge cost for customer open positions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Same dynamic SQL pattern as GetReferenceAccountOpenPositions. RANK() is used (not ROW_NUMBER()) consistent with the GetReferenceAccountOpenPositions approach. Performance depends on Hedge.CustomerOpenPositions having an index on (HedgeServerID, OccurredAt).

### 7.2 Constraints

N/A for Stored Procedure. This is the original version reading from `Hedge.CustomerOpenPositions`. The `_NewData` and `_SS` variants read from `Hedge.CustomerOpenPositions_New` using a different approach (temp tables + STRING_SPLIT). All three return the same output columns. Migration path: original -> _NewData -> _SS, with _NewData and _SS being functionally equivalent but using the newer data source.

---

## 8. Sample Queries

### 8.1 Get customer reference open positions for a specific day
```sql
EXEC [Hedge].[GetReferenceCustomerOpenPositions]
    @StartReferenceDate = '2026-03-18 00:00:00',
    @EndReferenceDate   = '2026-03-18 23:59:59',
    @HedgeServerIDs     = '1,2,3';
```

### 8.2 Compare customer vs LP open positions for hedge cost analysis
```sql
-- Step 1: Customer side
EXEC [Hedge].[GetReferenceCustomerOpenPositions]
    @StartReferenceDate = '2026-03-18',
    @EndReferenceDate   = '2026-03-19',
    @HedgeServerIDs     = '1';

-- Step 2: LP side
EXEC [Hedge].[GetReferenceAccountOpenPositions]
    @StartReferenceDate = '2026-03-18',
    @EndReferenceDate   = '2026-03-19',
    @HedgeServerIDs     = '1';

-- Hedge cost unrealized per instrument:
-- = CustomerUnrealizedZeroPL - AccountUnrealizedNetPL (grouped by InstrumentID)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 9 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetReferenceCustomerOpenPositions | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetReferenceCustomerOpenPositions.sql*
