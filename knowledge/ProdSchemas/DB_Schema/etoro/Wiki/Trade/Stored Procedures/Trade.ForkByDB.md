# Trade.ForkByDB

> Orchestrates an instrument fork: creates new positions on the post-fork instrument for all eligible customers who held the forked instrument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Fork operation recorded in Trade.PositionOpenByFork |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure implements the database-side logic for instrument forks. When an instrument is split (e.g., a cryptocurrency fork), customers who held the original instrument at fork time receive equivalent positions on the new instrument. The procedure nets units per customer (buy positive, sell negative), applies a conversion factor, and opens new positions via Trade.PositionOpenForFork.

Without this procedure, fork operations would require manual or external scripting. The procedure ensures consistency: only customers with leverage 1, positions opened after DateFrom, still open at DateOfFork, and not already forked are processed. Each fork is recorded in Trade.PositionOpenByFork for audit and deduplication.

Data flows when a fork job or operator invokes this procedure with the old and new instrument IDs, fork date, and rate/unit parameters. The procedure reads Trade.GetPositionData (view), Customer.CustomerMoney, and Trade.PositionOpenByFork; it writes via Trade.PositionOpenForFork and Trade.PositionOpenByFork.

---

## 2. Business Logic

### 2.1 Eligibility Rules for Fork

**What**: A customer is eligible if they hold the forked instrument with specific conditions.

**Columns/Parameters Involved**: `InstrumentID`, `InitDateTime`, `EndDateTime`, `Leverage`, `Trade.PositionOpenByFork`

**Rules**:
- GPD.InstrumentID = @ForekedInstrumentID (holds the forked instrument)
- InitDateTime >= @DateFrom (position opened after cutoff)
- ISNULL(EndDateTime, @DateOfFork) >= @DateOfFork (position still open at fork)
- Leverage = 1 (no leveraged positions forked)
- LEFT JOIN PositionOpenByFork F ON F.CID = CM.CID AND F.ForkDate = @DateOfFork; F.CID IS NULL (not already forked)
- HAVING SUM(netted units) > 0 (net long after unit aggregation)

### 2.2 Unit Netting and Conversion

**What**: Buy and sell positions are netted; result is multiplied by Factor for new instrument units.

**Columns/Parameters Involved**: `IsBuy`, `AmountInUnitsDecimal`, `@Factor`, `@UnitMargin`

**Rules**:
- NettedUnits = SUM(IIF(IsBuy='true', AmountInUnitsDecimal, -AmountInUnitsDecimal))
- UnitsToOpen = NettedUnits * @Factor
- NewPositionAmount = ROUND(NettedUnits * @Factor * @UnitMargin, 2)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ForekedInstrumentID | int | NO | - | CODE-BACKED | Original (forked) instrument ID. Positions on this instrument are migrated. |
| 2 | @NewInstrumentID | int | NO | - | CODE-BACKED | New instrument ID after fork. New positions are created on this instrument. |
| 3 | @DateOfFork | datetime | NO | - | CODE-BACKED | Date/time when the fork occurred. Used for eligibility and PositionOpenByFork.ForkDate. |
| 4 | @DateFrom | datetime | NO | - | CODE-BACKED | Cutoff date. Only positions opened on or after this date are eligible. |
| 5 | @InitForexRate | dtPrice | NO | - | CODE-BACKED | Initial forex rate for the new instrument. |
| 6 | @UnitMargin | dtPrice | NO | - | CODE-BACKED | Unit margin for the new instrument. Used to compute NewPositionAmount. |
| 7 | @LimitRate | dtPrice | NO | - | CODE-BACKED | Take-profit rate for new positions. |
| 8 | @StopRate | dtPrice | NO | - | CODE-BACKED | Stop-loss rate for new positions. |
| 9 | @Factor | decimal(16,8) | NO | - | CODE-BACKED | Unit conversion factor. Netted units * Factor = new instrument units. |
| 10 | @HedgeServerID | int | NO | - | CODE-BACKED | Hedge server ID for new positions. |
| 11 | @Units | int | NO | - | CODE-BACKED | Units value passed to PositionOpenForFork. |
| 12 | @pReason | int | NO | - | CODE-BACKED | Compensation reason ID for SetBalanceCompensation. |
| 13 | @InitForexPriceRateID | bigint | NO | - | CODE-BACKED | Initial forex price rate ID. |
| 14 | @LastOpConversionRate | dtPrice | NO | - | CODE-BACKED | Last operation conversion rate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.GetPositionData | View | Position data for eligibility and unit netting |
| JOIN | Customer.CustomerMoney | Implicit | Credit for #PositionsToFork |
| LEFT JOIN | Trade.PositionOpenByFork | Implicit | Exclude already-forked customers |
| EXEC | Trade.PositionOpenForFork | Procedure call | Create position per customer |
| SELECT/INSERT | Trade.Position | Table | Read new position; INSERT into PositionOpenByFork |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (External/Job) | EXEC | Procedure call | Invoked by fork orchestration |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ForkByDB (procedure)
├── Trade.GetPositionData (view)
├── Customer.CustomerMoney (table)
├── Trade.PositionOpenByFork (table)
├── Trade.Position (table)
└── Trade.PositionOpenForFork (procedure)
        ├── BackOffice.Customer (table)
        ├── Customer.CustomerMoney (table)
        ├── Customer.SetBalanceCompensation (procedure)
        └── Trade.PositionOpen (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionData | View | Source for position data and eligibility |
| Customer.CustomerMoney | Table | JOIN for Credit in #PositionsToFork |
| Trade.PositionOpenByFork | Table | LEFT JOIN for dedup; INSERT for audit |
| Trade.Position | Table | SELECT after PositionOpenForFork for INSERT data |
| Trade.PositionOpenForFork | Procedure | EXEC per eligible CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Fork orchestration job) | - | Invokes procedure for fork execution |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. Uses SET XACT_ABORT ON and TRY/CATCH. Comment in source: "17/11/2021 Bonnie Change positionID to bigint".

---

## 8. Sample Queries

### 8.1 Execute fork operation
```sql
EXEC Trade.ForkByDB
    @ForekedInstrumentID = 100,
    @NewInstrumentID = 101,
    @DateOfFork = '2025-01-15 12:00:00',
    @DateFrom = '2025-01-01 00:00:00',
    @InitForexRate = 50000.0,
    @UnitMargin = 5000.0,
    @LimitRate = 55000.0,
    @StopRate = 45000.0,
    @Factor = 1.0,
    @HedgeServerID = 1,
    @Units = 1,
    @pReason = 1,
    @InitForexPriceRateID = 12345,
    @LastOpConversionRate = 1.0;
```

### 8.2 Inspect fork audit records
```sql
SELECT ForkDate, PositionID, CID, InstrumentID, AmountInUnitsDecimal, Amount, Occurred
FROM Trade.PositionOpenByFork WITH (NOLOCK)
WHERE ForkDate = '2025-01-15 12:00:00'
ORDER BY CID;
```

### 8.3 Check eligible positions before fork (manual validation)
```sql
SELECT GPD.CID, GPD.InstrumentID, GPD.AmountInUnitsDecimal, GPD.IsBuy, GPD.InitDateTime, GPD.EndDateTime, GPD.Leverage
FROM Trade.GetPositionData AS GPD WITH (NOLOCK)
WHERE GPD.InstrumentID = 100
  AND GPD.InitDateTime >= '2025-01-01'
  AND ISNULL(GPD.EndDateTime, '2025-01-15') >= '2025-01-15'
  AND GPD.Leverage = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ForkByDB | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ForkByDB.sql*
