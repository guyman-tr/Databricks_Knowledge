# Trade.GetTradingDATAforCopyFund

> Computes asset class allocation ratios and recent trade activity counts for a Copy Fund trader, as of a given date. Returns Forex/Stocks/Indices ratios and trade counts for the trader's historical position data.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Date DATETIME, @ID UNIQUEIDENTIFIER |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure analyzes a trader's asset class distribution for the **Copy Fund** (Smart Portfolio) product. A Copy Fund is a eToro investment product that automatically allocates customer funds across a set of Popular Investors based on their trading profiles. To select and weight traders in a Copy Fund, the system needs to know what proportion of each trader's activity is in Forex, Stocks, and Indices.

Given a trader's customer GUID (`@ID`) and a reference date (`@Date`), the procedure computes:
- **Ratios**: What percentage of all historical positions (opened before @Date) were in each asset class (Forex, Stocks, Indices)
- **Recent trade counts**: How many positions were opened in the recent period - 1 month back for Forex and Indices, 1 quarter back for Stocks

The `@ID` parameter is a GUID (Customer.CustomerStatic.ID) rather than an integer CID - this is the external customer identifier used in public-facing APIs and external integrations. The first step resolves it to an internal CID.

**Asset class determination**: Resolved via `Trade.Instrument.BuyCurrencyID -> Dictionary.Currency -> Dictionary.CurrencyType.Name` (checking for 'Forex', 'Stocks', 'Indices'). Only these three asset classes contribute to the ratios; positions in other asset classes (Crypto, Commodities) count toward TotalPositions but are not counted in any ratio numerator.

---

## 2. Business Logic

### 2.1 GUID to CID Resolution

**What**: Resolves the external customer GUID to an internal CID.

**Columns/Parameters Involved**: `@ID`, `@CID`, `Customer.CustomerStatic.ID`, `Customer.CustomerStatic.CID`

**Rules**:
- `SELECT @CID = CID FROM Customer.CustomerStatic WHERE ID = @ID`
- If no matching GUID is found, @CID remains NULL and the main query returns no rows

### 2.2 Asset Class Ratio Calculation

**What**: For each position, flags it as Forex, Stocks, or Indices based on the instrument's buy currency type. Aggregates to compute ratios over all historical positions.

**Columns/Parameters Involved**: `Dictionary.CurrencyType.Name`, `OpenOccurred`, `@Date`

**Rules**:
- Only positions WHERE OpenOccurred < @Date (historical, not current) are included
- CASE WHEN CurrencyType.Name = 'Forex' THEN 1 ELSE 0 -> CountForex (all time)
- CASE WHEN CurrencyType.Name = 'Stocks' THEN 1 ELSE 0 -> CountStocks (all time)
- CASE WHEN CurrencyType.Name = 'Indices' THEN 1 ELSE 0 -> CountIndices (all time)
- Ratios: SUM(CountX) * 1.0 / SUM(CountPositions) -> floating point division (1.0 cast prevents integer division)
- A position in 'Crypto' or 'Commodities' increments TotalPositions but no ratio numerator

### 2.3 Recent Trade Activity Counts

**What**: Counts trades in a recent time window for each asset class.

**Columns/Parameters Involved**: `OpenOccurred`, `@Date`, `dateadd`

**Rules**:
- ForexTrades: count of Forex positions opened in the 1 month prior to @Date (OpenOccurred > DATEADD(m,-1,@Date))
- IndicesTrades: count of Indices positions opened in the 1 month prior to @Date
- StocksTrades: count of Stocks positions opened in the 1 quarter prior to @Date (DATEADD(q,-1,@Date))
- Note: "Month" (m) uses SQL Server's MONTH interval; "Quarter" (q) uses QUARTER interval

**Diagram**:
```
@Date = 2024-01-01

All positions opened before 2024-01-01 (for this CID):
  Position #1 - Forex     (OpenOccurred: 2023-10-15) -> CountForex=1, CountForexMonth=1 (>2023-12-01)
  Position #2 - Forex     (OpenOccurred: 2023-03-05) -> CountForex=1, CountForexMonth=0 (<=2023-12-01)
  Position #3 - Stocks    (OpenOccurred: 2023-11-20) -> CountStocks=1, CountStocksQuarter=1 (>2023-10-01)
  Position #4 - Indices   (OpenOccurred: 2022-06-01) -> CountIndices=1, CountIndicesMonth=0
  Position #5 - Crypto    (OpenOccurred: 2023-08-01) -> counted in TotalPositions only

Output: ForexRatio=0.4, ForexTrades=1, StocksRatio=0.2, StocksTrades=1, IndicesRatio=0.2, IndicesTrades=0, TotalPositions=5
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Date | DATETIME | NO | - | CODE-BACKED | Reference date. Positions opened before this date are analyzed. Used as the "as-of" date for the Copy Fund portfolio analysis. |
| 2 | @ID | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | External customer GUID (Customer.CustomerStatic.ID). Resolved to CID via Customer.CustomerStatic. |

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | ID | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | The input @ID GUID, passed through to the output for identification. |
| 4 | CID | INT | YES | NULL | CODE-BACKED | Resolved internal customer ID. NULL if @ID is not found in Customer.CustomerStatic. |
| 5 | ForexRatio | FLOAT | YES | NULL | CODE-BACKED | Proportion of all historical positions that are Forex. Range 0.0-1.0. NULL if TotalPositions=0. |
| 6 | ForexTrades | INT | YES | NULL | CODE-BACKED | Count of Forex positions opened in the 1 month prior to @Date. |
| 7 | StocksRatio | FLOAT | YES | NULL | CODE-BACKED | Proportion of all historical positions that are Stocks. Range 0.0-1.0. |
| 8 | StocksTrades | INT | YES | NULL | CODE-BACKED | Count of Stocks positions opened in the 1 quarter prior to @Date. |
| 9 | IndicesRatio | FLOAT | YES | NULL | CODE-BACKED | Proportion of all historical positions that are Indices. Range 0.0-1.0. |
| 10 | IndicesTrades | INT | YES | NULL | CODE-BACKED | Count of Indices positions opened in the 1 month prior to @Date. |
| 11 | TotalPositions | INT | YES | NULL | CODE-BACKED | Total number of positions opened before @Date for this customer. Denominator for all ratio calculations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID resolution | Customer.CustomerStatic | Reader (cross-schema) | SELECT CID WHERE ID = @ID (GUID lookup) |
| Position data | Trade.GetPositionData | Reader (view) | Source of historical position records; filtered by CID and OpenOccurred < @Date |
| InstrumentID / BuyCurrencyID | Trade.Instrument | Reader (INNER JOIN) | Resolves instrument to its buy currency |
| CurrencyID / CurrencyTypeID | Dictionary.Currency | Reader (INNER JOIN, cross-schema) | Resolves currency to currency type |
| CurrencyTypeID / Name | Dictionary.CurrencyType | Reader (INNER JOIN, cross-schema) | Resolves currency type to asset class name ('Forex', 'Stocks', 'Indices') |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Copy Fund / Smart Portfolio service | @Date, @ID | Application call | Computes trader asset allocation profile for fund portfolio construction |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetTradingDATAforCopyFund (procedure)
+-- Customer.CustomerStatic (table - cross-schema)
+-- Trade.GetPositionData (view)
+-- Trade.Instrument (table)
+-- Dictionary.Currency (table - cross-schema)
+-- Dictionary.CurrencyType (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table (Customer schema) | GUID -> CID resolution; SELECT CID WHERE ID = @ID; NOLOCK |
| Trade.GetPositionData | View | Source of historical open positions; NOLOCK; filtered by CID and OpenOccurred < @Date |
| Trade.Instrument | Table | INNER JOIN on InstrumentID for BuyCurrencyID; NOLOCK |
| Dictionary.Currency | Table (Dictionary schema) | INNER JOIN on CurrencyID = BuyCurrencyID for CurrencyTypeID; NOLOCK |
| Dictionary.CurrencyType | Table (Dictionary schema) | INNER JOIN on CurrencyTypeID for Name ('Forex', 'Stocks', 'Indices'); NOLOCK |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Copy Fund / Smart Portfolio construction service | External application | Trader asset allocation profiling for fund construction |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK on all tables | Isolation hint | READ UNCOMMITTED; acceptable for historical analysis |
| WHERE OpenOccurred < @Date | Time filter | Only historical positions (opened before reference date) |
| *1.0 in ratio calculations | Type cast | Forces float division (SUM(CountX)*1.0 / SUM(CountPositions)); prevents integer division truncation |
| INNER JOIN chain (Instrument -> Currency -> CurrencyType) | Asset classification | Positions without a resolvable currency type are excluded from the result |
| DATEADD(m,-1,@Date) | Recency filter (Forex/Indices) | 1-month lookback from @Date |
| DATEADD(q,-1,@Date) | Recency filter (Stocks) | 1-quarter (3-month) lookback from @Date |

---

## 8. Sample Queries

### 8.1 Get trading data for a Copy Fund trader as of today

```sql
EXEC Trade.GetTradingDATAforCopyFund
    @Date = GETDATE(),
    @ID = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
```

### 8.2 Analyze a trader's allocation as of a historical date

```sql
EXEC Trade.GetTradingDATAforCopyFund
    @Date = '2023-12-31',
    @ID = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
-- Returns asset ratios and trade counts as of end of 2023
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetTradingDATAforCopyFund | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetTradingDATAforCopyFund.sql*
