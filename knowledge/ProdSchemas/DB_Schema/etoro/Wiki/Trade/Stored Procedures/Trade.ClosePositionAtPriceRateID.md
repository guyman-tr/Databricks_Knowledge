# Trade.ClosePositionAtPriceRateID

> Batch-closes positions at specified historical price rate IDs by looking up the actual spreaded prices from HistoryCurrencyPrice_Active, building dynamic EXEC commands for Trade.ManualPositionClose_Crisis, and executing each close in a cursor with error tracking.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionPrice (TVP mapping PositionIDs to PriceRateIDs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ClosePositionAtPriceRateID is a batch close tool that closes multiple positions, each at a specific historical price rate. This is used when positions need to be closed retroactively at the price that was valid at a specific point in time (e.g., when the system failed to close them at the correct moment due to an outage or error).

The procedure accepts a TVP containing PositionID → PriceRateID mappings. For each position, it looks up the actual Bid/Ask prices from the historical price archive (dbo.HistoryCurrencyPrice_Active), calculates the appropriate closing rate based on whether the position is "real" (uses Bid+SkewValue) or CFD (uses BidSpreaded), then executes Trade.ManualPositionClose_Crisis via dynamic SQL.

Key features:
- **Date range validation**: Rejects requests spanning more than 2 days to prevent excessive history scans
- **Debug mode**: When @isDebug=1, prints the close commands without executing
- **Error resilience**: Each close is individually TRY/CATCH wrapped; failures are captured in the result set
- **Result reporting**: Returns the full #PositionInstrument table showing which positions were closed, which failed, and the error details

---

## 2. Business Logic

### 2.1 Price Lookup

**What**: Resolves PriceRateIDs to actual Bid/Ask/Spreaded prices.

**Rules**:
- Source: dbo.HistoryCurrencyPrice_Active (partitioned historical price archive)
- Only queried when TVP has NULL BidSpreaded or AskSpreaded (price lookup needed)
- OPTION (RECOMPILE) on the lookup query for optimal plan with temp table
- Date range filter: HCP.Occurred BETWEEN @DateFrom AND @DateTo

### 2.2 Real vs CFD Price Selection

**What**: Uses different price columns based on position type.

**Rules**:
- FnIsRealPosition(IsSettled, InstrumentID): determines if position is "real"
- Real positions: use Bid+SkewValueBid / Ask+SkewValueAsk (raw prices with skew)
- CFD positions: use BidSpreaded / AskSpreaded (includes markup)

### 2.3 Dynamic SQL Close Execution

**What**: Builds and executes dynamic EXEC commands for each position.

**Rules**:
- Command format: `EXEC Trade.ManualPositionClose_Crisis @PositionID=..., @BidSpread=..., @AskSpread=..., @OperationID=..., @CloseActionType=..., @LastOpConversionRate=..., @LastOpConversionRateID=...`
- If CTE lookup fails (CloseCommand IS NULL): RAISERROR 'PriceRateID wasn't found'
- @isDebug=0: executes; @isDebug=1: only PRINT

### 2.4 Date Range Safety

**What**: Limits the historical date range to prevent expensive scans.

**Rules**:
- DATEDIFF(DAY, @DateFrom, @DateTo) > 2 → RAISERROR
- Message: "split the list so every list will contain up to 2 day range"

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DateFrom | DATETIME | NO | - | CODE-BACKED | Earliest date for historical price lookup. Must be within 2 days of @DateTo. |
| 2 | @DateTo | DATETIME | NO | - | CODE-BACKED | Latest date for historical price lookup. |
| 3 | @PositionPrice | Trade.PositionPriceRateIDTableType READONLY | NO | - | CODE-BACKED | TVP mapping PositionID to PriceRateID (and optionally BidSpreaded/AskSpreaded). |
| 4 | @isDebug | INT | YES | 0 | CODE-BACKED | When 1, prints close commands without executing. When 0, executes closes. |
| 5 | @OperationID | INT | NO | - | CODE-BACKED | Batch operation ID passed to Trade.ManualPositionClose_Crisis for audit. |
| 6 | @CloseActionType | INT | YES | NULL | CODE-BACKED | Override close action type. Passed to ManualPositionClose_Crisis. |
| 7 | @LastOpConversionRate | dtPrice | YES | NULL | CODE-BACKED | Override conversion rate for the close. |
| 8 | @LastOpConversionRateID | BIGINT | YES | -1 | CODE-BACKED | Override conversion rate ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.Position | SELECT | Reads position data for each PositionID |
| FROM | BackOffice.Customer | SELECT | Gets ManagerID |
| FROM | dbo.HistoryCurrencyPrice_Active | SELECT | Historical price lookup by PriceRateID |
| APPLY | Trade.FnIsRealPosition | FUNCTION | Determines real vs CFD price selection |
| EXEC (dynamic) | Trade.ManualPositionClose_Crisis | EXEC | Closes each position via dynamic SQL |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (none found in SSDT) | - | - | Called by DBA/admin tools for retroactive closes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ClosePositionAtPriceRateID (procedure)
+-- Trade.Position (view)
+-- BackOffice.Customer (table)
+-- dbo.HistoryCurrencyPrice_Active (table/view)
+-- Trade.FnIsRealPosition (function)
+-- Trade.ManualPositionClose_Crisis (procedure) [dynamic]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | SELECT - position data |
| BackOffice.Customer | Table | SELECT - manager ID |
| dbo.HistoryCurrencyPrice_Active | Table/View | SELECT - historical prices |
| Trade.FnIsRealPosition | Function | CROSS APPLY - position type |
| Trade.ManualPositionClose_Crisis | Procedure | EXEC (dynamic) - closes positions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found in SSDT) | - | DBA tooling |

---

## 7. Technical Details

### 7.1 Indexes

Created on temp tables during execution:
- `#PositionInstrument`: Clustered on (PriceRateID, InstrumentID), NonClustered on (PositionID)
- `#price`: Clustered on (PriceRateID, InstrumentID)

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| 2-day date range | Validation | @DateFrom to @DateTo must be ≤ 2 days |
| Dynamic SQL | Execution | Commands built as strings and EXEC'd |
| Debug mode | Safety | @isDebug=1 prevents execution |

---

## 8. Sample Queries

### 8.1 Prepare and execute batch close

```sql
DECLARE @pp Trade.PositionPriceRateIDTableType;
INSERT INTO @pp (PositionID, PriceRateID)
VALUES (12345, 99999), (12346, 99998);

EXEC Trade.ClosePositionAtPriceRateID
    @DateFrom = '2026-03-14',
    @DateTo = '2026-03-15',
    @PositionPrice = @pp,
    @isDebug = 1,
    @OperationID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 9.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ClosePositionAtPriceRateID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ClosePositionAtPriceRateID.sql*
