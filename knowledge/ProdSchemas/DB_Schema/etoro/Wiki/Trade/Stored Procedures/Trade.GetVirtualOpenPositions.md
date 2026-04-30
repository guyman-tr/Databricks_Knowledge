# Trade.GetVirtualOpenPositions

> Returns detailed open position data for a customer (by GCID) including normalized bid/ask spreads and copy-trade parent linkage, used by BI analytics for virtual/demo account position reporting.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Input: @GCID (global customer ID); Returns: 12 columns per open position |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetVirtualOpenPositions retrieves the full open position dataset for a single customer identified by their Global Customer ID (GCID). It combines position data from Trade.Position with instrument precision from Trade.ProviderToInstrument to normalize raw spread pip values into human-readable spread rates. The LEFT JOIN to dbo.RealOpenPositions (a synonym for Trade.Position) resolves the parent/leader CID for copy-trade positions by looking up the ParentPositionID in the positions view.

The procedure is primarily used by BI/analytics roles (PROD_BIadmins) to examine the full open position state for a given customer, including both manual and copy-trade positions. The name "Virtual Open Positions" reflects historical eToro product terminology where CopyTrader relationships were described as "virtual" positions that mirror a leader's portfolio.

Data flows: the customer GCID is joined to Customer.Customer to filter Trade.Position by CID. ProviderToInstrument provides the decimal Precision for each instrument, which is used to convert SpreadedPipBid and SpreadedPipAsk from their stored integer pip representation to decimal spread values (`pip / 10^Precision`). The LEFT JOIN to RealOpenPositions retrieves the parent/leader's CID for positions that are copies of a leader's trade (ParentPositionID > 0).

**Note**: The FROM clause uses comma-syntax cross-join between ProviderToInstrument and Position (equi-joined on InstrumentID without a ProviderID filter). If an instrument has configurations for multiple providers, this may return duplicate position rows - one per provider configuration.

---

## 2. Business Logic

### 2.1 Spread Normalization

**What**: Converts raw integer spread pip values to decimal spread rates using instrument precision.

**Columns/Parameters Involved**: `Trade.Position.SpreadedPipBid`, `Trade.Position.SpreadedPipAsk`, `Trade.ProviderToInstrument.Precision`

**Rules**:
- SpreadedPipBid and SpreadedPipAsk are stored as integer pip values (e.g., 3 pips)
- Precision from ProviderToInstrument defines the decimal places for the instrument (e.g., 4 for EUR/USD)
- SpreadBid output = SpreadedPipBid / POWER(10, Precision) -> yields the actual spread rate (e.g., 3 / 10000 = 0.0003)
- SpreadAsk output = SpreadedPipAsk / POWER(10, Precision) -> symmetric calculation

### 2.2 Copy-Trade Parent Linkage

**What**: For copy-trade positions, resolves the parent/leader's CID via the ParentPositionID reference.

**Columns/Parameters Involved**: `Trade.Position.ParentPositionID`, `dbo.RealOpenPositions.CID` (aliased as ParentCID)

**Rules**:
- Copy-trade positions have ParentPositionID pointing to the leader's PositionID in Trade.Position
- LEFT JOIN to dbo.RealOpenPositions (= Trade.Position) on ParentPositionID = ROP.PositionID fetches the leader's CID
- ISNULL(ROP.CID, 0) -> 0 when the position is not a copy-trade (manual position), or the parent position is closed
- ISNULL(POS.MirrorID, 0) -> 0 for manual positions; >0 identifies the CopyTrader mirror relationship
- ISNULL(POS.ParentPositionID, 0) -> 0 for root positions (not copy-trade)

**Diagram**:
```
POS (Trade.Position) -- ParentPositionID --> ROP (dbo.RealOpenPositions = Trade.Position)
  Manual position:    ParentPositionID = NULL  -> ParentCID = 0
  Copy-trade position: ParentPositionID = leader's PositionID -> ParentCID = leader's CID
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters:** | | | | | | |
| 1 | @GCID | INT | NO | - | CODE-BACKED | Global Customer ID. Used to filter Customer.Customer and hence Trade.Position to one customer's open positions. |
| **Output columns:** | | | | | | |
| 2 | CID | int | NO | - | CODE-BACKED | Internal customer ID. From Trade.Position.CID. The customer whose open positions are returned. |
| 3 | PositionID | bigint | NO | - | CODE-BACKED | Unique identifier of the open position. From Trade.Position.PositionID. |
| 4 | InstrumentID | int | NO | - | CODE-BACKED | Instrument being traded. From Trade.Position.InstrumentID. Joins to Trade.Instrument for name/type. |
| 5 | IsBuy | bit | NO | - | CODE-BACKED | Trade direction: 1=Buy/Long, 0=Sell/Short. From Trade.Position.IsBuy. |
| 6 | InitDateTime | datetime | NO | - | CODE-BACKED | When the position was opened. From Trade.Position.InitDateTime. |
| 7 | InitForexRate | decimal | NO | - | CODE-BACKED | Opening rate (price) of the position. From Trade.Position.InitForexRate. |
| 8 | SpreadBid | decimal | NO | - | CODE-BACKED | Normalized bid spread at position open: SpreadedPipBid / POWER(10, PTI.Precision). Represents the actual bid-side spread rate applied at entry. |
| 9 | SpreadAsk | decimal | NO | - | CODE-BACKED | Normalized ask spread at position open: SpreadedPipAsk / POWER(10, PTI.Precision). Represents the actual ask-side spread rate applied at entry. |
| 10 | Amount | money | NO | - | CODE-BACKED | Dollar amount invested in the position. From Trade.Position.Amount. |
| 11 | Leverage | int | NO | - | CODE-BACKED | Leverage multiplier applied to the position (e.g., 1 for real stocks, 2-200 for CFDs). From Trade.Position.Leverage. |
| 12 | StopRate | decimal | YES | - | CODE-BACKED | Stop-loss rate for the position. From Trade.Position.StopRate (via PositionTreeInfo). NULL if no stop-loss is set. |
| 13 | LimitRate | decimal | YES | - | CODE-BACKED | Take-profit rate for the position. From Trade.Position.LimitRate (via PositionTreeInfo). NULL if no take-profit is set. |
| 14 | LotCountDecimal | decimal | YES | - | CODE-BACKED | Number of lots (contract units) in the position. From Trade.Position.LotCountDecimal. Used for lot-based fee and P&L calculations. |
| 15 | OrderID | int | NO | -1 | CODE-BACKED | Associated order ID, or -1 if the position was opened without a pending order. ISNULL(Trade.Position.OrderID, -1). |
| 16 | ParentPositionID | int | NO | 0 | CODE-BACKED | The leader's PositionID if this is a copy-trade position, or 0 for manual positions. ISNULL(Trade.Position.ParentPositionID, 0). |
| 17 | ParentCID | int | NO | 0 | CODE-BACKED | The leader's CID if this is a copy-trade position (resolved via ParentPositionID -> dbo.RealOpenPositions), or 0 for manual positions or closed parent positions. ISNULL(ROP.CID, 0). |
| 18 | MirrorID | int | NO | 0 | CODE-BACKED | CopyTrader mirror relationship ID, or 0 for manual positions. ISNULL(Trade.Position.MirrorID, 0). Links to Trade.Mirror.MirrorID for the copy relationship context. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.Customer | Lookup (INNER JOIN) | Resolves GCID to CID for filtering positions |
| CID, PositionID, all position columns | Trade.Position | SELECT FROM (INNER) | Primary source of open position data |
| SpreadBid, SpreadAsk (computed) | Trade.ProviderToInstrument | SELECT FROM (cross-join on InstrumentID) | Provides Precision for spread normalization |
| ParentCID | dbo.RealOpenPositions | SELECT FROM (LEFT JOIN) | Synonym for Trade.Position; resolves leader CID from ParentPositionID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins (BI analytics role) | GRANT EXECUTE | Permission | Business intelligence team uses this SP for open position analysis per customer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetVirtualOpenPositions (procedure)
+-- Customer.Customer (table) [x-schema, leaf]
+-- Trade.Position (view)
|     +-- Trade.PositionTbl (table) [leaf]
|     +-- Trade.PositionTreeInfo (table) [leaf]
+-- Trade.ProviderToInstrument (table) [leaf]
+-- dbo.RealOpenPositions (synonym -> Trade.Position) [same expansion as above]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Resolves @GCID to CID (INNER JOIN filter) |
| Trade.Position | View | Source of all open position columns |
| Trade.ProviderToInstrument | Table | Provides Precision for spread normalization; cross-joined on InstrumentID |
| dbo.RealOpenPositions | Synonym | Synonym for Trade.Position; LEFT JOINed to resolve parent/leader CID via ParentPositionID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins | Permission | GRANT EXECUTE - BI analytics |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. Note: the FROM clause uses implicit cross-join syntax (comma-separated tables) between ProviderToInstrument and Position, equi-joined on InstrumentID without ProviderID filter. If an instrument is configured for multiple providers, position rows may be returned multiple times (once per provider).

---

## 8. Sample Queries

### 8.1 Execute for a specific customer by GCID

```sql
EXEC Trade.GetVirtualOpenPositions @GCID = 12345;
```

### 8.2 Direct equivalent query with explicit JOIN syntax

```sql
SELECT
    POS.CID,
    POS.PositionID,
    POS.InstrumentID,
    POS.IsBuy,
    POS.InitDateTime,
    POS.InitForexRate,
    POS.SpreadedPipBid / POWER(10.0, PTI.Precision) AS SpreadBid,
    POS.SpreadedPipAsk / POWER(10.0, PTI.Precision) AS SpreadAsk,
    POS.Amount,
    POS.Leverage
FROM Trade.Position POS WITH (NOLOCK)
INNER JOIN Customer.Customer CUS WITH (NOLOCK) ON CUS.CID = POS.CID
INNER JOIN Trade.ProviderToInstrument PTI WITH (NOLOCK) ON PTI.InstrumentID = POS.InstrumentID
WHERE CUS.GCID = 12345;
```

### 8.3 Identify copy-trade positions (ParentCID > 0)

```sql
DECLARE @Results TABLE (CID INT, PositionID BIGINT, InstrumentID INT, IsBuy BIT,
    InitDateTime DATETIME, InitForexRate DECIMAL(18,8), SpreadBid DECIMAL(18,8),
    SpreadAsk DECIMAL(18,8), Amount MONEY, Leverage INT, StopRate DECIMAL(18,8),
    LimitRate DECIMAL(18,8), LotCountDecimal DECIMAL(18,8), OrderID INT,
    ParentPositionID INT, ParentCID INT, MirrorID INT);

INSERT INTO @Results EXEC Trade.GetVirtualOpenPositions @GCID = 12345;

SELECT * FROM @Results WHERE ParentCID > 0;  -- Copy-trade positions only
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1, 8, 11 - Phase 10: no results)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos (skipped - not found) | Corrections: 0 applied*
*Object: Trade.GetVirtualOpenPositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetVirtualOpenPositions.sql*
