# History.GetUnrealizedPnl

> Scalar function that retrieves total unrealized position PnL for a customer at a historical date - reads PositionPnL from a DWH liabilities snapshot table, returning the most recent daily value before the requested date.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Scalar Function |
| **Signature** | `GetUnrealizedPnl(@CID INT, @Date DATETIME) RETURNS MONEY` |
| **Author** | Yulia Kramer - COFKV-772 (Account Statement Fix Old Summary), 2020-07-15 |
| **Purpose** | Account Statement historical unrealized equity lookup from DWH daily snapshots |

---

## 1. Business Meaning

`History.GetUnrealizedPnl` answers: *"What was this customer's total unrealized position P&L as of this historical date?"* It reads from `CustomerRealizedAnUnRealizedDate` - a synonym for `[DWH_Rep_AZR].[DWH_rep].[dbo].[V_Liabilities]` (the Data Warehouse liabilities view). The DWH stores daily portfolio snapshots with unrealized P&L values keyed by CID and a DateID integer in `yyyymmdd` format (the comment says `yyyymmddhhmm`, but the conversion uses `char(8)` of date 112 = `yyyymmdd`).

The function is used by Account Statement report procedures to show unrealized equity on a given historical date - specifically for customers requesting statements for past periods. Rather than recomputing unrealized PnL from raw position data, the function retrieves a pre-aggregated DWH snapshot.

**Companion function**: `History.GetUnrealizedPnlReal(@CID, @Date)` retrieves `PositionPnLStocksReal` (the real/non-synthetic component) from the same DWH table. The two are used together by `History.GetUnrealizedPnl_v1` (batch #22).

---

## 2. Business Logic

### 2.1 DWH Snapshot Lookup

**What**: Retrieves the most recent daily unrealized PnL snapshot before the requested date.

**Columns/Parameters Involved**: `@CID`, `@Date`, `CustomerRealizedAnUnRealizedDate.PositionPnL`, `CustomerRealizedAnUnRealizedDate.DateID`

**Rules**:
- Converts `@Date` to DateID integer: `CONVERT(INT, CONVERT(CHAR(8), @Date, 112))` -> e.g., `'2024-01-15'` -> `20240115`
- `SELECT TOP 1 PositionPnL FROM CustomerRealizedAnUnRealizedDate WITH(NOLOCK) WHERE CID = @CID AND DateID < @IntNum ORDER BY DateID DESC`
- Returns the most recent snapshot strictly BEFORE the requested date (not equal - using `<` not `<=`)
- Returns 0 if no snapshot exists for the customer before that date (ISNULL(..., 0))

**Note on DateID format**: The comment says `yyyymmddhhmm` but the conversion only captures the date part (`char(8)` with style 112 = `yyyymmdd`). The effective DateID is an 8-digit date integer. If the DWH stores multiple daily snapshots, this returns the latest snapshot before midnight of the requested day.

### 2.2 Account Statement Integration

**What**: Account Statement procedures call this function to include unrealized equity in the statement summary.

**Rules**:
- `dbo.AccountStatement_GetUnrealizedEquity` sets `@UnrealizedEquity = History.GetUnrealizedPnl(@CID, @DateTime)` then uses it in the statement
- Returns total portfolio unrealized PnL (all positions) - contrast with GetUnrealizedPnlReal which returns only real (stock) position PnL
- Used for COFKV-772 account statement fixes and ASIC compliance reporting

---

## 3. Data Overview

Direct query blocked (`CustomerRealizedAnUnRealizedDate` = synonym to `[DWH_Rep_AZR].[DWH_rep].[dbo].[V_Liabilities]` - DWH linked server). Based on the DDL:

| @CID | @Date | Expected PositionPnL | Meaning |
|------|-------|---------------------|---------|
| (active customer) | yesterday | Most recent daily snapshot | Customer's total unrealized position PnL |
| (customer with no positions) | any | 0 | NULL converted to 0 |
| any | earlier than first snapshot | 0 | No record found - returns 0 |

---

## 4. Elements

### Parameters

| # | Parameter | Type | Description |
|---|-----------|------|-------------|
| 1 | @CID | INT | Customer ID. Filters `CustomerRealizedAnUnRealizedDate` WHERE CID = @CID. |
| 2 | @Date | DATETIME | Target date. Converted to `yyyymmdd` integer (DateID). Returns latest snapshot with DateID < @IntNum. |

### Return Value

| Type | Description |
|------|-------------|
| MONEY | Total unrealized position PnL for the customer at the most recent DWH snapshot before @Date. Returns 0 if no snapshot found. Positive = unrealized profit, negative = unrealized loss. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @Date | CustomerRealizedAnUnRealizedDate | Query (DWH synonym) | DWH liabilities view: `[DWH_Rep_AZR].[DWH_rep].[dbo].[V_Liabilities]` - reads PositionPnL column |

### 5.2 Referenced By (other objects point to this)

| Object | Type | How Used |
|--------|------|----------|
| dbo.AccountStatement_GetUnrealizedEquity | Stored Procedure | ACTIVE - calls this to set @UnrealizedEquity for account statement |
| dbo.PR_NFA_Account_Statment | Stored Procedure | ACTIVE - NFA account statement report |
| History.GetUnrealizedPnl_v1 | Function (#22 this batch) | ACTIVE - combines GetUnrealizedPnl and GetUnrealizedPnlReal |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetUnrealizedPnl (scalar function)
+--> dbo.CustomerRealizedAnUnRealizedDate (synonym -> [DWH_Rep_AZR].[DWH_rep].[dbo].[V_Liabilities])
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.CustomerRealizedAnUnRealizedDate | Synonym (DWH linked server) | Source of PositionPnL and DateID |

### 6.2 Objects That Depend On This

| Object | Active? |
|--------|---------|
| dbo.AccountStatement_GetUnrealizedEquity | YES |
| dbo.PR_NFA_Account_Statment | YES |
| History.GetUnrealizedPnl_v1 | YES |

---

## 7. Technical Details

### 7.1 Performance Notes

- Queries the DWH linked server (`[DWH_Rep_AZR]`) on every call - network round-trip to DWH.
- TOP 1 with ORDER BY DateID DESC after CID filter - depends on DWH-side index on (CID, DateID).
- NOLOCK applied - acceptable for pre-aggregated DWH snapshots.

### 7.2 DateID Integer Format

- `CONVERT(CHAR(8), @Date, 112)` produces `'yyyymmdd'` (SQL Server style 112)
- `CONVERT(INT, ...)` converts to integer: `20240115`
- DateID < @IntNum means "before this date" (strictly) - a snapshot for exactly @Date would be excluded if DateID format is date-only

---

## 8. Sample Queries

### 8.1 Get unrealized PnL for a customer on a specific date

```sql
DECLARE @CID INT = 14866508
DECLARE @Date DATETIME = '2024-01-15'
SELECT History.GetUnrealizedPnl(@CID, @Date) AS UnrealizedPnL
```

### 8.2 Use in account statement context

```sql
-- Pattern used by dbo.AccountStatement_GetUnrealizedEquity
DECLARE @UnrealizedEquity MONEY
DECLARE @CID INT = 14866508
DECLARE @DateTime DATETIME = '2024-01-15 23:59:59'
SET @UnrealizedEquity = History.GetUnrealizedPnl(@CID, @DateTime)
SELECT @UnrealizedEquity AS UnrealizedEquity
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Related Jira tickets from DDL comments: COFKV-772 (Account Statement Fix Old Summary).

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 8.8/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 5, 7, 8, 10, 11) - DWH access blocked*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 direct consumers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetUnrealizedPnl | Type: Scalar Function | Source: etoro/etoro/History/Functions/History.GetUnrealizedPnl.sql*
