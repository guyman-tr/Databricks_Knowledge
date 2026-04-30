# Trade.GetParentPositionWithMirrorData

> Returns two result sets for copy-trade open setup: (1) leader position data from RealOpenPositions with instrument/provider/equity context; (2) active mirror relationship data including fund-copy detection.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ParentPositionID + @MirrorID - leader position and mirror relationship |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetParentPositionWithMirrorData` retrieves all data needed to open or validate a copy-trade child position. It returns two result sets: the first provides the leader's live position details (instrument, leverage, stop/limit, settlement, realized equity), and the second provides the active mirror relationship state (CID, amounts, fund-copy flag).

**WHY:** When a copier's copy system needs to open a child position mirroring a leader's position, it must know both the position parameters (InstrumentID, Leverage, IsBuy, precision, settlement type) and the mirror relationship state (is the mirror still active? is it a fund copy?). This SP delivers both in a single round-trip.

**HOW:** Result set 1 queries `dbo.RealOpenPositions` (the real-time open positions distributed view) joined to Trade.Instrument (forex rates), Trade.ProviderToInstrument (precision/units), and two CROSS APPLYs: one for the root/tree position's settlement type, and one for the parent CID's realized equity. Result set 2 queries Trade.Mirror for the given MirrorID (IsActive=1), with an OUTER APPLY to dbo.RealFund to detect if the copy is via a fund account (IsFundCopy).

**Note (Partition filter):** The first query applies `@ParentPositionID%50 = TPOS.PartitionCol` - a modulo-based partition routing that ensures the query targets only the correct partition shard in the distributed RealOpenPositions view.

---

## 2. Business Logic

### 2.1 Parent Position Lookup with Partition Routing

**What:** Retrieves the leader's live position with all fields required to initialize a copy position.

**Columns/Parameters Involved:** `@ParentPositionID`, `PartitionCol`, `TPOS.*`, `TISR.*`, `TP2I.*`

**Rules:**
- `WHERE TPOS.PositionID = @ParentPositionID AND @ParentPositionID%50 = TPOS.PartitionCol`
- PartitionCol = PositionID modulo 50 - routes to the correct shard of the distributed view
- All fields NOLOCK on the main table
- Returns 0 or 1 rows (PositionID is unique)

### 2.2 Root Settlement Type via Tree Root Lookup

**What:** The CROSS APPLY on PTI gets the settlement context of the tree root (TreeID), not just the current position. This determines if the entire copy tree is settled (real stock ownership) or CFD.

**Columns/Parameters Involved:** `TPOS.TreeID`, `PTI.IsSettled`, `PTI.SettlementTypeID`, `RootSettlementTypeID`

**Rules:**
- `SELECT TOP 1 IsSettled, SettlementTypeID FROM dbo.RealOpenPositions PTI WHERE TPOS.TreeID = PTI.PositionID AND PTI.PartitionCol = TPOS.TreeID%50`
- `PTI.IsSettled AS IsRootSettled` - root position's settlement status
- `PTI.SettlementTypeID AS RootSettlementTypeID` - added 2023-02-28 for Free Stocks settlement routing
- Used to determine if the copy position should use real-stock or CFD processing path

### 2.3 Realized Equity Lookup

**What:** Attaches the parent CID's current realized equity to the result for copy-open capital calculations.

**Columns/Parameters Involved:** `TPOS.CID`, `RRE.RealizedEquity`, `ParentRealizedEquityDollars`

**Rules:**
- `CROSS APPLY(SELECT TOP 1 RealizedEquity FROM dbo.RealGetRealizedEquity RRE WHERE TPOS.CID = RRE.CID)`
- Returns the leader's realized equity in dollars at the time of the copy-open request

### 2.4 Mirror Relationship State

**What:** Second result set returns the active mirror for the given MirrorID with fund-copy detection.

**Columns/Parameters Involved:** `@MirrorID`, `IsActive`, `IsFundCopy`

**Rules:**
- `WHERE MirrorID = @MirrorID AND IsActive = 1` - only returns the mirror if currently active
- Returns 0 rows if mirror was paused/stopped - caller uses this to abort copy-open
- `IsFundCopy = CASE WHEN TF.FundID IS NOT NULL THEN 1 ELSE 0 END`
- Fund copy detected via OUTER APPLY to dbo.RealFund WHERE ParentCID = FundAccountID
- IsFundCopy=1 means the leader is a fund account (eToro virtual fund); affects copy fee and position hierarchy rules

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ParentPositionID | BIGINT | NO | - | CODE-BACKED | Leader's position ID. Used to look up the position in dbo.RealOpenPositions. Changed from INT to BIGINT on 2021-11-17. |
| 2 | @MirrorID | INT | NO | - | CODE-BACKED | Copy relationship ID. Used to fetch the active mirror state from Trade.Mirror. |

**Output - Result Set 1 (Parent Position Data):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | ParentCID | INT | NO | - | CODE-BACKED | Leader's customer ID. From TPOS.CID aliased as ParentCID. |
| 4 | ParentPositionID | BIGINT | NO | - | CODE-BACKED | Echo of the leader's PositionID. |
| 5 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument being traded. FK to Trade.Instrument. |
| 6 | StopRate | DECIMAL | YES | - | CODE-BACKED | Stop loss rate on the leader's position. Copy position will inherit this rate. |
| 7 | LimitRate | DECIMAL | YES | - | CODE-BACKED | Take profit rate on the leader's position. |
| 8 | ForexBuy | INT | YES | - | CODE-BACKED | Buy-side currency ID from Trade.Instrument.BuyCurrencyID. Used for forex rate conversion. |
| 9 | ForexSell | INT | YES | - | CODE-BACKED | Sell-side currency ID from Trade.Instrument.SellCurrencyID. |
| 10 | Leverage | INT | YES | - | CODE-BACKED | Leverage multiplier on the leader's position. Copy position uses same leverage. |
| 11 | Currency | INT | YES | - | CODE-BACKED | CurrencyID of the leader's position (denomination). |
| 12 | InstrumentPrecision | INT | YES | - | CODE-BACKED | Decimal precision for the instrument from Trade.ProviderToInstrument.Precision. Used for price/amount rounding. |
| 13 | IsBuy | VARCHAR(5) | NO | - | CODE-BACKED | Direction as string: 'true' (Long) or 'false' (Short). Converted from BIT via CASE expression. |
| 14 | ProviderID | INT | YES | - | CODE-BACKED | Market data provider ID from the leader's position. |
| 15 | Units | DECIMAL | YES | - | CODE-BACKED | Unit size from Trade.ProviderToInstrument.Unit. |
| 16 | HedgeServerID | INT | YES | - | CODE-BACKED | Hedge server that manages the leader's position hedge. |
| 17 | RootHedgeServerID | INT | YES | - | CODE-BACKED | Hedge server of the root position in the copy tree. |
| 18 | TreeID | BIGINT | YES | - | CODE-BACKED | Root position ID of this copy tree. Used to look up PTI (root settlement data). |
| 19 | IsTslEnabled | BIT | YES | - | CODE-BACKED | Whether Trailing Stop Loss is enabled on the leader's position. |
| 20 | SLManualVer | INT | YES | - | CODE-BACKED | Stop loss manual version counter. Used for optimistic concurrency on SL updates. |
| 21 | IsSettled | BIT | YES | - | CODE-BACKED | Whether the leader's specific position is settled (real stock ownership). 1=real stock, 0=CFD. |
| 22 | SettlementTypeID | INT | YES | - | CODE-BACKED | Settlement type of the leader's position. FK to Dictionary settlement types. |
| 23 | IsRootSettled | BIT | YES | - | CODE-BACKED | Whether the tree ROOT position is settled. From PTI CROSS APPLY. Determines if the copy tree uses real-stock path. |
| 24 | AmountInUnitsDecimal | DECIMAL | YES | - | CODE-BACKED | Leader's position size in units (instrument-denominated). Used to calculate copy proportion. |
| 25 | ParentPositionRatioAtOpen | DECIMAL | YES | - | CODE-BACKED | PositionRatio at the time the leader's position was opened. Used for proportional copy sizing. |
| 26 | AmountDollars | MONEY | YES | - | CODE-BACKED | Leader's position amount in dollars (original invested amount). |
| 27 | ParentRealizedEquityDollars | MONEY | YES | - | CODE-BACKED | Leader's realized equity in dollars at time of call. From dbo.RealGetRealizedEquity. Used for proportional copy amount calculation. |
| 28 | InitialUnits | DECIMAL | YES | - | CODE-BACKED | Initial units when the leader's position was opened. |
| 29 | UnitMargin | DECIMAL | YES | - | CODE-BACKED | Margin per unit for the leader's position. |
| 30 | UnitsBaseValueCents | BIGINT | YES | - | CODE-BACKED | Base value of units in cents. Used in settlement calculations. |
| 31 | IsDiscounted | BIT | YES | - | CODE-BACKED | Whether the leader's position has a commission discount applied. |
| 32 | RootSettlementTypeID | INT | YES | - | CODE-BACKED | SettlementTypeID of the tree ROOT position. Added 2023-02-28. Enables settlement-aware routing for Free Stocks copy flow. |

**Output - Result Set 2 (Mirror Relationship Data):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 33 | CID | INT | NO | - | CODE-BACKED | Copier's customer ID from Trade.Mirror. |
| 34 | MirrorID | INT | NO | - | CODE-BACKED | Copy relationship ID (echo of @MirrorID). |
| 35 | ParentCID | INT | NO | - | CODE-BACKED | Leader's customer ID from Trade.Mirror.ParentCID. |
| 36 | ParentUserName | NVARCHAR | YES | - | CODE-BACKED | Leader's username from Trade.Mirror.ParentUserName. |
| 37 | MirrorAmountDollars | MONEY | YES | - | CODE-BACKED | Total copy allocation in dollars from Trade.Mirror.Amount. |
| 38 | RealizedEquityDollars | MONEY | YES | - | CODE-BACKED | Mirror's realized equity from Trade.Mirror.RealizedEquity. |
| 39 | IsActive | BIT | NO | - | CODE-BACKED | Mirror active status. Always 1 (filtered in WHERE). Confirms mirror is live at time of call. |
| 40 | IsFundCopy | BIT | NO | - | CODE-BACKED | 1=copying a fund account (eToro fund); 0=regular copy trade. Determined by OUTER APPLY to dbo.RealFund WHERE ParentCID = FundAccountID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ParentPositionID | dbo.RealOpenPositions | Lookup | Leader's live position data with partition routing |
| InstrumentID | Trade.Instrument | Lookup | BuyCurrencyID, SellCurrencyID (forex rates) |
| ProviderID + InstrumentID | Trade.ProviderToInstrument | Lookup | Precision, Units |
| TreeID | dbo.RealOpenPositions (PTI) | CROSS APPLY | Root position's IsSettled, SettlementTypeID |
| ParentCID | dbo.RealGetRealizedEquity | CROSS APPLY | Leader's realized equity in dollars |
| @MirrorID | Trade.Mirror | Lookup | Active mirror state (IsActive=1) |
| ParentCID | dbo.RealFund | OUTER APPLY | Fund account detection (IsFundCopy) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by copy-trade open processing.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetParentPositionWithMirrorData (procedure)
|- dbo.RealOpenPositions (view/table) - leader position data
|- Trade.Instrument (table) - forex currency IDs
|- Trade.ProviderToInstrument (table) - precision, units
|- dbo.RealGetRealizedEquity (view) - realized equity
|- dbo.RealFund (table/view) - fund account detection
|- Trade.Mirror (table) - mirror relationship state
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.RealOpenPositions | View | Leader's live position (PositionID=@ParentPositionID, partition-routed) |
| Trade.Instrument | Table | BuyCurrencyID, SellCurrencyID for forex rate context |
| Trade.ProviderToInstrument | Table | Precision, Unit for copy position sizing |
| dbo.RealGetRealizedEquity | View | Leader's current realized equity |
| dbo.RealFund | Table/View | Fund account detection for IsFundCopy |
| Trade.Mirror | Table | Active mirror relationship state |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by copy-trade open processing service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PartitionCol = @ParentPositionID%50 | Partition routing | Shard routing: modulo 50 ensures correct partition of RealOpenPositions is queried |
| IsActive = 1 | Filter | Only returns mirror if currently active - caller aborts copy-open if no row returned |
| OUTER APPLY on RealFund | Fund detection | Returns 0 or 1 fund row; IsFundCopy derived from presence/absence |
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Get copy-open context for a specific parent position and mirror

```sql
EXEC Trade.GetParentPositionWithMirrorData
    @ParentPositionID = 987654321,
    @MirrorID = 12345
```

### 8.2 Check if mirror is a fund copy

```sql
-- Result set 2, IsFundCopy column
-- 1 = copying a fund account, 0 = regular copy trade
EXEC Trade.GetParentPositionWithMirrorData
    @ParentPositionID = 987654321,
    @MirrorID = 12345
```

### 8.3 Verify partition routing

```sql
-- The partition filter: PositionID % 50 = PartitionCol
-- e.g. PositionID = 987654321 -> 987654321 % 50 = 21 -> queries PartitionCol=21 rows only
SELECT 987654321 % 50 AS PartitionCol
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 40 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetParentPositionWithMirrorData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetParentPositionWithMirrorData.sql*
