# History.GetClosedPositionsPerPage

> Returns a paginated list of a customer's closed positions from the last 3 months, enriched with instrument details, currency info, and CopyTrader leader name, ordered by close date descending.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID customer filter; @ItemsPerPage + @PageNum pagination |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure powers the **closed positions page** in the eToro platform's trading history UI. When a customer views their trade history, this procedure returns a paginated list of their closed positions from the past 3 months, each enriched with instrument details (buy/sell currency abbreviations and type IDs), position metadata (trade direction, amount, rates, PnL, gain), and CopyTrader context (position type classification, leader's username).

The 3-month hard limit (`hp.CloseOccurred > DATEADD(m,-3,GETUTCDATE())`) ensures the query stays performant on the large History.Position table. For wider date ranges, `History.GetClosedPositionsPerPageAndTimeFrame` is used instead.

---

## 2. Business Logic

### 2.1 Position Type Classification

**What**: Classifies each closed position as Regular, CopyPlus, or Mirror based on ParentPositionID and MirrorID.

**Columns/Parameters Involved**: `ParentPositionID`, `MirrorID`

**Rules**:
- `Regular`: ISNULL(ParentPositionID,0)=0 - no parent, no mirror. Customer opened manually.
- `CopyPlus`: ParentPositionID>0 AND ISNULL(MirrorID,0)=0 - copied but not mirrored (Copy Plus / Smart Portfolio).
- `Mirror`: ParentPositionID>0 AND MirrorID>0 - full CopyTrader position with leader mirror.

### 2.2 Pagination Pattern

**What**: ROW_NUMBER() + BETWEEN for page-based pagination.

**Rules**:
- CTE computes ROW_NUMBER() OVER (ORDER BY hp.EndDateTime DESC) - newest closes first.
- Outer SELECT: WHERE RowNum BETWEEN (@ItemsPerPage * (@PageNum-1)) + 1 AND (@ItemsPerPage * @PageNum).
- Page 1 = rows 1-@ItemsPerPage, Page 2 = rows @ItemsPerPage+1 to 2*@ItemsPerPage, etc.

### 2.3 3-Month Hard Filter

**What**: Results limited to positions closed within the last 3 calendar months.

**Rules**: `WHERE hp.CloseOccurred > DATEADD(m,-3,GETUTCDATE())` - hard-coded in the WHERE clause.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose closed positions are retrieved. Filters History.Position WHERE CID = @CID. |
| 2 | @ItemsPerPage | INT | NO | - | CODE-BACKED | Number of positions per page. Used in ROW_NUMBER() pagination: rows 1 to @ItemsPerPage for page 1. |
| 3 | @PageNum | INT | NO | - | CODE-BACKED | 1-based page number. Page 1 returns the most recently closed positions. |

**Result set columns:**

| Column | Source | Description |
|--------|--------|-------------|
| CID | History.Position | Customer ID |
| PositionID | History.Position | Unique position identifier |
| GameName | Dictionary.GameType | Game type name (e.g., "Demo", "Real") |
| IsBuy | History.Position | 1=Long/Buy, 0=Short/Sell |
| CurrencyBuy | Trade.Instrument.BuyCurrencyID | Buy currency ID |
| CurrencySell | Trade.Instrument.SellCurrencyID | Sell currency ID |
| BuyCurAbbreviation | Dictionary.Currency | Buy currency abbreviation (e.g., "EUR") |
| SellCurAbbreviation | Dictionary.Currency | Sell currency abbreviation (e.g., "USD") |
| BuyCurrencyTypeID | Dictionary.Currency | Buy currency type (e.g., 1=Forex, 5=Real Stock) |
| SellCurrencyTypeID | Dictionary.Currency | Sell currency type |
| OpenDate | History.Position.OpenOccurred | Position open timestamp |
| CloseDate | History.Position.EndDateTime | Position close timestamp |
| Amount | History.Position.Amount | Invested amount in USD |
| Units | History.Position.AmountInUnitsDecimal | Position size in units |
| OpenRate | History.Position.InitForexRate | Opening exchange rate |
| CloseRate | History.Position.EndForexRate | Closing exchange rate |
| Spread | History.Position.Commission*100 | Commission multiplied by 100 (spread in basis points) |
| Profit | History.Position.NetProfit | Net realized PnL in USD |
| Gain | (NetProfit/Amount)*100 | Percentage gain/loss on invested amount |
| MirrorID | History.Position | CopyTrader mirror/relationship ID (0 if manual) |
| ParentPositionID | History.Position | Parent position ID for copy trades (0 if manual) |
| PositionType | Computed | "Regular", "CopyPlus", or "Mirror" (see Section 2.1) |
| ClosePositionActionName | Dictionary.ClosePositionActionType | Human-readable close reason (e.g., "Manual", "Stop Loss") |
| ParentUserName | History.Mirror | CopyTrader leader's username (NULL if not a copy trade) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | History.Position | Read | Primary data source for closed positions. |
| JOIN | History.ForexResult | Read | Retrieves GameTypeID for the position. |
| JOIN | Dictionary.GameType | Lookup | Resolves GameTypeID to game name. |
| JOIN | Trade.Instrument | Lookup | Retrieves BuyCurrencyID and SellCurrencyID for the instrument. |
| JOIN | Dictionary.Currency (x2) | Lookup | Resolves buy and sell currency IDs to abbreviations and type IDs. |
| JOIN | Dictionary.ClosePositionActionType | Lookup | Resolves ActionType to close reason name. |
| LEFT JOIN | History.Mirror | Read | Retrieves ParentUserName for copy trade positions. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| eToro platform API | EXEC | Direct call | Position history page calls this for paginated closed position results. |
| PROD\BIadmins | VIEW DEFINITION | Monitoring | BI admins can inspect the definition. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetClosedPositionsPerPage (procedure)
├── History.Position (table)
├── History.ForexResult (table)
├── History.Mirror (table)
├── Dictionary.GameType (table) [cross-schema]
├── Dictionary.Currency (table) [cross-schema - x2]
├── Dictionary.ClosePositionActionType (table) [cross-schema]
└── Trade.Instrument (table) [cross-schema]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | Table | Main source of closed position data. |
| History.ForexResult | Table | JOIN for GameTypeID. |
| History.Mirror | Table | LEFT JOIN for ParentUserName (CopyTrader leader). |
| Dictionary.GameType | Table | Lookup for game name. |
| Dictionary.Currency | Table | Lookup for buy/sell currency abbreviations and type IDs (joined twice). |
| Dictionary.ClosePositionActionType | Table | Lookup for close action name. |
| Trade.Instrument | Table | Lookup for buy/sell currency IDs of the instrument. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| eToro platform (application) | External | Calls to display customer closed position history. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| 3-month filter | Hard limit | Only positions with CloseOccurred > 3 months ago are returned. |
| Spread = Commission * 100 | Data derivation | This procedure multiplies Commission by 100; GetClosedPositionsPerPageAndTimeFrame uses CommissionOnClose directly. |

---

## 8. Sample Queries

### 8.1 Get the first page of a customer's recent closed positions

```sql
EXEC History.GetClosedPositionsPerPage @CID = 12345, @ItemsPerPage = 10, @PageNum = 1;
```

### 8.2 Get the second page

```sql
EXEC History.GetClosedPositionsPerPage @CID = 12345, @ItemsPerPage = 10, @PageNum = 2;
```

### 8.3 Check underlying data for a specific customer and date range

```sql
SELECT TOP 10
    hp.PositionID, hp.OpenOccurred, hp.EndDateTime, hp.NetProfit,
    hp.ActionType, hp.MirrorID, hp.ParentPositionID
FROM History.Position hp WITH (NOLOCK)
WHERE hp.CID = 12345
  AND hp.CloseOccurred > DATEADD(MONTH, -3, GETUTCDATE())
ORDER BY hp.EndDateTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.9/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetClosedPositionsPerPage | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.GetClosedPositionsPerPage.sql*
