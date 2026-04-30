# Hedge.AddCustomersDataGeneral

> Job-driven orchestrator that writes both unrealized and realized customer hedge data in a single transaction: populates dbo.HedgeCustomerOpenPositions from live positions and dbo.HedgeCustomerClosedPositions from realized P&L for a given time window.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Orchestrator - calls Hedge.GetUnrealizedCustomersData and Hedge.GetRealizedCustomersData |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.AddCustomersDataGeneral` is the central data-loading orchestrator for customer hedge data. It runs inside a continuously-looping SQL Agent job (per the inline comment: `while 1=1` infinite loop, re-scheduled every minute as a safety restart). Each invocation performs two insertions in one transaction:

1. **Unrealized data**: Calls `Hedge.GetUnrealizedCustomersData` and inserts its output into `dbo.HedgeCustomerOpenPositions` - giving a current snapshot of open customer positions aggregated by hedge server and instrument.
2. **Realized data**: Calls `Hedge.GetRealizedCustomersData @From, @To` and inserts its output into `dbo.HedgeCustomerClosedPositions` - giving the realized P&L for the specified time window.

The procedure handles the edge case where no customer positions are currently open: if `GetUnrealizedCustomersData` returns zero rows, it inserts a sentinel/dummy row per active hedge server (InstrumentID=1, all amounts=0) to mark that the query ran but found nothing. This prevents monitoring systems from interpreting a zero-row result as a system failure vs. an empty book.

The target tables (`dbo.HedgeCustomerOpenPositions`, `dbo.HedgeCustomerClosedPositions`) are in the dbo schema, indicating they are shared reporting tables used across schema boundaries.

---

## 2. Business Logic

### 2.1 Empty Book Sentinel Row

**What**: When no unrealized positions exist, dummy rows are inserted per active hedge server to mark that the cycle ran.

**Columns/Parameters Involved**: `@@rowcount`, Trade.HedgeServer.IsActive

**Rules**:
- After inserting unrealized data: check `@@rowcount`
- If `@@rowcount = 0`: INSERT one row per `Trade.HedgeServer WHERE IsActive = 1` with InstrumentID=1, all values=0
- Comment in code: "In case no customer positions are open, insert dummy row for each hedge server in order to mark the time for future references"
- This allows downstream consumers to distinguish "no positions" from "procedure didn't run"

### 2.2 Transaction Atomicity

**What**: Both the unrealized and realized inserts are wrapped in a single transaction.

**Columns/Parameters Involved**: BEGIN TRAN / COMMIT TRAN

**Rules**:
- `SET XACT_ABORT ON` - any error in the transaction automatically rolls back both inserts
- `BEGIN TRAN` / `COMMIT TRAN` ensures the open-position snapshot and closed-position data are always written together
- If either insert fails, neither is committed

**Diagram**:
```
Job (infinite loop, every minute restart safety)
      |
      v
Hedge.AddCustomersDataGeneral(@From, @To)
      |
      BEGIN TRAN
      |
      +--EXEC Hedge.GetUnrealizedCustomersData
      |     |
      |     v
      |  INSERT INTO dbo.HedgeCustomerOpenPositions
      |     |
      |     +--[@@rowcount = 0]--> INSERT dummy rows per active HedgeServer
      |
      +--EXEC Hedge.GetRealizedCustomersData @From, @To
      |     |
      |     v
      |  INSERT INTO dbo.HedgeCustomerClosedPositions
      |
      COMMIT TRAN
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @From | DATETIME | NO | - | CODE-BACKED | Start of the time window for realized P&L data. Passed to Hedge.GetRealizedCustomersData. Typically set by the calling job to cover the interval since the last execution. |
| 2 | @To | DATETIME | NO | - | CODE-BACKED | End of the time window for realized P&L data. Passed to Hedge.GetRealizedCustomersData. Typically set to the current job execution time. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (calls) | Hedge.GetUnrealizedCustomersData | Procedure call | Provides the current unrealized customer position data |
| (calls) | Hedge.GetRealizedCustomersData | Procedure call | Provides the realized P&L for the @From/@To window |
| (writes) | dbo.HedgeCustomerOpenPositions | INSERT | Unrealized position snapshot target |
| (writes) | dbo.HedgeCustomerClosedPositions | INSERT | Realized P&L data target |
| (reads) | Trade.HedgeServer | Lookup | Reads active servers for sentinel row insertion when no positions exist |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Invoked by a continuously running SQL Agent job with an infinite loop structure.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.AddCustomersDataGeneral (procedure)
├── Hedge.GetUnrealizedCustomersData (procedure) - see its own doc
├── Hedge.GetRealizedCustomersData (procedure) - see its own doc
├── Trade.HedgeServer (table) - sentinel row source
├── dbo.HedgeCustomerOpenPositions (table - dbo schema, not in SSDT)
└── dbo.HedgeCustomerClosedPositions (table - dbo schema, not in SSDT)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetUnrealizedCustomersData | Procedure | Called via INSERT...EXEC to get current unrealized positions |
| Hedge.GetRealizedCustomersData | Procedure | Called via INSERT...EXEC with @From/@To for realized P&L |
| Trade.HedgeServer | Table | SELECT WHERE IsActive=1 to generate sentinel rows for empty book |
| dbo.HedgeCustomerOpenPositions | Table | INSERT target for unrealized data (dbo schema) |
| dbo.HedgeCustomerClosedPositions | Table | INSERT target for realized data (dbo schema) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (SQL Agent Job - infinite loop) | External | Calls this procedure continuously; restarts every minute via schedule |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- `SET NOCOUNT ON` - suppresses row count messages
- `SET XACT_ABORT ON` - auto-rollback on any error
- Single transaction wrapping both inserts ensures atomicity
- The `@@rowcount` check is performed immediately after the first INSERT...EXEC

---

## 8. Sample Queries

### 8.1 Execute: Run the data load for a 1-hour window

```sql
DECLARE @From DATETIME = DATEADD(HOUR, -1, GETUTCDATE())
DECLARE @To   DATETIME = GETUTCDATE()
EXEC Hedge.AddCustomersDataGeneral @From = @From, @To = @To
```

### 8.2 Query: Check recent unrealized data loaded by this procedure

```sql
SELECT TOP 20
    HedgeServerID,
    InstrumentID,
    UnrealizedPL,
    CommissionOnOpen,
    OpenedBuyUnits,
    OpenedSellUnits,
    NetOpenInUSD
FROM dbo.HedgeCustomerOpenPositions WITH (NOLOCK)
ORDER BY PriceRateID DESC
```

### 8.3 Identify sentinel (empty-book) rows inserted when no positions exist

```sql
SELECT TOP 20 *
FROM dbo.HedgeCustomerOpenPositions WITH (NOLOCK)
WHERE InstrumentID = 1
  AND UnrealizedPL = 0
  AND OpenedBuyUnits = 0
  AND OpenedSellUnits = 0
ORDER BY PriceRateID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.AddCustomersDataGeneral | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.AddCustomersDataGeneral.sql*
