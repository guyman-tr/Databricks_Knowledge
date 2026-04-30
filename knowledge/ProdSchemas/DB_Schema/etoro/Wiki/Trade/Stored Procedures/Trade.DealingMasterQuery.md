# Trade.DealingMasterQuery

> Weekly dealing desk profitability report that calculates realized and unrealized P&L by hedge server, combining closed-position profits with mark-to-market changes on open positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Weekly P&L summary grouped by HedgeServerID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DealingMasterQuery is a financial reporting procedure used by the dealing desk to assess weekly profitability across hedge servers. It produces a single result set showing realized profits from positions closed during the week, plus the change in unrealized P&L from positions that remained open at the start and end of the reporting period. The "Zero" metric (NetProfit + Commission) represents the net dealing P&L after commissions are factored in.

This procedure exists to give the dealing/risk management team a consolidated view of how each hedge server performed over a given week. Without it, analyzing realized vs. unrealized P&L across multiple hedge servers and time windows would require complex ad-hoc queries against both Trade.Position and History.Position.

Data flows from three logical sources: (1) closed positions during the week from History.Position provide realized P&L, (2) positions open at the start-of-week provide the unrealized baseline, and (3) positions open at end-of-week provide the unrealized endpoint. The difference in unrealized values gives the weekly unrealized P&L change. Demo/test accounts (PlayerLevelID = 4) are excluded from all calculations. Two different P&L functions are used: History.GetNetProfitForDealing for historical positions and Internal.GetNetProfit (divided by 100 to convert from cents to dollars) for live positions.

---

## 2. Business Logic

### 2.1 Realized P&L Calculation

**What**: Profits from positions that closed during the reporting week.

**Columns/Parameters Involved**: `@StartOfweek`, `@EndOfweek`, `NetProfit`, `CommissionOnClose`, `Commission`

**Rules**:
- RealizedNetProfit = SUM of NetProfit from History.Position where CloseOccurred is within the week
- RealizedCommission = SUM of CommissionOnClose from closed positions
- RealizedZero = SUM(NetProfit + Commission) - the net P&L after commissions

### 2.2 Unrealized P&L Diff Calculation

**What**: Change in mark-to-market value of positions open across the week boundary.

**Columns/Parameters Involved**: `@StartOfweek`, `@EndOfweek`, `History.GetNetProfitForDealing`, `Internal.GetNetProfit`

**Rules**:
- Start-of-week unrealized = sum of GetNetProfitForDealing + CommissionOnClose for positions open at start-of-week (both historical positions that were open at that time and still-open Trade.Position positions)
- End-of-week unrealized = same calculation at end-of-week, plus Internal.GetNetProfit/100 for live positions
- UnrealizedZeroDiff = EOW unrealized - SOW unrealized
- TotalZero = RealizedZero + UnrealizedZeroDiff (complete weekly dealing P&L)

**Diagram**:
```
Week: @StartOfweek --------- @EndOfweek
         |                        |
    SOW Snapshot             EOW Snapshot
    (unrealized)             (unrealized)
         |                        |
         +--- UnrealizedZeroDiff -+
                    +
              RealizedZero (closed during week)
                    =
                TotalZero
```

### 2.3 Demo Account Exclusion

**What**: Filters out non-real accounts from dealing reports.

**Columns/Parameters Involved**: `PlayerLevelID`

**Rules**:
- All subqueries JOIN to Customer.Customer and filter WHERE PlayerLevelID <> 4
- PlayerLevelID = 4 represents demo/test accounts that should not affect dealing desk P&L

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartOfweek | DATETIME | NO | - | CODE-BACKED | Start of the reporting week. Used as the lower bound for CloseOccurred (realized P&L) and as the snapshot time for start-of-week unrealized P&L calculation. |
| 2 | @EndOfweek | DATETIME | NO | - | CODE-BACKED | End of the reporting week. Used as the upper bound for CloseOccurred (realized P&L) and as the snapshot time for end-of-week unrealized P&L calculation. |

**Output Columns**:

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | (GETDATE()) | DATETIME | CODE-BACKED | Report generation timestamp. |
| 2 | HedgeServerID | INT | CODE-BACKED | Hedge server identifier. Groups all P&L metrics by the hedge server that handled the positions. |
| 3 | Instrument | VARCHAR | CODE-BACKED | Always returns empty string - placeholder column, instrument-level detail is commented out in the query. |
| 4 | RealizedNetProfit | MONEY | CODE-BACKED | Sum of NetProfit from positions closed during the week on this hedge server. |
| 5 | RealizedCommission | MONEY | CODE-BACKED | Sum of CommissionOnClose from positions closed during the week. |
| 6 | RealizedZero | MONEY | CODE-BACKED | Net realized P&L: SUM(NetProfit + Commission) for closed positions. "Zero" represents the net-of-commission dealing P&L. |
| 7 | UnrealizedZeroDiff | MONEY | CODE-BACKED | Change in unrealized P&L across the week: (end-of-week unrealized) - (start-of-week unrealized). Captures mark-to-market movement on positions that stayed open. |
| 8 | TotalZero | MONEY | CODE-BACKED | Total weekly dealing P&L: RealizedZero + UnrealizedZeroDiff. The complete profitability metric for the hedge server for the week. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (FROM) | History.Position | READ | Source for closed positions (realized P&L) and historical positions open at snapshot time (unrealized P&L) |
| (JOIN) | Customer.Customer | READ | Joined via CID to exclude demo accounts (PlayerLevelID <> 4) |
| (FROM) | Trade.Position | READ | Source for currently-open positions used in unrealized P&L snapshots |
| (CALL) | History.GetNetProfitForDealing | Function Call | Calculates dealing-adjusted net profit for historical positions |
| (CALL) | Internal.GetNetProfit | Function Call | Calculates net profit for live positions (returns value in cents, divided by 100) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| UsersPermissions/Dealing | GRANT | Permission | EXECUTE permission granted to Dealing role |
| UsersPermissions/PROD_BIadmins | GRANT | Permission | EXECUTE permission granted to PROD_BIadmins role |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DealingMasterQuery (procedure)
+-- History.Position (table, cross-schema)
+-- Customer.Customer (table, cross-schema)
+-- Trade.Position (view)
+-- History.GetNetProfitForDealing (function, cross-schema)
+-- Internal.GetNetProfit (function, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | Table | Read for closed positions (realized P&L) and historical unrealized snapshots |
| Customer.Customer | Table | Joined to filter out demo accounts (PlayerLevelID <> 4) |
| Trade.Position | View | Read for currently-open positions in unrealized P&L calculation |
| History.GetNetProfitForDealing | Scalar Function | Called to compute dealing-adjusted net profit for historical positions |
| Internal.GetNetProfit | Scalar Function | Called to compute net profit for live positions (returns cents) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dealing role | Permission | Has EXECUTE permission |
| PROD_BIadmins role | Permission | Has EXECUTE permission |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Run weekly dealing report for the current week

```sql
DECLARE @StartOfWeek DATETIME = DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0)
DECLARE @EndOfWeek DATETIME = DATEADD(DAY, 6, @StartOfWeek)
EXEC Trade.DealingMasterQuery @StartOfWeek, @EndOfWeek
```

### 8.2 Run for a specific historical week

```sql
EXEC Trade.DealingMasterQuery '2026-03-02', '2026-03-08'
```

### 8.3 Check hedge server P&L with server names

```sql
DECLARE @S DATETIME = '2026-03-02', @E DATETIME = '2026-03-08'
SELECT  hs.HedgeServerName,
        r.*
FROM    (
    SELECT  HedgeServerID, RealizedNetProfit, RealizedCommission, TotalZero
    FROM    OPENROWSET('SQLNCLI', 'Server=.;Trusted_Connection=yes;',
            'EXEC Trade.DealingMasterQuery ''2026-03-02'', ''2026-03-08''')
) r
JOIN    Trade.HedgeServer hs WITH (NOLOCK) ON hs.HedgeServerID = r.HedgeServerID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 5.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DealingMasterQuery | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DealingMasterQuery.sql*
