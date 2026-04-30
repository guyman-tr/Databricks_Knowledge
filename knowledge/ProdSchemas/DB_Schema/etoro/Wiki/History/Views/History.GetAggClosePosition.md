# History.GetAggClosePosition

> Hourly aggregated closed-position view - groups History.Position by customer and hour (CID + CloseOccurred truncated to the hour) computing summed Commission, NetProfit, and lot count, with BonusUsed calculated via a scalar function call. Enriches each row with customer acquisition/tracking attributes from Customer.Customer. Used for closed position aggregate reporting.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | CID + Occurred (datetime hour truncated) |
| **Partition** | N/A |
| **Indexes** | N/A (view - aggregation-based) |

---

## 1. Business Meaning

History.GetAggClosePosition provides a pre-aggregated hourly summary of closed positions per customer. Rather than returning individual position rows, it groups all positions closed within the same calendar hour by the same customer, summing Commission (in cents), NetProfit, and lot count into a single row per (CID, hour, customer acquisition attributes) combination.

The view is used for reporting and analytics that need hourly position close summaries - dashboards, SSRS reports, and data exports that show trading activity aggregated by hour rather than individual position level.

**Key aggregation**: The `Occurred` column is a datetime truncated to the hour (year/month/day/hour:00:00) computed from CloseOccurred. This allows consumers to group or filter by hour without needing to perform date truncation themselves.

**BonusUsed**: The `Trade.GetBonusUsed` scalar function is called inline for each group, computing how much bonus was consumed during that hour for the customer. This is a scalar UDF call inside a GROUP BY view, which may cause performance concerns for large datasets.

**Customer acquisition context**: The view enriches each row with tracking metadata from Customer.Customer: OriginalCID, OriginalProviderID, SerialID, SubSerialID, BannerID, DownloadID, CountryIDByIP, ProviderID, RealProviderID, FunnelID, LabelID, DownloadCounter, PlayerLevelID. These are marketing and acquisition attribution fields used in performance analysis.

---

## 2. Business Logic

### 2.1 Hourly Grouping Pattern

**What**: CloseOccurred is truncated to the hour and returned as `Occurred`.

**Columns/Parameters Involved**: `Occurred`, `CloseOccurred`

**Rules**:
- `Occurred = convert(datetime, YYYY-MM-DD HH:00:00)` - reconstructed datetime at hour precision
- All positions closed within the same calendar hour for the same customer are aggregated into one row
- The GROUP BY includes all non-aggregated columns: CID, acquisition attributes (OriginalCID, ProviderID, etc.), and the date parts

### 2.2 Financial Aggregations

**What**: Commission, NetProfit, and Lots are summed across all positions closed in the hour.

**Columns/Parameters Involved**: `Commission`, `NetProfit`, `Lots`, `BonusUsed`

**Rules**:
- `Commission = SUM(Commission*100)` - aggregated commission in cents (Commission from History.Position is in dollars, multiplied by 100)
- `NetProfit = SUM(NetProfit)` - total net profit for all positions closed in the hour
- `Lots = SUM(LotCountDecimal)` - total lot count across closed positions in the hour
- `BonusUsed = Trade.GetBonusUsed(CID, year, month, day, hour)` - scalar UDF computing bonus consumption for the customer in that hour. Called once per GROUP BY row.

### 2.3 Customer Acquisition Attributes

**What**: Marketing and acquisition tracking fields are inherited from Customer.Customer per-customer.

**Columns/Parameters Involved**: `OriginalCID`, `OriginalProviderID`, `SerialID`, `SubSerialID`, `BannerID`, `DownloadID`, `CountryIDByIP`, `ProviderID`, `RealProviderID`, `FunnelID`, `LabelID`, `DownloadCounter`, `PlayerLevelID`

**Rules**:
- These fields come from Customer.Customer (INNER JOIN on CID)
- The GROUP BY includes all these fields - each unique combination of (CID + acquisition attributes + hour) produces one row
- Since acquisition attributes are 1:1 with CID (they don't change per position), the GROUP BY does not produce multiple rows per CID per hour

---

## 3. Data Overview

The view aggregates History.Position data. Sample output (conceptual):

| Occurred | CID | Commission | NetProfit | Lots | BonusUsed | OriginalProviderID |
|----------|-----|-----------|-----------|------|-----------|-------------------|
| 2026-03-21 08:00:00 | 14952810 | (sum cents) | (sum USD) | (sum lots) | 0.00 | varies |

Actual data depends on positions closed in each hour; no rows for hours with no closed positions for a given customer.

---

## 4. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | Occurred | datetime | NO | CODE-BACKED | CloseOccurred truncated to the hour (YYYY-MM-DD HH:00:00). Groups all positions closed within the same calendar hour. |
| 2 | CID | int | NO | CODE-BACKED | Customer ID. INNER JOIN with Customer.Customer guarantees non-NULL. |
| 3 | Commission | money | YES | CODE-BACKED | SUM(Commission*100) - total commission in cents for all positions closed in this hour for this customer. |
| 4 | NetProfit | money | YES | CODE-BACKED | SUM(NetProfit) - total realized P&L (USD) for all positions closed in this hour. Negative = net loss. |
| 5 | Lots | decimal | YES | CODE-BACKED | SUM(LotCountDecimal) - total lot count across all positions closed in this hour. |
| 6 | BonusUsed | (scalar UDF result) | YES | CODE-BACKED | Trade.GetBonusUsed(CID, year, month, day, hour) - bonus amount consumed by this customer in this hour. Computed per aggregation group. |
| 7 | OriginalCustomerID | int | YES | CODE-BACKED | Customer.Customer.OriginalCID - the "original" CID for customers who were re-created or migrated. |
| 8 | OriginalProviderID | int | YES | CODE-BACKED | Original marketing provider at customer acquisition time. |
| 9 | SerialID | int | YES | CODE-BACKED | Marketing serial/campaign identifier at acquisition. |
| 10 | SubSerialID | int | YES | CODE-BACKED | Sub-campaign identifier. |
| 11 | BannerID | int | YES | CODE-BACKED | Banner/creative ID that attributed this customer acquisition. |
| 12 | DownloadID | int | YES | CODE-BACKED | App download tracking ID. |
| 13 | CountryIDByIP | int | YES | CODE-BACKED | Customer's country as detected by IP at registration. FK to Dictionary.Country. |
| 14 | ProviderID | int | YES | CODE-BACKED | Customer.Customer.ProviderID - current provider (may differ from OriginalProviderID if migrated). |
| 15 | RealProviderID | int | YES | CODE-BACKED | The real/final provider for this customer. |
| 16 | FunnelID | int | YES | CODE-BACKED | Marketing funnel this customer entered through. |
| 17 | LabelID | int | YES | CODE-BACKED | Marketing label/tag. |
| 18 | DownloadCounter | int | YES | CODE-BACKED | Count of app downloads attributed to this customer's acquisition. |
| 19 | PlayerLevelID | int | YES | CODE-BACKED | Player level/tier classification for this customer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (positions) | History.Position | View (aggregation source) | All closed positions - INNER JOIN on CID |
| CID | Customer.Customer | View (INNER JOIN) | Customer acquisition attributes |
| BonusUsed | Trade.GetBonusUsed | Scalar function call | Computes bonus consumption per customer+hour |

### 5.2 Referenced By (other objects point to this)

No stored procedure consumers found in SSDT codebase. The view is likely consumed directly by BI tools, SSRS reports, or external analytics platforms. Access permissions in PROD_BIadmins.sql and PositionAdapterService.sql reference GetClosedPositions/GetAggClosePosition.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetAggClosePosition (view)
|- History.Position (view - 65-branch UNION ALL, full history)
|- Customer.Customer (table - cross-schema)
+- Trade.GetBonusUsed (scalar function - computes bonus per CID+hour)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | View | Aggregation source - all closed positions |
| Customer.Customer | Table | INNER JOIN for acquisition attributes |
| Trade.GetBonusUsed | Scalar Function | Inline call per aggregation group |

### 6.2 Objects That Depend On This

No SQL procedure consumers found in SSDT. Likely consumed by BI/reporting layers directly.

---

## 7. Technical Details

### 7.1 Performance Note

This view calls `Trade.GetBonusUsed` as a scalar UDF inside the GROUP BY definition. Scalar UDF calls in views disable set-based optimization - each group executes the UDF once, which can be a bottleneck for large date ranges. Consumers should filter by CID and narrow date ranges.

---

## 8. Sample Queries

### 8.1 Get hourly closed position summary for a customer
```sql
SELECT
    acp.Occurred,
    acp.Commission,
    acp.NetProfit,
    acp.Lots,
    acp.BonusUsed
FROM History.GetAggClosePosition acp WITH (NOLOCK)
WHERE acp.CID = 14952810
  AND acp.Occurred >= DATEADD(DAY, -30, GETUTCDATE())
ORDER BY acp.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for History.GetAggClosePosition.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 2, 5, 7, 8)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 consumers found | App Code: 0 repos | Corrections: 0 applied*
*Object: History.GetAggClosePosition | Type: View | Source: etoro/etoro/History/Views/History.GetAggClosePosition.sql*
