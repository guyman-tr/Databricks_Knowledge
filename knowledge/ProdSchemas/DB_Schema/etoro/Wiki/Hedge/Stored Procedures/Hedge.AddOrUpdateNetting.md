# Hedge.AddOrUpdateNetting

> Upserts the net hedge position for a (LiquidityAccount, Instrument) pair in Hedge.Netting: updates if a record exists for that key, inserts if it does not.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Upserts Hedge.Netting on (LiquidityAccountID, InstrumentID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.AddOrUpdateNetting` is the primary writer for the `Hedge.Netting` table, which stores the current net aggregate hedge position per (liquidity account, instrument) combination. Each invocation either:
- **Updates** an existing position record (same LiquidityAccountID + InstrumentID key) with new units, direction, rate, and timing
- **Inserts** a new position record if no existing row matches the key

This upsert pattern reflects the core semantic of netting: at any moment, there is at most ONE active net position per instrument per LP account. When the hedge server executes a new trade that adjusts the net position, it calls this procedure to replace the stale position state with the current one.

Per the `Hedge.Netting` table documentation: when the hedge server executes a hedge order, it calls this procedure to adjust the position. System versioning automatically captures every change to `History.Netting_History`. The ExposureBalancer also calls this procedure when correcting imbalances.

@AvgRate uses the `dtPrice` user-defined type (the standard price type in the etoro DB), ensuring consistent precision for the average entry rate.

---

## 2. Business Logic

### 2.1 Upsert Semantics - UPDATE First, INSERT if No Match

**What**: Attempts UPDATE first; if no row was affected, falls through to INSERT.

**Columns/Parameters Involved**: `@LiquidityAccountID`, `@InstrumentID`, `@@ROWCOUNT`

**Rules**:
- Step 1: UPDATE WHERE (LiquidityAccountID = @LiquidityAccountID AND InstrumentID = @InstrumentID)
- Step 2: `IF @@ROWCOUNT = 0` -> INSERT (no existing row for this key)
- The UPDATE targets all mutable fields: HedgeServerID, Units, IsBuy, AvgRate, ValueDate, ExecTime, UpdateTime
- The INSERT includes all fields including the key (LiquidityAccountID, HedgeServerID, InstrumentID) plus mutable fields
- TRY/CATCH with THROW: any error (e.g., PK violation on INSERT race) is re-raised to caller

### 2.2 Concurrency: System Versioning Capture

**What**: The Netting table uses SQL Server system versioning - every change via this procedure is automatically captured to History.Netting_History.

**Rules**:
- No explicit action needed in this procedure - system versioning is table-level
- Each UPDATE overwrites the current row; the old state is archived to History.Netting_History automatically
- This means every call to AddOrUpdateNetting that does an UPDATE creates one history record

**Diagram**:
```
Hedge.AddOrUpdateNetting(@LiquidityAccountID, @InstrumentID, ...)
      |
      v
UPDATE Hedge.Netting
WHERE LiquidityAccountID = @LiquidityAccountID AND InstrumentID = @InstrumentID
      |
      +--[@@ROWCOUNT > 0]--> DONE (row updated; old state in History.Netting_History)
      |
      +--[@@ROWCOUNT = 0]--> INSERT new row into Hedge.Netting
      |
      v
TRY/CATCH - THROW on error
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LiquidityAccountID | INT | NO | - | CODE-BACKED | LP account holding the hedge position. Part of the upsert key: UPDATE/INSERT WHERE LiquidityAccountID=this. FK to Trade.LiquidityAccounts. |
| 2 | @HedgeServerID | INT | NO | - | CODE-BACKED | Hedge server managing this position. Updated/inserted each call - the server can change ownership of the position. FK to Trade.HedgeServer. |
| 3 | @InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument being hedged. Part of the upsert key. FK to Trade.Instrument. |
| 4 | @Units | DECIMAL(16,2) | NO | - | CODE-BACKED | Net aggregate position size in instrument units. The total number of units bought or sold at the LP to cover the customer book exposure. |
| 5 | @IsBuy | BIT | NO | - | CODE-BACKED | Net position direction: 1=net long (bought more than sold), 0=net short (sold more than bought). |
| 6 | @AvgRate | dtPrice | NO | - | CODE-BACKED | Volume-weighted average entry rate for the net position. Uses dtPrice UDT (standard precision price type). Used to calculate unrealized P&L: IsBuy=1: PNL=(Bid-AvgRate)*Units; IsBuy=0: PNL=(AvgRate-Ask)*Units. |
| 7 | @ValueDate | DATE | NO | - | CODE-BACKED | Settlement value date for the hedge position. Used for forward/FX instruments where delivery date matters. |
| 8 | @ExecTime | DATETIME | NO | - | CODE-BACKED | Timestamp when the hedge execution that created/updated this position occurred (trade execution time at LP). |
| 9 | @UpdateTime | DATETIME | NO | - | CODE-BACKED | Timestamp when this record was last updated. Serves as the freshness indicator for the position state. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @LiquidityAccountID | Trade.LiquidityAccounts | Implicit | LP account key for the position |
| @HedgeServerID | Trade.HedgeServer | Implicit | Hedge server owning the position |
| @InstrumentID | Trade.Instrument | Implicit | Instrument being hedged |
| (writes to) | Hedge.Netting | UPDATE / INSERT | Upserts the current net position |
| (auto-captured) | History.Netting_History | System versioning | Old state archived automatically on UPDATE |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Called by hedge engine execution layer and ExposureBalancer.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.AddOrUpdateNetting (procedure)
└── Hedge.Netting (table, system-versioned) - UPDATE / INSERT target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.Netting | Table | UPDATE (existing position) or INSERT (new position) - upsert target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.Netting | Table | Primary writer |
| History.Netting_History | Table | Receives old row states automatically via system versioning on UPDATE |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- TRY/CATCH with THROW - errors propagate cleanly to caller
- No explicit transaction - each operation is auto-committed (single UPDATE or INSERT)
- @AvgRate typed as `dtPrice` (User Defined Type) - must match the column type in Hedge.Netting

---

## 8. Sample Queries

### 8.1 Execute: Upsert a net long position on EUR/USD

```sql
EXEC Hedge.AddOrUpdateNetting
    @LiquidityAccountID = 101,
    @HedgeServerID      = 1,
    @InstrumentID       = 1,
    @Units              = 500000.00,
    @IsBuy              = 1,
    @AvgRate            = 1.08500,
    @ValueDate          = '2026-03-21',
    @ExecTime           = GETUTCDATE(),
    @UpdateTime         = GETUTCDATE()
```

### 8.2 Verify: Check the current netting state for an account

```sql
SELECT
    LiquidityAccountID,
    HedgeServerID,
    InstrumentID,
    Units,
    IsBuy,
    AvgRate,
    ValueDate,
    UpdateTime
FROM Hedge.Netting WITH (NOLOCK)
WHERE LiquidityAccountID = 101
ORDER BY InstrumentID
```

### 8.3 Query history: See how a position evolved over time

```sql
SELECT
    InstrumentID, Units, IsBuy, AvgRate, UpdateTime,
    SysStartTime, SysEndTime
FROM Hedge.Netting
FOR SYSTEM_TIME ALL
WHERE LiquidityAccountID = 101 AND InstrumentID = 1
ORDER BY SysStartTime
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.AddOrUpdateNetting | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.AddOrUpdateNetting.sql*
