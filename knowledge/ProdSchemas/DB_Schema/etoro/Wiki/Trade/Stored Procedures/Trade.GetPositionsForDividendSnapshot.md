# Trade.GetPositionsForDividendSnapshot

> Takes a dividend snapshot for an instrument at market close time, returning all positions (open or recently closed) that were open at that moment, with IsSettled adjusted for any settlement-type changes that occurred after market close.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID, @MarketCloseDateTimeUtc, @PositionIDModDivider/@PositionIDModResult |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure captures the set of positions that were open at the moment a stock dividend's ex-date market close occurred, for the purpose of determining which customers are eligible to receive a dividend payment. A customer qualifies for a dividend if they held a position in the relevant instrument at the market close time (the "record date"). The procedure handles the complexity of positions that may have been open at market close but were subsequently closed before the snapshot is taken, and also corrects IsSettled for positions whose settlement type changed after market close (since dividend eligibility depends on IsSettled as of market close time, not the current value).

The procedure exists to serve the dividend distribution workflow executed by the DividendsApp. Dividend processing must be deterministic: the same snapshot must be reproducible. The @PositionIDModDivider/@PositionIDModResult parameters enable parallel execution - multiple workers each process a shard of positions by PositionID modulo, without overlap.

Data flows: Called by DividendsApp (EXECUTE permission). Two position sources are combined via UNION ALL: (1) Trade.PositionTbl for currently open positions (StatusID=1) that were open before @MarketCloseDateTimeUtc; (2) History.PositionSlim for positions that were open at market close (OpenOccurred <= @MarketCloseDateTimeUtc) but have since closed (CloseOccurred > @MarketCloseDateTimeUtc). Both sources exclude US customers (via Trade.IsUsUser). The IsSettled rollback step corrects positions where settlement type (IsSettled) was changed after market close - using the previous value from History.PositionChangeLog_Active.

---

## 2. Business Logic

### 2.1 Point-in-Time Snapshot at Market Close

**What**: Determines which positions were open precisely at @MarketCloseDateTimeUtc, regardless of current position status.

**Columns/Parameters Involved**: `@MarketCloseDateTimeUtc`, `IsPositionOpenOnSnapshot`, `Trade.PositionTbl.StatusID`, `History.PositionSlim.OpenOccurred`, `History.PositionSlim.CloseOccurred`

**Rules**:
- Open at snapshot = StatusID=1 AND Occurred <= @MarketCloseDateTimeUtc (still open, opened before close).
- Was open but closed since = OpenOccurred <= @MarketCloseDateTimeUtc AND CloseOccurred > @MarketCloseDateTimeUtc (closed after).
- IsPositionOpenOnSnapshot: 1 = position is still open; 0 = was open at snapshot but now closed.
- @SnapshotDateTime = GETUTCDATE() at procedure execution time (not @MarketCloseDateTimeUtc).

**Diagram**:
```
Timeline:
  |---[Occurred/OpenOccurred]---[MarketClose]---[CloseOccurred]---[NOW]
                                     ^
                                     Snapshot point

  Included in ResultSet:
  Case A (open):   Occurred <= MarketClose, StatusID=1         -> IsPositionOpenOnSnapshot=1
  Case B (closed): OpenOccurred <= MarketClose < CloseOccurred -> IsPositionOpenOnSnapshot=0
```

### 2.2 IsSettled Rollback (Historical Correction)

**What**: Corrects IsSettled to its value at market close time, rolling back any settlement-type changes that occurred AFTER market close.

**Columns/Parameters Involved**: `IsSettled`, `History.PositionChangeLog_Active.PreviousIsSettled`, `ChangeTypeID=13`

**Rules**:
- ChangeTypeID=13 in Dictionary.PCL_ChangeType = "Edit Is Settled" events.
- If a ChangeTypeID=13 event occurred AFTER @MarketCloseDateTimeUtc for a position in the snapshot, the position's IsSettled was different AT market close.
- The procedure uses PreviousIsSettled (the value BEFORE the change) from the change log to roll back.
- Only the earliest such change after market close is used (TOP(1) ORDER BY Occurred).
- Business reason (code comment): "Dividend eligibility depends on IsSettled at the exact market close moment, not the current value."

### 2.3 Parallelism via PositionID Modulo Sharding

**What**: @PositionIDModDivider and @PositionIDModResult enable parallel dividend processing across multiple worker instances.

**Columns/Parameters Involved**: `@PositionIDModDivider`, `@PositionIDModResult`

**Rules**:
- WHERE PositionID % @PositionIDModDivider = @PositionIDModResult.
- Example: 4 workers use Divider=4, Results=0,1,2,3. Each worker processes a distinct 25% shard.
- Consistent sharding: a position always belongs to the same worker regardless of how many times the snapshot is re-run.

### 2.4 US User Exclusion

**What**: US-registered customers are excluded from dividend snapshots.

**Columns/Parameters Involved**: `Trade.IsUsUser.IsUsUser`

**Rules**:
- CROSS APPLY Trade.IsUsUser(POS.CID) on each position.
- WHERE IU.IsUsUser = 0 - US users excluded.
- Applies to both open and closed-since branches.
- Regulatory or operational restriction: eToro US customers are handled separately.

### 2.5 Optional IsSettled Filter

**What**: @IsSettled (nullable) allows the caller to filter the final result to only real-stock or CFD positions.

**Columns/Parameters Involved**: `@IsSettled`, `IsSettled`

**Rules**:
- @IsSettled IS NULL -> return all positions regardless of settlement type.
- @IsSettled = 1 -> return only real stock positions (eligible for stock dividends).
- @IsSettled = 0 -> return only CFD positions.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | The instrument (stock) for which to take the dividend snapshot. Only positions holding this instrument are returned. |
| 2 | @MarketCloseDateTimeUtc | DATETIME | NO | - | CODE-BACKED | The ex-date market close time in UTC. Positions open at or before this moment are included. Positions that closed after this moment (but before now) are also included. |
| 3 | @IsSettled | BIT | YES | NULL | CODE-BACKED | Optional settlement type filter. NULL=all positions, 1=real stock positions only, 0=CFD positions only. Applied after IsSettled rollback correction. |
| 4 | @PositionIDModDivider | INT | NO | - | CODE-BACKED | Denominator for parallel sharding: PositionID % @PositionIDModDivider must equal @PositionIDModResult. Set to 1 to include all positions (no sharding). |
| 5 | @PositionIDModResult | INT | NO | - | CODE-BACKED | Expected modulo result for this worker's shard. Set to 0 when @PositionIDModDivider=1 for full processing. |

**Output Columns (from #PositionsSnapshot temp table)**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 6 | PositionID | BIGINT | NO | - | CODE-BACKED | The trading position that was open at market close time. |
| 7 | CID | INT | NO | - | CODE-BACKED | Customer ID of the position owner. |
| 8 | MirrorID | INT | YES | - | CODE-BACKED | CopyTrader mirror ID. 0/NULL = manual trade. |
| 9 | ParentPositionID | BIGINT | YES | - | CODE-BACKED | For copy-trade positions, the leader's position ID. 0 = root/manual. |
| 10 | IsSettled | BIT | NO | - | VERIFIED | Settlement type as of market close time (after historical rollback correction). 1=real stock position, 0=CFD. This is the primary dividend eligibility flag - real stock positions (IsSettled=1) receive stock dividends. |
| 11 | IsBuy | BIT | NO | - | VERIFIED | Direction: 1=Buy/Long. Dividend-eligible positions must be Buy (long) - short positions do not receive dividends. |
| 12 | AmountInUnitsDecimal | DECIMAL | NO | - | CODE-BACKED | Number of units (shares) held at market close time. Used to calculate proportional dividend payment. |
| 13 | SnapshotDateTime | DATETIME | NO | - | CODE-BACKED | Timestamp when the snapshot was taken (GETUTCDATE() at procedure execution). |
| 14 | IsPositionOpenOnSnapshot | BIT | NO | - | CODE-BACKED | 1 = position is still open now; 0 = position was open at market close but has since been closed. Dividend must be paid to closed positions before the position was settled. |
| 15 | GCID | INT | YES | - | CODE-BACKED | Group Customer ID from Customer.CustomerStatic. Used in dividend allocation calculations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID (open branch) | Trade.PositionTbl | Primary source | Open positions at market close time for the instrument |
| PositionID (closed branch) | History.PositionSlim | Primary source | Positions closed after market close but before now |
| CID | Customer.CustomerStatic | JOIN | GCID resolution |
| CID | Trade.IsUsUser | CROSS APPLY | US user exclusion check |
| PositionID | History.PositionChangeLog_Active | JOIN (ChangeTypeID=13) | IsSettled rollback - settlement type changes after market close |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DividendsApp (DB user) | GRANT EXECUTE | Permission | The dividend processing application calls this per instrument per ex-date |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionsForDividendSnapshot (procedure)
├── Trade.PositionTbl (table)
├── History.PositionSlim (table)
├── Customer.CustomerStatic (table)
├── Trade.IsUsUser (function)
└── History.PositionChangeLog_Active (table) [for IsSettled rollback]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Open positions at market close for the instrument (StatusID=1, Occurred <= @MarketCloseDateTimeUtc) |
| History.PositionSlim | Table | Positions that were open at market close but have since been closed |
| Customer.CustomerStatic | Table | GCID lookup |
| Trade.IsUsUser | Function | CROSS APPLY to exclude US customers |
| History.PositionChangeLog_Active | Table | IsSettled rollback: ChangeTypeID=13 events after @MarketCloseDateTimeUtc |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DividendsApp (application service) | External | Calls once per instrument per ex-date, with sharding parameters, to determine dividend-eligible positions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure (temp tables use: PRIMARY KEY on #PositionsSnapshot.PositionID, NONCLUSTERED INDEX IX_PositionID on #tblPreviousIsSettled.PositionID).

### 7.2 Constraints

None explicit beyond business rules.

---

## 8. Sample Queries

### 8.1 Take a full snapshot for an instrument (single worker)

```sql
EXEC Trade.GetPositionsForDividendSnapshot
    @InstrumentID = 32,                          -- e.g., Apple
    @MarketCloseDateTimeUtc = '2024-01-12 21:00:00', -- market close on ex-date
    @IsSettled = NULL,                           -- all settlement types
    @PositionIDModDivider = 1,                   -- no sharding
    @PositionIDModResult = 0;
```

### 8.2 Take a snapshot for real stock positions only (dividend-eligible)

```sql
EXEC Trade.GetPositionsForDividendSnapshot
    @InstrumentID = 32,
    @MarketCloseDateTimeUtc = '2024-01-12 21:00:00',
    @IsSettled = 1,                              -- real stock only
    @PositionIDModDivider = 1,
    @PositionIDModResult = 0;
```

### 8.3 Parallel sharding: worker 2 of 4

```sql
EXEC Trade.GetPositionsForDividendSnapshot
    @InstrumentID = 32,
    @MarketCloseDateTimeUtc = '2024-01-12 21:00:00',
    @IsSettled = NULL,
    @PositionIDModDivider = 4,
    @PositionIDModResult = 1;  -- this worker handles PositionID % 4 = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionsForDividendSnapshot | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPositionsForDividendSnapshot.sql*
