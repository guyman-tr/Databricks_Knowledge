# History.ORG_GetClosedPositionsPerPage

> Back-office paged query for a customer's closed positions from the last 3 months, with instrument currency details, calculated profit/gain/spread, position type classification (Regular/CopyPlus/Mirror), and parent trader username resolution via cross-database dynamic SQL.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @ItemsPerPage + @PageNum - identifies the specific page of closed positions to return |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.ORG_GetClosedPositionsPerPage` is a back-office (ORG = organization/operations) reporting procedure that returns a paginated view of a customer's closed trading positions for the last 3 months. It is designed for back-office tools and customer service interfaces where an agent needs to review a customer's recent trading history page by page.

The procedure enriches raw position data from `History.Position` with instrument details (currency pairs, abbreviations, currency types), game type name, close action type name, and calculated financial metrics (profit, gain, spread). For copy/mirror positions, it resolves the parent trader's username from the Real database (handling both Real and Demo environments via the IsRealDB feature flag).

Data flow: (1) Reads IsRealDB from Maintenance.Feature to determine environment; (2) executes a CTE over History.Position for the last 3 months with JOINs to ForexResult, GameType, Instrument, Currency, and ClosePositionActionType; (3) paginates results using ROW_NUMBER() into a temp table; (4) for positions with a ParentPositionID (copy/mirror), constructs dynamic SQL to look up the parent trader's username from the Real database (either via linked server OPENQUERY for Demo, or local synonyms for Real); (5) returns the final result set with ParentUsername joined in; (6) drops temp tables.

---

## 2. Business Logic

### 2.1 Pagination

**What**: Results are paginated server-side using ROW_NUMBER() ordered by CloseDate DESC.

**Columns/Parameters Involved**: `@ItemsPerPage`, `@PageNum`

**Rules**:
- ROW_NUMBER() OVER (ORDER BY CloseDate DESC) assigns a row number to all matching positions
- Filter: RowNum BETWEEN (@ItemsPerPage * (@PageNum - 1)) + 1 AND (@ItemsPerPage * @PageNum)
- Example: Page 1, 20 items = rows 1-20; Page 2, 20 items = rows 21-40
- @PageNum is 1-based (page 1 = first page)
- Date filter: CloseOccurred > dateadd(m,-3, getutcdate()) - hard 3-month lookback window

### 2.2 Position Type Classification

**What**: Each position is classified as Regular, CopyPlus, or Mirror based on ParentPositionID and MirrorID values.

**Columns/Parameters Involved**: `ParentPositionID`, `MirrorID`

**Rules**:
- Regular: ISNULL(ParentPositionID,0) = 0 (no parent - manually opened position)
- CopyPlus: ISNULL(ParentPositionID,0) > 0 AND ISNULL(MirrorID,0) = 0 (has parent, no mirror - Smart Copy / CopyPlus)
- Mirror: ISNULL(ParentPositionID,0) > 0 AND ISNULL(MirrorID,0) > 0 (has both parent and mirror - old Mirror/CopyTrader)

**Diagram**:
```
ParentPositionID = 0/NULL AND MirrorID = 0/NULL  -> "Regular"
ParentPositionID > 0      AND MirrorID = 0/NULL  -> "CopyPlus"
ParentPositionID > 0      AND MirrorID > 0       -> "Mirror"
```

### 2.3 Financial Metric Calculations

**What**: Profit, Gain, and Spread are derived from raw position columns.

**Columns/Parameters Involved**: `NetProfit`, `Commission`, `Amount`, `AmountInUnitsDecimal`

**Rules**:
- Spread = Commission * 100 (Commission is in fractional units; * 100 converts to basis points or the expected UI unit)
- Profit = NetProfit + Commission (total realized profit including spread cost)
- Gain = (NetProfit + Commission) / CAST(Amount AS FLOAT) * 100 (percentage return on invested amount)
- Units = AmountInUnitsDecimal (raw units from position; no calculation)

### 2.4 Real vs Demo Cross-Database Parent Username Lookup

**What**: For copy/mirror positions, the parent trader's username is looked up from the Real database. The mechanism differs between Real and Demo environments.

**Columns/Parameters Involved**: `@IsRealDB`, `@sql_cmd`, `ParentPositionID`

**Rules**:
- IsRealDB read from Maintenance.Feature WHERE FeatureID=22: 0 = Demo environment, 1 = Real environment
- Demo (IsRealDB=0): Dynamic SQL queries [etoro].[Customer].[OpenAndClosePositions] and [etoro].[Customer].[Customer] on the Real linked server via OPENQUERY([Real], ...)
- Real (IsRealDB=1): Dynamic SQL queries local synonyms OpenAndClosePositionsFromReal and RealCustomers
- Dynamic SQL is only constructed if the temp table contains rows with ParentPositionID > 0; otherwise the lookup is skipped
- The ParentPositionIDs are concatenated into a WHERE IN (...) clause for a single batch lookup

**Diagram**:
```
IsRealDB = 0 (Demo)?
     |
     v
OPENQUERY([Real], 'SELECT PositionID, UserName FROM [etoro].[Customer].[OpenAndClosePositions]
                   LEFT JOIN [etoro].[Customer].[Customer] WHERE PositionID IN (...)')

IsRealDB = 1 (Real)?
     |
     v
SELECT PositionID, UserName FROM OpenAndClosePositionsFromReal
LEFT JOIN RealCustomers WHERE PositionID IN (...)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose closed positions are to be retrieved. Filtered as History.Position WHERE CID=@CID within the last 3 months. |
| 2 | @ItemsPerPage | INT | NO | - | CODE-BACKED | Number of positions to return per page. Defines the page size for pagination. Example: 20 returns 20 positions per page. |
| 3 | @PageNum | INT | NO | - | CODE-BACKED | 1-based page number to retrieve. Page 1 = first @ItemsPerPage results, Page 2 = next @ItemsPerPage, etc. Positions are ordered by CloseDate DESC within each page. |

**Result Set Columns Returned:**

| # | Column | Source | Description |
|---|--------|--------|-------------|
| R1 | CID | History.Position.CID | Customer ID (same as @CID). |
| R2 | PositionID | History.Position.PositionID | Unique position identifier (BIGINT). |
| R3 | GameName | Dictionary.GameType.Name | Name of the game/trading context (e.g., "Real", "Demo"). |
| R4 | IsBuy | History.Position.IsBuy | 1 = Buy (Long), 0 = Sell (Short). |
| R5 | CurrencyBuy | Trade.Instrument.BuyCurrencyID | CurrencyID of the base (buy) currency of the instrument. |
| R6 | CurrencySell | Trade.Instrument.SellCurrencyID | CurrencyID of the quote (sell) currency of the instrument. |
| R7 | BuyCurAbbreviation | Dictionary.Currency.Abbreviation | Ticker symbol of the buy currency (e.g., "USD", "EUR"). |
| R8 | SellCurAbbreviation | Dictionary.Currency.Abbreviation | Ticker symbol of the sell currency. |
| R9 | BuyCurrencyTypeID | Dictionary.Currency.CurrencyTypeID | Type of the buy currency (e.g., fiat, crypto). |
| R10 | SellCurrencyTypeID | Dictionary.Currency.CurrencyTypeID | Type of the sell currency. |
| R11 | OpenDate | History.Position.OpenOccurred | UTC timestamp when the position was opened. |
| R12 | CloseDate | History.Position.EndDateTime | UTC timestamp when the position was closed. |
| R13 | Amount | History.Position.Amount | Invested amount in account currency. |
| R14 | Units | History.Position.AmountInUnitsDecimal | Position size in units of the instrument. |
| R15 | OpenRate | History.Position.InitForexRate | Exchange rate at position open. |
| R16 | CloseRate | History.Position.EndForexRate | Exchange rate at position close. |
| R17 | Spread | History.Position.Commission * 100 | Spread cost (Commission scaled by 100). |
| R18 | Profit | NetProfit + Commission | Total realized profit including spread cost. |
| R19 | Gain | (NetProfit + Commission) / Amount * 100 | Percentage return on invested amount. |
| R20 | MirrorID | History.Position.MirrorID | ID of the mirror/copy-trade relationship. 0/NULL = not a mirror position. |
| R21 | ParentPositionID | History.Position.ParentPositionID | PositionID of the parent trader's position (for copy trades). 0/NULL = not a copy position. |
| R22 | PositionType | Computed | "Regular", "CopyPlus", or "Mirror" - derived from ParentPositionID and MirrorID. See Section 2.2. |
| R23 | ParentUsername | Cross-DB lookup | Username of the parent trader (looked up from Real database). NULL if not a copy/mirror position or parent not found. |
| R24 | ClosePositionActionName | Dictionary.ClosePositionActionType.ClosePositionActionName | Human-readable name of the action that closed the position (e.g., "Manual", "StopLoss", "TakeProfit"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, position data | History.Position | READER | Main source of closed position records; filtered by CID and CloseOccurred within last 3 months |
| ForexResultID | History.ForexResult | JOIN | Maps ForexResultID to GameTypeID (UNION with Game.ForexResult) |
| ForexResultID | Game.ForexResult | JOIN (UNION) | Fallback ForexResult source for game-type positions |
| GameTypeID | Dictionary.GameType | JOIN | Resolves GameTypeID to human-readable GameName |
| InstrumentID | Trade.Instrument | JOIN | Reads BuyCurrencyID and SellCurrencyID for currency pair details |
| BuyCurrencyID | Dictionary.Currency | JOIN (as buyCur) | Resolves buy currency to Abbreviation and CurrencyTypeID |
| SellCurrencyID | Dictionary.Currency | JOIN (as sellCur) | Resolves sell currency to Abbreviation and CurrencyTypeID |
| ActionType | Dictionary.ClosePositionActionType | JOIN | Resolves ActionType to ClosePositionActionName |
| FeatureID=22 | Maintenance.Feature | Lookup | Reads IsRealDB to determine Real vs Demo environment for cross-DB parent username lookup |
| ParentPositionID | Cross-DB (Real linked server or local synonyms) | Dynamic SQL | Looks up parent trader's username from OpenAndClosePositions in Real database |

### 5.2 Referenced By (other objects point to this)

No callers found in SSDT repository. Called by back-office tooling / customer service portals.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ORG_GetClosedPositionsPerPage (procedure)
+-- History.Position (table)
+-- History.ForexResult (table)
+-- Game.ForexResult (table, cross-schema)
+-- Dictionary.GameType (table)
+-- Trade.Instrument (table, cross-schema)
+-- Dictionary.Currency (table)
+-- Dictionary.ClosePositionActionType (table)
+-- Maintenance.Feature (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | Table | Primary source of closed position data - SELECT with CID filter and 3-month date filter |
| History.ForexResult | Table | UNION source for ForexResultID -> GameTypeID mapping |
| Game.ForexResult | Table | UNION source for ForexResultID -> GameTypeID mapping (game-type positions) |
| Dictionary.GameType | Table | JOIN to resolve GameTypeID to GameName |
| Trade.Instrument | Table | JOIN to get BuyCurrencyID and SellCurrencyID for the position's instrument |
| Dictionary.Currency | Table | Joined twice (buyCur, sellCur) to get Abbreviation and CurrencyTypeID |
| Dictionary.ClosePositionActionType | Table | JOIN to resolve ActionType to ClosePositionActionName |
| Maintenance.Feature | Table | SELECT FeatureID=22 for IsRealDB flag |

### 6.2 Objects That Depend On This

No dependents found in SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| 3-month lookback | Business rule | WHERE hp.CloseOccurred > dateadd(m,-3, getutcdate()) - only last 3 months of closed positions are searched |
| Dynamic SQL injection risk | Implementation note | ParentPositionIDs are BIGINT values concatenated into SQL string - numeric values only so no injection risk, but the pattern should be noted for code review |
| Comment: PositionID changed to bigint (2021-11-17) | Change history | Per inline comment "Bonnie - Change positionID to bigint" |

---

## 8. Sample Queries

### 8.1 Get the first page of a customer's recent closed positions (20 per page)

```sql
EXEC History.ORG_GetClosedPositionsPerPage
    @CID = 12345678,
    @ItemsPerPage = 20,
    @PageNum = 1
```

### 8.2 Check raw data before calling - how many closed positions in last 3 months

```sql
SELECT COUNT(*) AS ClosedPositionCount
FROM History.Position WITH (NOLOCK)
WHERE CID = 12345678
  AND CloseOccurred > DATEADD(m, -3, GETUTCDATE())
```

### 8.3 Check position types breakdown for a customer

```sql
SELECT
    CASE WHEN ISNULL(ParentPositionID,0) = 0 THEN 'Regular'
         WHEN ISNULL(ParentPositionID,0) > 0 AND ISNULL(MirrorID,0) = 0 THEN 'CopyPlus'
         WHEN ISNULL(ParentPositionID,0) > 0 AND ISNULL(MirrorID,0) > 0 THEN 'Mirror'
    END AS PositionType,
    COUNT(*) AS PositionCount
FROM History.Position WITH (NOLOCK)
WHERE CID = 12345678
  AND CloseOccurred > DATEADD(m, -3, GETUTCDATE())
GROUP BY
    CASE WHEN ISNULL(ParentPositionID,0) = 0 THEN 'Regular'
         WHEN ISNULL(ParentPositionID,0) > 0 AND ISNULL(MirrorID,0) = 0 THEN 'CopyPlus'
         WHEN ISNULL(ParentPositionID,0) > 0 AND ISNULL(MirrorID,0) > 0 THEN 'Mirror'
    END
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ORG_GetClosedPositionsPerPage | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.ORG_GetClosedPositionsPerPage.sql*
