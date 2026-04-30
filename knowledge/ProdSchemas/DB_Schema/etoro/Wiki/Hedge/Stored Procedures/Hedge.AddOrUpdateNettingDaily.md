# Hedge.AddOrUpdateNettingDaily

> Inserts a new time-series row into Hedge.NettingDaily for each position state change (append-only, no update logic), recording the full netting position history for daily reconciliation and analytics.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT-only into Hedge.NettingDaily - no upsert logic |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.AddOrUpdateNettingDaily` is the writer for the `Hedge.NettingDaily` time-series table. Despite the "AddOrUpdate" naming, this procedure performs only INSERTs - there is no UPDATE logic. Each call appends a new row recording the state of a hedge position at a specific UpdateTime, building a cumulative history of position changes.

The distinction from `Hedge.AddOrUpdateNetting` is fundamental:
- **AddOrUpdateNetting** maintains the CURRENT state in `Hedge.Netting` (one row per position, upserted)
- **AddOrUpdateNettingDaily** appends EVERY change to `Hedge.NettingDaily` (a new row per change, append-only)

NettingDaily serves as a flat time-series for daily reconciliation and analytics that need direct row-level access to historical states, without using SQL Server's `FOR SYSTEM_TIME` syntax. The two tables are complementary: Netting gives current state, NettingDaily gives the history.

The "AddOrUpdate" name is misleading - it was likely named to match AddOrUpdateNetting for consistency, even though the semantics differ. There is no UpdateTime-based deduplication.

---

## 2. Business Logic

### 2.1 Append-Only: Pure INSERT, No UPDATE

**What**: Unlike AddOrUpdateNetting, there is no "check if exists then update" logic here.

**Columns/Parameters Involved**: All parameters

**Rules**:
- Only one code path: INSERT INTO Hedge.NettingDaily
- PK = (LiquidityAccountID, InstrumentID, UpdateTime) - allows multiple rows per position pair differentiated by UpdateTime
- If the same (LiquidityAccountID, InstrumentID, UpdateTime) is inserted twice, a PK violation will occur
- TRY/CATCH with THROW - PK violations propagate to caller
- Caller is responsible for ensuring unique UpdateTime per call for the same instrument+account pair

### 2.2 Parameter Parity with AddOrUpdateNetting

**What**: Identical parameter signature to AddOrUpdateNetting, enabling symmetric calling.

**Rules**:
- Same 9 parameters in identical order and types
- Calling code can invoke both procedures in tandem: AddOrUpdateNetting for current state, AddOrUpdateNettingDaily for history

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LiquidityAccountID | INT | NO | - | CODE-BACKED | LP account holding the hedge position. Part of NettingDaily composite PK. FK to Trade.LiquidityAccounts. |
| 2 | @HedgeServerID | INT | NO | - | CODE-BACKED | Hedge server managing this position at the time of this snapshot. FK to Trade.HedgeServer. |
| 3 | @InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument being hedged. Part of NettingDaily composite PK. FK to Trade.Instrument. |
| 4 | @Units | DECIMAL(16,2) | NO | - | CODE-BACKED | Net aggregate position size in units at this point in time. |
| 5 | @IsBuy | BIT | NO | - | CODE-BACKED | Net position direction at this point: 1=net long, 0=net short. |
| 6 | @AvgRate | dtPrice | NO | - | CODE-BACKED | Volume-weighted average entry rate for the position at this snapshot time. Uses dtPrice UDT. |
| 7 | @ValueDate | DATE | NO | - | CODE-BACKED | Settlement value date applicable at this point in time. |
| 8 | @ExecTime | DATETIME | NO | - | CODE-BACKED | Execution timestamp of the hedge trade that created this position state. |
| 9 | @UpdateTime | DATETIME | NO | - | CODE-BACKED | Timestamp of this position state change. Part of NettingDaily composite PK - must be unique per (LiquidityAccountID, InstrumentID) pair. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @LiquidityAccountID | Trade.LiquidityAccounts | Implicit | LP account for this position snapshot |
| @HedgeServerID | Trade.HedgeServer | Implicit | Hedge server context |
| @InstrumentID | Trade.Instrument | Implicit | Instrument being tracked |
| (writes to) | Hedge.NettingDaily | INSERT | Append-only time-series target |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Called by hedge engine execution layer alongside AddOrUpdateNetting.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.AddOrUpdateNettingDaily (procedure)
└── Hedge.NettingDaily (table) - INSERT target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.NettingDaily | Table | INSERT target for time-series position history |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.NettingDaily | Table | Written by this procedure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- TRY/CATCH with THROW - errors propagate to caller
- No transaction wrapper - single INSERT auto-commits
- @AvgRate typed as `dtPrice` UDT - matches NettingDaily column type

---

## 8. Sample Queries

### 8.1 Execute: Append a position state change record

```sql
EXEC Hedge.AddOrUpdateNettingDaily
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

### 8.2 Query: Full position change history for an account+instrument pair

```sql
SELECT
    LiquidityAccountID,
    InstrumentID,
    Units,
    IsBuy,
    AvgRate,
    UpdateTime,
    ExecTime
FROM Hedge.NettingDaily WITH (NOLOCK)
WHERE LiquidityAccountID = 101 AND InstrumentID = 1
ORDER BY UpdateTime
```

### 8.3 Compare current state vs daily history

```sql
-- Current state (1 row per position)
SELECT N.LiquidityAccountID, N.InstrumentID, N.Units, N.AvgRate, N.UpdateTime AS CurrentUpdateTime
FROM Hedge.Netting N WITH (NOLOCK)
WHERE N.LiquidityAccountID = 101

UNION ALL

-- History (all changes)
SELECT ND.LiquidityAccountID, ND.InstrumentID, ND.Units, ND.AvgRate, ND.UpdateTime AS HistoryUpdateTime
FROM Hedge.NettingDaily ND WITH (NOLOCK)
WHERE ND.LiquidityAccountID = 101
ORDER BY 1, 2, 5
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.AddOrUpdateNettingDaily | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.AddOrUpdateNettingDaily.sql*
