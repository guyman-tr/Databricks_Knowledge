# History.GetUnrealizedPnlReal

> Scalar function that retrieves the real (non-synthetic, stocks-only) component of unrealized position PnL for a customer at a historical date - reads PositionPnLStocksReal from the same DWH liabilities snapshot as GetUnrealizedPnl.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Scalar Function |
| **Signature** | `GetUnrealizedPnlReal(@CID INT, @Date DATETIME) RETURNS MONEY` |
| **Author** | Yulia Kramer - COFKV-149, COFKV-519 (ASIC GAML in Account Statement), 2020-06-16 |
| **Purpose** | Historical unrealized equity lookup for real/non-synthetic stock positions only |

---

## 1. Business Meaning

`History.GetUnrealizedPnlReal` is the "real positions" counterpart to `History.GetUnrealizedPnl`. Both functions query the same DWH table (`CustomerRealizedAnUnRealizedDate` = `[DWH_Rep_AZR].[DWH_rep].[dbo].[V_Liabilities]`) using identical logic - but this function reads `PositionPnLStocksReal` instead of `PositionPnL`.

The "Real" distinction separates non-leveraged real stock positions (e.g., eToro Free Stocks - actual share ownership) from synthetic/leveraged CFD positions. `PositionPnLStocksReal` represents the unrealized P&L on real stock holdings only, which is particularly relevant for:
- ASIC (Australian Securities and Investments Commission) compliance reporting - COFKV-149, COFKV-519 reference "ASIC GAML in Account Statement" (GAML = Global Account Management Layer)
- Regulatory statements that must distinguish real asset exposure from synthetic trading exposure

**Combined usage**: `History.GetUnrealizedPnl_v1` (batch #22) calls both `GetUnrealizedPnl` and `GetUnrealizedPnlReal` to compute the total minus the real component, effectively extracting the synthetic/CFD component.

See `History.GetUnrealizedPnl.md` for the full DWH lookup pattern - logic is identical except for the column name.

---

## 2. Business Logic

### 2.1 DWH Snapshot Lookup

Identical to `History.GetUnrealizedPnl` except reads `PositionPnLStocksReal`:

**Rules**:
- `SELECT @IntNum = CONVERT(INT, CONVERT(CHAR(8), @Date, 112))`
- `SELECT TOP 1 @UnrealizedPnl = ISNULL(PositionPnLStocksReal, 0) FROM CustomerRealizedAnUnRealizedDate WITH(NOLOCK) WHERE CID = @CID AND DateID < @IntNum ORDER BY DateID DESC`
- Returns 0 if no snapshot found

**Column distinction**:
- `PositionPnL` (in GetUnrealizedPnl): Total unrealized P&L across ALL position types
- `PositionPnLStocksReal` (this function): Unrealized P&L from real/non-synthetic stock positions only

---

## 3. Data Overview

Same data source as `History.GetUnrealizedPnl`. Returns 0 for customers with no real stock positions.

---

## 4. Elements

### Parameters

| # | Parameter | Type | Description |
|---|-----------|------|-------------|
| 1 | @CID | INT | Customer ID. |
| 2 | @Date | DATETIME | Target date. Converted to yyyymmdd DateID integer. Returns latest snapshot with DateID < @IntNum. |

### Return Value

| Type | Description |
|------|-------------|
| MONEY | Unrealized PnL from real/non-synthetic stock positions as of the most recent DWH snapshot before @Date. Returns 0 if no snapshot found or customer has no real positions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @Date | CustomerRealizedAnUnRealizedDate | Query (DWH synonym) | `[DWH_Rep_AZR].[DWH_rep].[dbo].[V_Liabilities]` - reads PositionPnLStocksReal column |

### 5.2 Referenced By (other objects point to this)

| Object | Type | How Used |
|--------|------|----------|
| dbo.AccountStatement_GetUnrealizedEquityReal | Stored Procedure | ACTIVE - calls this to set @UnrealizedEquity for real-position account statement |
| History.GetUnrealizedPnl_v1 | Function (#22 this batch) | ACTIVE - subtracts GetUnrealizedPnlReal from total to isolate synthetic P&L |

---

## 6. Dependencies

Same as `History.GetUnrealizedPnl` - single dependency on `dbo.CustomerRealizedAnUnRealizedDate` synonym.

---

## 7. Technical Details

Identical to `History.GetUnrealizedPnl` in all technical aspects (linked server query, DateID conversion, NOLOCK). The only difference is the DWH column name: `PositionPnLStocksReal` vs `PositionPnL`.

---

## 8. Sample Queries

### 8.1 Get real-position unrealized PnL

```sql
DECLARE @CID INT = 14866508
DECLARE @Date DATETIME = '2024-01-15'
SELECT History.GetUnrealizedPnlReal(@CID, @Date) AS UnrealizedRealPnL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Related Jira tickets from DDL comments: COFKV-149, COFKV-519 (ASIC GAML in Account Statement).

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 8.5/10, Logic: 8.8/10, Relationships: 8.8/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 5, 7, 8, 10, 11) - DWH access blocked*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 direct consumers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetUnrealizedPnlReal | Type: Scalar Function | Source: etoro/etoro/History/Functions/History.GetUnrealizedPnlReal.sql*
