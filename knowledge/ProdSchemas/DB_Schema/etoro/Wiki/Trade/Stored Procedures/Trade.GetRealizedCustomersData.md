# Trade.GetRealizedCustomersData

> Aggregates total realized P&L, commission, and combined IFX revenue from closed positions since a given date, excluding demo (PlayerLevelID=4) accounts.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @From DATETIME |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure computes three aggregate financial metrics over all closed positions since a given datetime: eToro's net P&L (PNLeToro), commission revenue (Commission), and IFX revenue (PNLIFX). "IFX" refers to the interdealer FX/broker revenue model - eToro's total revenue from a closed position equals the commission plus the net P&L from hedging spreads. Excluding demo accounts (PlayerLevelID=4) ensures only real-money trading activity is measured.

The procedure serves financial reporting and reconciliation. It answers the question: "How much did eToro's real-money customers earn/lose, and how much commission did eToro collect, since time X?" A parallel procedure `Hedge.GetRealizedCustomersData` provides a more detailed breakdown by HedgeServerID and InstrumentID for the hedging layer.

Data flows: Reads History.Position (closed positions) JOINed to Customer.Customer to filter out demo accounts. EndDateTime >= @From limits to positions closed on or after the start of the reporting window. Results are aggregated to a single summary row with three SUM values.

---

## 2. Business Logic

### 2.1 Demo Account Exclusion

**What**: Only real-money trading activity is included - demo/practice accounts are excluded.

**Columns/Parameters Involved**: `Customer.Customer.PlayerLevelID`

**Rules**:
- JOIN to Customer.Customer and filter PlayerLevelID <> 4.
- PlayerLevelID=4 = Demo/practice account (context from Hedge.GetRealizedCustomersData which applies the same filter).
- All other PlayerLevelIDs represent real-money accounts.
- This ensures financial metrics reflect only actual revenue, not simulated trading.

### 2.2 IFX Revenue Calculation

**What**: PNLIFX represents the total eToro revenue from a closed position - the sum of direct commission plus net profit from the position.

**Columns/Parameters Involved**: `CommissionOnClose`, `NetProfit`

**Rules**:
- PNLeToro = SUM(NetProfit): The position's P&L from the spread/hedge.
- Commission = SUM(CommissionOnClose): Direct commission charged on close.
- PNLIFX = SUM(CommissionOnClose + NetProfit): Total IFX revenue per position (eToro's total take).
- Both inputs use ISNULL(..., 0) to treat NULL as zero in the aggregation.

**Diagram**:
```
Per closed position:
  NetProfit          -> eToro's hedge/spread P&L
  CommissionOnClose  -> Direct commission charged to customer
  pnl_ifx = CommissionOnClose + NetProfit -> Total eToro revenue

Aggregated across all qualifying positions:
  PNLeToro  = SUM(NetProfit)
  Commission = SUM(CommissionOnClose)
  PNLIFX    = SUM(pnl_ifx)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @From | DATETIME | NO | - | CODE-BACKED | Start of the reporting window. Filters History.Position WHERE EndDateTime >= @From. Positions closed at or after this datetime are included. Typically set to start of the reporting period (e.g., start of month, start of day). |

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | PNLeToro | DECIMAL | NO | 0 | CODE-BACKED | Total realized net profit/loss across all qualifying closed positions since @From. Aggregates History.Position.NetProfit. Represents eToro's P&L from the hedge/spread. ISNULL-protected: returns 0 if no qualifying positions exist. |
| 3 | Commission | DECIMAL | NO | 0 | CODE-BACKED | Total commission collected on close across all qualifying positions. Aggregates History.Position.CommissionOnClose. Direct commission revenue. ISNULL-protected. |
| 4 | PNLIFX | DECIMAL | NO | 0 | CODE-BACKED | Total IFX revenue since @From: SUM(CommissionOnClose + NetProfit). Represents the full eToro revenue per closed position (commission plus hedge P&L). ISNULL-protected. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| NetProfit, CommissionOnClose | History.Position | Reader (cross-schema) | Source of closed position P&L and commission data |
| PlayerLevelID | Customer.Customer | INNER JOIN filter (cross-schema) | Excludes demo accounts (PlayerLevelID=4) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | EXECUTE | Permission | BI admin access for financial reporting |
| Hedge.AddCustomersDataGeneral | EXEC call | Procedure caller | Called from hedging data aggregation process |
| Financial reporting service | @From | Application call | Period P&L and revenue aggregation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetRealizedCustomersData (procedure)
+-- History.Position (table - cross-schema)
+-- Customer.Customer (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | Table (History schema) | Source of closed position NetProfit, CommissionOnClose; filtered by EndDateTime >= @From |
| Customer.Customer | Table (Customer schema) | INNER JOIN to filter out demo accounts (PlayerLevelID <> 4) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AddCustomersDataGeneral | Procedure (Hedge schema) | Calls this procedure as part of hedge data aggregation |
| PROD_BIadmins | DB user | EXECUTE permission - BI financial reporting |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK | Isolation hint | READ UNCOMMITTED on History.Position and Customer.Customer |
| WHERE EndDateTime >= @From | Time filter | Only positions closed from @From onwards |
| PlayerLevelID <> 4 | Business filter | Excludes demo/practice accounts from revenue reporting |
| INNER JOIN Customer.Customer | Implicit filter | Positions for customers not in Customer.Customer are excluded |

---

## 8. Sample Queries

### 8.1 Get realized P&L and revenue for the current month

```sql
EXEC Trade.GetRealizedCustomersData @From = '2026-03-01';
```

### 8.2 Equivalent inline query for a specific date range

```sql
SELECT
    ISNULL(SUM(HCFPC.NetProfit), 0) AS PNLeToro,
    ISNULL(SUM(HCFPC.CommissionOnClose), 0) AS Commission,
    ISNULL(SUM(HCFPC.CommissionOnClose + HCFPC.NetProfit), 0) AS PNLIFX
FROM History.Position HCFPC WITH (NOLOCK)
INNER JOIN Customer.Customer CC WITH (NOLOCK) ON HCFPC.CID = CC.CID
    AND CC.PlayerLevelID <> 4
WHERE HCFPC.EndDateTime >= '2026-03-01';
```

### 8.3 Compare daily revenue trends across multiple days

```sql
-- Run separately for each day to build a trend
SELECT
    CAST(HCFPC.EndDateTime AS DATE) AS CloseDate,
    COUNT(*) AS ClosedPositions,
    ISNULL(SUM(HCFPC.NetProfit), 0) AS PNLeToro,
    ISNULL(SUM(HCFPC.CommissionOnClose), 0) AS Commission
FROM History.Position HCFPC WITH (NOLOCK)
INNER JOIN Customer.Customer CC WITH (NOLOCK) ON HCFPC.CID = CC.CID
    AND CC.PlayerLevelID <> 4
WHERE HCFPC.EndDateTime >= DATEADD(DAY, -7, GETDATE())
GROUP BY CAST(HCFPC.EndDateTime AS DATE)
ORDER BY CloseDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller (Hedge.AddCustomersDataGeneral) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetRealizedCustomersData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetRealizedCustomersData.sql*
