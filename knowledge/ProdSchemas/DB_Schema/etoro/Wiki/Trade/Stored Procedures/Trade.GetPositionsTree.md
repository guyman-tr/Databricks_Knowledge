# Trade.GetPositionsTree

> Returns the tree of open positions for a given root or child position: if the position is a root (TreeID=PositionID), returns all child positions in the tree from Trade.Position; if it is a child, delegates to Trade.GetPositionHierarchy for the full recursive hierarchy.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID BIGINT, @UseHierarchy INT = 1 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the entry point for navigating the CopyTrader position tree. In eToro's CopyTrader model, a leader position (the root) has a TreeID equal to its own PositionID; follower/mirror positions share the same TreeID, which references the root. Given any PositionID (root or child), this procedure determines the correct traversal strategy and returns the full set of related open positions.

If the input position is a root (TreeID = PositionID), it executes dynamic SQL against Trade.Position to retrieve either all tree members (@UseHierarchy=1) or only direct children (@UseHierarchy=0). If the input position is a child (TreeID != PositionID), it delegates to `Trade.GetPositionHierarchy` for full recursive hierarchy resolution.

The @IsReal flag was previously controlled by a Maintenance.Feature flag (FeatureID=22), but is now hardcoded to 1 (REAL mode always). This means the @IsReal=0 code path (which used a simpler non-hierarchy approach) is currently unreachable.

Data flows: Step 1: look up TreeID from Trade.PositionTbl (using PartitionCol=@PositionID%50); fallback to History.Position_Active. Step 2: if TreeID=PositionID (root), execute dynamic SQL on Trade.Position to return children. Step 3: if TreeID!=PositionID (child), EXEC Trade.GetPositionHierarchy.

---

## 2. Business Logic

### 2.1 Root vs Child Detection

**What**: Determines whether the given PositionID is the root of a tree or a child/leaf.

**Columns/Parameters Involved**: `@TreeID`, `@PositionID`, `Trade.PositionTbl.TreeID`

**Rules**:
- TreeID lookup: SELECT TreeID FROM Trade.PositionTbl WHERE PositionID=@PositionID AND PartitionCol=@PositionID%50 (partition-aligned read).
- If NULL (closed position): SELECT TreeID FROM History.Position_Active WHERE PositionID=@PositionID.
- IF @TreeID = @PositionID: this is a root position -> execute direct child SELECT.
- IF @TreeID != @PositionID: this is a child position -> delegate to Trade.GetPositionHierarchy.

### 2.2 Root Path: Dynamic SQL on Trade.Position

**What**: When the position is a root, returns its children using sp_executesql on Trade.Position.

**Columns/Parameters Involved**: `@UseHierarchy`, `@IsReal`, `Trade.Position`, `Trade.Instrument`, `Trade.ProviderToInstrument`

**Rules**:
- @IsReal is hardcoded to 1 (Real mode always active; feature flag check commented out).
- @UseHierarchy=1 (default): WHERE (TreeID=@TreeID AND TGP.ParentPositionID>0) OR ParentPositionID=@PositionID ORDER BY ParentPositionID. Returns all tree members where ParentPositionID>0 (i.e., not the root itself) plus direct children of the root.
- @UseHierarchy=0: WHERE ParentPositionID=@PositionID ORDER BY ParentPositionID. Returns only direct children.
- @IsReal=0 code path: same SELECT with WHERE ParentPositionID=@PositionID (static SQL, no sp_executesql). Currently UNREACHABLE since @IsReal=1 always.
- Dynamic SQL uses sp_executesql with parameterized @TreeID and @PositionID to prevent SQL injection.

### 2.3 Child Path: Delegate to GetPositionHierarchy

**What**: When the input is a child position, full hierarchy resolution is delegated.

**Columns/Parameters Involved**: `Trade.GetPositionHierarchy`, `@PositionID`, `@UseHierarchy`, `@IsReal`

**Rules**:
- EXEC Trade.GetPositionHierarchy @PositionID=@PositionID, @UseHierarchy=@UseHierarchy, @IsReal=@IsReal.
- @IsReal=1 passed through (hardcoded).
- GetPositionHierarchy handles recursive multi-level position trees.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | The position to look up. Can be a root (TreeID=PositionID) or a child position. Changed from INT to BIGINT (2021-11-17). |
| 2 | @UseHierarchy | INT | YES | 1 | CODE-BACKED | 1=return all tree members (TreeID match + direct children); 0=return only direct children (ParentPositionID=@PositionID). Passed through to GetPositionHierarchy if delegating. |

**Output Columns (root path, same schema in both @UseHierarchy branches)**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | Level | NULL | YES | NULL | CODE-BACKED | Always NULL (placeholder; hierarchy level not computed in this path, set by GetPositionHierarchy when delegating). |
| 4 | CID | INT | NO | - | CODE-BACKED | Customer ID of the position owner. |
| 5 | PositionID | BIGINT | NO | - | CODE-BACKED | Trading position identifier. |
| 6 | ParentPositionID | BIGINT | YES | - | CODE-BACKED | Parent position ID. 0 or NULL = root/manual; >0 = copy position whose parent is this ID. |
| 7 | ForexResultID | INT | YES | - | CODE-BACKED | Foreign exchange rate result identifier for PnL conversion. |
| 8 | IsOpened | BIT | NO | 1 | CODE-BACKED | Always 1 (hardcoded). All positions from Trade.Position are open (StatusID=1). |
| 9 | Currency | INT | NO | - | CODE-BACKED | CurrencyID of the position's account denomination. |
| 10 | ProviderID | INT | NO | - | CODE-BACKED | Liquidity provider or hedge server provider for this position. |
| 11 | InstrumentID | INT | NO | - | CODE-BACKED | Traded instrument. |
| 12 | PositionHedgeServerID | INT | YES | - | CODE-BACKED | HedgeServerID for position routing. |
| 13 | Leverage | INT | NO | - | CODE-BACKED | Leverage multiplier. 1 = no leverage. |
| 14 | ForexBuy | INT | YES | - | CODE-BACKED | BuyCurrencyID from Trade.Instrument (buy-side currency for PnL conversion). |
| 15 | ForexSell | INT | YES | - | CODE-BACKED | SellCurrencyID from Trade.Instrument (sell-side currency). |
| 16 | InitForexRate | DECIMAL | NO | - | CODE-BACKED | Instrument price at position open. |
| 17 | EndForexRate | NULL | YES | NULL | CODE-BACKED | Always NULL (open positions have no close rate). |
| 18 | InitDateTime | DATETIME | NO | - | CODE-BACKED | Datetime when position was opened. |
| 19 | EndDateTime | NULL | YES | NULL | CODE-BACKED | Always NULL (open positions have no close time). |
| 20 | ActionType | NULL | YES | NULL | CODE-BACKED | Always NULL in this path (close ActionType not applicable for open positions). |
| 21 | NetProfit | DECIMAL | YES | - | CODE-BACKED | Running unrealized PnL of the open position. |
| 22 | LimitRate | DECIMAL | NO | - | CODE-BACKED | Take-profit rate. 0 if not set. |
| 23 | StopRate | DECIMAL | NO | - | CODE-BACKED | Stop-loss rate. 0 if not set. |
| 24 | Amount | DECIMAL | NO | - | CODE-BACKED | Invested amount in USD. |
| 25 | AmountInUnitsDecimal | DECIMAL | YES | - | CODE-BACKED | Position size in instrument units (shares, contracts). |
| 26 | Commission | DECIMAL | NO | - | CODE-BACKED | Spread commission charged at open. |
| 27 | SpreadedCommission | DECIMAL | NO | - | CODE-BACKED | Additional spread-based commission. |
| 28 | IsBuy | BIT | NO | - | CODE-BACKED | 1=Buy/Long, 0=Sell/Short. |
| 29 | CloseOnEndOfWeek | BIT | NO | - | CODE-BACKED | Flag indicating position should auto-close at end of week. |
| 30 | EndOfWeekFee | DECIMAL | NO | - | CODE-BACKED | Accumulated overnight/EOW fees charged to this position so far. |
| 31 | LotCountDecimal | DECIMAL | YES | - | CODE-BACKED | Lot count as decimal. |
| 32 | AdditionalParam | VARCHAR | YES | - | CODE-BACKED | Free-form additional parameters (JSON or key=value string). |
| 33 | OpenOccurred | DATETIME | NO | - | CODE-BACKED | Timestamp when position was opened (aliased from Occurred). |
| 34 | CloseOccurred | NULL | YES | NULL | CODE-BACKED | Always NULL for open positions. |
| 35 | OrderID | BIGINT | YES | - | CODE-BACKED | The order that opened this position. |
| 36 | TradeRange | DECIMAL | YES | - | CODE-BACKED | Market range tolerance at open. |
| 37 | InitForexPriceRateID | BIGINT | YES | - | CODE-BACKED | Rate record ID for the open price. |
| 38 | OrigParentPositionID | BIGINT | YES | - | CODE-BACKED | Original parent before partial close restructuring. |
| 39 | LastOpPriceRate | DECIMAL | YES | - | CODE-BACKED | Price rate at last operation (SL/TP adjustment, partial close). |
| 40 | LastOpPriceRateID | BIGINT | YES | - | CODE-BACKED | Rate record ID for last operation. |
| 41 | LastOpConversionRate | DECIMAL | YES | - | CODE-BACKED | Conversion rate at last operation. |
| 42 | LastOpConversionRateID | BIGINT | YES | - | CODE-BACKED | Rate record ID for last conversion rate. |
| 43 | UnitMargin | DECIMAL | YES | - | CODE-BACKED | Margin per unit for leveraged positions. |
| 44 | Units | DECIMAL | YES | - | CODE-BACKED | Instrument unit size from Trade.ProviderToInstrument. |
| 45 | InstrumentPrecision | INT | YES | - | CODE-BACKED | Decimal precision for instrument price display. |
| 46 | MirrorID | INT | YES | - | CODE-BACKED | CopyTrader mirror ID. 0/NULL = manual trade. |
| 47 | PositionRatio | DECIMAL | YES | - | CODE-BACKED | Copy ratio relative to parent mirror. |
| 48 | DirectAggLotCount | DECIMAL | YES | - | CODE-BACKED | Direct aggregate lot count. |
| 49 | SpreadGroupID | INT | YES | - | CODE-BACKED | Spread group governing this position's spread rates. |
| 50 | InitialAmountCents | INT | YES | - | CODE-BACKED | Initial invested amount in cents. |
| 51 | IsComputeForHedge | BIT | YES | - | CODE-BACKED | Flag indicating this position participates in hedge computation. |
| 52 | TreeID | BIGINT | NO | - | CODE-BACKED | Tree root PositionID. All positions in the same copy-trade tree share this TreeID. |
| 53 | RootHedgeServerID | INT | YES | - | CODE-BACKED | Hedge server ID of the tree root position. |
| 54 | IsMirrorActive | BIT | NO | 0 | CODE-BACKED | Whether the associated mirror is active (ISNULL(TM.IsActive, 0)). |
| 55 | UnitsBaseValueCents | INT | YES | - | CODE-BACKED | ISNULL(UnitsBaseValueCents, CONVERT(INT, InitialAmountCents)) - base value in cents for unit calculations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID (open) | Trade.PositionTbl | Lookup | TreeID resolution with PartitionCol=@PositionID%50 |
| @PositionID (closed) | History.Position_Active | Lookup (fallback) | TreeID resolution for closed positions |
| PositionID tree members | Trade.Position | Primary source | Open positions in the tree (dynamic SQL) |
| InstrumentID | Trade.Instrument | JOIN | BuyCurrencyID/SellCurrencyID for forex columns |
| ProviderID+InstrumentID | Trade.ProviderToInstrument | JOIN | Unit and Precision for the instrument |
| MirrorID | Trade.Mirror | LEFT JOIN | IsMirrorActive flag |
| @PositionID (child path) | Trade.GetPositionHierarchy | EXEC callee | Full recursive hierarchy when input is a child position |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trading execution services | @PositionID, @UseHierarchy | Application call | Called to display or process a position's full tree (e.g., when closing or inspecting a mirror trade) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionsTree (procedure)
+-- Trade.PositionTbl (table) [TreeID lookup]
+-- History.Position_Active (table) [TreeID fallback]
+-- Trade.Position (view) [open child positions - root path]
|     +-- Trade.PositionTbl
|     +-- Trade.PositionTreeInfo
+-- Trade.Instrument (table) [forex currency IDs]
+-- Trade.ProviderToInstrument (table) [Unit and Precision]
+-- Trade.Mirror (table) [IsMirrorActive]
+-- Trade.GetPositionHierarchy (procedure) [child path delegate]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | TreeID lookup with partition filter (PartitionCol=@PositionID%50) |
| History.Position_Active | Table | TreeID fallback when position not found in PositionTbl (closed) |
| Trade.Position | View | Source of open child positions in dynamic SQL (root path) |
| Trade.Instrument | Table | BuyCurrencyID/SellCurrencyID for ForexBuy/ForexSell columns |
| Trade.ProviderToInstrument | Table | Unit and Precision for instrument display |
| Trade.Mirror | Table | IsMirrorActive flag for mirror metadata |
| Trade.GetPositionHierarchy | Procedure | Delegates full recursive hierarchy for child positions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trading execution services | External application | Retrieves position tree for display, close processing, or hierarchy inspection |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PartitionCol = @PositionID%50 | Partition | PositionTbl is partitioned; lookup must include partition filter |
| @IsReal hardcoded to 1 | Design | Feature flag (FeatureID=22) removed; @IsReal=0 code path is dead code |
| Dynamic SQL via sp_executesql | Security | Parameterized to prevent SQL injection |
| @UseHierarchy filter | Control | 1=full tree; 0=direct children only |

---

## 8. Sample Queries

### 8.1 Get full tree for a root position

```sql
EXEC Trade.GetPositionsTree @PositionID = 1234567890, @UseHierarchy = 1;
```

### 8.2 Get only direct children (no deep hierarchy)

```sql
EXEC Trade.GetPositionsTree @PositionID = 1234567890, @UseHierarchy = 0;
```

### 8.3 Determine if a position is a root or child

```sql
SELECT PositionID, TreeID,
       CASE WHEN TreeID = PositionID THEN 'Root' ELSE 'Child' END AS TreeRole
FROM Trade.PositionTbl WITH (NOLOCK)
WHERE PositionID = 1234567890
  AND PartitionCol = 1234567890 % 50;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 callee analyzed (GetPositionHierarchy) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionsTree | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPositionsTree.sql*
