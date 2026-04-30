# Trade.GetPositionHierarchy

> Recursively traverses the copy-trade position hierarchy from a given parent PositionID, returning all open child positions with full position data, instrument context, and mirror active status.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID - the parent/root position to traverse from |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetPositionHierarchy` uses a recursive CTE to find all open positions that copied a given parent position. Level 0 = direct children (ParentPositionID = @PositionID); Level N = children of children (if @UseHierarchy=1 AND IsReal=1). Returns full position details for each child plus IsMirrorActive from Trade.Mirror.

**WHY:** When a leader closes their position, the copy engine needs to enumerate all copier positions in the tree to trigger cascading closes. This SP provides the full tree from a given root.

**HOW:** Recursive CTE `PositionHierarchy` seeds with Level=0 where ParentPositionID=@PositionID AND StatusID=1. Recursive step adds Level+1 positions where ParentPositionID=previous level's PositionID AND StatusID=1 AND @UseHierarchy=1 AND @IsReal=1 (recursion only in real environment). Final SELECT joins PositionTbl (with partition routing), Trade.Instrument, Trade.PositionTreeInfo (for LimitRate/StopRate/CloseOnEndOfWeek), Trade.ProviderToInstrument, and LEFT JOINs Trade.Mirror for IsMirrorActive.

**Note:** @IsReal is read from Maintenance.Feature FeatureID=22 if not provided. Recursion only occurs in real (IsReal=1) environments - demo environments return only Level 0 (direct children).

---

## 2. Business Logic

### 2.1 Recursive CTE - Position Tree Traversal

**What:** CTE traverses the copy tree depth-first, level by level.

**Columns/Parameters Involved:** `@PositionID`, `@UseHierarchy`, `@IsReal`, `Level`

**Rules:**
- Anchor: `WHERE ParentPositionID = @PositionID AND StatusID = 1` (Level 0 = direct children)
- Recursive: `WHERE @UseHierarchy = 1 AND @IsReal = 1` (deeper levels only if flags set)
- Returns only open positions (StatusID=1)

### 2.2 Feature Flag Control (@IsReal from Maintenance.Feature)

**What:** @IsReal determines whether deep hierarchy traversal is enabled.

**Rules:**
- `SELECT @IsReal = CAST(Value AS INT) FROM Maintenance.Feature WHERE FeatureID = 22`
- If not passed by caller, read from feature flag table
- IsReal=1: Full recursion enabled
- IsReal=0 or NULL: Level 0 only (direct children)

### 2.3 Mirror Active Status

**What:** IsMirrorActive indicates whether the copy relationship that created this child position is still active.

**Rules:**
- `LEFT JOIN Trade.Mirror TM ON TM.MirrorID = TGP.MirrorID`
- `ISNULL(TM.IsActive, 0) AS IsMirrorActive`
- IsMirrorActive=0 could mean: no mirror (manual), or mirror is stopped

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | Parent/root position ID to traverse from. |
| 2 | @UseHierarchy | INT | YES | 1 | CODE-BACKED | 1=recurse into deeper levels; 0=Level 0 only. |
| 3 | @IsReal | INT | YES | NULL | CODE-BACKED | 1=real environment (full recursion); 0=demo. If NULL, read from Maintenance.Feature FeatureID=22. |
| 4 | Level | INT | NO | - | CODE-BACKED | Depth in the copy tree. 0=direct children, 1=grandchildren, etc. |
| 5 | CID | INT | NO | - | CODE-BACKED | Customer ID of the child position's owner. |
| 6 | PositionID | BIGINT | NO | - | CODE-BACKED | Child position ID. |
| 7 | ParentPositionID | BIGINT | YES | - | CODE-BACKED | The position this child copied. |
| 8 | ForexResultID | INT | YES | - | CODE-BACKED | Forex result reference. |
| 9 | IsOpened | INT | NO | 1 | CODE-BACKED | Always 1 (only StatusID=1 positions in CTE). |
| 10 | Currency | INT | YES | - | CODE-BACKED | CurrencyID of position account. |
| 11 | ProviderID | INT | YES | - | CODE-BACKED | Market data provider. |
| 12 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument being traded. |
| 13 | PositionHedgeServerID | INT | YES | - | CODE-BACKED | Hedge server for this position. |
| 14 | Leverage | INT | YES | - | CODE-BACKED | Leverage multiplier. |
| 15 | ForexBuy | INT | YES | - | CODE-BACKED | Buy currency ID from Trade.Instrument. |
| 16 | ForexSell | INT | YES | - | CODE-BACKED | Sell currency ID from Trade.Instrument. |
| 17 | InitForexRate | DECIMAL | YES | - | CODE-BACKED | Initial forex rate at open. |
| 18 | EndForexRate | DECIMAL | YES | - | CODE-BACKED | Close rate (NULL for open positions). |
| 19 | InitDateTime | DATETIME | YES | - | CODE-BACKED | Position open timestamp. |
| 20 | EndDateTime | DATETIME | YES | - | CODE-BACKED | Position close timestamp (NULL for open). |
| 21 | ActionType | INT | YES | - | CODE-BACKED | Open action type. |
| 22 | NetProfit | MONEY | YES | - | CODE-BACKED | Net profit (NULL for open). |
| 23 | LimitRate | DECIMAL | YES | - | CODE-BACKED | Take profit rate from Trade.PositionTreeInfo (tree-level TP). |
| 24 | StopRate | DECIMAL | YES | - | CODE-BACKED | Stop loss rate from Trade.PositionTreeInfo (tree-level SL). |
| 25 | Amount | MONEY | YES | - | CODE-BACKED | Current position amount. |
| 26 | AmountInUnitsDecimal | DECIMAL | YES | - | CODE-BACKED | Position size in units. |
| 27 | Commission | MONEY | YES | - | CODE-BACKED | Commission at open. |
| 28 | SpreadedCommission | MONEY | YES | - | CODE-BACKED | Spread-adjusted commission. |
| 29 | IsBuy | BIT | NO | - | CODE-BACKED | 1=Long, 0=Short. |
| 30 | CloseOnEndOfWeek | VARCHAR(5) | NO | - | CODE-BACKED | 'true'/'false' from Trade.PositionTreeInfo. |
| 31 | EndOfWeekFee | MONEY | YES | - | CODE-BACKED | End-of-week fee. |
| 32 | LotCountDecimal | DECIMAL | YES | - | CODE-BACKED | Position size in lots. |
| 33 | AdditionalParam | NVARCHAR | YES | - | CODE-BACKED | Additional parameters. |
| 34 | OpenOccurred | DATETIME | YES | - | CODE-BACKED | Position open timestamp (Occurred alias). |
| 35 | CloseOccurred | DATETIME | YES | - | CODE-BACKED | NULL for open positions. |
| 36 | OrderID | BIGINT | YES | - | CODE-BACKED | Opening order ID. |
| 37 | TradeRange | DECIMAL | YES | - | CODE-BACKED | Trade range at open. |
| 38 | InitForexPriceRateID | BIGINT | YES | - | CODE-BACKED | Price rate ID at open. |
| 39 | OrigParentPositionID | BIGINT | YES | - | CODE-BACKED | Original parent before reassignment. |
| 40 | LastOpPriceRate | DECIMAL | YES | - | CODE-BACKED | Price at last operation. |
| 41 | LastOpPriceRateID | BIGINT | YES | - | CODE-BACKED | Price rate ID at last operation. |
| 42 | LastOpConversionRate | DECIMAL | YES | - | CODE-BACKED | Conversion rate at last operation. |
| 43 | LastOpConversionRateID | BIGINT | YES | - | CODE-BACKED | Conversion rate ID at last operation. |
| 44 | UnitMargin | DECIMAL | YES | - | CODE-BACKED | Margin per unit. |
| 45 | Units | DECIMAL | YES | - | CODE-BACKED | Unit size from Trade.ProviderToInstrument. |
| 46 | InstrumentPrecision | INT | YES | - | CODE-BACKED | Decimal precision from Trade.ProviderToInstrument. |
| 47 | MirrorID | INT | YES | - | CODE-BACKED | Copy relationship ID. |
| 48 | PositionRatio | DECIMAL | YES | - | CODE-BACKED | Position size ratio. |
| 49 | DirectAggLotCount | DECIMAL | YES | - | CODE-BACKED | Direct aggregated lot count. |
| 50 | SpreadGroupID | INT | YES | - | CODE-BACKED | Spread group at open. |
| 51 | InitialAmountCents | BIGINT | YES | - | CODE-BACKED | Initial amount in cents. |
| 52 | IsComputeForHedge | BIT | YES | - | CODE-BACKED | Hedge computation flag. |
| 53 | TreeID | BIGINT | YES | - | CODE-BACKED | Root position of the copy tree. |
| 54 | RootHedgeServerID | INT | YES | - | CODE-BACKED | Hedge server of the tree root. |
| 55 | IsMirrorActive | BIT | NO | 0 | CODE-BACKED | Whether the copy relationship is active. ISNULL(TM.IsActive, 0). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID | Trade.PositionTbl | Recursive CTE | Copy tree traversal starting from parent |
| InstrumentID | Trade.Instrument | Lookup | ForexBuy, ForexSell |
| TreeID | Trade.PositionTreeInfo | Lookup | LimitRate, StopRate, CloseOnEndOfWeek (tree-level) |
| ProviderID + InstrumentID | Trade.ProviderToInstrument | Lookup | Units, InstrumentPrecision |
| MirrorID | Trade.Mirror | LEFT JOIN | IsMirrorActive |
| FeatureID=22 | Maintenance.Feature | Lookup | IsReal flag for recursion control |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by copy-tree close cascade services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionHierarchy (procedure)
|- Trade.PositionTbl (table) - recursive copy tree traversal
|- Trade.Instrument (table) - forex currency IDs
|- Trade.PositionTreeInfo (table) - tree-level SL/TP/weekend close
|- Trade.ProviderToInstrument (table) - precision, units
|- Trade.Mirror (table) - mirror active status
|- Maintenance.Feature (table) - IsReal feature flag (FeatureID=22)
```

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by copy tree close cascade |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| StatusID=1 in CTE | Filter | Only open positions in hierarchy |
| @UseHierarchy=1 AND @IsReal=1 | Recursion gate | Deep traversal only in real environment |
| PartitionCol = PositionID%50 | Partition routing | Modulo-50 shard routing in final join |
| abs(TreeID%50) = TPTI.PartitionCol | Partition routing | PositionTreeInfo partition routing |
| ISNULL(TM.IsActive, 0) | Null safety | 0 if no mirror record |
| ORDER BY removed (2020-07-14) | Performance | Removed by Yitzchak for better performance |

---

## 8. Sample Queries

### 8.1 Get all open copies of a leader's position

```sql
EXEC Trade.GetPositionHierarchy @PositionID = 987654321
```

### 8.2 Level 0 only (direct children, no deep recursion)

```sql
EXEC Trade.GetPositionHierarchy @PositionID = 987654321, @UseHierarchy = 0
```

### 8.3 Force demo mode (no recursion)

```sql
EXEC Trade.GetPositionHierarchy @PositionID = 987654321, @UseHierarchy = 1, @IsReal = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 55 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionHierarchy | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPositionHierarchy.sql*
