# History.CES_LogUpdateExposures

> Audit writer that records each CES exposure manual update into History.CES_UpdateExposures, capturing who applied a directional exposure adjustment, to which instrument and hedge server, and whether the exposure was for an open or closed position.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No return value; fire-and-forget audit INSERT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.CES_LogUpdateExposures` is the sole writer for `History.CES_UpdateExposures`. It records each time an operator or automated process applies a targeted exposure adjustment to the Currency Exposure Service (CES). While `History.CES_LogReloadExposures` records a full reload of all exposure data for an instrument, this procedure records a specific directional correction: adding or subtracting a given amount of exposure in a particular direction (buy or sell) on a specific hedge server.

This type of adjustment is performed when the in-memory CES exposure aggregates drift from the true database state - for example, after a failed hedge, a manual position correction, or a data reconciliation. The audit record captures all the parameters of the adjustment so that risk engineers can understand exactly what was changed and why (via the AppUserName who triggered it).

From live data: only 3 rows exist, all from May 2025, indicating this is a rare administrative operation.

---

## 2. Business Logic

### 2.1 Directional Exposure Adjustment Audit

**What**: Records a targeted correction to CES hedge exposure data for a specific instrument, direction, and hedge server.

**Columns/Parameters Involved**: `@InstrumentID`, `@Amount`, `@IsBuy`, `@HedgeServerID`, `@IsOpen`

**Rules**:
- @IsBuy=1: adjustment is on the long (buy) side of the book; @IsBuy=0: short (sell) side
- @IsOpen=1: adjustment applies to open position exposure; @IsOpen=0: closed position exposure
- @HedgeServerID identifies which hedge server's exposure aggregate is being corrected
- @Amount is the size of the exposure correction in instrument units (decimal 16,6)
- From live data: all 3 adjustments used Amount=100, IsBuy=true, IsOpen=false on HedgeServerID=8 for instruments 7 and 8

**Diagram**:
```
CES exposure drift detected:
    |
    +-> Operator identifies specific (InstrumentID, HedgeServerID, Direction) needing correction
    |
    +-> Calls History.CES_LogUpdateExposures(@AppUserName, @InstrumentID, @Amount, @IsBuy, @HedgeServerID, @IsOpen)
    |
    +-> INSERT History.CES_UpdateExposures (DBUserName=SUSER_NAME(), AppUserName, IsOpen, IsBuy, HedgeServerID, Amount, InstrumentID)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AppUserName | nvarchar(255) | NO | - | CODE-BACKED | Application-layer identity of the operator applying the exposure correction. Stored alongside DBUserName (SUSER_NAME(), captured automatically) for dual-identity audit. |
| 2 | @InstrumentID | int | NO | - | CODE-BACKED | Financial instrument whose CES exposure is being corrected. Implicit FK to Trade.Instrument. Stored as History.CES_UpdateExposures.InstrumentID. |
| 3 | @Amount | decimal(16,6) | NO | - | CODE-BACKED | Size of the exposure adjustment in instrument units. Supports large notional values (16 digits) and fractional units (6 decimal places). Stored as History.CES_UpdateExposures.Amount. |
| 4 | @IsBuy | bit | NO | - | CODE-BACKED | Direction of the exposure adjustment. 1=long (buy) side correction; 0=short (sell) side correction. From live data: all observed corrections were IsBuy=1. Stored as History.CES_UpdateExposures.IsBuy. |
| 5 | @HedgeServerID | int | NO | - | CODE-BACKED | ID of the hedge server whose exposure aggregate is being corrected. Implicit FK to hedge server configuration. Enables per-server reconciliation queries. Stored as History.CES_UpdateExposures.HedgeServerID. |
| 6 | @IsOpen | bit | NO | - | CODE-BACKED | Whether the adjustment applies to open or closed position exposure. 1=open position exposure; 0=closed position exposure. From live data: all observed corrections were IsOpen=0 (closed position exposure). Stored as History.CES_UpdateExposures.IsOpen. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| all params | History.CES_UpdateExposures | Write target | Inserts one audit row per exposure adjustment event |
| @InstrumentID | Trade.Instrument | Implicit | Identifies the instrument being adjusted |
| @HedgeServerID | Hedge server config | Implicit | Identifies which hedge server's exposure is corrected |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External CES management tooling | (application call) | Application | Called when a targeted CES exposure correction is applied. No SSDT procedures call this procedure. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CES_LogUpdateExposures (procedure)
└── History.CES_UpdateExposures (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.CES_UpdateExposures | Table | INSERT target - one audit row per exposure adjustment |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External CES management tooling | Application | Calls this procedure when applying targeted exposure corrections |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. No TRY/CATCH. Target table is a heap with IDENTITY(1,2) (odd-only IDs) and no PK constraint.

---

## 8. Sample Queries

### 8.1 Show all CES exposure update events

```sql
SELECT
    ID,
    Occurred,
    AppUserName,
    InstrumentID,
    Amount,
    IsBuy,
    HedgeServerID,
    IsOpen
FROM History.CES_UpdateExposures WITH (NOLOCK)
ORDER BY ID DESC
```

### 8.2 Find adjustments for a specific instrument and direction

```sql
SELECT
    ID,
    Occurred,
    AppUserName,
    Amount,
    HedgeServerID,
    IsOpen
FROM History.CES_UpdateExposures WITH (NOLOCK)
WHERE InstrumentID = 7
  AND IsBuy = 1
ORDER BY Occurred DESC
```

### 8.3 Summarize exposure corrections by hedge server

```sql
SELECT
    HedgeServerID,
    InstrumentID,
    IsBuy,
    COUNT(*) AS CorrectionCount,
    SUM(Amount) AS TotalAdjustedAmount,
    MAX(Occurred) AS LastAdjustment
FROM History.CES_UpdateExposures WITH (NOLOCK)
GROUP BY HedgeServerID, InstrumentID, IsBuy
ORDER BY LastAdjustment DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 applicable (Phase 9B: no app code match)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: History.CES_LogUpdateExposures | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.CES_LogUpdateExposures.sql*
