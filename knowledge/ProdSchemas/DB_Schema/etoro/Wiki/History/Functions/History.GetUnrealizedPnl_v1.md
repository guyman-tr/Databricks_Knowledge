# History.GetUnrealizedPnl_v1

> Scalar function that computes the synthetic/CFD-only unrealized PnL for a customer at a historical date - subtracts the real/stocks component (PositionPnLStocksReal) from total (PositionPnL) using the same DWH snapshot as GetUnrealizedPnl.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Scalar Function |
| **Signature** | `GetUnrealizedPnl_v1(@CID INT, @Date DATETIME) RETURNS MONEY` |
| **Author** | Yulia Kramer - COFKV-772, 2020-07-15 |
| **Purpose** | Synthetic/CFD-only unrealized PnL = total minus real stocks component |

---

## 1. Business Meaning

`History.GetUnrealizedPnl_v1` returns the unrealized P&L from synthetic (CFD/forex/leveraged) positions only, by computing `PositionPnL - PositionPnLStocksReal` from the DWH snapshot in `CustomerRealizedAnUnRealizedDate`. This is the "v1" (version 1) refinement of `History.GetUnrealizedPnl` that separates out the real stock position P&L.

The business distinction:
- `History.GetUnrealizedPnl` returns `PositionPnL` = total unrealized P&L (all position types)
- `History.GetUnrealizedPnlReal` returns `PositionPnLStocksReal` = real stock positions only
- `History.GetUnrealizedPnl_v1` (this function) returns `PositionPnL - PositionPnLStocksReal` = synthetic/CFD positions only

This separation is needed for regulatory reporting (ASIC compliance) and account statements that must distinguish leveraged/synthetic trading exposure from real stock ownership.

The consumer `dbo.AccountStatement_GetUnrealizedEquity_v1` calls this function to get the synthetic P&L component for account statement generation.

---

## 2. Business Logic

### 2.1 DWH Snapshot Lookup (Combined Formula)

**What**: Single query that subtracts real from total in one DWH round-trip.

**Rules**:
- `SELECT @IntNum = CONVERT(INT, CONVERT(CHAR(8), @Date, 112))`
- `SELECT TOP 1 @UnrealizedPnl = ISNULL(PositionPnL, 0) - ISNULL(PositionPnLStocksReal, 0) FROM CustomerRealizedAnUnRealizedDate WITH(NOLOCK) WHERE CID = @CID AND DateID < @IntNum ORDER BY DateID DESC`
- Computes the subtraction in the SELECT clause - single query to the DWH vs two separate calls to GetUnrealizedPnl + GetUnrealizedPnlReal
- Returns 0 if no snapshot found (ISNULL on result)

**Optimization note**: This function is more efficient than calling `GetUnrealizedPnl(@CID, @Date) - GetUnrealizedPnlReal(@CID, @Date)` separately - it does one DWH query instead of two.

---

## 3. Data Overview

Same DWH source as `History.GetUnrealizedPnl`. Returns 0 for customers with no synthetic positions or no DWH snapshot.

---

## 4. Elements

### Parameters

Identical to `History.GetUnrealizedPnl` and `History.GetUnrealizedPnlReal`.

| # | Parameter | Type | Description |
|---|-----------|------|-------------|
| 1 | @CID | INT | Customer ID. |
| 2 | @Date | DATETIME | Target date. Converted to yyyymmdd DateID integer. Returns latest snapshot with DateID < @IntNum. |

### Return Value

| Type | Description |
|------|-------------|
| MONEY | Synthetic/CFD unrealized PnL = PositionPnL minus PositionPnLStocksReal. Returns 0 if no snapshot or if real P&L equals total P&L. Positive = unrealized synthetic profit, negative = unrealized synthetic loss. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @Date | CustomerRealizedAnUnRealizedDate | Query (DWH synonym) | `[DWH_Rep_AZR].[DWH_rep].[dbo].[V_Liabilities]` - reads PositionPnL minus PositionPnLStocksReal |

### 5.2 Referenced By (other objects point to this)

| Object | Type | How Used |
|--------|------|----------|
| dbo.AccountStatement_GetUnrealizedEquity_v1 | Stored Procedure | ACTIVE - calls this for synthetic/CFD unrealized equity in account statement |

---

## 6. Dependencies

Same as `History.GetUnrealizedPnl` - single dependency on `dbo.CustomerRealizedAnUnRealizedDate`.

---

## 7. Technical Details

See `History.GetUnrealizedPnl.md` Section 7 for performance and DateID format notes. This function makes a single DWH call for both columns, making it more efficient than separately calling the other two functions.

### 7.1 GetUnrealizedPnl Family Comparison

| Function | Formula | Use Case |
|----------|---------|---------|
| GetUnrealizedPnl | PositionPnL | Total unrealized (all positions) |
| GetUnrealizedPnlReal | PositionPnLStocksReal | Real stocks only |
| GetUnrealizedPnl_v1 | PositionPnL - PositionPnLStocksReal | Synthetic/CFD only |

---

## 8. Sample Queries

### 8.1 Get synthetic/CFD unrealized PnL

```sql
DECLARE @CID INT = 14866508
DECLARE @Date DATETIME = '2024-01-15'
SELECT History.GetUnrealizedPnl_v1(@CID, @Date) AS UnrealizedSyntheticPnL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Related Jira tickets: COFKV-772 (Account Statement Fix Old Summary).

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 8.8/10, Logic: 9.2/10, Relationships: 9.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 5, 7, 8, 10, 11) - DWH blocked*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 direct consumer | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetUnrealizedPnl_v1 | Type: Scalar Function | Source: etoro/etoro/History/Functions/History.GetUnrealizedPnl_v1.sql*
