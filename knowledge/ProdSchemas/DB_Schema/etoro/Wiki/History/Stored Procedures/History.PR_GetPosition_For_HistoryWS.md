# History.PR_GetPosition_For_HistoryWS

> HistoryWS read procedure that returns enriched open position data for a date range - joining game type, instrument currency pair abbreviations, and calculated Profit/Gain - from Trade.GetPosition (open positions). Amount and Profit are divided by 100 to convert from cents to dollar units.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BeginDate + @EndDate - open position date range (filters on Occurred) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.PR_GetPosition_For_HistoryWS` (PR = Procedure, HistoryWS = History Web Service) provides open position data to the legacy History Web Service layer. It queries `Trade.GetPosition` (the live open position view) filtered by the position open date range, enriches the data with game type name, instrument currency pair abbreviations, and computed financial metrics, and returns the result set for web service consumers.

**Key behavioral note**: This procedure queries **Trade.GetPosition** (open/active positions), NOT closed position history. Despite being in the History schema and named "For_HistoryWS", it returns currently open positions opened within the given date window.

**Amount/Profit cents conversion**: Trade.GetPosition stores Amount and (NetProfit+Commission) in cents. This procedure divides both by 100 to return dollar-unit values. This matches the convention from other History procedures but differs from direct table access patterns.

**Customer.Customer JOIN**: The procedure JOINs Customer.Customer but selects no columns from it. This acts as an implicit filter: only positions belonging to customers present in Customer.Customer (active accounts) are returned. Positions for deleted/orphaned CIDs would be excluded.

Data flow: (1) SELECT from Trade.GetPosition WITH (NOLOCK) filtered by Occurred >= @BeginDate AND <= @EndDate; (2) JOIN to History.ForexResult UNION Game.ForexResult for GameTypeID; (3) JOIN Dictionary.GameType for GameName; (4) JOIN subquery combining Trade.Instrument+Dictionary.Currency for buy/sell currency abbreviations; (5) JOIN Customer.Customer for active account filter; (6) ORDER BY Occurred DESC; (7) return result set.

---

## 2. Business Logic

### 2.1 Amount and Profit Cents Conversion

**What**: Amount and Profit figures from Trade.GetPosition are stored in cents and divided by 100 for output.

**Columns/Parameters Involved**: `Amount`, `NetProfit`, `Commission`

**Rules**:
- Amount: `CAST([Trade].[GetPosition].[Amount] AS FLOAT)/100` - cents to dollars
- Profit: `CAST(NetProfit + Commission AS FLOAT)/100` - combined profit (net + spread) in dollars
- Gain: `(NetProfit + Commission) / NULLIF(Amount, 0) * 100` - percentage return; ISNULL wrapper returns 0 if Amount is 0
- Spread: `Commission` - raw commission value (NOT divided by 100 and NOT multiplied by 100)

### 2.2 Currency Pair Abbreviation Resolution

**What**: Each instrument's buy and sell currency abbreviations are resolved separately and joined.

**Columns/Parameters Involved**: `Trade.Instrument`, `Dictionary.Currency`, `BuyCurAbbreviation`, `SellCurAbbreviation`

**Rules**:
- BA subquery: Trade.Instrument JOIN Dictionary.Currency ON BuyCurrencyID -> BuyAbbreviation
- SA subquery: Trade.Instrument JOIN Dictionary.Currency ON SellCurrencyID -> SellAbbreviation
- Both filter InstrumentID > 0 (excludes InstrumentID=0 placeholder)
- JOINed on InstrumentID -> returns [InstrumentID, BuyCurAbbreviation, SellCurAbbreviation]

### 2.3 Game Type Resolution

**What**: ForexResultID is resolved to a game type name via a UNION of History and Game schema sources.

**Columns/Parameters Involved**: `ForexResultID`, `GameTypeID`, `GameName`

**Rules**:
- UNION (not UNION ALL) of History.ForexResult and Game.ForexResult
- Maps ForexResultID -> GameTypeID -> GameName (e.g., "Real", "Demo", "PaperTrading")

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BeginDate | DATETIME | NO | - | CODE-BACKED | Start of the open position date range (inclusive). Matched against Trade.GetPosition.Occurred >= @BeginDate. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of the open position date range (inclusive). Matched against Trade.GetPosition.Occurred <= @EndDate. |

**Result Set Columns Returned:**

| # | Column | Source | Description |
|---|--------|--------|-------------|
| R1 | CID | Trade.GetPosition.CID | Customer ID of the position owner. |
| R2 | PositionID | Trade.GetPosition.PositionID | Unique position identifier. |
| R3 | GameName | Dictionary.GameType.Name | Trading environment name (e.g., "Real", "Demo"). |
| R4 | IsBuy | Trade.GetPosition.IsBuy | 1=Buy/Long, 0=Sell/Short. |
| R5 | BuyCurAbbreviation | Dictionary.Currency.Abbreviation | Ticker of the instrument's base (buy) currency (e.g., "USD", "EUR"). |
| R6 | SellCurAbbreviation | Dictionary.Currency.Abbreviation | Ticker of the instrument's quote (sell) currency. |
| R7 | OpenDate | Trade.GetPosition.Occurred | UTC timestamp when the position was opened. |
| R8 | Amount | Trade.GetPosition.Amount / 100 | Invested amount in dollars (divided by 100 from cents storage). |
| R9 | Units | Trade.GetPosition.AmountInUnitsDecimal | Position size in instrument units. |
| R10 | OpenRate | Trade.GetPosition.InitForexRate | Exchange rate at position open. |
| R11 | Spread | Trade.GetPosition.Commission | Commission/spread value (raw value, not divided). |
| R12 | Profit | (NetProfit + Commission) / 100 | Total realized profit in dollars (net profit + spread, divided by 100 from cents). |
| R13 | Gain | (NetProfit + Commission) / Amount * 100 | Percentage return on invested amount. 0 if Amount=0. |
| R14 | LimitRate | Trade.GetPosition.LimitRate | Take profit rate. |
| R15 | StopRate | Trade.GetPosition.StopRate | Stop loss rate. |
| R16 | ParentPositionID | ISNULL(Trade.GetPosition.ParentPositionID, 0) | Parent copy position ID (0 = not a copy position). |
| R17 | OrigParentPositionID | ISNULL(Trade.GetPosition.OrigParentPositionID, 0) | Original parent position ID at open. |
| R18 | MirrorID | ISNULL(Trade.GetPosition.MirrorID, 0) | Mirror/copy relationship ID (0 = not mirrored). |
| R19 | Leverage | Trade.GetPosition.Leverage | Leverage applied to the position. |
| R20 | Credit | Trade.GetPosition.Credit | Credit used for this position. |
| R21 | CloseOnEndOfWeek | ISNULL(Trade.GetPosition.CloseOnEndOfWeek, 0) | Auto-close at weekend flag (0 or 1). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BeginDate, @EndDate | Trade.GetPosition | READER (view) | Primary data source for open position data; filtered by Occurred date range |
| ForexResultID | History.ForexResult | UNION JOIN | Maps ForexResultID to GameTypeID |
| ForexResultID | Game.ForexResult | UNION JOIN | Fallback ForexResult source for game-type positions |
| GameTypeID | Dictionary.GameType | JOIN | Resolves GameTypeID to GameName |
| InstrumentID | Trade.Instrument | JOIN (x2) | Reads BuyCurrencyID and SellCurrencyID for currency pair |
| BuyCurrencyID, SellCurrencyID | Dictionary.Currency | JOIN (x2) | Resolves to currency Abbreviations |
| CID | Customer.Customer | JOIN | Implicit active account filter (no columns selected) |

### 5.2 Referenced By (other objects point to this)

No callers found in SSDT repository. Called by HistoryWS (History Web Service) application layer.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PR_GetPosition_For_HistoryWS (procedure)
+-- Trade.GetPosition (view, cross-schema)
+-- History.ForexResult (table)
+-- Game.ForexResult (table, cross-schema)
+-- Dictionary.GameType (table)
+-- Trade.Instrument (table, cross-schema)
+-- Dictionary.Currency (table)
+-- Customer.Customer (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPosition | View (cross-schema) | Primary data source for all open position fields; filtered by Occurred date range |
| History.ForexResult | Table | UNION source for ForexResultID -> GameTypeID mapping |
| Game.ForexResult | Table (cross-schema) | UNION source for game-type positions |
| Dictionary.GameType | Table | JOIN to resolve GameTypeID to human-readable GameName |
| Trade.Instrument | Table (cross-schema) | Joined twice for BuyCurrencyID and SellCurrencyID |
| Dictionary.Currency | Table | Joined twice (buy/sell) to get Abbreviation |
| Customer.Customer | Table (cross-schema) | JOIN to filter to active accounts only; no columns selected |

### 6.2 Objects That Depend On This

No dependents found in SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Trade.GetPosition as source | Behavioral | Returns OPEN positions, not closed position history - despite "History" schema and "HistoryWS" name |
| Amount/Profit /100 | Unit conversion | Amount and Profit are in cents in Trade.GetPosition; divided by 100 for dollar output |
| Spread not converted | Behavioral | Commission is returned as raw value (not divided by 100); inconsistency with Amount/Profit conversion |
| Customer.Customer INNER JOIN | Implicit filter | Excludes positions for CIDs not in Customer.Customer (deleted/orphaned accounts) |
| Occurred inclusive bounds | Boundary | Both @BeginDate and @EndDate are inclusive (>= and <=) |
| ORDER BY Occurred DESC | Ordering | Results sorted by open date descending (most recent first) |

---

## 8. Sample Queries

### 8.1 Get open positions opened in the last 30 days (HistoryWS pattern)

```sql
EXEC History.PR_GetPosition_For_HistoryWS
    @BeginDate = DATEADD(day, -30, GETUTCDATE()),
    @EndDate = GETUTCDATE()
```

### 8.2 Check open position count for a date range

```sql
SELECT COUNT(*) AS OpenPositionCount
FROM Trade.GetPosition WITH (NOLOCK)
WHERE Occurred >= DATEADD(day, -7, GETUTCDATE())
  AND Occurred <= GETUTCDATE()
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PR_GetPosition_For_HistoryWS | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.PR_GetPosition_For_HistoryWS.sql*
