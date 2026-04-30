# Trade.GetHedgeCost

> Calculates hedge cost per hedge server for a date range, optionally including net profit in the total.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | HedgeServerID + HedgeCost (result set) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure calculates the total hedging cost for each specified hedge server within a date range. Hedge cost is the sum of commissions paid to liquidity providers for hedging client positions. For some hedge servers, net profit from the hedge is also factored into the cost calculation (controlled by a per-server flag).

The procedure exists to support dealing desk KPI reporting and cost analysis. It enables the dealing team to compare hedging costs across different liquidity providers and hedge servers over time. The Hedge.InsertKPIData procedure references this, suggesting it feeds into a periodic KPI data collection pipeline.

Data flow: caller passes two parallel CSV lists (@ServerList of hedge server IDs and @UseNetProfitList of boolean flags) plus a date range. The SP parses both lists using Internal.ConvertListToTable, pairs them by position (ID column), and for each pair queries History.Hedge to sum Commission + optionally NetProfit. Returns one row per hedge server with the computed HedgeCost.

---

## 2. Business Logic

### 2.1 Hedge Cost Calculation

**What**: Per-server cost aggregation with optional net profit inclusion.

**Columns/Parameters Involved**: `@ServerList`, `@UseNetProfitList`, `Commission`, `NetProfit`, `HedgeCost`

**Rules**:
- Base cost is always `ISNULL(SUM(Commission), 0)` from History.Hedge
- If the corresponding @UseNetProfitList flag is 1 (true), adds `ISNULL(SUM(NetProfit), 0)` to the cost
- If the flag is 0 (false), only Commission is included
- Date range filter uses `OpenOccurred BETWEEN @From AND @To`
- Each server in @ServerList is paired with its corresponding flag in @UseNetProfitList by positional ID

**Diagram**:
```
@ServerList:        "101,102,103"      @UseNetProfitList: "1,0,1"
        |                                       |
Internal.ConvertListToTable          Internal.ConvertListToTable
        |                                       |
  ID=1,Param=101                          ID=1,Param=1
  ID=2,Param=102                          ID=2,Param=0
  ID=3,Param=103                          ID=3,Param=1
        |_______________JOIN ON ID______________|
                        |
    For each pair: SUM(Commission) + IIF(UseNetProfit, SUM(NetProfit), 0)
                   FROM History.Hedge
                   WHERE HedgeServerID = {server} AND OpenOccurred BETWEEN @From AND @To
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ServerList | VARCHAR(MAX) | NO | - | CODE-BACKED | Comma-separated list of HedgeServerID values to calculate costs for. Parsed by Internal.ConvertListToTable. FK values to Trade.HedgeServer. |
| 2 | @UseNetProfitList | VARCHAR(MAX) | NO | - | CODE-BACKED | Comma-separated list of boolean flags (0/1), positionally paired with @ServerList. 1 = include net profit in cost calculation, 0 = commission only. |
| 3 | @From | DATETIME | NO | - | CODE-BACKED | Start of the date range (inclusive). Filters History.Hedge.OpenOccurred. |
| 4 | @To | DATETIME | NO | - | CODE-BACKED | End of the date range (inclusive). Filters History.Hedge.OpenOccurred. |
| 5 | HedgeServerID (output) | INT | NO | - | CODE-BACKED | Hedge server identifier from the input list. Cast from VARCHAR parameter to INTEGER. |
| 6 | HedgeCost (output) | MONEY | NO | - | CODE-BACKED | Computed hedge cost for this server in the date range. Formula: SUM(Commission) + optionally SUM(NetProfit) from History.Hedge. Defaults to 0 via ISNULL when no matching hedges exist. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | History.Hedge | FROM (subquery) | Source of Commission and NetProfit for cost aggregation |
| @ServerList | Internal.ConvertListToTable | CROSS JOIN (function) | Parses CSV server list into rows |
| @UseNetProfitList | Internal.ConvertListToTable | CROSS JOIN (function) | Parses CSV flag list into rows |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.InsertKPIData | EXEC | Caller | KPI data collection pipeline calls this to get hedge costs |
| Dealing (user) | GRANT EXECUTE | Permission | Dealing desk service account |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI admin reporting access |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetHedgeCost (procedure)
+-- History.Hedge (table)
+-- Internal.ConvertListToTable (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Hedge | Table | Subquery - SUM(Commission) and SUM(NetProfit) filtered by HedgeServerID and date range |
| Internal.ConvertListToTable | Function | FROM - parses @ServerList and @UseNetProfitList CSV strings into table rows |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InsertKPIData | Stored Procedure | Calls this to get hedge costs for KPI data insertion |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Returns 0 via RETURN statement on completion.

---

## 8. Sample Queries

### 8.1 Execute for two hedge servers

```sql
EXEC Trade.GetHedgeCost
    @ServerList = '101,102',
    @UseNetProfitList = '1,0',
    @From = '2026-01-01',
    @To = '2026-01-31';
```

### 8.2 Query History.Hedge directly for a single server

```sql
SELECT  HedgeServerID,
        SUM(Commission) AS TotalCommission,
        SUM(NetProfit) AS TotalNetProfit,
        SUM(Commission) + SUM(NetProfit) AS TotalCost
FROM    History.Hedge WITH (NOLOCK)
WHERE   OpenOccurred BETWEEN '2026-01-01' AND '2026-01-31'
AND     HedgeServerID = 101
GROUP BY HedgeServerID;
```

### 8.3 Join result with HedgeServer for server names

```sql
DECLARE @Results TABLE (HedgeServerID INT, HedgeCost MONEY);

INSERT INTO @Results
EXEC Trade.GetHedgeCost
    @ServerList = '101,102,103',
    @UseNetProfitList = '1,1,1',
    @From = '2026-01-01',
    @To = '2026-03-31';

SELECT  r.HedgeServerID,
        hs.Name AS ServerName,
        r.HedgeCost
FROM    @Results r
JOIN    Trade.HedgeServer hs WITH (NOLOCK)
        ON hs.HedgeServerID = r.HedgeServerID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. A "Hedge Cost Alignment" Confluence page was discovered but is no longer accessible (404).

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetHedgeCost | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetHedgeCost.sql*
