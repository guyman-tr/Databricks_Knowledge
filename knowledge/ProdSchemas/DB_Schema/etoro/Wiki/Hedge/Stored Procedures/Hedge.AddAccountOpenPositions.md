# Hedge.AddAccountOpenPositions

> Inserts a single open hedge position record for a given hedge server, liquidity account, and instrument into the AccountOpenPositions store.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes to Hedge.AccountOpenPositions (HedgeServerID, LiquidityAccountID, InstrumentID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.AddAccountOpenPositions` is the primitive writer for the hedge open position store. Each call records one snapshot entry representing how much exposure the hedge server currently holds in a given instrument on a given liquidity account - expressed as unrealized net P&L in USD and as a notional hedged amount in USD - along with the price rate snapshot that anchors the valuation.

This procedure exists as the atomic building block for the open position feed. Without it, the hedge system would have no mechanism to persist the current state of its open book per account and instrument. It feeds the downstream reporting and monitoring pipeline that compares hedge account exposure to customer book exposure.

Data flows from the hedge server engine: the hedge server computes the aggregate open position values and calls this procedure once per (HedgeServerID, LiquidityAccountID, InstrumentID) combination. A parallel procedure `Hedge.AddAccountPositionsFromNetting` performs the same INSERT but derives values by computing from the Netting table rather than receiving pre-computed values. The deletion counterpart `Hedge.DelAccountOpenPositions` enforces a 30-day rolling retention on this table. Note: `Hedge.AccountOpenPositions` is not tracked in the SSDT project (no table DDL file), indicating it is either a legacy or external-managed table.

Change history: The procedure comment records a 2012 change (FB 17303) upgrading `MarketPriceRateID` and `PriceRateID` from INT to BIGINT.

---

## 2. Business Logic

### 2.1 Primitive Insert - No Upsert Logic

**What**: The procedure performs a plain INSERT with no duplicate check or merge logic.

**Columns/Parameters Involved**: `@HedgeServerID`, `@LiquidityAccountID`, `@InstrumentID`

**Rules**:
- No EXISTS check before INSERT - calling code is responsible for ensuring no duplicate
- If AccountOpenPositions has a unique constraint, duplicates will raise an error to the caller
- Companion procedure `AddAccountPositionsFromNetting` derives the same values from Hedge.Netting and inserts them via SELECT, not VALUES

**Diagram**:
```
Hedge Server Engine
      |
      | (computes open position values)
      v
Hedge.AddAccountOpenPositions(@HedgeServerID, @LiquidityAccountID, @InstrumentID, ...)
      |
      v
INSERT INTO Hedge.AccountOpenPositions
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | INTEGER | NO | - | CODE-BACKED | Identifier of the hedge server instance managing this position. FK to Trade.HedgeServer. Determines which hedge engine owns this open position record. |
| 2 | @LiquidityAccountID | INTEGER | NO | - | CODE-BACKED | Identifier of the liquidity provider account where the hedge position is held. FK to Trade.LiquidityAccounts. |
| 3 | @InstrumentID | INTEGER | NO | - | CODE-BACKED | Financial instrument being hedged (e.g., EUR/USD, AAPL). FK to Trade.Instrument. |
| 4 | @UnrealizedNetPL | decimal(14,4) | NO | - | CODE-BACKED | Current floating P&L on the open hedge position in USD, at the time of this snapshot. Positive = gain, negative = loss. |
| 5 | @NetHedgedInUSD | decimal(14,4) | NO | - | CODE-BACKED | Notional dollar value of the net hedged position. Represents the market exposure value (units x price) in USD equivalent. |
| 6 | @PriceRateID | BIGINT | NO | - | CODE-BACKED | Reference to the price rate snapshot used to value this position. Changed from INT to BIGINT in 2012 (FB 17303) to support high-volume rate ID sequences. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeServerID | Trade.HedgeServer | Implicit | Hedge server managing this position |
| @LiquidityAccountID | Trade.LiquidityAccounts | Implicit | LP account holding the hedge position |
| @InstrumentID | Trade.Instrument | Implicit | Instrument being hedged |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Called externally by the hedge server application.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.AddAccountOpenPositions (procedure)
└── Hedge.AccountOpenPositions (table - not in SSDT project)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AccountOpenPositions | Table | INSERT target - open hedge position store |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Hedge server application) | External | Calls this procedure to record open hedge positions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. No parameter validation in procedure body.

---

## 8. Sample Queries

### 8.1 Execute: Insert a single open position record

```sql
EXEC Hedge.AddAccountOpenPositions
    @HedgeServerID     = 1,
    @LiquidityAccountID = 101,
    @InstrumentID      = 1,
    @UnrealizedNetPL   = 1250.75,
    @NetHedgedInUSD    = 50000.00,
    @PriceRateID       = 9876543210
```

### 8.2 Verify: Check recent open positions for a hedge server

```sql
SELECT TOP 10 *
FROM Hedge.AccountOpenPositions WITH (NOLOCK)
WHERE HedgeServerID = 1
ORDER BY OccurredAt DESC
```

### 8.3 Compare open position values across procedures

```sql
-- Compare AddAccountOpenPositions (direct) vs AddAccountPositionsFromNetting (computed)
-- Both target the same table; this shows recent entries by instrument
SELECT TOP 20
    HedgeServerID,
    LiquidityAccountID,
    InstrumentID,
    UnrealizedNetPL,
    NetHedgedInUSD,
    PriceRateID
FROM Hedge.AccountOpenPositions WITH (NOLOCK)
ORDER BY OccurredAt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.3/10 (Elements: 9.0/10, Logic: 7.0/10, Relationships: 7.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.AddAccountOpenPositions | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.AddAccountOpenPositions.sql*
