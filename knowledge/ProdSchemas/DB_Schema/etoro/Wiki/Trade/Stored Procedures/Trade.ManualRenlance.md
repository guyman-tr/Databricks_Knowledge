# Trade.ManualRenlance

> Manual rebalancing script generator: given a set of position/price-rate pairs, resolves historical prices, logs the operation, and returns a set of ready-to-execute Trade.ManualPositionClose_Crisis EXEC strings for DBA review and execution.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @i (Trade.Rebalance TVP) - position/price-rate pairs to rebalance |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ManualRenlance (note: intentional or typo of "ManualRebalance") is a DBA-operated script-generation tool for manual portfolio rebalancing. Given a set of positions and their target historical price rates, it resolves the Bid/Ask prices from dbo.HistoryCurrencyPrice_Active, determines whether each position is a real stock (uses raw prices) or CFD (uses spread prices), logs the rebalancing batch to History.ManualOperationPositionClose_Crisis, and returns a SELECT result set containing ready-to-run EXEC command strings for Trade.ManualPositionClose_Crisis.

This procedure does NOT close positions itself - it generates the commands that the DBA can then review and execute in sequence. This design gives the DBA a "preview" of what will be closed and at what price before committing.

The 2022 change note (Approved by Gutman) indicates PriceLog was moved to Azure for performance - dbo.HistoryCurrencyPrice_Active is the local/active view of that historical price data.

---

## 2. Business Logic

### 2.1 Two-Phase Price Resolution

**What**: Builds the close prices by joining the input TVP through Trade.Position (for InstrumentID) and then to dbo.HistoryCurrencyPrice_Active (for the specific PriceRateID prices).

**Columns/Parameters Involved**: `@i.PositionID`, `@i.PriceRateID`, `Trade.Position.InstrumentID`, `dbo.HistoryCurrencyPrice_Active.Bid/Ask/BidSpreaded/AskSpreaded`

**Rules**:
- Phase 1: #step1 = TVP data + clustered index on PositionID.
- Phase 2: #step2 = JOIN with Trade.Position (partition-aware: PartitionCol = PositionID % 50) to get InstrumentID and PriceRateID together.
- Phase 3: #priceStep1 = JOIN dbo.HistoryCurrencyPrice_Active ON InstrumentID AND PriceRateID WHERE Occurred > GETDATE()-4 (last 4 days - prevents resolving stale rates).
- If a PriceRateID is not found in the last 4 days, those positions will be absent from the final output.

**Diagram**:
```
@i (Trade.Rebalance TVP)
    -> #step1 (PositionID, PriceRateID)
        -> #step2 JOIN Trade.Position -> (PositionID, PriceRateID, InstrumentID)
            -> #priceStep1 JOIN dbo.HistoryCurrencyPrice_Active
                -> (Bid, Ask, BidSpreaded, AskSpreaded, InstrumentID, Occurred, PriceRateID)
```

### 2.2 Real vs CFD Price Selection

**What**: Uses Trade.FnIsRealPosition to determine whether to use raw or spread-adjusted prices for each position.

**Columns/Parameters Involved**: `Trade.Position.IsSettled`, `Trade.Position.InstrumentID`, `FnIsRealPosition.IsRealPosition`

**Rules**:
- CROSS APPLY Trade.FnIsRealPosition(P.IsSettled, P.InstrumentID) returns IsRealPosition (0 or 1).
- If IsRealPosition=1 (real stock): BidSpread = Bid (raw price, no spread applied).
- If IsRealPosition=0 (CFD): BidSpread = BidSpreaded (spread-adjusted price).
- Same logic for Ask/AskSpreaded.
- This ensures real stock positions are closed at the exact historical price, while CFD positions include the spread cost.

### 2.3 Script Generation Output

**What**: The final SELECT generates concatenated EXEC command strings rather than executing closes directly.

**Rules**:
- Output contains: full EXEC string for Trade.ManualPositionClose_Crisis (with @UserName_LOWER, @PositionID, @BidSpread, @AskSpread, @OperationID), plus CID, PositionID, PositionOpened, InstrumentID, AmountInUnitsDecimal, IsBuy for context.
- @OperationID = @@IDENTITY of the log row just inserted into History.ManualOperationPositionClose_Crisis - all closes in this batch share the same OperationID.
- The DBA reviews the output, verifies the prices and positions, then pastes and executes the EXEC commands.
- ManualOperationReasonID=1 in the history log represents "Rebalancing"; OperationDescription includes the date.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @username | varchar(50) | NO | - | CODE-BACKED | Username of the DBA or operator initiating the rebalance. Written to History.ManualOperationPositionClose_Crisis.UserName and included in each generated EXEC string as @UserName_LOWER for position ownership validation in ManualPositionClose_Crisis. |
| 2 | @i | Trade.Rebalance (READONLY TVP) | NO | - | CODE-BACKED | Table-valued parameter with columns (PositionID BIGINT, PriceRateID BIGINT). Each row specifies one position to rebalance and the historical price rate to use for its close price. Must be READONLY. See Trade.Rebalance UDT documentation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @i.PositionID | Trade.Position | JOIN/Read | Resolves InstrumentID for each position; uses partition-aware JOIN (PartitionCol = PositionID % 50) |
| @i.PriceRateID, InstrumentID | dbo.HistoryCurrencyPrice_Active | JOIN/Read | Fetches historical Bid/Ask/BidSpreaded/AskSpreaded for the specific price rate (within last 4 days) |
| @username, OperationID | History.ManualOperationPositionClose_Crisis | Write | Logs the batch rebalance operation; @@IDENTITY becomes @iden used as @OperationID in all generated EXEC strings |
| IsSettled, InstrumentID | Trade.FnIsRealPosition | CROSS APPLY | Determines raw vs spread price for each position |
| @i | Trade.Rebalance | UDT Reference | TVP type definition for the input parameter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No callers found) | - | - | Called directly by DBA or back-office tools; no SP callers in Trade schema. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ManualRenlance (procedure)
├── Trade.Rebalance (type - TVP)
├── Trade.Position (view/table)
├── dbo.HistoryCurrencyPrice_Active (table/view)
├── Trade.FnIsRealPosition (function)
└── History.ManualOperationPositionClose_Crisis (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Rebalance | User Defined Type | TVP input parameter type (PositionID, PriceRateID) |
| Trade.Position | View | JOINed NOLOCK with partition-aware condition to resolve InstrumentID per PositionID |
| dbo.HistoryCurrencyPrice_Active | Table/View | JOINed NOLOCK to resolve historical Bid/Ask/BidSpreaded/AskSpreaded by PriceRateID and InstrumentID; filtered to last 4 days |
| Trade.FnIsRealPosition | Function | CROSS APPLied with Position.IsSettled and InstrumentID to determine raw vs spread price selection |
| History.ManualOperationPositionClose_Crisis | Table | INSERTed to log the rebalancing operation; ManualOperationReasonID=1 (Rebalancing) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No dependents found) | - | Invoked directly by DBA; no SP consumers in the schema. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Internally creates clustered index CIX on #step1 (PositionID), clustered index CIX on #step2 (PositionID), nonclustered index IX1 on #step2 (PriceRateID, InstrumentID), and clustered index CIX on #priceStep1 (PriceRateID, InstrumentID) for join performance.

### 7.2 Constraints

N/A for stored procedure. Note: no explicit transaction; the INSERT log and SELECT output are not transactionally linked. If the SELECT fails, the History log row remains.

---

## 8. Sample Queries

### 8.1 Find recent rebalancing batch operations logged to History

```sql
SELECT TOP 10 MO.ManualOperationID, MO.UserName, MO.ManualOperationReasonID,
       MO.OperationDescription, MO.InsertDate
FROM History.ManualOperationPositionClose_Crisis AS MO WITH (NOLOCK)
WHERE MO.ManualOperationReasonID = 1
ORDER BY MO.InsertDate DESC;
```

### 8.2 Check which positions in a rebalance TVP would have resolvable prices

```sql
SELECT P.PositionID, P.InstrumentID, PR.PriceRateID,
       PR.Bid, PR.Ask, PR.BidSpreaded, PR.AskSpreaded, PR.Occurred
FROM Trade.Position AS P WITH (NOLOCK)
INNER JOIN dbo.HistoryCurrencyPrice_Active AS PR WITH (NOLOCK)
    ON PR.InstrumentID = P.InstrumentID
    AND PR.PriceRateID = <PriceRateID>
    AND PR.Occurred > GETDATE() - 4
WHERE P.PositionID IN (<PositionID1>, <PositionID2>);
```

### 8.3 Identify positions where IsRealPosition determines raw vs spread pricing

```sql
SELECT P.PositionID, P.InstrumentID, P.IsSettled, FRP.IsRealPosition,
       P.IsBuy
FROM Trade.Position AS P WITH (NOLOCK)
CROSS APPLY Trade.FnIsRealPosition(P.IsSettled, P.InstrumentID) AS FRP
WHERE P.PositionID IN (<PositionID1>, <PositionID2>);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.ManualRenlance | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ManualRenlance.sql*
